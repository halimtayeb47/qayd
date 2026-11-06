#!/usr/bin/env python3
"""
qayd — client-side audio preparation & fragmentation.

This is the exact prep step qayd performs before sending audio to Groq
Whisper. It runs entirely on-device / offline:

  1. Convert any source audio -> 16 kHz mono FLAC.
     (Groq downsamples everything to 16 kHz mono internally anyway, so
      this loses nothing the model was going to discard. FLAC is
      lossless at that rate AND much smaller than WAV -> helps us stay
      under the 25 MB free-tier upload cap.)
  2. Probe duration.
  3. Split into overlapping chunks only when a chunk would exceed
     MAX_BYTES. Each chunk record carries its start offset so the
     transcribe step can convert chunk-local timestamps -> global ones.

Usage:
    python qayd_audio_prep.py <input_audio> [--chunk-min 10] [--overlap 5] [--outdir chunks]

No third-party packages required — it shells out to `ffmpeg`/`ffprobe`.
"""

import argparse
import json
import math
import os
import shutil
import subprocess
import sys

# ---- tunables ---------------------------------------------------------------
# Groq free-tier upload cap is 25 MB. We keep a safety margin so a slightly
# variable encoder never overruns the request limit.
MAX_BYTES = 22 * 1024 * 1024          # ~22 MiB per uploaded chunk (safe < 25 MB)
DEFAULT_CHUNK_SEC = 10 * 60           # 10 minutes
DEFAULT_OVERLAP_SEC = 5.0             # boundary overlap to protect cut words
DEDUP_GAP_SEC = 2.0                   # segments within this gap AND text-similar = duplicate
TARGET_RATE = 16000                   # 16 kHz — Whisper's internal rate
TARGET_CHANNELS = 1                   # mono


def _check_tools():
    for tool in ("ffmpeg", "ffprobe"):
        if shutil.which(tool) is None:
            sys.exit(f"ERROR: `{tool}` not found on PATH. Install ffmpeg first.")


def ffprobe_duration(path):
    """Return media duration in seconds (float)."""
    out = subprocess.check_output(
        [
            "ffprobe", "-v", "error",
            "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1",
            path,
        ],
        text=True,
    ).strip()
    return float(out)


def convert_to_working_file(src, dst):
    """Re-encode src to 16 kHz mono FLAC at dst."""
    subprocess.check_call(
        [
            "ffmpeg", "-y", "-v", "error",
            "-i", src,
            "-ac", str(TARGET_CHANNELS),
            "-ar", str(TARGET_RATE),
            "-c:a", "flac",
            "-sample_fmt", "s16",
            dst,
        ]
    )


def plan_chunks(duration_sec, chunk_sec, overlap_sec):
    """
    Build a list of (index, start, end) chunk windows covering the file.
    Each window after the first begins `overlap_sec` before the previous
    window ended so a word split at a boundary appears in two chunks and
    can be de-duplicated downstream.

    Guards against a non-advancing schedule (overlap >= chunk length would
    loop forever) and against runaway chunk counts.
    """
    if chunk_sec <= 0:
        raise ValueError("chunk_sec must be > 0")
    # The step forward is chunk_sec - overlap_sec; if that's <= 0 we never
    # advance past the start, which is the infinite-loop bug this guards.
    step = chunk_sec - overlap_sec
    if step <= 0:
        raise ValueError(
            f"overlap ({overlap_sec}s) must be smaller than chunk window "
            f"({chunk_sec}s); step would be {step}s"
        )
    # hard ceiling so a huge file can't produce an unbounded manifest
    max_chunks = max(1, int(duration_sec / max(step, 1)) + 4)

    chunks = []
    start = 0.0
    idx = 0
    while start < duration_sec and len(chunks) <= max_chunks:
        end = min(duration_sec, start + chunk_sec)
        chunks.append({"index": idx, "start": round(start, 3), "end": round(end, 3)})
        idx += 1
        if end >= duration_sec:
            break
        start = end - overlap_sec  # next chunk overlaps the tail of this one
    return chunks


def extract_chunk(src, start, end, dst):
    """Write the [start,end) window of src to dst as 16 kHz mono FLAC."""
    subprocess.check_call(
        [
            "ffmpeg", "-y", "-v", "error",
            "-ss", f"{start}",
            "-to", f"{end}",
            "-i", src,
            "-ac", str(TARGET_CHANNELS),
            "-ar", str(TARGET_RATE),
            "-c:a", "flac",
            "-sample_fmt", "s16",
            dst,
        ]
    )


