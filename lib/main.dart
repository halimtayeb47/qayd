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

  runApp(
    QaydApp(
      storageService: storageService,
      whisperService: GroqWhisperService(),
      summaryService: GeminiSummaryService(),
      recordingService: AudioRecordingService(),
      pickerService: AudioPickerService(),
    ),
  );
}

class QaydApp extends StatelessWidget {
  final StorageService? storageService;
  final GroqWhisperService? whisperService;
  final GeminiSummaryService? summaryService;
  final AudioRecordingService? recordingService;
  final AudioPickerService? pickerService;

  const QaydApp({
    super.key,
    this.storageService,
    this.whisperService,
    this.summaryService,
    this.recordingService,
    this.pickerService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<QaydProvider>(
          create: (_) => QaydProvider(
            storageService: storageService ?? StorageService(),
            whisperService: whisperService ?? GroqWhisperService(),
            summaryService: summaryService ?? GeminiSummaryService(),
            recordingService: recordingService ?? AudioRecordingService(),
            pickerService: pickerService ?? AudioPickerService(),
          )..loadInitialData(),
        ),
      ],
      child: Consumer<QaydProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'Qayd - قَيْد',
            debugShowCheckedModeBanner: false,
            theme: QaydTheme.light,
            darkTheme: QaydTheme.dark,
            themeMode: provider.themeMode,
            locale: provider.currentLocale,
            // Bilingual localization support (Arabic + English with RTL)
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
