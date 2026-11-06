# qayd (قَيْد) — 5-Week Project Roadmap

*AI-Powered Lecture Summarizer · Mobile Application Development · Islamic University of Madinah*

> Dates are approximate and meant as weekly checkpoints, not hard day boundaries.

## 1. Snapshot

| Item | Detail |
|------|--------|
| **Team** | Halim Tayeb, Wasel (2 developers) |
| **Timeline** | 5 weeks — kickoff 2026-10-09, target finish ~2026-11-13 |
| **Methodology** | SDLC (requirements → design → implementation → testing → deployment), run iteratively because of the compressed timeline |
| **Primary goal** | A working, demo-ready Flutter app; documentation kept light and practical |
| **Scope strategy** | Lean MVP first; stretch features only once the core flow is stable |

## 2. Scope (MoSCoW)

**Must have — the core "Qayd" flow (MVP):**

- Record a lecture in-app, or upload/pick an existing audio file
- Transcribe audio to text (Speech-to-Text model)
- Generate a structured summary from the transcript (LLM): summary + key points + key terms
- View the result (transcript and summary) on a detail screen
- Save each "Qayd" locally and list past Qayds on the home screen
- Arabic + English support (RTL-aware UI)

**Should have (only if the core is stable):**

- Subject/semester folders to organize Qayds
- Auto-generated quiz questions from the lecture

**Could have (stretch):**

- Cloud sync (Firebase Auth + Firestore + Storage)
- Audio "podcast" summary (text-to-speech)
- Share/export a summary as PDF or text

**Won't have (this version):**

- Lecture-to-lecture comparison, multi-user collaboration, on-device offline transcription

## 3. How the SDLC fits into 5 weeks

With only 5 weeks the phases overlap rather than run strictly one after another. Week 1 is mostly **requirements + design**, Weeks 2–3 are **implementation**, Week 4 is **testing + hardening** (plus a little stretch work), and Week 5 is **deployment + finalization**. Testing is continuous from Week 2 onward, not saved for the end. Every week ends in a working, demonstrable build (an "increment") so progress is always visible and the deadline risk stays low.

## 4. Tech stack & key decisions

| Concern | Choice | Note |
|---------|--------|------|
| Framework | Flutter / Dart (SDK ^3.13.4) | already scaffolded |
| State management | Provider (or Riverpod) | Provider is the simplest option for a 2-person MVP |
| Audio recording | `record` | microphone capture |
| File picking | `file_picker` | upload an existing audio file |
| Audio playback | `just_audio` | replay recordings |
| HTTP / API calls | `dio` | handles multipart audio upload cleanly |
| Local storage | `hive` (or `sqflite`) | store Qayd records offline-first |
| Speech-to-Text | OpenAI Whisper API (`whisper-1`) | supports Arabic |
| Summarization LLM | Google Gemini (`gemini-1.5-flash`) | cheap, fast, Arabic-capable |

**⚠️ API-key security (read this).** Calling Whisper/Gemini directly from the app means shipping your secret API keys inside the installed app, where they can be extracted. For a graded classroom demo that is a known, accepted risk — but the correct design is a thin serverless proxy (e.g., a Firebase Cloud Function) that holds the keys, with the app calling that proxy instead. Recommendation: put all API calls behind a service interface so you can start with direct calls for speed and swap in a proxy later without touching the UI. Never commit keys to git — load them via `--dart-define` or a `.env` file and make sure that file is in `.gitignore`.

**Simplification option.** Gemini 1.5 can accept audio directly and transcribe + summarize in a single call. The proposal specifies two models (Whisper + Gemini), which is worth showcasing, so keep that two-stage pipeline as the main design — but Gemini-audio is a solid fallback if Whisper integration stalls.

## 5. Architecture (brief)

A layered structure keeps UI and logic separate and lets two people work in parallel without stepping on each other:

```
lib/
  models/     # Qayd entity, Summary, KeyTerm, ...
  services/   # audio recorder, transcription (Whisper), summarizer (Gemini), storage
  state/      # providers / controllers
  screens/    # home (Your Qayds), record/new, processing, detail
  widgets/    # reusable UI (cards, loaders, empty states)
  theme/      # colors, typography, branding microcopy
```

