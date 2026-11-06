# qayd — Home Screen Figma Build Sheet

This is the first screen to build in Figma. It establishes the app shell, card language, empty state, folder treatment, primary capture action, and the qayd-specific Tether Line.

## Frame setup

Create these frames:

- `Home / LTR / Light` — 390 × 844 px
- `Home / LTR / Dark` — 390 × 844 px
- `Home / RTL / Light` — 390 × 844 px
- `Home / Edge states` — four additional frames for loading, processing, failed, and empty states

Use a 16 px left and right inset, an 8 px spacing grid, and the device safe-area inset. Keep the content scrollable below the app bar. The primary action must remain reachable without covering the last list item.

## Home structure

```text
┌──────────────────────────────────────┐
│  Your Qayds              EN   ···    │  24 px top safe area
│  ─────────── ·· ───────────────────  │  TetherRule, optional quiet divider
│                                      │
│  [All Qayds] [Folders  ˅]            │  filter row
│                                      │
│  Today                                │  section label
│  ┌──────────────────────────────────┐ │
│  │  ◌────··   Cell Biology          │ │
│  │             Today · 10:42         │ │
│  │             48 min   Mixed       │ │
│  └──────────────────────────────────┘ │
│                                      │
│  Yesterday                           │
│  ┌──────────────────────────────────┐ │
│  │  ◌────··   Research Methods      │ │
│  │             Yesterday · 14:10    │ │
│  │             32 min   English     │ │
│  └──────────────────────────────────┘ │
│                                      │
│                               ┌────┐ │
│                               │ +  │ │ extended FAB
│                               └────┘ │
└──────────────────────────────────────┘
```

The wireframe is a compositional guide, not a requirement to draw a generic divider or a waveform in every card. The Tether Line should appear only where it communicates the relationship between a Qayd and its source audio.

## App bar

Height: 72 px excluding the safe area. Align the title to the leading edge.

- Title: `Your Qayds`, Headline Small or Title Large, on-surface.
- Language control: compact outlined or text control showing `EN` / `ع`; minimum 48 px hit area. It changes the UI language, not the lecture language.
- Overflow: icon button with settings access and future app-level actions.
- Avoid a logo in the app bar on every screen. The q/ق mark should appear in the empty state and capture/processing moments so it remains meaningful.

Use `Your Qayds` rather than “Dashboard” or “Library”. It names the user’s saved knowledge, not a software area.

## Filter row

Place 16 px below the app bar. The row contains:

- `All Qayds`: selected tonal control.
- `Folders`: outlined control with a chevron, opening a bottom sheet.
- Optional count only when it adds value; do not show a decorative badge.

Selected `All Qayds` uses primary-container and on-primary-container. The folder control uses surface-low with outline-variant. In RTL, the controls reverse order and the chevron mirrors.

If no folders exist, the sheet should offer `Create folder` and explain that folders keep subjects together. Do not make folders dominate the Home screen.

## Qayd card

Use a 16 px radius, surface-low background, and 16 px internal padding. Do not apply a large shadow. Each card is one tap target with a separate trailing overflow button whose hit area remains 48 px.

### Card anatomy

Leading region: a 40 px quiet audio-thread mark. Use a small indigo circle, a short structural line, and the two qaf dots. The mark is not a play button; it identifies the lecture thread.

Content region:

- Title: maximum two lines, Title Medium, on-surface.
- Metadata: relative date/time, Body Small, on-surface-variant.
- Bottom metadata: duration and lecture language chip.

Trailing region: overflow icon. For processing cards, replace or supplement the status with a compact progress label such as `Transcribing`.

### Card variants

`QaydCard / done`: indigo thread mark, duration, language chip, no active status.

`QaydCard / transcribing`: teal current dot and `Transcribing` label. The card must remain tappable and show the saved artifact if available.

`QaydCard / summarizing`: status label `Writing summary`. Do not display a percentage unless the source can provide a meaningful percentage.

`QaydCard / failed`: error-container status strip or inline `Needs attention`; trailing action can open retry. Preserve the title and captured metadata.

`QaydCard / pressed`: surface-high and a visible but restrained outline. The entire card must show a response within the platform motion budget.

## Empty state

The empty state is the strongest Home expression of the qayd identity.

