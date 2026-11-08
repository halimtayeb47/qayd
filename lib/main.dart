import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/qayd_theme.dart';
import 'data/services/storage_service.dart';
import 'data/services/groq_whisper_service.dart';
import 'data/services/gemini_summary_service.dart';
import 'data/services/audio_recording_service.dart';
import 'data/services/audio_picker_service.dart';
import 'providers/qayd_provider.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local persistence (Hive)
  final storageService = StorageService();
  await storageService.init();

  // Initialize application services
  final whisperService = GroqWhisperService();
  final summaryService = GeminiSummaryService();
  final recordingService = AudioRecordingService();
  final pickerService = AudioPickerService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<QaydProvider>(
          create: (_) => QaydProvider(
            storageService: storageService,
            whisperService: whisperService,
            summaryService: summaryService,
            recordingService: recordingService,
            pickerService: pickerService,
          )..loadInitialData(),
        ),
      ],
      child: const QaydApp(),
    ),
  );
}

class QaydApp extends StatelessWidget {
  const QaydApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qayd - قَيْد',
      debugShowCheckedModeBanner: false,
      theme: QaydTheme.light,
      darkTheme: QaydTheme.dark,
      themeMode: ThemeMode.system,
      // Bilingual localization support (Arabic + English with RTL)
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
    );
  }
}
