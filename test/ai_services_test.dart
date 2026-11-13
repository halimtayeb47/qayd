import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/core/constants/api_constants.dart';
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

    test('groqPrompt is a single clean lexical glossary without instruction prose',
        () {
      expect(ApiConstants.groqPrompt.contains('\n'), false);
      expect(ApiConstants.groqPrompt.contains("'"), false);
      expect(ApiConstants.groqPrompt.toLowerCase(), isNot(contains('transcribe')));
      expect(ApiConstants.groqPrompt.toLowerCase(), isNot(contains('translate')));
      expect(ApiConstants.groqPrompt, contains('API, database'));
    });

    test('Filters known Whisper subtitle hallucinations and prompt echoes cleanly',
        () {
      final mockGroqResponse = {
        'task': 'transcribe',
        'language': 'Arabic',
        'duration': 35.0,
        'text':
            'السلام عليكم API and database connect the backend. ترجمة نانسي قنقر. API, database, backend, frontend, server, client. شكراً للمشاهدة!',
        'segments': [
          {
            'id': 0,
            'start': 0.0,
            'end': 8.0,
            'text': ' السلام عليكم API and database connect the backend.',
            'no_speech_prob': 0.02,
            'avg_logprob': -0.15,
          },
          {
            'id': 1,
            'start': 8.0,
            'end': 12.0,
            'text': ' ترجمة نانسي قنقر.',
            'no_speech_prob': 0.30,
            'avg_logprob': -0.45,
          },
          {
            'id': 2,
            'start': 12.0,
            'end': 18.0,
            'text':
                ' API, database, backend, frontend, server, client.',
            'no_speech_prob': 0.25,
            'avg_logprob': -0.40,
          },
          {
            'id': 3,
            'start': 18.0,
            'end': 25.0,
            'text': ' Transcribe Arabic speech in Arabic script and so on.',
            'no_speech_prob': 0.15,
            'avg_logprob': -0.35,
          },
          {
            'id': 4,
            'start': 25.0,
            'end': 30.0,
            'text': ' شكراً للمشاهدة!',
            'no_speech_prob': 0.40,
            'avg_logprob': -0.50,
          },
          {
            'id': 5,
            'start': 30.0,
            'end': 35.0,
            'text': ' كلام غير واضح في الصمت',
            'no_speech_prob': 0.85,
            'avg_logprob': -1.40,
          },
        ],
      };

      final result =
          GroqWhisperService.parseTranscriptionResponse(mockGroqResponse);

      expect(result.segments.length, 1);
      expect(result.segments.first.text,
          'السلام عليكم API and database connect the backend.');
      expect(result.text,
          'السلام عليكم API and database connect the backend.');
      expect(result.language, QaydLanguage.mixed);
    });

    test('Returns empty text when entire response is a Whisper credit hallucination',
        () {
      final mockGroqResponse = {
        'task': 'transcribe',
        'language': 'Arabic',
        'duration': 5.0,
        'text': 'ترجمة نانسي قنقر.',
        'segments': [
          {
            'id': 0,
            'start': 0.0,
            'end': 5.0,
            'text': 'ترجمة نانسي قنقر.',
            'no_speech_prob': 0.2,
            'avg_logprob': -0.3,
          },
        ],
      };

      final result =
          GroqWhisperService.parseTranscriptionResponse(mockGroqResponse);

      expect(result.segments, isEmpty);
      expect(result.text, isEmpty);
    });

    test('Whisper repetition loops drop consecutive duplicate segments', () {
      final mockGroqResponse = {
        'task': 'transcribe',
        'language': 'Arabic',
        'duration': 15.0,
        'text': 'شرح المفهوم الأول شرح المفهوم الأول شرح المفهوم الأول',
        'segments': [
          {
            'id': 0,
            'start': 0.0,
            'end': 5.0,
            'text': 'شرح المفهوم الأول',
            'no_speech_prob': 0.05,
          },
          {
            'id': 1,
            'start': 5.0,
            'end': 10.0,
            'text': 'شرح المفهوم الأول',
            'no_speech_prob': 0.05,
          },
          {
            'id': 2,
            'start': 10.0,
            'end': 15.0,
            'text': 'شرح المفهوم الأول',
            'no_speech_prob': 0.05,
          },
        ],
      };

      final result =
          GroqWhisperService.parseTranscriptionResponse(mockGroqResponse);

      expect(result.segments.length, 1);
      expect(result.segments.first.text, 'شرح المفهوم الأول');
      expect(result.text, 'شرح المفهوم الأول');
    });

    test('Detects pure English, pure Arabic, and mixed code-switching accurately', () {
      final arabicResp = {
        'text': 'محاضرة في نظم التشغيل وإدارة العمليات',
        'language': 'Arabic',
        'segments': [],
      };
      final englishResp = {
        'text': 'Operating systems process and memory management',
        'language': 'English',
        'segments': [],
      };
      final mixedResp = {
        'text': 'نظام التشغيل يستخدم Process و Thread في الذاكرة',
        'language': 'Arabic',
        'segments': [],
      };

      expect(GroqWhisperService.parseTranscriptionResponse(arabicResp).language,
          QaydLanguage.ar);
      expect(GroqWhisperService.parseTranscriptionResponse(englishResp).language,
          QaydLanguage.en);
      expect(GroqWhisperService.parseTranscriptionResponse(mixedResp).language,
          QaydLanguage.mixed);
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

    test('Skips Gemini 3 thinking parts and parses sections schema cleanly', () {
      final mockThinkingResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'thought': true,
                  'text': 'Let me analyze the transcript carefully before formatting JSON...',
                },
                {
                  'text': '''
{
  "overview": "This lecture contrasts RESTful APIs with RPC architectures.",
  "sections": [
    {
      "heading": "REST Principles",
      "startSec": 125.0,
      "summary": "Covers stateless HTTP verbs and resource URLs."
    }
  ],
  "keyPoints": [
    "REST relies on standard HTTP methods."
  ],
  "keyTerms": [
    {
      "term": "REST",
      "definition": "Representational State Transfer architectural style."
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
          GeminiSummaryService.parseGeminiResponse(mockThinkingResponse);

      expect(summary.overview, contains('RESTful APIs'));
      expect(summary.sections.length, 1);
      expect(summary.sections.first.heading, 'REST Principles');
      expect(summary.sections.first.startSec, 125.0);
      expect(summary.keyTerms.first.term, 'REST');
    });

    test('Formats timestamped segments into [MM:SS] lines for Gemini input', () {
      final formatted = GeminiSummaryService.formatTranscriptForGemini(
        transcript: 'fallback transcript',
        segments: const [
          TranscriptSegment(startSec: 5.0, endSec: 10.0, text: ' Intro '),
          TranscriptSegment(startSec: 125.0, endSec: 140.0, text: 'APIs matter.'),
        ],
      );

      expect(formatted, '[00:05] Intro\n[02:05] APIs matter.');

      final fallback = GeminiSummaryService.formatTranscriptForGemini(
        transcript: '  Plain transcript  ',
      );
      expect(fallback, 'Plain transcript');
    });

    test('Supports brief summaries with empty sections, keyPoints, and keyTerms', () {
      final mockBriefResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': '''
{
  "overview": "A brief casual greeting between speakers.",
  "sections": [],
  "keyPoints": [],
  "keyTerms": []
}
''',
                }
              ]
            }
          }
        ]
      };

      final summary =
          GeminiSummaryService.parseGeminiResponse(mockBriefResponse);

      expect(summary.overview, 'A brief casual greeting between speakers.');
      expect(summary.sections, isEmpty);
      expect(summary.keyPoints, isEmpty);
      expect(summary.keyTerms, isEmpty);
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
