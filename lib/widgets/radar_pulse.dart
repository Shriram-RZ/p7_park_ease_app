import 'dart:math';
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Pulsing radar rings used on splash, dashboard and navigation arrival.
class RadarPulse extends StatefulWidget {
  const RadarPulse({
    super.key,
    this.size = 220,
    this.color = PFColors.brand,
    this.rings = 3,
    this.duration = const Duration(milliseconds: 2400),
    this.child,
  });

  final double size;
  final Color color;
  final int rings;
  final Duration duration;
  final Widget? child;

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => CustomPaint(
          painter: _RadarPainter(
            t: _ctrl.value,
            color: widget.color,
            rings: widget.rings,
          ),
          child: child,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.t, required this.color, required this.rings});
  final double t;
  final Color color;
  final int rings;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    // Soft background glow.
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, glow);

    for (int i = 0; i < rings; i++) {
      final offset = (t + i / rings) % 1.0;
      final radius = maxR * offset;
      final alpha = (1.0 - offset) * 0.65;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = color.withValues(alpha: alpha);
      canvas.drawCircle(center, radius, p);
    }

    // Sweep arm.
    final sweepAngle = pi * 2 * t;
    final armP = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 0.6,
        endAngle: sweepAngle,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxR))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxR * 0.92),
      sweepAngle - 0.6,
      0.6,
      false,
      armP,
    );

    // Inner core.
    final core = Paint()..color = color.withValues(alpha: 0.85);
    canvas.drawCircle(center, 4, core);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.t != t || old.color != color;
}
