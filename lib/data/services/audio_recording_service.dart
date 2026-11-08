// ==============================================================================
// Audio Recording Service
// File: lib/data/services/audio_recording_service.dart
//
// Manages microphone recording, pause/resume, and elapsed timer (FR1).
// Encodes directly to 16 kHz Mono AAC at 32 kbps matching Whisper requirements.
// ==============================================================================

import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  final AudioRecorder _audioRecorder;

  Timer? _timer;
  int _elapsedSeconds = 0;
  String? _currentFilePath;

  // Stream controller to broadcast elapsed duration to the UI
  final _durationController = StreamController<int>.broadcast();
  Stream<int> get durationStream => _durationController.stream;

  AudioRecordingService({AudioRecorder? audioRecorder})
      : _audioRecorder = audioRecorder ?? AudioRecorder();

  int get elapsedSeconds => _elapsedSeconds;
  String? get currentFilePath => _currentFilePath;

  /// Checks and requests microphone permission
  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  /// Starts a new recording session
  Future<String> startRecording() async {
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      throw Exception('Microphone permission not granted.');
    }

    // Prepare target path in application documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${appDir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${recordingsDir.path}/qayd_$timestamp.m4a';
    _currentFilePath = filePath;

    // Direct 16 kHz Mono AAC at 32 kbps (Whisper-native format)
    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 16000,
      numChannels: 1,
      bitRate: 32000,
    );

    await _audioRecorder.start(config, path: filePath);

    // Reset and start elapsed timer
    _elapsedSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _durationController.add(_elapsedSeconds);
    });

    return filePath;
  }

  /// Pauses the current recording
  Future<void> pauseRecording() async {
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.pause();
      _timer?.cancel();
    }
  }

  /// Resumes recording after pause
  Future<void> resumeRecording() async {
    if (await _audioRecorder.isPaused()) {
      await _audioRecorder.resume();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _elapsedSeconds++;
        _durationController.add(_elapsedSeconds);
      });
    }
  }

  /// Stops recording and returns the final local audio file path
  Future<String?> stopRecording() async {
    _timer?.cancel();
    _timer = null;

    final path = await _audioRecorder.stop();
    return path ?? _currentFilePath;
  }

  /// Checks if actively recording
  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }

  /// Checks if recording is paused
  Future<bool> isPaused() async {
    return await _audioRecorder.isPaused();
  }

  /// Disposes internal resources
  void dispose() {
    _timer?.cancel();
    _durationController.close();
    _audioRecorder.dispose();
  }
}
