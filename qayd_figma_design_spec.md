# qayd — Figma Design System & MVP Screen Specification

**Purpose:** a reusable design foundation for future products, expressed through a distinctive qayd experience rather than a generic mobile template.

**Audience:** students capturing university lectures; instructor-facing MVP prototype; bilingual English/Arabic UI with RTL support.

**Design thesis:** qayd is a tether for fleeting knowledge. The interface should make the journey from sound to retained understanding visible: capture → transcribe → shape → revisit. It should feel scholarly, calm, trustworthy, and precise, with a recognisable audio-and-tether interaction language.

## 1. Design direction

### The memorable idea
The signature interaction is the **Tether Line**: a thin horizontal or vertical rule interrupted by two qaf dots. It is used sparingly to connect related things: a recording to its progress, a transcript segment to its audio position, and a lecture to its saved note. It is not a decorative divider. It communicates continuity and retrieval.

The second signature is the **Lecture Thread**: a quiet waveform or segmented line that appears in recording, processing, and transcript contexts. It uses indigo as the structural line and teal only for the current/live position. It should never look like a stock equalizer or a decorative audio visualizer.

### What qayd is not
Avoid a generic SaaS dashboard, a card grid with identical rounded boxes, a neon AI aesthetic, decorative gradients, glassmorphism, chat-bubble metaphors, meeting-bot language, excessive badges, or a large permanent bottom navigation bar. The product is a focused capture-and-study tool, not a social or analytics product.

### Emotional targets
The first five seconds should communicate: “I can safely capture this lecture.” During processing: “My work is still safe.” On Detail: “I can return to the exact moment I need.”

## 2. Reusable foundation

### Color tokens
Use the locked Academic Indigo Material 3 tokens. Do not hand-pick screen-specific colors.

| Token | Value | Role |
|---|---|---|
| primary | #2A4D82 | brand, primary actions, structural emphasis |
| on-primary | #FFFFFF | text/icons on primary |
| primary-container | #D7E3F8 | selected surfaces, quiet emphasis |
| on-primary-container | #0A1F3D | text on primary container |
| secondary | #0B8072 | live, active, completed, positive progression |
| secondary-container | #AEEDE1 | active/positive containers |
| on-secondary-container | #00382F | text on teal containers |
| tertiary | #45506B | supporting emphasis |
| surface | #FAFBFD | app background |
| surface-low | #F3F5F9 | cards and grouped content |
| surface-container | #EDEFF4 | rails, navigation, grouped controls |
| surface-high | #E7EAF1 | fields and elevated quiet surfaces |
| on-surface | #141A24 | primary text |
| on-surface-variant | #44474F | secondary text |
| outline | #74777F | borders and controls |
| outline-variant | #C4C7CF | subtle rules and dividers |
| error | #C0392B | destructive/error states |

Dark mode uses the corresponding tokens already defined in `qayd_theme.dart`.

**Color rule:** indigo establishes structure. Teal marks a living or completed state. Error is reserved for a problem. Never use teal as a general brand replacement for indigo.

### Typography
Use IBM Plex Sans for Latin and IBM Plex Sans Arabic for Arabic. Use the same semantic roles in both directions; do not create a separate visual hierarchy for Arabic.

- Display: 32–36 px, regular/medium, for rare screen-level statements.
- Headline: 24–28 px, medium, for screen titles and major result headings.
- Title: 16–22 px, semibold, for card titles and section headings.
- Body: 14–16 px, regular, with generous line height.
- Label: 12–14 px, semibold, for actions, chips, and metadata.
- Mono: 11–12 px only for timestamps, technical limits, and progress values.

Use sentence case. Do not use all-caps labels as decoration. Allow Arabic text to determine its own line breaks and preserve readable RTL punctuation.

### Spacing and shape
Base spacing is an 8 px grid. Use 4 px only for optical adjustments.

- 8 px: compact gaps, icon-to-label spacing.
- 16 px: standard content gap and card padding.
- 24 px: section separation and major card padding.
- 32 px: screen-level breathing room.
- 48 px: major empty-state or hero spacing.
- 8 px radius: small controls and compact fields.
- 12 px radius: fields, snackbars, small panels.
- 16 px radius: cards, FAB, feature panels.
- 28 px radius: dialogs and bottom sheets.
- Stadium shape: buttons and chips only when the action is clearly compact.

