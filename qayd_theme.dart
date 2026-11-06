// qayd — Academic Indigo brand theme (Material 3)
// ---------------------------------------------------------------------------
// Single source of truth for colour, type and shape across the qayd app.
// Generated from the locked visual identity (see qayd_visual_identity.html).
//
//   MaterialApp(
//     theme: QaydTheme.light,
//     darkTheme: QaydTheme.dark,
//     themeMode: ThemeMode.system,
//   )
//
// FONTS — the identity uses IBM Plex Sans (Latin) + IBM Plex Sans Arabic.
// This file references them by family name only, so it COMPILES AND RUNS as-is
// (Flutter falls back to Roboto until the fonts are present). To make Plex
// actually render, pick ONE of:
//
//   A) google_fonts — add `google_fonts: ^6.2.1` to pubspec.yaml, then build
//      the text theme with GoogleFonts.ibmPlexSansTextTheme(...).
//   B) bundled assets — drop the .ttf files in fonts/ and declare them under
//      flutter: > fonts: with families "IBM Plex Sans" / "IBM Plex Sans Arabic".
//
// Keep teal (secondary) as a SPARING accent — success / active / selected only.
// Indigo (primary) is the brand. Do not hand-pick colours in widgets; read them
// from Theme.of(context).colorScheme so light/dark and contrast stay correct.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

abstract final class QaydTheme {
  const QaydTheme._();

  // --- Type family -----------------------------------------------------------
  static const String _fontFamily = 'IBM Plex Sans';
  static const List<String> _fontFallback = <String>[
    'IBM Plex Sans Arabic', // Arabic glyphs (RTL)
    'Noto Sans',
    'Noto Sans Arabic',
  ];

  // --- Brand constants (for the occasional custom-painted widget) ------------
  static const Color brandIndigo = Color(0xFF2A4D82);
  static const Color brandTeal = Color(0xFF0B8072);

  // --- Shape tokens (dp) ------------------------------------------------------
  static const double _rSmall = 8; // chips, small controls
  static const double _rField = 12; // text fields, snackbars
  static const double _rCard = 16; // cards, FAB
  static const double _rSheet = 28; // dialogs, bottom sheets

  // --- Public API -------------------------------------------------------------
  static ThemeData get light => _base(lightScheme);
  static ThemeData get dark => _base(darkScheme);

