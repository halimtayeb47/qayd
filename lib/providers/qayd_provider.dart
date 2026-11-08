// ==============================================================================
// Qayd State Provider (ChangeNotifier)
// File: lib/providers/qayd_provider.dart
//
// The central controller that manages state across all screens:
// - Manages the list of saved Qayds and folders (FR6, NFR10).
// - Orchestrates the pipeline: Record/Import -> Transcribe -> Summarize -> Save (FR1-FR4).
// - Ensures the critical reliability invariant: Transcript is persisted before
//   requesting summary so work is never lost on summary failure (NFR3).
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/qayd_model.dart';
import '../data/models/folder_model.dart';
import '../data/services/storage_service.dart';
import '../data/services/groq_whisper_service.dart';
import '../data/services/gemini_summary_service.dart';
import '../data/services/audio_recording_service.dart';
import '../data/services/audio_picker_service.dart';

class QaydProvider extends ChangeNotifier {
  final StorageService _storageService;
  final GroqWhisperService _whisperService;
  final GeminiSummaryService _summaryService;
  final AudioRecordingService _recordingService;
  final AudioPickerService _pickerService;

  // --- State Variables ---
  List<Qayd> _qayds = [];
  List<QaydFolder> _folders = [];
  String? _selectedFolderId;
  String _searchQuery = '';

  // Currently active or processing Qayd
  Qayd? _activeQayd;
  String _processingStatusMessage = '';
  double _processingProgress = 0.0;
  String? _errorMessage;

  // Recording State
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordDurationSeconds = 0;

  QaydProvider({
    required StorageService storageService,
    required GroqWhisperService whisperService,
    required GeminiSummaryService summaryService,
    required AudioRecordingService recordingService,
    required AudioPickerService pickerService,
  })  : _storageService = storageService,
        _whisperService = whisperService,
        _summaryService = summaryService,
        _recordingService = recordingService,
        _pickerService = pickerService {
    // Listen to recording timer stream
    _recordingService.durationStream.listen((seconds) {
      _recordDurationSeconds = seconds;
      notifyListeners();
    });
  }

