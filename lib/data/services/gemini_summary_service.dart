// ==============================================================================
// Gemini Academic Summarization Service
// File: lib/data/services/gemini_summary_service.dart
//
// Converts raw lecture transcripts into structured English study notes (FR4).
// Uses Google Gemini 1.5 Flash with enforced JSON output.
// ==============================================================================

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/qayd_model.dart';

class GeminiSummaryService {
  final Dio _dio;
  final String _apiKey;

  GeminiSummaryService({
    Dio? dio,
    String? apiKey,
  })  : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? ApiConstants.geminiApiKey;

  /// Generates a structured English summary from a lecture transcript
  Future<QaydSummary> generateSummary({
    required String transcript,
    String? customApiKey,
  }) async {
    final key = customApiKey ?? _apiKey;
    if (key.trim().isEmpty) {
      throw Exception(
        'Gemini API key is missing. Please provide it in ApiConstants or via --dart-define=GEMINI_API_KEY.',
      );
    }

    if (transcript.trim().isEmpty) {
      throw Exception('Cannot summarize an empty transcript.');
    }

    // Academic Prompt enforcing English output and exact JSON schema
    const systemPrompt = '''
You are an expert academic tutor for university students.
Analyze the following lecture transcript (which may be in Arabic, English, or a mix of both) and produce high-quality, structured study notes.

CRITICAL INSTRUCTIONS:
1. The entire summary MUST be written in clear, academic ENGLISH, regardless of the spoken language.
2. Provide:
   - "overview": A comprehensive 2-3 paragraph academic overview explaining the core concepts.
   - "keyPoints": An array of at least 4 clear, high-yield takeaways for exam preparation.
   - "keyTerms": An array of objects with "term" and "definition" for all key technical terminology mentioned.
3. Return ONLY valid JSON matching this exact structure:
{
  "overview": "...",
  "keyPoints": ["...", "..."],
  "keyTerms": [
    {"term": "...", "definition": "..."}
  ]
}
''';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': '$systemPrompt\n\nLecture Transcript:\n$transcript',
            }
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.2,
      }
    };

    try {
      final url = ApiConstants.geminiUrl(key);
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: requestBody,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      final data = response.data;
      if (data == null) {
        throw Exception('Received empty response from Gemini API');
      }

      return parseGeminiResponse(data);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorMsg = e.response?.data?['error']?['message'] ?? e.message;

      if (statusCode == 400) {
        throw Exception('Gemini Bad Request (400): $errorMsg');
      } else if (statusCode == 403) {
        throw Exception('Invalid Gemini API key (403 Forbidden).');
      } else if (statusCode == 429) {
        throw Exception(
          'Gemini rate limit reached (20 Requests/Day limit). Please try again tomorrow or upgrade quota.',
        );
      } else {
        throw Exception('Summarization failed ($statusCode): $errorMsg');
      }
    } catch (e) {
      throw Exception('Failed to parse summary output: $e');
    }
  }

  /// Parses the raw Gemini response JSON into a QaydSummary object
  static QaydSummary parseGeminiResponse(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No summary candidates returned from Gemini.');
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('No content parts found in Gemini response.');
      }

      final rawText = parts[0]['text'] as String? ?? '{}';

      // Clean markdown code blocks if present (e.g. ```json ... ```)
      String cleanJson = rawText.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      } else if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      final decoded = jsonDecode(cleanJson) as Map<String, dynamic>;
      return QaydSummary.fromMap(decoded);
    } catch (e) {
      throw Exception('Could not parse Gemini JSON output: $e');
    }
  }
}