def main():
    ap = argparse.ArgumentParser(description="qayd audio prep & chunking")
    ap.add_argument("input", help="source audio file (m4a/mp3/wav/flac/ogg)")
    ap.add_argument("--chunk-min", type=float, default=DEFAULT_CHUNK_SEC / 60,
                    help="target chunk length in minutes (default 10)")
    ap.add_argument("--overlap", type=float, default=DEFAULT_OVERLAP_SEC,
                    help="boundary overlap in seconds (default 5)")
    ap.add_argument("--outdir", default=None, help="output dir for chunks")
    args = ap.parse_args()

    _check_tools()
    src = os.path.abspath(args.input)
    if not os.path.isfile(src):
        sys.exit(f"ERROR: file not found: {src}")

    outdir = os.path.abspath(args.outdir or (os.path.splitext(src)[0] + "_chunks"))
    os.makedirs(outdir, exist_ok=True)

    duration = ffprobe_duration(src)
    print(f"source     : {src}")
    print(f"duration   : {duration:8.2f} s  ({duration/60:5.2f} min)")
    print(f"outdir     : {outdir}\n")

    # --- 1. convert once, so size probing reflects the real upload format ----
    working = os.path.join(outdir, "working_16k_mono.flac")
    print("converting -> 16 kHz mono FLAC ...")
    convert_to_working_file(src, working)
    wsize = os.path.getsize(working)
    print(f"working file size: {wsize/1e6:7.2f} MB "
          f"({wsize/duration/1000:5.1f} KB/s)\n")

    chunk_sec = args.chunk_min * 60
    overlap = args.overlap

    # --- 2. decide whether we even need to split --------------------------
    if wsize <= MAX_BYTES:
        print("file fits under the 25 MB cap -> single request, no chunking needed.")
        manifest = {
            "source": src,
            "duration_sec": duration,
            "chunked": False,
            "chunks": [{"index": 0, "start": 0.0, "end": round(duration, 3),
                        "file": os.path.basename(working),
                        "bytes": wsize}],
        }
    else:
        # estimate a chunk length that lands safely under the byte cap
        bytes_per_sec = wsize / duration
        safe_chunk_sec = min(chunk_sec, (MAX_BYTES * 0.9) / bytes_per_sec)
        windows = plan_chunks(duration, safe_chunk_sec, overlap)
        print(f"file > {MAX_BYTES/1e6:.0f} MB -> splitting into "
              f"{len(windows)} chunks of ~{safe_chunk_sec/60:.1f} min "
              f"(+{overlap:g}s overlap)\n")
        files = []
        for w in windows:
            fn = f"chunk_{w['index']:02d}.flac"
            fp = os.path.join(outdir, fn)
            extract_chunk(working, w["start"], w["end"], fp)
            size = os.path.getsize(fp)
            flag = "" if size <= MAX_BYTES else "   <-- OVER LIMIT!"
            print(f"  chunk {w['index']:02d}: {w['start']:8.1f}s - {w['end']:8.1f}s "
                  f"  {size/1e6:6.2f} MB{flag}")
            files.append({**w, "file": fn, "bytes": size})
        manifest = {
            "source": src,
            "duration_sec": duration,
            "chunked": True,
            "overlap_sec": overlap,
            "target_rate": TARGET_RATE,
            "chunks": files,
        }

    # --- 3. show how a chunk-local timestamp maps to the global timeline ---
    print("\n--- timestamp mapping (chunk-local -> global) ---")
    for c in manifest["chunks"][:3]:  # demo first few
        local_start, local_end = 12.4, 18.8  # example local segment from Whisper
        gs = c["start"] + local_start
        ge = c["start"] + local_end
        print(f"  chunk {c['index']:02d} local [{local_start:5.1f},{local_end:5.1f}] "
              f"+ offset {c['start']:7.1f}  ->  global [{gs:7.1f},{ge:7.1f}]")

    mpath = os.path.join(outdir, "manifest.json")
    with open(mpath, "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"\nmanifest written -> {mpath}")
    print("done. feed each chunk file to qayd_groq_test.py, then merge by offset.")


if __name__ == "__main__":
    main()
