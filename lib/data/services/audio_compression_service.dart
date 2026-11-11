// ==============================================================================
// Audio Compression Service
// File: lib/data/services/audio_compression_service.dart
//
// Compresses imported audio files to Whisper-optimal speech settings
// (16 kHz, Mono, 32 kbps MP3) using FFmpeg before size verification and upload.
// ==============================================================================

import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:path_provider/path_provider.dart';

/// Thrown when an audio file cannot be compressed or remains too large (>= 100 MB)
class AudioNotTranscribableException implements Exception {
  final String messageEn;
  final String messageAr;

  const AudioNotTranscribableException({
    required this.messageEn,
    required this.messageAr,
  });

  @override
  String toString() => messageEn;
}

class CompressedAudioResult {
  final String path;
  final int sizeBytes;

  const CompressedAudioResult({
    required this.path,
    required this.sizeBytes,
  });

  double get sizeMb => sizeBytes / (1024 * 1024);
}

class AudioCompressionService {
  /// Groq Whisper Developer/Paid maximum payload limit (strictly < 100 MB)
  static const int maxCompressedSizeBytes = 100 * 1024 * 1024;

  /// Checks whether a compressed audio size in bytes is strictly under 100 MB
  static bool isSizeTranscribable(int sizeBytes) {
    return sizeBytes > 0 && sizeBytes < maxCompressedSizeBytes;
  }

  /// Compresses [inputPath] into app storage as 16 kHz, Mono, 32 kbps MP3.
  ///
  /// Throws [AudioNotTranscribableException] if compression fails or the
  /// resulting file is not strictly under 100 MB.
  Future<CompressedAudioResult> compressToWhisperMp3(String inputPath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final importsDir = Directory('${appDir.path}/imported_audio');
    if (!await importsDir.exists()) {
      await importsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${importsDir.path}/imported_$timestamp.mp3';
    final outputFile = File(outputPath);

    // Resolve Android SAF content:// URIs if returned directly by a picker
    final effectiveInput =
        (Platform.isAndroid && inputPath.startsWith('content://'))
            ? (await FFmpegKitConfig.getSafParameterForRead(inputPath) ??
                inputPath)
            : inputPath;

    final completer = Completer<FFmpegSession>();

    try {
      await FFmpegKit.executeWithArgumentsAsync(
        [
          '-y',
          '-i',
          effectiveInput,
          '-vn',
          '-ac',
          '1',
          '-ar',
          '16000',
          '-b:a',
          '32k',
          outputPath,
        ],
        (FFmpegSession session) {
          if (!completer.isCompleted) {
            completer.complete(session);
          }
        },
      );
    } catch (e) {
      await _deleteIfExists(outputFile);
      throw const AudioNotTranscribableException(
        messageEn:
            'Could not compress this audio file on this platform. Please record in-app or pick another audio file.',
        messageAr:
            'تعذر ضغط هذا الملف الصوتي على هذا الجهاز. يرجى التسجيل داخل التطبيق أو اختيار ملف صوتي آخر.',
      );
    }

    final session = await completer.future;
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode) || !await outputFile.exists()) {
      await _deleteIfExists(outputFile);
      throw const AudioNotTranscribableException(
        messageEn:
            'Failed to process this audio file. It may be corrupted or in an unsupported format, so it cannot be transcribed.',
        messageAr:
            'فشلت معالجة هذا الملف الصوتي. قد يكون تالفاً أو بصيغة غير مدعومة، لذا لا يمكن تفريغه.',
      );
    }

    final compressedSizeBytes = await outputFile.length();
    if (!isSizeTranscribable(compressedSizeBytes)) {
      final sizeMbText = (compressedSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      await _deleteIfExists(outputFile);
      throw AudioNotTranscribableException(
        messageEn:
            'Even after compression, this file is $sizeMbText MB (limit is under 100 MB). This file is not transcribable.',
        messageAr:
            'حتى بعد الضغط، يبلغ حجم الملف $sizeMbText ميجابايت (الحد المسموح أقل من 100 ميجابايت). هذا الملف غير قابل للتفريغ.',
      );
    }

    return CompressedAudioResult(
      path: outputPath,
      sizeBytes: compressedSizeBytes,
    );
  }

  Future<void> _deleteIfExists(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
