#!/usr/bin/env python3
"""
qayd — Groq Whisper transcription smoke test + segment merge.

Runs on YOUR machine (needs outbound network). No SDK required — it calls
the OpenAI-compatible audio endpoint directly with `requests`, so it's the
same HTTP your Flutter dio layer will eventually send.

  POST https://api.groq.com/openai/v1/audio/transcriptions
    model                     = whisper-large-v3        (or ...-turbo)
    file                      = <chunk>.flac
    response_format           = verbose_json
    timestamp_granularities[] = segment
    language                  = (omitted -> auto-detect ar/en/mixed)

Then it merges every chunk's segments onto the GLOBAL lecture timeline
and de-duplicates the overlap region.

Usage:
    setx GROQ_API_KEY "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"          # Windows (or: export GROQ_API_KEY=...)
    python qayd_groq_test.py <manifest.json | audio_file> [--turbo]

Pass it either the manifest.json produced by qayd_audio_prep.py (recommended —
it loops all chunks and merges) OR a single audio file to test one-off.
"""

import argparse
import json
import os
import sys

try:
    import requests
except ImportError:
    sys.exit("ERROR: `requests` not installed. Run:  pip install requests")

API_URL = "https://api.groq.com/openai/v1/audio/transcriptions"
DEFAULT_MODEL = "whisper-large-v3"
TURBO_MODEL = "whisper-large-v3-turbo"


# --------------------------------------------------------------------------- #
#  transcription                                                               #
# --------------------------------------------------------------------------- #
def transcribe(path, api_key, model):
    """Send one audio file to Groq; return parsed verbose_json response."""
    with open(path, "rb") as fh:
        files = {"file": (os.path.basename(path), fh, "audio/flac")}
        data = {
            "model": model,
            "response_format": "verbose_json",
            # ask for segment-level timestamps (this is what powers tap-to-seek)
            "timestamp_granularities[]": "segment",
            # `language` intentionally omitted -> let Whisper auto-detect ar/en/mixed
        }
        r = requests.post(
            API_URL,
            headers={"Authorization": f"Bearer {api_key}"},
            files=files,
            data=data,
            timeout=300,
        )
    if r.status_code != 200:
        raise RuntimeError(f"Groq {r.status_code}: {r.text[:400]}")
    return r.json()


# --------------------------------------------------------------------------- #
#  merge: chunk-local segments -> global timeline, drop overlap duplicates     #
# --------------------------------------------------------------------------- #
def _norm(t):
    return " ".join(t.lower().split())


def _similar(a, b):
    """Normalized-text similarity in [0,1] via token-set Jaccard + equality bonus."""
    ta, tb = set(_norm(a).split()), set(_norm(b).split())
    if not ta or not tb:
        return 0.0
    jac = len(ta & tb) / len(ta | tb)
    return 1.0 if _norm(a) == _norm(b) else jac


# Segments that end/start within this many seconds of each other are candidates
# for boundary duplicates created by the audio overlap window.
_DEDUP_GAP_SEC = 2.0
_SIM_THRESHOLD = 0.6


def merge_segments(chunk_results):
    """
    chunk_results: list of (chunk_offset, segments[]) where each segment has
    start/end/text in *chunk-local* seconds.

    Returns globally-timestamped, de-duplicated, sorted segment list.

    A duplicate = the previous kept segment and this one are close in time
    (overlapping OR within _DEDUP_GAP_SEC of each other, which catches
    *touching* boundaries like 8.2 -> 8.2 that strict overlap misses) AND
    their text is sufficiently similar. We keep the longer/cleaner wording.
    """
    global_segs = []
    for offset, segs in chunk_results:
        for s in segs:
            global_segs.append({
                "startSec": round(offset + s["start"], 3),
                "endSec":   round(offset + s["end"], 3),
                "text":     s["text"].strip(),
            })

    global_segs.sort(key=lambda x: (x["startSec"], x["endSec"]))

    merged = []
    for seg in global_segs:
        if merged:
            prev = merged[-1]
            # closeness in time: true overlap OR adjacent-within-gap
            overlap = min(prev["endSec"], seg["endSec"]) - max(prev["startSec"], seg["startSec"])
            gap = seg["startSec"] - prev["endSec"]
            close_in_time = overlap > 0 or (0 <= gap <= _DEDUP_GAP_SEC)
            if close_in_time and _similar(prev["text"], seg["text"]) >= _SIM_THRESHOLD:
                # keep the longer (usually cleaner) boundary wording
                if len(seg["text"]) > len(prev["text"]):
                    merged[-1] = seg
                continue
        merged.append(seg)
    return merged


# --------------------------------------------------------------------------- #
def main():
    ap = argparse.ArgumentParser(description="qayd Groq transcription test")
    ap.add_argument("input", help="manifest.json OR a single audio file")
    ap.add_argument("--turbo", action="store_true",
                    help="use whisper-large-v3-turbo (cheaper, slightly lower WER)")
    ap.add_argument("--model", default=None, help="override model name")
    args = ap.parse_args()

    api_key = os.environ.get("GROQ_API_KEY")
    if not api_key:
        sys.exit(
            "ERROR: GROQ_API_KEY not set.\n"
            "  Windows:  setx GROQ_API_KEY \"gsk_...\"   (open a NEW terminal after)\n"
            "  bash:     export GROQ_API_KEY=gsk_..."
        )
    model = args.model or (TURBO_MODEL if args.turbo else DEFAULT_MODEL)
    print(f"model: {model}\n")

    inp = args.input
    jobs = []  # (offset_seconds, file_path)

    if inp.lower().endswith(".json"):
        with open(inp) as f:
            manifest = json.load(f)
        base = os.path.dirname(os.path.abspath(inp))
        for c in manifest["chunks"]:
            jobs.append((c["start"], os.path.join(base, c["file"])))
    else:
        jobs.append((0.0, os.path.abspath(inp)))

    chunk_results = []
    detected_lang = None
    for offset, path in jobs:
        if not os.path.isfile(path):
            sys.exit(f"ERROR: missing audio file {path}")
        print(f"transcribing {os.path.basename(path)}  (offset {offset:.0f}s) ...")
        resp = transcribe(path, api_key, model)
        detected_lang = detected_lang or resp.get("language")
        segs = resp.get("segments") or []
        print(f"   -> {len(segs)} segments, detected language: "
              f"{resp.get('language')}")
        chunk_results.append((offset, segs))

    segments = merge_segments(chunk_results)

    print("\n================ RESULT ================")
    print(f"language : {detected_lang}")
    print(f"segments : {len(segments)} (after overlap de-dup)\n")
    for s in segments:
        m0, s0 = divmod(int(s["startSec"]), 60)
        m1, s1 = divmod(int(s["endSec"]), 60)
        print(f"[{m0:02d}:{s0:02d}-{m1:02d}:{s1:02d}]  {s['text']}")

    out = os.path.splitext(os.path.abspath(inp))[0] + "_transcript.json"
    payload = {"language": detected_lang, "model": model,
               "segments": segments}
    with open(out, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    print(f"\nsaved -> {out}")


if __name__ == "__main__":
    main()