  // --- Colour schemes (WCAG-verified; see scheme_check.py) --------------------
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2A4D82),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD7E3F8),
    onPrimaryContainer: Color(0xFF0A1F3D),
    secondary: Color(0xFF0B8072),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFAEEDE1),
    onSecondaryContainer: Color(0xFF00382F),
    tertiary: Color(0xFF45506B),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDCE1EE),
    onTertiaryContainer: Color(0xFF161B29),
    error: Color(0xFFC0392B),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDA),
    onErrorContainer: Color(0xFF410E07),
    surface: Color(0xFFFAFBFD),
    onSurface: Color(0xFF141A24),
    onSurfaceVariant: Color(0xFF44474F),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF3F5F9),
    surfaceContainer: Color(0xFFEDEFF4),
    surfaceContainerHigh: Color(0xFFE7EAF1),
    surfaceContainerHighest: Color(0xFFE1E4EC),
    outline: Color(0xFF74777F),
    outlineVariant: Color(0xFFC4C7CF),
    inverseSurface: Color(0xFF2A2F38),
    onInverseSurface: Color(0xFFF0F2F7),
    inversePrimary: Color(0xFF9DB8E8),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF9DB8E8),
    onPrimary: Color(0xFF0A1A33),
    primaryContainer: Color(0xFF223A63),
    onPrimaryContainer: Color(0xFFD7E3F8),
    secondary: Color(0xFF5FD1BE),
    onSecondary: Color(0xFF00382F),
    secondaryContainer: Color(0xFF005345),
    onSecondaryContainer: Color(0xFFAEEDE1),
    tertiary: Color(0xFFB4BEDA),
    onTertiary: Color(0xFF1E2740),
    tertiaryContainer: Color(0xFF343E57),
    onTertiaryContainer: Color(0xFFDCE1EE),
    error: Color(0xFFF28B82),
    onError: Color(0xFF5F1611),
    errorContainer: Color(0xFF8C1D13),
    onErrorContainer: Color(0xFFF9DEDA),
    surface: Color(0xFF10131A),
    onSurface: Color(0xFFE8ECF3),
    onSurfaceVariant: Color(0xFFC4C7CF),
    surfaceContainerLowest: Color(0xFF0B0E14),
    surfaceContainerLow: Color(0xFF171B22),
    surfaceContainer: Color(0xFF1B1F27),
    surfaceContainerHigh: Color(0xFF262A32),
    surfaceContainerHighest: Color(0xFF31353D),
    outline: Color(0xFF8E9199),
    outlineVariant: Color(0xFF43474E),
    inverseSurface: Color(0xFFE8ECF3),
    onInverseSurface: Color(0xFF2A2F38),
    inversePrimary: Color(0xFF2A4D82),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  // --- Theme assembly ---------------------------------------------------------
  static ThemeData _base(ColorScheme s) {
    final TextTheme text = _textTheme(s.onSurface);
    return ThemeData(
      useMaterial3: true,
      colorScheme: s,
      brightness: s.brightness,
      scaffoldBackgroundColor: s.surface,
      canvasColor: s.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: text,
      iconTheme: IconThemeData(color: s.onSurfaceVariant),
      dividerTheme: DividerThemeData(
        color: s.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: s.surface,
        foregroundColor: s.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: s.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rCard),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: text.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: text.labelLarge,
          side: BorderSide(color: s.outline),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: text.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: s.primaryContainer,
        foregroundColor: s.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rCard),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: s.surfaceContainerLow,
        selectedColor: s.secondaryContainer,
        side: BorderSide(color: s.outlineVariant),
        labelStyle: text.labelLarge?.copyWith(color: s.onSurfaceVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rSmall),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: s.surfaceContainerHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_rField),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_rField),
          borderSide: BorderSide(color: s.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_rField),
          borderSide: BorderSide(color: s.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_rField),
          borderSide: BorderSide(color: s.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_rField),
          borderSide: BorderSide(color: s.error, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: s.surfaceContainer,
        indicatorColor: s.secondaryContainer,
        elevation: 2,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? s.onSecondaryContainer
                : s.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: s.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: s.onInverseSurface),
        actionTextColor: s.inversePrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rField),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: s.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rSheet),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_rSheet)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: s.primary,
        linearTrackColor: s.surfaceContainerHigh,
        circularTrackColor: s.surfaceContainerHigh,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: s.onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_rField),
        ),
      ),

    );
  }
  // --- Type scale (Material 3 roles) -----------------------------------------
  // Titles and labels nudged to SemiBold (w600) for a calm, scholarly voice;
  // display/headline/body stay at the Material 3 default weights.
  static TextTheme _textTheme(Color c) => _scale.apply(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFallback,
        bodyColor: c,
        displayColor: c,
      );

  static const TextTheme _scale = TextTheme(
    displayLarge: TextStyle(fontSize: 57, height: 1.12, letterSpacing: -0.25, fontWeight: FontWeight.w400),
    displayMedium: TextStyle(fontSize: 45, height: 1.16, letterSpacing: 0, fontWeight: FontWeight.w400),
    displaySmall: TextStyle(fontSize: 36, height: 1.22, letterSpacing: 0, fontWeight: FontWeight.w400),
    headlineLarge: TextStyle(fontSize: 32, height: 1.25, letterSpacing: 0, fontWeight: FontWeight.w400),
    headlineMedium: TextStyle(fontSize: 28, height: 1.29, letterSpacing: 0, fontWeight: FontWeight.w400),
    headlineSmall: TextStyle(fontSize: 24, height: 1.33, letterSpacing: 0, fontWeight: FontWeight.w500),
    titleLarge: TextStyle(fontSize: 22, height: 1.27, letterSpacing: 0, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, height: 1.50, letterSpacing: 0.15, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 14, height: 1.43, letterSpacing: 0.1, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.50, letterSpacing: 0.5, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, height: 1.43, letterSpacing: 0.25, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 12, height: 1.33, letterSpacing: 0.4, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 14, height: 1.43, letterSpacing: 0.1, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 12, height: 1.33, letterSpacing: 0.5, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 11, height: 1.45, letterSpacing: 0.5, fontWeight: FontWeight.w600),
  );

}
