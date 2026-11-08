// ==============================================================================
// Audio File Picker Service
// File: lib/data/services/audio_picker_service.dart
//
// Handles picking and importing external audio files (FR2).
// Validates file size (cap: 100 MB) and copies files to local storage.
// ==============================================================================

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

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
  static const int maxFileSizeBytes = 100 * 1024 * 1024; // 100 MB cap (FR2)
  static const List<String> allowedExtensions = ['mp3', 'm4a', 'wav', 'aac'];

  /// Prompts user to pick an audio file and copies it into app storage
  Future<PickedAudioResult?> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return null; // User canceled the picker
    }

    final platformFile = result.files.first;
    final sourcePath = platformFile.path;

    if (sourcePath == null) {
      throw Exception('Could not access the selected file path.');
    }

    final sourceFile = File(sourcePath);
    final fileSize = await sourceFile.length();

    // Check 100 MB limit
    if (fileSize > maxFileSizeBytes) {
      throw Exception(
        'Selected audio file is too large (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB). '
        'Maximum allowed size is 100 MB.',
      );
    }

    // Copy to app storage so the file is not lost if moved outside
    final appDir = await getApplicationDocumentsDirectory();
    final importsDir = Directory('${appDir.path}/imported_audio');
    if (!await importsDir.exists()) {
      await importsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = sourcePath.split('.').last;
    final destinationPath = '${importsDir.path}/imported_$timestamp.$extension';

    final savedFile = await sourceFile.copy(destinationPath);

    return PickedAudioResult(
      path: savedFile.path,
      fileName: platformFile.name,
      sizeBytes: fileSize,
    );
  }
}
