// ==============================================================================
// Audio File Picker Service
// File: lib/data/services/audio_picker_service.dart
//
// Handles picking external audio files (FR2).
// Size gating (< 100 MB) happens after FFmpeg compression in
// AudioCompressionService so large raw files (e.g., WAV) can be shrunk first.
// ==============================================================================

import 'dart:io';
import 'package:file_picker/file_picker.dart';

class PickedAudioResult {
  final String path;
  final String fileName;
  final int sizeBytes;

  const PickedAudioResult({
    required this.path,
    required this.fileName,
    required this.sizeBytes,
  });

  double get sizeMb => sizeBytes / (1024 * 1024);
}

class AudioPickerService {
  static const List<String> allowedExtensions = [
    'mp3',
    'm4a',
    'wav',
    'aac',
    'ogg',
    'webm',
    'flac',
  ];

  /// Prompts the user to pick an audio file and returns its path and metadata.
  /// Returns `null` if the user cancels the picker.
  Future<PickedAudioResult?> pickAudioFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (files.isEmpty) {
      return null; // User canceled the picker
    }

    final platformFile = files.first;
    final sourcePath = platformFile.path;

    if (sourcePath == null) {
      throw Exception('Could not access the selected file path.');
    }

    final fileSize =
        sourcePath.startsWith('content://') ? 0 : await File(sourcePath).length();

    return PickedAudioResult(
      path: sourcePath,
      fileName: platformFile.name,
      sizeBytes: fileSize,
    );
  }
}
