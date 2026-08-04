import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Animated isometric parking grid used as a hero background on splash,
/// onboarding and the dashboard. Cars drift across the canvas slowly.
class ParkingGridBackground extends StatefulWidget {
  const ParkingGridBackground({
    super.key,
    this.intensity = 1.0,
    this.tint = PFColors.brand,
    this.animated = true,
  });

  final double intensity;
  final Color tint;

  /// When false the grid is painted once as a static frame (no repeating
  /// controller). Used on the main app screens to avoid 20 continuously
  /// repainting canvases draining the battery; hero/entry screens keep it on.
  final bool animated;

  @override
  State<ParkingGridBackground> createState() => _ParkingGridBackgroundState();
}

class _ParkingGridBackgroundState extends State<ParkingGridBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animated) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(ParkingGridBackground old) {
    super.didUpdateWidget(old);
    if (widget.animated != old.animated) {
      if (widget.animated) {
        _ctrl.repeat();
      } else {
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _GridPainter(
            t: _ctrl.value,
            intensity: widget.intensity,
            tint: widget.tint,
            dark: dark,
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.t,
    required this.intensity,
    required this.tint,
    required this.dark,
  });

  final double t;
  final double intensity;
  final Color tint;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark
            ? const [Color(0xFF03100D), Color(0xFF050B0A)]
            : const [Color(0xFFEDF6F0), Color(0xFFF7FAF8)],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // Glow blobs.
    for (int i = 0; i < 3; i++) {
      final cx = size.width *
          (0.2 + 0.6 * ((t + i * 0.33) % 1.0));
      final cy = size.height *
          (0.15 + 0.7 * (1 - ((t * 0.7 + i * 0.5) % 1.0)));
      final r = size.shortestSide * (0.35 + 0.15 * i);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            tint.withValues(alpha: 0.18 * intensity),
            tint.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    // Isometric grid.
    final lineColor = dark
        ? Colors.white.withValues(alpha: 0.05 * intensity)
        : Colors.black.withValues(alpha: 0.05 * intensity);
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const step = 36.0;
    final shift = step * t;
    for (double x = -size.width + shift; x < size.width * 2; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height * 0.6, size.height),
        linePaint,
      );
    }
    for (double y = -size.height + shift; y < size.height * 2; y += step) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + size.width * 0.4),
        linePaint,
      );
    }

    // Drifting cars (rounded rects). Softer on light so they read as subtle
    // accents rather than solid green blocks on a near-white canvas.
    final carPaint = Paint()
      ..color = tint.withValues(alpha: (dark ? 0.85 : 0.45) * intensity);
    final glowPaint = Paint()
      ..color = tint.withValues(alpha: (dark ? 0.35 : 0.18) * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final rng = Random(7);
    for (int i = 0; i < 6; i++) {
      final lane = i / 6;
      final x = ((t + rng.nextDouble()) * (size.width + 220)) % (size.width + 220) - 110;
      final y = size.height * (0.18 + lane * 0.78);
      final rectCar = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 56, height: 22),
        const Radius.circular(8),
      );
      canvas.drawRRect(rectCar.inflate(2), glowPaint);
      canvas.drawRRect(rectCar, carPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.t != t || old.intensity != intensity;
}
