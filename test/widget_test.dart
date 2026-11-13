import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/core/theme/qayd_theme.dart';
import 'package:qayd/main.dart';
import 'package:qayd/screens/splash/qayd_splash_gate.dart';

void main() {
  testWidgets('QaydApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QaydApp());
    expect(find.byType(QaydApp), findsOneWidget);
  });

  testWidgets(
      'QaydSplashGate gates child interaction/semantics until animation completes and preserves child state',
      (WidgetTester tester) async {
    var tapped = 0;
    var initCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: QaydTheme.light,
        home: QaydSplashGate(
          child: _CounterProbe(
            onInit: () => initCount++,
            onTap: () => tapped++,
          ),
        ),
      ),
    );

    // Pump once to execute post-frame callback and start the 2000ms controller.
    await tester.pump();

    expect(find.text('قَيْد  •  Qayd'), findsOneWidget);
    expect(find.text('قَيِّدُوا الْعِلْمَ بِالْكِتَابِ'), findsOneWidget);

    // Child exists underneath, but taps are blocked and semantics are excluded.
    await tester.tap(find.text('Action'), warnIfMissed: false);
    await tester.pump();
    expect(tapped, 0);
    expect(tester.getSemantics(find.text('Action')).label, isEmpty);

    // Advance past the 2000ms splash duration so the overlay completes and clears.
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.pump();

    expect(find.text('قَيْد  •  Qayd'), findsNothing);
    expect(initCount, 1);

    // Child becomes interactive and exposes semantics after splash finishes.
    expect(tester.getSemantics(find.text('Action')).label, 'Action');
    await tester.tap(find.text('Action'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('QaydSplashGate renders cleanly in dark theme using scheme colors',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: QaydTheme.dark,
        home: const QaydSplashGate(
          child: Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1000));

    final coloredBox = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(QaydSplashGate),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(coloredBox.color, QaydTheme.darkScheme.surface);
  });
}

class _CounterProbe extends StatefulWidget {
  final VoidCallback onInit;
  final VoidCallback onTap;

  const _CounterProbe({
    required this.onInit,
    required this.onTap,
  });

  @override
  State<_CounterProbe> createState() => _CounterProbeState();
}

class _CounterProbeState extends State<_CounterProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: widget.onTap,
          child: const Text('Action'),
        ),
      ),
    );
  }
}
