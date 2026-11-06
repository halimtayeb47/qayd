# qayd — Project Handoff

**Context for whoever picks this up (human or AI agent).** Everything below is the current, agreed state. Where something is marked LOCKED, treat it as decided — don't reopen it without the team. The `lib/` Flutter app is essentially a fresh scaffold; almost all work so far is requirements, design, and a validated AI-pipeline proof. The next phase is implementation.

---

## 1. What qayd is

An **AI-powered lecture summarizer** for students at the Islamic University of Madinah. A student records a live lecture or imports an audio file → the app transcribes it (Arabic, English, or code-switched) → generates an English study summary (overview, key points, key terms) → the student taps any transcript line to jump to that exact moment in the audio.

Built in **Flutter** (Dart SDK ^3.13.4). Team: **Halim Tayeb** and **Wasel**. It's a ~5-week university course project (Mobile Application Development), target ~2026-11-13. We run it through a compressed SE lifecycle: requirements → design → implementation → testing.

The name is from the Arabic proverb "knowledge is a hunted prey, and writing is its tether (qayd)."

---

## 2. Locked scope — MVP behavior

- Record live in-app **or** import `.m4a` / `.mp3` / `.wav` (cap: **100 MB / 60 min**).
- Transcribe **AR + EN + code-switched** speech with **Groq Whisper-large-v3**; keep **timestamped segments**.
- Generate an **English-only** structured summary (overview / keyPoints / keyTerms) with **Gemini Flash**. The transcript stays in the spoken language; only the summary is English.
- **Tap-to-seek**: tap a transcript segment → seek audio; highlight the playing segment.
- **Local-first persistence** (Hive) for audio path, transcript, summary, metadata, processing state, folders.
- **Thin serverless proxy** holds all API keys — none ship in the binary.
- **Bilingual EN/AR UI with RTL.**
- Organization: folders + nested subfolders; a Qayd may be unfiled. Manage (rename/delete/move), transcript edit, summary regenerate.

**Out of scope (do not build):** quiz generation, PDF export, cloud sync/Firestore, collaboration, Arabic summary output, in-lecture notes/photos. Wasel's broader "Zubdah" concept features are parked as Phase 2.

---

## 3. Requirements (doctor-approved reclassification)

The doctor ruled *Manage / Edit / Organize* are **NFRs, not FRs**. Current clean numbering:

- **FR1** record · **FR2** import · **FR3** transcribe w/ timestamps · **FR4** English summary · **FR5** view transcript+summary · **FR6** local save + newest-first list · **FR7** bilingual UI/RTL · **FR8** tap-to-seek + highlight.
- **NFR1–NFR8** perf/usability/reliability/security-cost/portability/maintainability/accessibility.
- **NFR9** manage Qayd · **NFR10** organize folders · **NFR11** edit transcript.
- **FR12 (quiz) was deleted** — never reintroduce it.

---

## 4. Technical stack & architecture

- **Flutter + Material 3**, **Provider** for state, **Hive** for local DB, **repository pattern**, layered/MVVM-lite.
- Planned packages: `provider`, `record`, `file_picker`, `just_audio`, `dio`, `hive` + `hive_flutter`, `path_provider`, `uuid`.
- **Android 8+** first, platform-neutral code for later.
- Architecture: `Flutter app → thin serverless proxy → Groq / Gemini`. App does local audio prep, owns all artifacts, runs UI + retry. Proxy only attaches secrets and forwards.

### Data model (locked)
```dart
enum QaydStatus { recording, transcribing, transcribed, summarizing, done, failed }
enum QaydLanguage { ar, en, mixed }
class TranscriptSegment { double startSec; double endSec; String text; }
class Qayd { id, title, createdAt, durationSec, audioPath, language,
             transcript, segments, summary, status, folderId }
```

### Processing states
`recording → transcribing → transcribed → summarizing → done` (+ `failed`, recoverable). **Critical invariant: persist the transcript before requesting the summary** — a summary failure must never lose the transcript.

---

## 5. AI pipeline — validated, with hard numbers

