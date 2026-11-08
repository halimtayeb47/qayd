// ==============================================================================
// Groq Whisper Transcription Service
// File: lib/data/services/groq_whisper_service.dart
//
// Converts recorded or imported audio into timestamped segments (FR3).
// Uses Groq-hosted Whisper-large-v3 with code-switching prompt.
// ==============================================================================

import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/qayd_model.dart';

/// The result returned after successful transcription
class TranscriptionResult {
  final String text;
  final List<TranscriptSegment> segments;
  final QaydLanguage language;
  final double durationSec;

  const TranscriptionResult({
    required this.text,
    required this.segments,
    required this.language,
    required this.durationSec,
  });
}

class GroqWhisperService {
  final Dio _dio;
  final String _apiKey;

  GroqWhisperService({
    Dio? dio,
    String? apiKey,
  })  : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? ApiConstants.groqApiKey;

  /// Transcribes the given audio file using Groq Whisper-large-v3
  Future<TranscriptionResult> transcribeAudio({
    required String audioFilePath,
    String? customApiKey,
    ProgressCallback? onSendProgress,
  }) async {
    final key = customApiKey ?? _apiKey;
    if (key.trim().isEmpty) {
      throw Exception(
        'Groq API key is missing. Please provide it in ApiConstants or via --dart-define=GROQ_API_KEY.',
      );
    }

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('Audio file not found at: $audioFilePath');
    }

    // Build the multipart request payload matching your validated Node.js script
    final fileName = audioFilePath.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        audioFilePath,
        filename: fileName,
      ),
      'model': ApiConstants.groqModel,
      'prompt': ApiConstants.groqPrompt,
      'response_format': 'verbose_json',
      'temperature': '0.0',
      'timestamp_granularities[]': 'segment',
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.groqBaseUrl,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $key',
          },
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
        onSendProgress: onSendProgress,
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Received empty response from Groq API');
      }

      return parseTranscriptionResponse(data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorMsg = e.response?.data?['error']?['message'] ?? e.message;

      if (statusCode == 401) {
        throw Exception('Invalid Groq API key (401 Unauthorized).');
      } else if (statusCode == 429) {
        throw Exception('Groq API rate limit exceeded. Please wait a moment.');
      } else {
        throw Exception('Transcription failed ($statusCode): $errorMsg');
      }
    }
  }

  /// Parses raw JSON response from Groq into a typed TranscriptionResult
  static TranscriptionResult parseTranscriptionResponse(
      Map<String, dynamic> data) {
    final fullText = (data['text'] as String? ?? '').trim();
    final duration = (data['duration'] as num?)?.toDouble() ?? 0.0;

    // Parse timestamped segments (FR8 support)
    final segmentsList = <TranscriptSegment>[];
    if (data['segments'] is List) {
      for (final item in data['segments'] as List) {
        if (item is Map) {
          final start = (item['start'] as num?)?.toDouble() ?? 0.0;
          final end = (item['end'] as num?)?.toDouble() ?? 0.0;
          final segText = (item['text'] as String? ?? '').trim();

          if (segText.isNotEmpty) {
            segmentsList.add(
              TranscriptSegment(
                startSec: start,
                endSec: end,
                text: segText,
              ),
            );
          }
        }
      }
    }

    // Detect language: check for mixed script (Arabic + Latin)
    final language = _detectLanguage(fullText, data['language'] as String?);

    return TranscriptionResult(
      text: fullText,
      segments: segmentsList,
      language: language,
      durationSec: duration,
    );
  }

  /// Checks script diversity to detect Arabic, English, or Code-Switched (Mixed)
  static QaydLanguage _detectLanguage(String text, String? reportedLanguage) {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(text);

    if (hasArabic && hasLatin) {
      return QaydLanguage.mixed;
    } else if (hasArabic) {
      return QaydLanguage.ar;
    } else if (hasLatin) {
      return QaydLanguage.en;
    }

    if (reportedLanguage?.toLowerCase() == 'arabic') return QaydLanguage.ar;
    if (reportedLanguage?.toLowerCase() == 'english') return QaydLanguage.en;
    return QaydLanguage.mixed;
  }
}
