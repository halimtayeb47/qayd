# qayd — Technical Processing Pipeline Specification

## 1. Purpose

This document defines how qayd actually processes a lecture from capture or import to a searchable, timestamped transcript and an English study summary. It is written for the project review and can be adapted into the methodology and system-design sections of the research paper.

qayd is **local-first but cloud-assisted**. Audio files, transcripts, summaries, metadata, folders, and processing state are persisted on the student’s device. AI inference uses Groq-hosted Whisper-large-v3 for speech-to-text and Google Gemini Flash for summarization through a thin serverless proxy. The app is not fully offline because AI processing requires network access.

## 2. End-to-end pipeline

```text
Record live lecture OR import audio
              ↓
Validate file, duration, format, and storage
              ↓
Preserve original audio locally
              ↓
Prepare audio for provider limits
(convert, compress, or fragment if required)
              ↓
Upload one chunk at a time through the proxy
              ↓
Transcribe with Whisper-large-v3
              ↓
Offset, order, and de-duplicate timestamped segments
              ↓
Persist transcript locally
              ↓
Send transcript to Gemini Flash through the proxy
              ↓
Validate structured English summary
              ↓
Persist summary locally
              ↓
Display summary, transcript, and audio-linked navigation
```

Every stage has a status, an output artifact, and a recoverable failure state. The system never treats the whole process as one opaque request.

## 3. Capture and import

### Live recording

The recorder writes audio to a temporary local path while the user sees elapsed time and microphone activity. The recording state is managed locally:

```text
idle → recording → paused → recording → stopped
```

The MVP imposes a 60-minute recording cap. When the user stops, the app finalizes the file, verifies that it can be read, calculates duration and size, and copies or moves it into managed application storage. The user confirms or edits the title before processing begins.

### Imported audio

The app accepts `.m4a`, `.mp3`, and `.wav` files up to the application-level 100 MB limit. It validates the extension, decodability, size, duration, and available temporary storage. The original source is copied into application-managed local storage so later processing does not depend on the original external path.

The original audio is retained as the playback source. Converted or fragmented derivatives are temporary and are deleted after successful processing or cleanup after a terminal failure.

## 4. Local preparation and fragmentation

The app first checks the encoded file size against the transcription provider’s upload constraint. The 100 MB import limit is an application rule; the provider may accept a smaller request payload. The preparation strategy is:

```text
If the source is accepted directly:
    transcribe it as one request.
Otherwise:
    convert or compress to a supported working format;
    split the working file into sequential chunks;
    transcribe each chunk independently;
    merge the returned segments into one global transcript.
```

The implementation should prefer a practical fixed-duration chunk size, such as 5–10 minutes, while checking the resulting encoded size. The exact value is configuration, not user-facing behavior, because compression and speech density change file size.

Chunks should overlap by a small boundary window, for example five seconds:

```text
Chunk 1: 00:00–10:00
Chunk 2: 09:55–19:55
Chunk 3: 19:50–29:50
```

Overlap reduces the chance that a word is cut at a chunk boundary. It creates deliberate duplicate audio context, so the merge stage must remove repeated transcript content.

Each chunk record should include:

```text
chunk index
source Qayd ID
local file path
start offset in original audio
end offset in original audio
request status
retry count
provider request identifier, if available
```

Temporary chunks must not replace the original audio. They are processing artifacts and should be deleted after the Qayd reaches a terminal state unless retained temporarily for a retry.

## 5. Cloud boundary and security

The mobile app does not contain a permanent Groq or Gemini secret. Requests follow this boundary:

```text
Flutter app → thin serverless proxy → AI provider
```

The proxy authenticates the application request, attaches the provider secret, forwards the request, and returns the provider response. It should not become a permanent audio or transcript database. Audio is transmitted only for the requested transcription operation and is not intentionally stored by qayd’s proxy.

The application should communicate this accurately:

> Your Qayd stays on this device. AI processing temporarily sends the required audio or transcript to the connected processing service.

