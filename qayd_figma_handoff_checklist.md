# qayd — Figma handoff checklist

The interactive prototype and token file are complete. Use this checklist to reproduce the design in a Figma file or to hand it to a designer/developer.

## Import and file setup

Create a new Figma file named `qayd — MVP`. Add pages in this order:

`00 Cover — qayd direction`
`01 Foundations`
`02 Components`
`03 Flows`
`04 Screens — LTR light`
`05 Screens — RTL light`
`06 Screens — LTR dark`
`07 Edge states`
`08 Handoff`

Import `qayd_design_tokens.json` as the source of truth for variables. Import `qayd_monogram.svg` into the brand section and create 40, 56, and 96 px component variants.

## Foundations

Create color variables for Light and Dark modes. Create number variables for spacing, radii, minimum touch target, and mobile frame dimensions. Create text styles using IBM Plex Sans, IBM Plex Sans Arabic, and IBM Plex Mono.

Apply the following mobile frame sizes first:

- 390 × 844 px primary frame
- 360 × 800 px compact verification frame

Use 16 px page insets and an 8 px base grid. Keep every interactive target at least 48 × 48 px, even when the visible icon is smaller.

## Components to build first

Build components with Auto Layout and named variants rather than detached copies:

`QaydMark / size=40|56|96`
`AppBar / standard`
`TetherRule / default`
`Button / type=filled|tonal|outlined|text|destructive, state=default|pressed|focused|disabled`
`LanguageChip / language=AR|EN|Mixed`
`QaydCard / status=done|transcribing|summarizing|failed`
`EmptyState / context=home|transcript|summary`
`RecordButton / state=idle|recording|paused|disabled`
`LectureThread / state=idle|recording|processing|playback`
`StageStepper / stage=captured|transcribing|summarizing|ready|failed`
`AudioScrubber / state=idle|playing|paused`
`TranscriptSegment / state=default|active|edited`
`BottomSheet / type=permission|folder|rename|delete|settings`

For each component, expose only meaningful properties. Name variants by behavior and state, not by color name. Use variables for color so Light/Dark mode changes do not require manual recoloring.

## Screens and prototype links

Recreate the four screen groups from `qayd_interactive_prototype.html`:

- Home: populated, empty, loading, processing-card, and failed-card states.
- New Qayd: Record idle, permission sheet, recording, paused, stopped, Import, selected file, invalid file.
- Processing: transcribing, transcript saved, summarizing, ready, and failure.
- Detail: Summary, Transcript, active transcript segment, edit transcript, rename, delete confirmation, transcript-only.

Connect the happy path:

`Home → New Qayd → permission → recording → Processing → Detail`

Connect the alternative path:

`Home → New Qayd → Import → Processing → Detail`

Connect recovery:

`Processing failure → Retry | Edit transcript | Cancel`

Connect retrieval:

`Detail Summary ↔ Transcript → tap segment → active segment and audio position`

Use a 250 ms ease-out for navigation and bottom sheets. Use instant or short state transitions for processing and playback changes. Respect reduced-motion preferences in the implementation.

## Review gates

Before calling the Figma file ready, verify that the design still reads as qayd when the wordmark and color are hidden: the lecture thread, tethered progress, and transcript-to-audio relationship should remain recognisable. Verify that the shared components could be reused in a different product without carrying over lecture-specific copy or compositions.

Review all screens in LTR and RTL, Light and Dark. Test long titles, Arabic transcript lines, mixed Arabic/English text, 200% text scaling, error states, and keyboard/focus order. Confirm that the FAB never covers content and that all destructive actions require confirmation.
