// ==============================================================================
// Qayd Animated Monogram Splash Gate
// File: lib/screens/splash/qayd_splash_gate.dart
//
// Draws the Qayd "ق / Q" monogram stroke-by-stroke on app launch:
// 1. Circular Q/Qaf ring draws clockwise
// 2. Curved calligraphy tail strokes downward
// 3. Two teal dots pop in with an elastic bounce
// 4. Smoothly cross-fades into HomeScreen
// ==============================================================================

import 'package:flutter/material.dart';
import '../../core/theme/qayd_theme.dart';

class QaydSplashGate extends StatefulWidget {
  final Widget child;

  const QaydSplashGate({
    super.key,
    required this.child,
  });

  @override
  State<QaydSplashGate> createState() => _QaydSplashGateState();
}

class _QaydSplashGateState extends State<QaydSplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _completed = true);
        }
      });

    // Wait until the first frame is laid out and rasterized on cold start
    // before starting the stroke-by-stroke drawing animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Pre-mount HomeScreen underneath for instant transition & test compatibility
        widget.child,

        // Animated Stroke-by-Stroke Splash Overlay
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;

                // Fade out overlay during the final 18% (0.82 -> 1.00)
                final fadeOut = t <= 0.82
                    ? 1.0
                    : (1.0 - ((t - 0.82) / 0.18)).clamp(0.0, 1.0);

                // Small initial warm-up window (0.0 -> 0.06) so cold-start shader compilation
                // never clips the beginning of the circular Qaf stroke
                final animT = ((t - 0.06) / 0.76).clamp(0.0, 1.0);

                // Stage timings (normalized within animT 0.0 -> 1.0)
                final ringProgress = Curves.easeInOutCubic.transform(
                  (animT / 0.52).clamp(0.0, 1.0),
                );
                final tailProgress = Curves.easeOutCubic.transform(
                  ((animT - 0.40) / 0.32).clamp(0.0, 1.0),
                );
                final dot1Scale = Curves.elasticOut.transform(
                  ((animT - 0.60) / 0.32).clamp(0.0, 1.0),
                );
                final dot2Scale = Curves.elasticOut.transform(
                  ((animT - 0.68) / 0.32).clamp(0.0, 1.0),
                );
                final textOpacity = Curves.easeOut.transform(
                  ((animT - 0.55) / 0.32).clamp(0.0, 1.0),
                );

                return Opacity(
                  opacity: fadeOut,
                  child: ColoredBox(
                    color: isDark
                        ? const Color(0xFF10131A)
                        : const Color(0xFFFAFBFD),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 148,
                            height: 148,
                            child: CustomPaint(
                              painter: _QaydMonogramPainter(
                                ringProgress: ringProgress,
                                tailProgress: tailProgress,
                                dot1Scale: dot1Scale,
                                dot2Scale: dot2Scale,
                                primaryColor: isDark
                                    ? const Color(0xFF9DB8E8)
                                    : QaydTheme.brandIndigo,
                                secondaryColor: isDark
                                    ? const Color(0xFF5FD1BE)
                                    : QaydTheme.brandTeal,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Opacity(
                            opacity: textOpacity,
                            child: Transform.translate(
                              offset: Offset(0, (1.0 - textOpacity) * 10),
                              child: Column(
                                children: [
                                  Text(
                                    'قَيْد  •  Qayd',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF9DB8E8)
                                          : QaydTheme.brandIndigo,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'قَيِّدُوا الْعِلْمَ بِالْكِتَابِ',
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _QaydMonogramPainter extends CustomPainter {
  final double ringProgress;
  final double tailProgress;
  final double dot1Scale;
  final double dot2Scale;
  final Color primaryColor;
  final Color secondaryColor;

  _QaydMonogramPainter({
    required this.ringProgress,
    required this.tailProgress,
    required this.dot1Scale,
    required this.dot2Scale,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Map original SVG 120x120 coordinates cleanly to canvas size
    final s = size.width / 120.0;
    double tx(double x) => (x + 6.0) * s; // Shift cx=54 -> 60 to center
    double ty(double y) => y * s;

    final center = Offset(tx(54), ty(55));
    final radius = 34.0 * s;

    // Subtle soft circle fill that fades in as the ring completes
    if (ringProgress > 0.2) {
      final fillAlpha = ((ringProgress - 0.2) / 0.8).clamp(0.0, 1.0) * 0.08;
      final fillPaint = Paint()
        ..color = primaryColor.withValues(alpha: fillAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);
    }

    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.2 * s
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // 1. Draw the Q / Qaf circular ring progressively
    if (ringProgress > 0.0) {
      final ringPath = Path()
        ..addArc(
          Rect.fromCircle(center: center, radius: radius),
          -1.57079632679, // Start at top (-90 deg)
          6.28318530718 * ringProgress,
        );
      canvas.drawPath(ringPath, strokePaint);
    }

    // 2. Draw the Q / Qaf curved tail progressively using PathMetrics
    if (tailProgress > 0.0) {
      final fullTail = Path()
        ..moveTo(tx(72), ty(71))
        ..cubicTo(
          tx(74),
          ty(87),
          tx(69),
          ty(101),
          tx(58),
          ty(111),
        );

      for (final metric in fullTail.computeMetrics()) {
        final partialTail = metric.extractPath(
          0.0,
          metric.length * tailProgress,
        );
        canvas.drawPath(partialTail, strokePaint);
      }
    }

    // 3. Draw the two Teal Dots popping in
    final dotPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final baseDotRadius = 5.4 * s;
    if (dot1Scale > 0.0) {
      canvas.drawCircle(
        Offset(tx(43), ty(11)),
        baseDotRadius * dot1Scale,
        dotPaint,
      );
    }
    if (dot2Scale > 0.0) {
      canvas.drawCircle(
        Offset(tx(65), ty(11)),
        baseDotRadius * dot2Scale,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _QaydMonogramPainter oldDelegate) {
    return oldDelegate.ringProgress != ringProgress ||
        oldDelegate.tailProgress != tailProgress ||
        oldDelegate.dot1Scale != dot1Scale ||
        oldDelegate.dot2Scale != dot2Scale ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