Keep borders quiet and elevation shallow. Prefer a 1 px outline over a shadow. Use elevation only to establish a foreground relationship.

### Layout rules
Design the primary mobile frame at **390 × 844 px** and verify at **360 × 800 px**. Use 16 px horizontal page padding. Respect safe areas. Minimum interactive target is 48 × 48 px.

The composition should be vertically calm: one dominant action, one primary content region, and one clear next step. Do not stack more than two competing calls to action in the first viewport.

Every screen must be designed in both LTR and RTL. Mirroring includes alignment, leading/trailing placement, navigation affordances, and the Tether Line direction; icons that encode physical direction must be mirrored intentionally.

## 3. Core components to create in Figma

Create a `qayd / foundations` page with variables for color, spacing, radius, type, and elevation. Create a `qayd / components` page with component sets and state variants.

### Brand and navigation
- `QaydMark / tile`: q/ق vector monogram, 40, 56, and 96 px variants.
- `Wordmark / bilingual`: qayd + قَيْد lockup; use on onboarding/brand moments, not every screen.
- `AppBar / standard`: title, optional leading action, language control, overflow.
- `TetherRule / default`: quiet rule interrupted by two dots.

### Capture and audio
- `RecordButton / idle | recording | paused | disabled`: primary circular action, timer relationship, accessible label.
- `MicLevelMeter / idle | live | muted`: compact vertical or horizontal meter; teal indicates signal only.
- `LectureThread / idle | recording | processing | playback`: reusable audio line with current position.
- `AudioScrubber / idle | playing | paused`: timestamp labels, seek handle, active segment marker.

### Content
- `QaydCard / done | processing | failed`: title, relative date, duration, language, status.
- `LanguageChip / AR | EN | Mixed`.
- `StageStepper / transcribing | summarizing | complete | failed`.
- `SummaryPanel / loading | ready | failed`.
- `KeyPointRow / default`.
- `KeyTermTile / default`.
- `TranscriptSegment / default | active | edited`.
- `EmptyState / home | transcript | summary`.
- `ErrorRetry / inline | prominent`.

### Actions and overlays
- `Button / filled | tonal | outlined | text | destructive`.
- `SegmentedControl / Record | Import`.
- `BottomSheet / permission | rename | delete | settings`.
- `Toast / saved | processing | error`.

For every component, create default, pressed, focused, disabled, loading, and error states where meaningful. Name variants by behavior, not by color.

## 4. MVP screen specifications

### S1 — Home / Your Qayds

**Job:** show what the student has retained and make starting a new capture immediate.

**First viewport:** compact AppBar with “Your Qayds”, language control, and overflow. Under it, a restrained greeting or context line. Then the saved list. The primary “Start Qayd” action is a bottom-right extended FAB on LTR and bottom-left on RTL, with a small Tether Line connecting visually toward the content rather than floating as unrelated chrome.

**Qayd card anatomy:** a quiet indigo mark or audio thread on the leading side; title; “Today · 14:30”; duration; language chip; status dot only when processing. The card should feel like a retained note, not a media playlist row.

**Folder treatment:** if folders are shown in the MVP, use a compact filter row or bottom sheet rather than a permanent sidebar. The default list remains newest-first.

**Empty state:** a large, quiet q/ق tether illustration made from the monogram and a broken rule. Copy: “No Qayds yet.” Supporting line: “Capture your first lecture and keep the important parts.” Primary action: “Start Qayd”.

**Interactions:** tap card opens Detail; overflow opens rename/delete; folder filter opens a sheet; Start Qayd opens New Qayd.

### S2 — New Qayd

**Job:** let the student confidently choose Record or Import and understand what happens next.

Use a segmented control near the top: `Record` and `Import`. The selected state uses secondary-container with on-secondary-container text; the control should not resemble two unrelated tabs.

**Record mode:** center a large RecordButton over a very quiet Lecture Thread. Before recording, the line is still and the mic state says “Ready to capture”. During recording, the thread grows subtly with the mic level; the timer is prominent but not oversized. Primary controls are Pause and Stop. Avoid a loud red recording screen; use indigo structure and teal live status, with error red only for a problem.

**Import mode:** use a clear drop/pick panel with upload icon, accepted formats, and “Up to 100 MB”. After selection, show filename, duration, size, and a remove action. Do not hide file constraints in a tooltip.

