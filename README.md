# Qayd (قَيْد) - AI-Powered Lecture Summarizer 🎓

> **"قَيِّدُوا الْعِلْمَ بِالْكِتَابِ"** — *"Bind knowledge by writing it down."*

**Qayd** is an AI-powered, local-first mobile application built with Flutter for university students at the Islamic University of Madinah (Faculty of Computer Science & Information Technology). It bridges the linguistic and cognitive gap in bilingual university lectures by transforming recorded or imported classroom audio into accurate transcripts and structured academic study notes.

---

## 🚀 Core Features (MVP)

- **🎙️ Live Lecture Audio Recording (FR1):**
  Records directly via device microphone configured natively to **44.1 kHz Mono 64 kbps AAC** with auto-gain (`AndroidAudioSource.mic`, Bluetooth hijack disabled), ensuring crisp bilingual transcription quality without multi-channel overhead.
- **📁 Audio File Import (FR2):**
  Supports picking `.mp3`, `.m4a`, `.wav`, `.aac`, `.ogg`, `.webm`, and `.flac` files, automatically compresses them via FFmpeg (`16 kHz Mono 32 kbps MP3`), validates that compressed size is under **100 MB**, and routes transcribable lectures straight to processing.
- **⚡ Bilingual Speech-to-Text with Speech Auto-Detection (FR3):**
  Powered by **Groq Whisper-large-v3** using `verbose_json` for sub-second word and segment timestamps. Features true speech language auto-detection and an instruction-free technical glossary prompt (`API, database, backend, CPU, thread, process...`) preserving Latin script for technical terms without forcing languages or translating.
- **🛡️ 4-Layer Anti-Hallucination Shield:**
  Automated real-time filtering that suppresses Whisper silence hallucinations:
  1. *Acoustic Confidence Filter:* Drops segments where `no_speech_prob > 0.6` and `avg_logprob < -1.0`.
  2. *Repetition Loop Filter:* Drops segments where `compression_ratio > 2.4`.
  3. *Phantom Credit Blocklist:* Strips known Whisper hallucination strings and YouTube ghost credits (*"نانسي قنقر"*, *"اشترك في القناة"*).
  4. *Consecutive Deduplication:* Drops identical consecutive phrases repeated across silence.
- **🧠 Academic Structured Summarization (FR4):**
  Powered by **Google Gemini Flash** with strict JSON schema enforcement:
  - **Overview:** Crisp conceptual synthesis of the lecture.
  - **Topic Breakdown:** Chronological topic cards with clickable `[MM:SS]` audio timestamps.
  - **Key Points:** High-yield bullet points emphasizing major exam-relevant topics.
  - **Key Terms & Definitions:** Glossary of technical terms encountered during the lecture.
  - **Bilingual Summary Choice:** Seamless in-app toggle between Arabic (default) and English academic summaries.
- **⏱️ Tap-to-Seek Synchronized Audio Player (FR8):**
  Tapping any transcript segment immediately seeks the audio player to that exact timestamp. The transcript actively highlights the currently playing segment in real time.
- **📄 Publication-Grade Arabic PDF Export:**
  In-house PDF generation engine (`PdfExportService`) resolving bidirectional Unicode character-reversal through word-level un-reversing into Unicode Presentation Forms-B (`0xFE70`–`0xFEFF`), producing pristine, print-ready bilingual lecture briefs with official Qayd branding.
- **💾 Offline-First Local Persistence (FR6):**
  All Qayds and subject folders are stored locally on the device using **Hive CE**, eliminating the need for mandatory cloud logins while ensuring rapid offline access.
- **🌐 Native Bilingual UI with Instant RTL Toggle (FR7):**
  Full English and Arabic interface with right-to-left (RTL) support and zero RenderFlex layout overflows across all screen sizes.
- **🗂️ Course Folders & Search (NFR10):**
  Organize lectures into custom subject folders (e.g. *Operating Systems*, *Database Systems*, *Software Engineering*) with instant title, transcript, and summary search.
- **✏️ In-App Transcript Editing (NFR11):**
  Allows students to correct or refine lecture transcripts directly from the detail view.

---

## 🏗️ Project Architecture

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart             # API endpoints, models, and code-switching glossary
│   └── theme/
│       └── qayd_theme.dart                # Material 3 Academic Indigo theme (Light & Dark)
├── data/
│   ├── models/
│   │   ├── folder_model.dart              # QaydFolder entity
│   │   └── qayd_model.dart                # Qayd, TranscriptSegment, QaydSummary, SummarySection, KeyTerm
│   └── services/
│       ├── audio_compression_service.dart # FFmpeg 16kHz Mono 32kbps MP3 compressor (< 100 MB gate)
│       ├── audio_picker_service.dart      # FilePicker for external lecture audio imports
│       ├── audio_recording_service.dart   # 44.1kHz Mono 64kbps AAC mic recording service
│       ├── gemini_summary_service.dart    # Gemini Flash structured summary client
│       ├── groq_whisper_service.dart      # Groq Whisper client with 4-Layer Hallucination Shield
│       ├── pdf_export_service.dart        # Publication-grade Arabic PDF export engine
│       └── storage_service.dart           # Hive CE offline storage with orphan file protection
├── providers/
│   └── qayd_provider.dart                 # Central ChangeNotifier orchestrating state & pipeline
├── screens/
│   ├── detail/
│   │   └── detail_screen.dart             # S4: Audio player, Tap-to-Seek transcript & summary
│   ├── home/
│   │   └── home_screen.dart               # S1: Folder chips, search, and lecture list
│   ├── processing/
│   │   └── processing_screen.dart         # S3: Real-time multi-stage pipeline status checklist
│   ├── record/
│   │   └── record_screen.dart             # S2: Visualizer, live timer, pause/resume/stop controls
│   └── splash/
│       └── qayd_splash_gate.dart          # Animated Qaf splash screen with Android 12+ compatibility
├── widgets/
│   └── qayd_actions.dart                  # Shared rename, move, edit transcript, and delete dialogs
└── main.dart                              # App entry point, MultiProvider & MaterialApp
```

---

## ⚙️ Setup & Running

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.4` or later)
- Android Studio / VS Code / Antigravity with Android SDK & Flutter extension
- An active Groq API Key and Google Gemini API Key

### Installation

1. **Clone repository:**
   ```bash
   git clone https://github.com/halimtayeb47/qayd.git
   cd qayd
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure & Run the App with API Keys:**
   Copy `.env.example` to `.env`, add your `GROQ_API_KEY` and `GEMINI_API_KEY`, and pass it at runtime:
   ```bash
   flutter run --dart-define-from-file=.env
   ```
   *(You can also pass keys inline via `--dart-define=GROQ_API_KEY="..." --dart-define=GEMINI_API_KEY="..."`.)*

---

## 🧪 Testing & Verification

Qayd enforces automated testing across all business logic, data models, AI parsing, PDF shaping, and UI widgets:

- **Run all automated tests:**
  ```bash
  flutter test
  ```
  *(**40/40 tests passing**, 0 failed, 0 flaky)*

- **Run Flutter static code analysis:**
  ```bash
  flutter analyze
  ```
  *(**0 issues found** across entire codebase)*

---

## 👥 Contributors & Credits

- **Halim Tayeb**
- **Wasel Mohammed Almahri**

**Course Supervisor:** Mr. Ahmed Almatrafi  
*Faculty of Computer Science & Information Technology, Islamic University of Madinah*  
*Mobile Application Development Course Project (CS442)*