The privacy statement must not claim that audio never leaves the device, because cloud transcription necessarily transmits it. API keys must never be placed in the Flutter binary, committed to source control, or exposed in client logs.

## 6. Transcription

Each prepared chunk is sent to Groq Whisper-large-v3 through the proxy. The request must allow language detection because lectures may be Arabic, English, or code-switched. The app stores the detected overall language as:

```text
ar | en | mixed
```

The transcript itself preserves the spoken language. The English-only rule applies to the later study summary, not to transcription.

The required logical transcription output is:

```json
{
  "language": "mixed",
  "segments": [
    {
      "startSec": 12.4,
      "endSec": 18.8,
      "text": "..."
    }
  ]
}
```

If the provider returns chunk-relative timestamps, the app converts them into original-audio timestamps:

```text
globalStart = chunkOffset + localStart
globalEnd   = chunkOffset + localEnd
```

Example:

```text
chunkOffset = 600.0
localStart  = 12.4
localEnd    = 18.8

stored segment = 612.4–618.8 seconds
```

This conversion must happen before the transcript is persisted or displayed.

## 7. Segment reconstruction

After all chunks succeed, the merge service performs these operations:

### Ordering

Sort segments by `startSec`, then retain their original chunk index as a stable tie-breaker.

### Boundary de-duplication

Compare nearby segments from adjacent chunks. A duplicate candidate is identified by temporal overlap and high text similarity. Keep one copy, preferring the segment with the cleaner or longer boundary text. The exact similarity algorithm can begin as normalized token overlap and be improved if evaluation shows boundary errors.

### Gap preservation

Do not invent text for silent or unintelligible gaps. Timestamp gaps remain gaps. If a provider marks unintelligible speech, preserve a clear placeholder rather than fabricating content.

### Final validation

Before saving, confirm that each segment has valid finite times, `startSec < endSec`, non-empty text, and no negative timestamp. Confirm that the final sequence is chronologically ordered and lies within the audio duration, allowing a small tolerance at the end.

The final transcript is a reconstructed artifact, not merely the concatenation of raw provider responses.

## 8. Local persistence boundary

The transcript must be saved before summarization begins. This creates a valid intermediate Qayd:

```text
Audio saved
Transcript saved
Summary pending
```

Suggested local entities:

```text
Qayd
  id
  title
  createdAt
  durationSec
  audioPath
  language
  status
  transcript
  summary
  folderId

TranscriptSegment
  qaydId
  index
  startSec
  endSec
  text

ProcessingJob
  qaydId
  stage
  chunkCount
  completedChunks
  retryCount
  lastError
  updatedAt
```

Hive can store Qayd metadata and segment data. The audio file itself remains in application file storage, referenced by `audioPath`. Deleting a Qayd must remove both its metadata and its audio file; cleanup should also remove any remaining temporary chunks.

## 9. Summarization

Once the transcript is saved, the app sends the transcript text—not the original audio—to Gemini Flash through the protected proxy. The prompt must require an English-only structured study note and should instruct the model to avoid adding facts that are not supported by the transcript.

Expected logical response:

```json
{
  "overview": "...",
  "keyPoints": ["...", "..."],
  "keyTerms": [
    {
      "term": "...",
      "definition": "..."
    }
  ]
}
```

The client validates the response before displaying it. It must verify that `overview` is present, `keyPoints` is an array, and each key term has a term and definition. Invalid or incomplete output is treated as a processing error rather than silently rendered as a successful summary.

The summary language is English because the project’s official study and memorization language is English. The transcript remains Arabic, English, or mixed according to the lecture.

## 10. Editing and re-summarization

The student can edit the transcript after transcription. The edited text is saved locally and becomes the source for the next summary request:

```text
Open transcript editor
        ↓
Edit and save transcript
        ↓
Persist edited text
        ↓
Confirm “Save & re-summarize”
        ↓
Send edited text to Gemini Flash
        ↓
Replace the previous summary after validation
```