  // --- Getters ---
  List<Qayd> get qayds {
    var list = _qayds;
    if (_selectedFolderId != null) {
      list = list.where((q) => q.folderId == _selectedFolderId).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((item) {
        return item.title.toLowerCase().contains(q) ||
            item.transcript.toLowerCase().contains(q) ||
            (item.summary?.overview.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  List<QaydFolder> get folders => _folders;
  String? get selectedFolderId => _selectedFolderId;
  String get searchQuery => _searchQuery;

  Qayd? get activeQayd => _activeQayd;
  String get processingStatusMessage => _processingStatusMessage;
  double get processingProgress => _processingProgress;
  String? get errorMessage => _errorMessage;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  int get recordDurationSeconds => _recordDurationSeconds;

  // ---------------------------------------------------------------------------
  // Initialization & Loading (FR6)
  // ---------------------------------------------------------------------------

  /// Loads saved Qayds and folders from local storage
  void loadInitialData() {
    _qayds = _storageService.getAllQayds();
    _folders = _storageService.getAllFolders();
    notifyListeners();
  }

  void filterByFolder(String? folderId) {
    _selectedFolderId = folderId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Audio Recording Flow (FR1)
  // ---------------------------------------------------------------------------

  /// Starts live microphone recording
  Future<void> startRecording() async {
    try {
      _errorMessage = null;
      await _recordingService.startRecording();
      _isRecording = true;
      _isPaused = false;
      _recordDurationSeconds = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isRecording = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Pauses active recording
  Future<void> pauseRecording() async {
    await _recordingService.pauseRecording();
    _isPaused = true;
    notifyListeners();
  }

  /// Resumes recording
  Future<void> resumeRecording() async {
    await _recordingService.resumeRecording();
    _isPaused = false;
    notifyListeners();
  }

  /// Stops recording and triggers the AI processing pipeline
  Future<Qayd> stopRecordingAndProcess({String? title}) async {
    final audioPath = await _recordingService.stopRecording();
    _isRecording = false;
    _isPaused = false;
    final duration = _recordDurationSeconds;
    notifyListeners();

    if (audioPath == null || audioPath.isEmpty) {
      throw Exception('Recording produced no valid audio file.');
    }

    final finalTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : 'Lecture ${_qayds.length + 1}';

    return await _runAiPipeline(
      audioPath: audioPath,
      title: finalTitle,
      durationSec: duration,
      folderId: _selectedFolderId,
    );
  }

  // ---------------------------------------------------------------------------
  // Audio Import Flow (FR2)
  // ---------------------------------------------------------------------------

  /// Opens file picker to import an existing audio file and processes it
  Future<Qayd?> importAudioAndProcess({String? title}) async {
    try {
      final picked = await _pickerService.pickAudioFile();
      if (picked == null) return null; // User cancelled

      final finalTitle = title?.trim().isNotEmpty == true
          ? title!.trim()
          : picked.fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');

      return await _runAiPipeline(
        audioPath: picked.path,
        title: finalTitle,
        durationSec: 0, // Will be updated by Whisper duration
        folderId: _selectedFolderId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // The Core AI Pipeline (Record/Import -> Transcribe -> Summarize -> Save)
  // ---------------------------------------------------------------------------

  Future<Qayd> _runAiPipeline({
    required String audioPath,
    required String title,
    required int durationSec,
    String? folderId,
  }) async {
    _errorMessage = null;

    // 1. Create initial Qayd in transcribing state
    var qayd = Qayd(
      id: const Uuid().v4(),
      title: title,
      createdAt: DateTime.now(),
      durationSec: durationSec,
      audioPath: audioPath,
      status: QaydStatus.transcribing,
      folderId: folderId,
    );
    _activeQayd = qayd;
    _processingStatusMessage = 'Transcribing audio with Groq Whisper...';
    _processingProgress = 0.25;
    notifyListeners();

    try {
      // 2. Transcribe Audio (FR3)
      final transcriptResult = await _whisperService.transcribeAudio(
        audioFilePath: audioPath,
      );

      final finalDuration = durationSec > 0
          ? durationSec
          : transcriptResult.durationSec.round();

      // CRITICAL INVARIANT: Save transcript immediately before calling Gemini!
      // If summary fails or hits rate-limit, the transcript is completely safe (NFR3).
      qayd = qayd.copyWith(
        transcript: transcriptResult.text,
        segments: transcriptResult.segments,
        language: transcriptResult.language,
        durationSec: finalDuration,
        status: QaydStatus.transcribed,
      );
      _activeQayd = qayd;
      await _storageService.saveQayd(qayd);

      _processingStatusMessage = 'Generating academic summary with Gemini...';
      _processingProgress = 0.65;
      notifyListeners();

      // 3. Generate English Summary (FR4)
      try {
        final summary = await _summaryService.generateSummary(
          transcript: transcriptResult.text,
        );

        qayd = qayd.copyWith(
          summary: summary,
          status: QaydStatus.done,
        );
      } catch (geminiError) {
        // If Gemini fails (e.g. rate limit), keep the Qayd with transcript intact!
        qayd = qayd.copyWith(status: QaydStatus.failed);
        _errorMessage = 'Summary generation failed: $geminiError';
      }

      // 4. Save Final State and Update List (FR6)
      await _storageService.saveQayd(qayd);
      _activeQayd = qayd;
      _processingStatusMessage = 'Done!';
      _processingProgress = 1.0;
      loadInitialData(); // Refresh list
      notifyListeners();

      return qayd;
    } catch (e) {
      qayd = qayd.copyWith(status: QaydStatus.failed);
      await _storageService.saveQayd(qayd);
      _activeQayd = qayd;
      _errorMessage = e.toString();
      _processingStatusMessage = 'Processing failed.';
      loadInitialData();
      notifyListeners();
      rethrow;
    }
  }

  /// Retries summarization for a transcribed Qayd (e.g. after fixing rate limit)
  Future<void> retrySummary(String qaydId) async {
    var qayd = _storageService.getQayd(qaydId);
    if (qayd == null || qayd.transcript.isEmpty) return;

    _errorMessage = null;
    _processingStatusMessage = 'Regenerating summary with Gemini...';
    notifyListeners();

    try {
      final summary = await _summaryService.generateSummary(
        transcript: qayd.transcript,
      );

      qayd = qayd.copyWith(
        summary: summary,
        status: QaydStatus.done,
      );
      await _storageService.saveQayd(qayd);
      _activeQayd = qayd;
      loadInitialData();
    } catch (e) {
      _errorMessage = 'Retry failed: $e';
    } finally {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Management & Folder Operations (NFR9, NFR10, NFR11)
  // ---------------------------------------------------------------------------

  /// Renames a Qayd (NFR9)
  Future<void> renameQayd(String id, String newTitle) async {
    final qayd = _storageService.getQayd(id);
    if (qayd != null) {
      final updated = qayd.copyWith(title: newTitle.trim());
      await _storageService.saveQayd(updated);
      loadInitialData();
    }
  }

  /// Deletes a Qayd and its local audio file (NFR9)
  Future<void> deleteQayd(String id) async {
    await _storageService.deleteQayd(id);
    if (_activeQayd?.id == id) {
      _activeQayd = null;
    }
    loadInitialData();
  }

  /// Edits the transcript and saves it (NFR11)
  Future<void> editTranscript(String id, String newTranscript) async {
    final qayd = _storageService.getQayd(id);
    if (qayd != null) {
      final updated = qayd.copyWith(transcript: newTranscript);
      await _storageService.saveQayd(updated);
      if (_activeQayd?.id == id) {
        _activeQayd = updated;
      }
      loadInitialData();
    }
  }

  /// Moves a Qayd to a specific subject folder (NFR10)
  Future<void> moveQaydToFolder(String qaydId, String? folderId) async {
    final qayd = _storageService.getQayd(qaydId);
    if (qayd != null) {
      final updated = qayd.copyWith(folderId: folderId);
      await _storageService.saveQayd(updated);
      loadInitialData();
    }
  }

  /// Creates a new subject folder (NFR10)
  Future<void> createFolder(String name) async {
    if (name.trim().isEmpty) return;
    final folder = QaydFolder(
      id: const Uuid().v4(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    await _storageService.saveFolder(folder);
    loadInitialData();
  }

  /// Deletes a folder and safely unfiles all its Qayds
  Future<void> deleteFolder(String folderId) async {
    await _storageService.deleteFolder(folderId);
    if (_selectedFolderId == folderId) {
      _selectedFolderId = null;
    }
    loadInitialData();
  }

  void setActiveQayd(Qayd qayd) {
    _activeQayd = qayd;
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingService.dispose();
    super.dispose();
  }
}
