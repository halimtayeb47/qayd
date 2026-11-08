import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/data/models/qayd_model.dart';
import 'package:qayd/data/services/groq_whisper_service.dart';
import 'package:qayd/data/services/gemini_summary_service.dart';

void main() {
  group('Groq Whisper Service Parsing Tests', () {
    test('Parses Groq verbose_json format with segments accurately', () {
      final mockGroqResponse = {
        'task': 'transcribe',
        'language': 'Arabic',
        'duration': 14.5,
        'text': 'أحد أشهر المفاهيم في البرمجة هو الـ API',
        'segments': [
          {
            'id': 0,
            'start': 0.0,
            'end': 2.94,
            'text': ' أحد أشهر المفاهيم في البرمجة على الإطلاق هو الـ API',
          },
          {
            'id': 1,
            'start': 2.94,
            'end': 7.56,
            'text': ' وغالباً لو كنت مبرمج حيكون هذا المصطلح مر عليك',
          },
        ],
      };

      final result =
          GroqWhisperService.parseTranscriptionResponse(mockGroqResponse);

      expect(result.text, 'أحد أشهر المفاهيم في البرمجة هو الـ API');
      expect(result.durationSec, 14.5);
      expect(result.segments.length, 2);
      expect(result.segments[0].startSec, 0.0);
      expect(result.segments[0].endSec, 2.94);
      expect(result.segments[0].text,
          'أحد أشهر المفاهيم في البرمجة على الإطلاق هو الـ API');
      expect(result.language, QaydLanguage.mixed); // Contains Arabic and 'API'
    });

    test('Throws exception if Groq API key is empty', () async {
      final service = GroqWhisperService(apiKey: '');
      expect(
        () => service.transcribeAudio(audioFilePath: 'non_existent.mp3'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Gemini Summary Service Parsing Tests', () {
    test('Parses structured Gemini JSON response correctly', () {
      final mockGeminiResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': '''
{
  "overview": "This lecture explains the role of APIs in modern web architecture.",
  "keyPoints": [
    "APIs decouple the frontend and backend.",
    "Servers send structured data instead of static HTML pages."
  ],
  "keyTerms": [
    {
      "term": "API",
      "definition": "Application Programming Interface allowing software communication."
    }
  ]
}
''',
                }
              ]
            }
          }
        ]
      };

      final summary =
          GeminiSummaryService.parseGeminiResponse(mockGeminiResponse);

      expect(summary.overview,
          'This lecture explains the role of APIs in modern web architecture.');
      expect(summary.keyPoints.length, 2);
      expect(summary.keyTerms.first.term, 'API');
      expect(summary.keyTerms.first.definition,
          'Application Programming Interface allowing software communication.');
    });

    test('Handles markdown-wrapped json gracefully (```json ... ```)', () {
      final mockWrappedResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': '''```json
{
  "overview": "Lecture on database systems.",
  "keyPoints": ["Relational schemas", "ACID transactions"],
  "keyTerms": []
}
```''',
                }
              ]
            }
          }
        ]
      };

      final summary =
          GeminiSummaryService.parseGeminiResponse(mockWrappedResponse);

      expect(summary.overview, 'Lecture on database systems.');
      expect(summary.keyPoints.length, 2);
    });

    test('Throws exception if Gemini API key is empty', () async {
      final service = GeminiSummaryService(apiKey: '');
      expect(
        () => service.generateSummary(transcript: 'Sample text'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
