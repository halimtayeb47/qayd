# Qayd (قَيْد) - AI-Powered Lecture Summarizer 🎓

> **"قَيِّدُوا الْعِلْمَ بِالْكِتَابِ"** — *"Bind knowledge by writing it down."*

**Qayd** is an AI-powered mobile application built with Flutter for university students at the Islamic University of Madinah (Faculty of Computer & Information Systems). It bridges the linguistic and cognitive gap in bilingual university lectures by transforming recorded or imported classroom audio into accurate bilingual transcripts and structured academic notes.

---

## 🚀 Core Features (MVP)

- **🎙️ Live Lecture Audio Recording (FR1):**
  Records directly via device microphone configured natively to **16 kHz Mono 32 kbps AAC**, ensuring optimal transcription quality and small file sizes without heavy video or multi-channel overhead.
- **📁 Audio File Import (FR2):**
  Supports uploading existing `.mp3`, `.m4a`, and `.wav` audio files up to **100 MB** with built-in size validation.
- **⚡ Bilingual Speech-to-Text with Code-Switching (FR3):**
  Powered by **Groq Whisper-large-v3** using `verbose_json` for millisecond-level word and segment timestamps, featuring a custom vocabulary prompt to prevent unwanted translation of English technical terms within Arabic lectures.
- **🧠 Academic Structured Summarization (FR4):**
  Powered by **Google Gemini 1.5 Flash** with JSON Schema enforcement:
  - **Overview:** High-level conceptual synthesis of the lecture.
  - **Key Points:** 3 to 7 bullet points emphasizing major exam-relevant topics.
  - **Key Terms & Definitions:** Glossary of technical terms encountered during the lecture.
- **⏱️ Tap-to-Seek Synchronized Audio Player (FR8):**
  Tapping any transcript segment immediately seeks the audio player to that exact timestamp. The transcript actively highlights the currently playing segment in real time.
- **💾 Offline-First Local Persistence (FR6):**
  All Qayds and subject folders are stored locally on the device using **Hive**, eliminating the need for mandatory cloud logins while ensuring rapid access.
- **🌐 Bilingual UI with Instant RTL Toggle (FR7):**
  Full English and Arabic interface with right-to-left (RTL) support, accessible with a single tap from the AppBar.
- **🗂️ Course Folders & Search (NFR10):**
  Organize lectures into custom subject folders (e.g. *Operating Systems*, *Database Systems*, *AI*) with instant title, transcript, and summary search.
- **✏️ In-App Transcript Editing (NFR11):**
  Allows students to correct or refine lecture transcripts directly from the detail view.

---

## 🏗️ Project Architecture

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart         # API endpoints, models, and code-switching prompts
│   └── theme/
│       └── qayd_theme.dart            # Material 3 Academic Indigo theme (Light & Dark)
├── data/
│   ├── models/
│   │   ├── folder_model.dart          # QaydFolder entity
│   │   └── qayd_model.dart            # Qayd, TranscriptSegment, QaydSummary, KeyTerm
│   └── services/
│       ├── audio_picker_service.dart  # FilePicker with 100 MB validation
│       ├── audio_recording_service.dart# 16kHz Mono 32kbps AAC recording service
│       ├── gemini_summary_service.dart# Gemini 1.5 Flash structured summary client
│       ├── groq_whisper_service.dart  # Groq Whisper client with timestamped segments
│       └── storage_service.dart       # Hive offline storage with orphan file protection
├── providers/
│   └── qayd_provider.dart             # Central ChangeNotifier orchestrating state & pipeline
├── screens/
│   ├── detail/
│   │   └── detail_screen.dart         # S4: Audio player, Tap-to-Seek transcript & summary
│   ├── home/
│   │   └── home_screen.dart           # S1: Folder chips, search, and lecture list
│   ├── processing/
│   │   └── processing_screen.dart     # S3: Real-time multi-stage pipeline status checklist
│   └── record/
│       └── record_screen.dart         # S2: Visualizer, live timer, pause/resume/stop controls
└── main.dart                          # App entry point, MultiProvider & MaterialApp
```

---

## ⚙️ Setup & Running

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.47.0` or later)
- Android Studio / VS Code / Antigravity with Android SDK & Flutter extension
- An active Groq API Key and Google Gemini API Key

### Installation

1. **Clone repository and checkout the `dev` branch:**
   ```bash
   git clone https://github.com/halimtayeb47/qayd.git
   cd qayd
   git checkout dev
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the App with API Keys:**
   You can pass your API keys securely at runtime using `--dart-define`:
   ```bash
   flutter run --dart-define=GROQ_API_KEY="your_groq_key_here" --dart-define=GEMINI_API_KEY="your_gemini_key_here"
   ```
   *(Alternatively, for local offline testing or emulator runs, you can specify your keys directly in `lib/core/constants/api_constants.dart`.)*

---

## 🧪 Testing & Verification

Qayd includes comprehensive unit and smoke tests covering model serialization, AI response parsing, state management, search, and localization:

- **Run all automated tests:**
  ```bash
  flutter test
  ```
  *(13/13 unit tests pass)*

- **Run Flutter static code analysis:**
  ```bash
  flutter analyze
  ```
  *(0 issues found)*

---

## 👥 Contributors & Credits

- **Halim Tayeb**
- **Wasel**

*Department of Information Technology, Islamic University of Madinah*
*Mobile Application Development Course Project*