Core data model — a **Qayd**: `id`, `title`, `createdAt`, `audioPath`, `transcript`, `summary`, `keyPoints[]`, `keyTerms[]`, optional `folderId`.

## 6. Week-by-week plan

### Week 1 (Oct 9–15) — Requirements & Design
- Write light functional + non-functional requirements and 3–4 use cases / user stories (~2 pages)
- Lock the MVP scope (section 2); sketch simple wireframes for the 4 screens
- Decide the tech stack, create API keys (OpenAI + Gemini), set up git and `.gitignore`
- Clean the scaffold, create the folder structure, add dependencies, build an empty navigation shell
- **Deliverable:** light SRS + wireframes + running app skeleton with navigation
- **Milestone:** app launches on a real device and navigates between (empty) screens

### Week 2 (Oct 16–22) — Implementation 1: Audio → Transcript
- Record screen (start/stop, timer) and the file-upload path
- Transcription service: send audio to Whisper, receive a transcript
- Processing/loading screen with clear progress feedback
- Save the raw audio file locally
- **Deliverable:** record or upload → see an accurate transcript
- **Milestone:** first half of the pipeline works end-to-end

### Week 3 (Oct 23–29) — Implementation 2: Summary & Persistence
- Summarization service: transcript → Gemini → summary, key points, key terms (prompt-engineered, Arabic-aware)
- Detail screen presenting transcript + summary in tabs/cards
- Local persistence (Hive): save Qayds, list them on the home screen, open and delete
- **Deliverable:** full core flow working; Qayds persist between app launches
- **Milestone:** MVP feature-complete

### Week 4 (Oct 30–Nov 5) — Testing & Hardening
- Error handling: no network, API failure, empty/too-long audio, denied mic permission
- Test with real lectures (Arabic + English), short and long; fix accuracy and prompt issues
- Widget tests for the key screens + a short written manual test plan
- UI/UX polish and branding ("Start Qayd", "Your Qayds"), empty/loading states, RTL check
- Add **one** stretch feature only if the core is stable (folders *or* quiz)
- **Deliverable:** stable, tested app
- **Milestone:** no known crashes in the core flow

### Week 5 (Nov 6–13) — Deployment & Finalization
- Final bug-fixing and polish; app icon and splash screen
- Build the release Android APK; optionally deploy the API proxy function
- Write the README + a short user guide; prepare the final report, screenshots, and a demo video
- Rehearse the presentation
- **Deliverable:** submitted project + demo-ready build
- **Milestone:** everything handed in

## 7. Suggested ownership (adjust freely — you're pairing)

- **Halim:** services / AI layer (Whisper + Gemini integration, prompt design), data model & storage
- **Wasel:** UI screens, navigation, theming/branding, wireframes
- **Shared:** Week 1 requirements & design, Week 4 testing, Week 5 report & demo
- Review each other's commits so both of you understand the whole app — important for grading and the defense.

## 8. Risks & mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Late start / only 5 weeks | High | Strict weekly milestones; cut stretch goals first |
| API costs | Medium | Use Gemini Flash; cap recording length (~45–60 min); test on short clips |
| API keys exposed in the app | High | Keep keys out of git; plan a serverless proxy; interface-based services |
| Whisper accuracy on long/Arabic audio | Medium | Test early; chunk long audio; allow manual transcript edits |
| Scope creep | Medium | MVP first; stretch features gated on a stable core |
| 2-person bandwidth | Medium | Clear ownership + pairing; weekly demoable increments |

## 9. Definition of Done (MVP)

A user can open qayd, record or upload a lecture, watch it get transcribed and summarized, read a clear structured summary, and find that Qayd saved in their list the next time they open the app — in both Arabic and English, without crashing.

## 10. This week's immediate next steps

1. Confirm this roadmap (and tell me anything you'd change).
2. Create the OpenAI and Gemini API keys.
3. I draft the light SRS + wireframes and set up the Flutter folder structure + navigation shell.
