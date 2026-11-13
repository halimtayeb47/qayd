// ==============================================================================
// Gemini Academic Summarization Service
// File: lib/data/services/gemini_summary_service.dart
//
// Converts raw lecture transcripts into structured English study notes (FR4).
// Uses Google Gemini 3 Flash Preview with enforced responseJsonSchema output
// and timestamp-aware topic breakdown sections.
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

  static const Map<String, dynamic> _summaryJsonSchema = {
    'type': 'object',
    'properties': {
      'overview': {
        'type': 'string',
        'description':
            'A concise English overview proportional to transcript substance (1 plain sentence for brief/casual clips; 2-4 sentences for substantive lectures).',
      },
      'sections': {
        'type': 'array',
        'description':
            'Chronological topic breakdown sections aligned to transcript [MM:SS] timestamps. Empty [] for brief casual clips.',
        'items': {
          'type': 'object',
          'properties': {
            'heading': {'type': 'string'},
            'startSec': {'type': 'number'},
            'summary': {'type': 'string'},
          },
          'required': ['heading', 'startSec', 'summary'],
        },
      },
      'keyPoints': {
        'type': 'array',
        'description':
            'Concrete takeaways actually discussed in the transcript. Empty [] when no substantive points exist.',
        'items': {'type': 'string'},
      },
      'keyTerms': {
        'type': 'array',
        'description':
            'Genuine technical or domain-specific terms explicitly used in the transcript. Empty [] when none exist.',
        'items': {
          'type': 'object',
          'properties': {
            'term': {'type': 'string'},
            'definition': {'type': 'string'},
          },
          'required': ['term', 'definition'],
        },
      },
    },
    'required': ['overview', 'sections', 'keyPoints', 'keyTerms'],
  };

  /// Formats timestamped Whisper segments into compact `[MM:SS] <text>` lines
  /// for Gemini input, falling back to plain [transcript] when segments are empty.
  static String formatTranscriptForGemini({
    required String transcript,
    List<TranscriptSegment> segments = const [],
  }) {
    final buffer = StringBuffer();
    for (final seg in segments) {
      final text = seg.text.trim();
      if (text.isEmpty) continue;
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write('[${_formatTimestamp(seg.startSec)}] $text');
    }

    if (buffer.isNotEmpty) {
      return buffer.toString();
    }
    return transcript.trim();
  }

  static String _formatTimestamp(double seconds) {
    final totalSec = seconds < 0 ? 0 : seconds.floor();
    final minutes = (totalSec ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSec % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  /// Generates a structured academic summary from a lecture transcript
  /// in either English ('en') or Arabic ('ar') per user preference.
  Future<QaydSummary> generateSummary({
    required String transcript,
    List<TranscriptSegment> segments = const [],
    String summaryLanguage = 'en',
    String? customApiKey,
  }) async {
    final key = customApiKey ?? _apiKey;
    if (key.trim().isEmpty) {
      throw Exception(
        'Gemini API key is missing. Please provide it in ApiConstants or via --dart-define=GEMINI_API_KEY.',
      );
    }

    final formattedTranscript = formatTranscriptForGemini(
      transcript: transcript,
      segments: segments,
    );

    if (formattedTranscript.isEmpty) {
      throw Exception('Cannot summarize an empty transcript.');
    }

    final systemPrompt = summaryLanguage == 'ar'
        ? '''
أنت مساعد أكاديمي رفيع المستوى ودقيق في تلخيص المحاضرات والشروحات الجامعية.
قم بتلخيص نص المحاضرة التالي (والذي قد يكون بالعربية أو الإنجليزية أو خليطاً بينهما مع طوابع زمنية [MM:SS]) بدقة متناهية ومباشرة من المحتوى الفعلي فقط.

تعليمات حرجة:
1. اكتب كامل الملخص بلغة عربية فصحى أكاديمية، واضحة ورصينة وموجزة.
2. حافظ على المصطلحات التقنية والبرمجية والعلمية بالحروف اللاتينية الإنجليزية الأصلية مع شرحها (مثل: API، Database، Algorithm، Data Structure).
3. لا تختلق ولا تضخم محتوى غير موجود:
   - طابق التفاصيل تماماً مع ما قيل في المحاضرة.
   - إذا كانت المحاضرة مجرد تحية قصيرة أو كلام عابر (مثل: "السلام عليكم كيف الحال")، اذكر ذلك بجملة واحدة في "overview" وأرجع مصفوفات فارغة [] في "sections" و "keyPoints" و "keyTerms".
   - لا تخترع مفاهيم مجردة لم تُذكر أبداً في النص.
4. للمحاضرات والشروحات العلمية:
   - "overview": فقرة تمهيدية أكاديمية من 2 إلى 4 جمل تشرح جوهر الموضوع ونطاق المحاضرة.
   - "sections": محاور زمنية تسلسلية مرتبة زمنياً (من 2 إلى 6 أقسام عند تعدد الموضوعات؛ مصفوفة فارغة [] للمقاطع القصيرة أحادية الفكرة). يتضمن كل عنصر:
     * "heading": عنوان موجز وسهل القراءة للمحور.
     * "startSec": زمن البداية بالثواني محولاً من طابع [MM:SS] (مثال: [02:30] -> 150). استخدم 0 إذا لم توجد طوابع.
     * "summary": جملة أو جملتان تشرحان ما تم تناوله بالفعل.
   - "keyPoints": أهم النقاط المستفادة والأفكار الأساسية المذكورة في المحاضرة (حتى 6 نقاط واضحة دون حشو).
   - "keyTerms": المصطلحات العلمية والتقنية المذكورة صراحة مع تعريف موجز ("term" و "definition"). أرجع [] إذا لم توجد مصطلحات.
5. أرجع الإخراج بصيغة JSON فقط متطابقاً تماماً مع المخطط المرفق.
'''
        : '''
You are a precise academic note-taking assistant.
Summarize the following transcript (which may be in Arabic, English, or a mix of both, and may include [MM:SS] timestamps) strictly from what was actually said.

CRITICAL INSTRUCTIONS:
1. Write the entire summary in clear, natural, concise ENGLISH, regardless of the spoken language.
2. NEVER invent, pad, or inflate content with filler or fake academic jargon:
   - Match length and detail strictly to the transcript content.
   - If the transcript is a brief greeting, small talk, or lacks substantive information (e.g., "Hi, how are you?"), state that plainly in 1 concise sentence in "overview" and return empty arrays [] for "sections", "keyPoints", and "keyTerms".
   - Do NOT invent abstract concepts (like "communicative rapport" or "interpersonal communication") when none were discussed.
3. For substantive lectures or presentations:
   - "overview": A crisp 2-4 sentence academic overview summarizing the core topic and scope.
   - "sections": Chronological topic breakdown cards (2-6 distinct topics when multiple ideas exist; empty [] for short single-topic clips). Each item needs:
     * "heading": Short scannable topic title.
     * "startSec": Numeric start time in seconds converted from the matching [MM:SS] timestamp (for example [02:30] -> 150). Use 0 if no timestamps are present.
     * "summary": 1-2 clear sentences explaining what was actually covered.
   - "keyPoints": Concrete, distinct takeaways actually mentioned in the transcript (up to 6 bullets; do not pad with filler).
   - "keyTerms": Genuine technical or domain-specific terms explicitly used in the transcript with crisp definitions ("term" and "definition"). Return [] if none exist.
4. Return ONLY valid JSON adhering strictly to the schema.
''';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': '$systemPrompt\n\nLecture Transcript:\n$formattedTranscript',
            }
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseJsonSchema': _summaryJsonSchema,
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
      final errorData = e.response?.data;
      String? errorMsg;
      if (errorData is Map && errorData['error'] is Map) {
        errorMsg = errorData['error']['message']?.toString();
      }
      errorMsg ??= e.message;

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

  /// Parses the raw Gemini response JSON into a QaydSummary object,
  /// safely skipping any reasoning/thinking parts (`thought: true`).
  static QaydSummary parseGeminiResponse(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No summary candidates returned from Gemini.');
      }

      final firstCandidate = candidates[0] as Map?;
      final content = firstCandidate?['content'] as Map?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('No content parts found in Gemini response.');
      }

      String? rawText;
      for (final part in parts) {
        if (part is! Map) continue;
        if (part['thought'] == true) continue;
        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) {
          rawText = text;
        }
      }

      if (rawText == null) {
        throw Exception('No non-thought JSON text found in Gemini response.');
      }

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