Composition: vertically center the illustration in the available content region, but leave room for the FAB. Use the q/ق monogram as a circular bowl with a descending tail. Extend a thin rule from it and interrupt the rule with two small qaf dots. The rule should feel as if it is tethering an unformed lecture to a saved note.

Copy:

- Heading: `No Qayds yet`
- Supporting text: `Capture your first lecture and keep the important parts.`
- Primary action: `Start Qayd`

Do not add a generic “Get started” illustration, robot, microphone mascot, or gradient blob. The visual should be ownable by qayd even without the wordmark.

## Primary action

Use an extended FAB labeled `Start Qayd` with a plus or record icon. Place it in the trailing bottom corner in LTR and the leading bottom corner in RTL. Keep 16 px edge inset and 16 px bottom safe-area spacing.

- Background: primary.
- Foreground: on-primary.
- Radius: 16 px, not a full pill.
- Height: 56 px minimum.
- Pressed state: primary with a clear elevation/overlay response.
- Accessibility label: `Start a new Qayd`.

The FAB is the only dominant action on Home. Do not add a second “Import” button here; Record and Import are choices inside New Qayd.

## Loading state

Show three skeleton cards with the same height and spacing as real Qayd cards. Use surface-container and a subtle animated opacity shift. Avoid drawing fake text that looks like unreadable stripes. The app bar and filter row remain stable so the screen does not jump.

Reduced-motion mode: replace animation with a static skeleton and a text label, `Loading your Qayds…`.

## Error state

Keep the app bar and filter row. Replace the list with an inline error block:

- Heading: `Your Qayds could not be loaded`
- Supporting text: `Your saved recordings are still on this device. Try again.`
- Action: `Try again`

Do not imply data loss when the problem is only a read failure. Use error color for the icon or action emphasis, not as a red background over the whole screen.

## Prototype connections

Create these interactions in Figma Prototype mode:

- `Start Qayd` → `New Qayd / Record idle`, Navigate to, 250 ms ease-out.
- Tap a completed card → `Detail / Summary`, Navigate to.
- Tap a processing card → `Processing / current stage`, Navigate to.
- Tap card overflow → `Qayd actions / bottom sheet`, Open overlay from bottom.
- Tap `Folders` → `Folder filter / bottom sheet`, Open overlay from bottom.
- Tap language control → `Language choice / bottom sheet` or a paired Arabic frame for prototype demonstration.
- Tap `Try again` → loading state, then done state in the happy-path prototype.

Use instant transitions for state changes caused by playback/progress. Use a short ease-out only for navigation and sheets. Do not animate every card independently.

## Accessibility and content checks

Verify that:

- Every icon button has a semantic label and a 48 × 48 px target.
- Card title, date, duration, and language have sufficient contrast in light and dark themes.
- The selected filter is identifiable without color alone.
- Processing and failed statuses have text labels, not only dots.
- Long English titles wrap at two lines without overlapping the overflow action.
- Arabic titles and metadata align correctly in RTL and do not collide with the trailing action.
- At 200% text scaling, the card remains usable and the title can expand vertically.
- The FAB does not obscure content or the system gesture area.
- Focus order follows app bar → filter row → cards → FAB in LTR, with the logical equivalent in RTL.

## Completion test

Do not move to New Qayd until the Home screen answers these questions without explanation:

1. What have I already captured?
2. Which Qayds need attention?
3. How do I start a new lecture?
4. Can I tell that a lecture is Arabic, English, or mixed?
5. Can I find a subject folder without turning Home into a dashboard?

The screen passes the uniqueness test if removing the colors and wordmark still leaves the audio-thread/tether relationship recognisable. It passes the reusability test if the AppBar, filter controls, cards, sheets, and state patterns can be reused in another product by swapping content and the product-specific mark.

## Build order in Figma

1. Create variables and apply the existing qayd color/type tokens.
2. Build `AppBar / standard`, `TetherRule`, `LanguageChip`, `QaydCard`, `EmptyState`, `Button`, and `BottomSheet` components.
3. Build the empty Home frame first.
4. Add the done, processing, failed, and loading frames using component variants.
5. Duplicate the frames for RTL and dark mode; do not redraw components manually.
6. Add the prototype links for the capture flow.
7. Review at 390 × 844 and 360 × 800, then test long English and Arabic content.