**Decision: use hosted APIs, not on-device models.** The Arabic code-switching requirement forces a large model (large-v3 ≈ 1.5 GB), and the small on-device models that would fit a phone are too weak on Arabic. Local on-device STT/VAD is scoped future work only.

### Confirmed Groq free-tier limits (from the doctor's own dashboard screenshots)
| Model | RPM | RPD | ASH (audio sec/hr) | ASD (audio sec/day) |
|---|---|---|---|---|
| whisper-large-v3 | 20 | 2000 | 7200 (2 h) | 28800 (8 h) |
| whisper-large-v3-turbo | 20 | 2000 | 7200 | 28800 |

- **Upload cap: 25 MB free tier** (100 MB dev tier). Min billed length 10 s. Only first audio track transcribed. Timestamp granularity `segment` or `word`.
- Price: large-v3 **$0.111/hr (WER 10.3%)**, turbo **$0.04/hr (WER 12%, no translation)**.
- Groq downsamples all input to **16 kHz mono** internally → so client-side convert to **16 kHz mono 32 kbps MP3** (or lossless FLAC). At 32 kbps a 60-min lecture ≈ **14 MB → fits in ONE request**. **Chunking is the rare path, not the common one.**

### Confirmed Gemini free-tier (user's dashboard = **Gemini 2.5 Flash Lite**)
- **20 RPD** · 10 RPM · ~250K TPM. **20 requests/day is the binding constraint** — every summary attempt, retry, and regenerate burns one. Counted **per project, not per key** (extra keys don't help).
- Cost/hour of lecture: **free tier $0.00 · typical paid ≈ $0.12 · max ≈ $0.35**. Transcription is ~95% of cost.
- **Privacy:** free tier is an "unpaid service" — prompts/responses can train Google. Enabling billing (even at $0 actual spend) moves to paid data handling. Recommend enabling billing before a real demo.

### Audio prep & fragmentation (implemented + tested offline)
- Convert to 16 kHz mono. If the working file > ~22 MB, split into sequential chunks with **~5 s overlap**; convert each chunk-local timestamp to global via `global = chunkOffset + local`.
- Merge: sort by start, then **de-duplicate boundary repeats** using temporal proximity **and** text similarity — must catch *touching* boundaries (e.g. `8.2 → 8.2`, zero-width overlap) not just true overlap. Keep the longer/cleaner wording.
- Scripts already built and verified: `tests/qayd_audio_prep.py` (prep/chunk) and `tests/qayd_groq_test.py` (transcribe + merge). The merge dedup and the non-advancing-chunk guard were real bugs found and fixed.

---

## 6. Groq API evaluation — DONE (was blocking)

Wasel ran 3 real clips through Groq large-v3 (`index.js`, `groq-sdk`, FFmpeg `-ac 1 -ar 16000 -b:a 32k`). Findings:

- **Code-switching works** — the killer requirement. In the programming-tutorial clip, `API`, `Database`, `request`, `browser` stay in **Latin script inside the Arabic word stream** with correct sub-second word timestamps.
- **The `prompt` field is the control knob.** Adding "transcribe verbatim, strict code-switching, English terms in Latin script (list examples)" turned a 124-segment, drift-prone output into a tighter 101-segment output with English preserved. **Lock this prompt into the app.**
- `language` returns only the **dominant** language → detect `QaydLanguage.mixed` by scanning script diversity in text, not the language field.
- Use `segment` granularity only in production (word payload is bloat — 1550 entries for 16 min).

**Still unproven:** nothing tested exceeded 25 MB, so the multi-chunk/merge path is only synthetic-verified. Keep it as a tested fallback. Also **Gemini summarization is not yet tested end-to-end** — next AI task.

---

## 7. Design & identity — LOCKED

- **"Academic Indigo" M3** light+dark palette, **IBM Plex** type, **q/ق bilingual monogram** (indigo bowl + tail, two teal qaf dots). Single source: `qayd_theme.dart`.
- Brand concept: **Tether Line + Lecture Thread** — every study statement tethers back to an audio moment.
- Design system, Figma specs, interactive HTML prototype all exist (see §9). Screens: **S1 Home (folder-first), S2 New Qayd, S3 Processing, S4 Detail + Settings sheet.**
- Folder model: Home is folder-first but unfiled Qayds stay visible; folders nest; overflow menus = rename/delete/add-to-folder; prevent folder-in-itself moves; delete-folder must explain contents' fate.

---

## 8. Immediate next steps (what we will do)

1. **Rotate the exposed Groq key** — a live `gsk_` was shared in a `.env`; move all keys into the serverless proxy before any shared build.
2. **Test Gemini Flash summarization** on one of the real transcripts (e.g. the API-tutorial transcript) — the only untested AI stage. Verify the structured `{overview, keyPoints[], keyTerms[{term,definition}]}` output and the **20 RPD** limit.
3. **Stand up the thin proxy** (Cloud Function or small Node service — Wasel's Groq test already runs Node, so Node is the natural choice).
4. **Start the Flutter app** in `lib/`: wire `qayd_theme.dart`, the `Qayd`/`TranscriptSegment` models + Hive adapters, repository, recorder (`record`), importer (`file_picker`), audio prep, dio calls to the proxy, `just_audio` playback + tap-to-seek, and the FR/NFR checklist per `qayd_design_developer.md` §4.
5. **Port the Python prep/merge logic to Dart** (`qayd_audio_prep.py` → client-side ffmpeg/chunk; `qayd_groq_test.py` merge → Dart segment merger). Or call ffmpeg via a package.
6. Keep the **20 RPD** guard: local decrement counter so retries can't silently burn the daily pool.

---

## 9. File inventory (project root = `Projects/qayd/`)

**App source:** `qayd_theme.dart` (M3 theme, single truth) · `lib/` (fresh scaffold) · `pubspec.yaml`

**Locked specs / docs:**
- `qayd_design_developer.md` — authoritative dev spec: FR/NFR, screens, data model, ADRs, build checklist.
- `qayd_technical_processing_pipeline.md` + `.pdf` + `_landscape.pdf` — instructor-facing pipeline (local/cloud boundary, fragmentation, recovery, evaluation).
- `qayd_design_proof_of_concept.pdf` — doctor-facing PoC (idea, MVP, requirements, architecture, competitors).
- `qayd_groq_api_report.docx` — Groq evaluation write-up (Halim house theme; instructor "Mr. Ahmed Almatrafi", authors Halim + Wasel).
- `qayd_figma_design_spec.md`, `qayd_home_figma_build_sheet.md`, `qayd_figma_handoff_checklist.md`, `qayd_design_tokens.json` — design→Figma handoff.
- `qayd_visual_identity.html`, `qayd_interactive_prototype.html`, `qayd_monogram.svg`, `qayd_mark_mono.svg`, `qayd_app_icon.svg`, `qayd_app_icon_dark.svg`.
- `project_roadmap.md`, `project_comparison.md`, `project_proposal.html`, `name_explanation.md`.

**Test harness:** `tests/qayd_audio_prep.py`, `tests/qayd_groq_test.py`. Wasel's JS test: `index.js`, `package.json`, and transcript outputs `output*.json` (kept as evaluation evidence).

**Generator scripts (in session outputs, not committed):** `make_groq_report.py`, `groq_report_spec.json`, `build_pipeline_pdf.py` — regenerate the report/PDFs if content changes.

---

## 10. Standing cautions for the next agent

- **Never reintroduce FR12/quiz** or move NFR9–11 back into FR — the doctor fixed that numbering.
- **Summary is English-only** by locked decision; don't add Arabic summary output.
- **Transcript-persistence-first** is the core reliability invariant.
- **Chunking must handle touching-boundary duplicates** and must guard against non-advancing windows (overlap ≥ chunk).
- **20 RPD Gemini cap** is the real constraint — design retries around it.
- The Groq/Gemini free-tier numbers above came partly from dashboard screenshots and partly from docs; rate limits have moved during 2026 — verify live in the consoles before quoting them in the paper.
- This environment has **no outbound network** — PyPI/npm installs and live API calls must run on the developer's own machine.
