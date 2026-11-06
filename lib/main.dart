import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/qayd_theme.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QaydApp());
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
