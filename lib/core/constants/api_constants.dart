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

  /// Bilingual technical vocabulary glossary prompt for Whisper.
  /// Intentionally contains ZERO instructional phrases ("Transcribe...", "Translate...", etc.)
  /// so Whisper never echoes instructions or gets tricked into translation mode.
  static const String groqPrompt =
      'محاضرة وشرح، السلام عليكم، أهلاً بكم. '
      'API, database, backend, frontend, server, client, request, response, '
      'array, loop, function, class, object, architecture, framework, '
      'thread, process, memory, cache, CPU, algorithm, debug, data, network.';

  /// Backward-compatible aliases
  static const String groqArabicPrompt = groqPrompt;
  static const String groqEnglishPrompt = groqPrompt;
  // ---------------------------------------------------------------------------
  // Google Gemini API (Academic Summarization)
  // ---------------------------------------------------------------------------
  static const String geminiModel = 'gemini-3-flash-preview';

  static String geminiUrl(String apiKey) =>
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$apiKey';

  /// Gemini API key: Reads from --dart-define=GEMINI_API_KEY or defaults to fallback
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Insert your development key or pass via --dart-define
  );
}