**Finish state:** title field defaults to “Lecture · {date}”. Continue action says “Continue to processing”.

**Permission sheet:** explain why microphone access is needed before the system prompt. Use “Allow microphone” and “Not now”; if denied, provide “Open settings”.

### S3 — Processing

**Job:** make the wait legible and communicate that work is safe.

This screen is the product’s most distinctive moment. Show the lecture title, a centered Lecture Thread, and a two-stage Tether Stepper:

`Audio captured` → `Transcribing` → `Writing your summary` → `Qayd ready`

The active stage uses teal for the current dot and indigo for the structural line. Completed stages use a restrained check mark. The transcript must be saved before summarization, so when the first stage completes, show a subtle “Transcript saved” confirmation.

Use copy that describes the operation: “Transcribing your lecture…” and “Writing your English study note…”. Never show a bare spinner. On failure, preserve the current artifact and show Retry, Edit transcript, or Cancel.

### S4 — Detail / Qayd

**Job:** help the student study and return to the exact audio moment behind a note.

The header contains an editable title, date/duration metadata, language chip, and overflow. Below it, use a segmented switch or tabs: `Summary` and `Transcript`. Keep the summary as the first landing state.

**Summary:** one readable overview block, followed by key points as a vertical list and key terms as compact definition tiles. The summary is always English and LTR even when the transcript is Arabic or mixed.

**Transcript:** place the AudioScrubber above the transcript. Each segment has a timestamp in mono and text in the lecture’s language. The active segment has a thin teal leading indicator, primary-container background, and a small position marker on the Tether Line. Tapping a segment seeks the audio; playback updates the active segment.

**Editing:** Edit transcript opens a focused editor with Save and “Save & re-summarize”. Make the consequence explicit: “Your summary will be regenerated from the edited transcript.”

**Transcript-only state:** if summarization fails, show the preserved transcript and a clear “Generate summary” action. The user must never see an empty detail screen after successful transcription.

## 5. Interaction signatures

- **Tethered retrieval:** every timestamped transcript segment has a visible relationship to the audio scrubber.
- **Safe progress:** processing stages show what has already been saved, not only what is currently loading.
- **Quiet live state:** active/live uses teal, motion, and a small status label; never a full-screen color change.
- **Return to study:** Detail opens on the useful content, not on metadata or a playback control.
- **One decisive action:** each first viewport has one clear next action.

## 6. Content and localization notes

English UI examples: “Your Qayds”, “Start Qayd”, “Record lecture”, “Import audio”, “Transcribing your lecture…”, “Writing your English study note…”, “Transcript saved”, “Qayd ready”, “Save & re-summarize”.

Arabic translations should be natural and product-oriented, not literal. Use the Arabic brand form قَيْد in brand moments, while keeping the product name qayd where the Latin wordmark is used. Validate all screens with real Arabic strings to catch wrapping and alignment problems.

The English summary remains LTR. Arabic or mixed transcript content follows the detected language and uses RTL where appropriate. Mixed paragraphs should not force the entire screen into a single direction.

## 7. Prototype flows to build first

Create these clickable prototype paths before polishing every state:

1. Home empty → Start Qayd → Record idle → permission sheet → recording → processing → Detail.
2. Home → Import mode → selected file → title → processing → Detail.
3. Processing failure → Retry / Edit transcript / Cancel.
4. Detail Summary ↔ Transcript → tap segment → audio position changes → active segment highlights.
5. Detail title edit → save; Detail overflow → delete confirmation → Home.
6. Home folder filter → filtered newest-first list.

## 8. Figma file structure

- `00 Cover — qayd direction`
- `01 Foundations — variables, color, type, spacing, shape, elevation`
- `02 Components — component sets and states`
- `03 Flows — prototype maps and interaction notes`
- `04 Screens — LTR light`
- `05 Screens — RTL light`
- `06 Screens — LTR dark`
- `07 Screens — edge states`
- `08 Handoff — measurements, tokens, copy, accessibility`

## 9. Definition of design readiness

The first design pass is ready for implementation when every MVP screen has LTR and RTL variants, light and dark themes, empty/loading/error/success states, 48 px minimum targets, clear keyboard/screen-reader labels where applicable, and a prototype path from capture to saved Detail. The unique qayd signatures must be visible in at least three places: the Home empty/list state, Processing, and transcript-to-audio retrieval.
