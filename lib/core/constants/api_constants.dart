// ==============================================================================
// API Constants & Configurations
// File: lib/core/constants/api_constants.dart
//
// Centralized configuration for Groq Whisper and Google Gemini APIs.
// Keys can be passed via --dart-define during build, or replaced here for testing.
// ==============================================================================

class ApiConstants {
  ApiConstants._();

  // ---------------------------------------------------------------------------
  // Groq Whisper API (Speech-to-Text)
  // ---------------------------------------------------------------------------
  static const String groqBaseUrl =
      'https://api.groq.com/openai/v1/audio/transcriptions';

  /// Groq API key: Reads from --dart-define=GROQ_API_KEY or defaults to fallback
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '', // Insert your development key or pass via --dart-define
  );

  static const String groqModel = 'whisper-large-v3';

  /// The validated code-switching prompt that enforces English technical terms
  /// inside Arabic speech without unwanted translations.
  static const String groqPrompt =
      'Transcribe verbatim without translation. '
      'Maintain strict code-switching between Arabic and English. '
      'Transcribe Arabic speech in Arabic script and all technical terms, '
      'programming concepts, and spoken English words in standard English Latin script: '
      'API, database, backend, frontend, server, client, request, response, '
      'array, loop, function, class, object, architecture, framework.';

  // ---------------------------------------------------------------------------
  // Google Gemini API (Academic Summarization)
  // ---------------------------------------------------------------------------
  static const String geminiModel = 'gemini-1.5-flash';

  static String geminiUrl(String apiKey) =>
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$apiKey';

  /// Gemini API key: Reads from --dart-define=GEMINI_API_KEY or defaults to fallback
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Insert your development key or pass via --dart-define
  );
}