The original audio is never modified. For the MVP, editing can operate on the full transcript text while preserving the original timestamped segments for playback. If the edit changes a sentence substantially, the UI should treat the edited text as the summarization source and avoid pretending that every changed word has a new precise audio alignment.

## 11. Playback and searchable transcript behavior

The Detail screen reads the local audio path and timestamped segments. During playback, the active segment is the segment satisfying:

```text
segment.startSec ≤ currentPosition < segment.endSec
```

The app highlights that segment. When the student taps a segment, the player seeks to `segment.startSec`; playback can begin immediately or remain paused according to the player state.

This produces the research-relevant behavior:

```text
study statement → timestamped transcript segment → source audio moment
```

The transcript is searchable locally in the MVP. Search matches are performed against the saved transcript text and can scroll to the matching segment. No server search request is needed.

## 12. Failure and recovery model

Every stage must preserve the last successful artifact.

| Failure | Preserved artifact | Recovery |
|---|---|---|
| Microphone denied | none or partial temporary recording | explain permission and retry/open settings |
| Invalid import | original external file | choose another file |
| Conversion/chunk failure | original local audio | retry preparation |
| Network/upload failure | local audio and job state | retry without recording again |
| One chunk fails | successful chunks and local source | retry failed chunk |
| Merge validation fails | raw chunk results and source audio | retry reconstruction or transcription |
| Summary failure | complete local transcript | retry or edit transcript |
| App closes during processing | Qayd and processing state | resume or show recoverable pending state |
| Delete | none after confirmation | irreversible local cleanup |

A failure screen must never show only “Something went wrong.” It should identify the stage and offer an action that does not require repeating completed work.

## 13. Research-paper framing

The method can be described as a staged multimodal transformation pipeline:

1. **Input acquisition:** capture or import lecture audio.
2. **Local preprocessing:** validate, normalize, and fragment the source under provider constraints.
3. **Speech-to-text inference:** transcribe chunks with Whisper-large-v3 while preserving language and timestamps.
4. **Temporal reconstruction:** offset timestamps, order segments, remove overlap duplicates, and validate the merged transcript.
5. **Local persistence:** save the transcript before downstream generation.
6. **Knowledge transformation:** generate an English overview, key points, and key terms from the transcript with Gemini Flash.
7. **Output validation:** reject malformed generation responses and preserve transcript-only states.
8. **Study interaction:** provide local search, audio playback, and timestamp-based transcript seeking.
9. **Evaluation:** measure completion, timestamp accuracy, transcript quality, summary usefulness, processing time, and failure recovery.

## 14. Evaluation plan

For the university prototype, evaluate the pipeline with a small set of representative lecture recordings:

- English-only lecture.
- Arabic-only lecture.
- Code-switched Arabic/English lecture.
- Short audio below provider limits.
- Long audio requiring fragmentation.
- Audio containing silence and boundary speech.
- Network interruption during transcription.
- Summary failure or malformed response.

Record at least these measures:

- End-to-end processing success rate.
- Transcription completion rate by language condition.
- Timestamp-seeking accuracy at sampled segments.
- Boundary duplication rate after merging.
- Summary schema validity rate.
- Median processing time.
- Recovery success without re-recording.
- User-rated usefulness of the summary and navigation flow.

The prototype should not claim clinical, legal, or research-grade transcription accuracy. It should report observed results on the selected test recordings and describe provider limitations.

## 15. Final architectural statement

qayd is a local-first lecture knowledge pipeline with cloud-assisted AI inference. The original audio and derived study artifacts belong to the local Qayd record. The cloud boundary is limited to temporary provider requests through a protected proxy. Fragmentation is an implementation detail required by upload constraints; timestamp offsetting and overlap de-duplication reconstruct one coherent transcript. Saving the transcript before summarization makes the system recoverable, while local search and timestamped playback turn the generated output into a study tool rather than a generic text generator.
