import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// ParkFlow brand mark — a glowing "P" inside a hex with a pulsing ring.
class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key, this.size = 96, this.spin = true});

  final double size;
  final bool spin;

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
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
        builder: (_, __) => CustomPaint(
          painter: _LogoPainter(t: _ctrl.value, spin: widget.spin),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.t, required this.spin});
  final double t;
  final bool spin;

  Path _hex(Offset c, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final a = (pi / 3) * i + pi / 6;
      final p = Offset(c.dx + cos(a) * r, c.dy + sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Outer glow.
    canvas.drawCircle(
      center,
      r * 1.05,
      Paint()
        ..color = PFColors.brand.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Hex body.
    final hexFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [PFColors.brand, PFColors.brandStrong],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawPath(_hex(center, r * 0.86), hexFill);

    // Inner hex stroke.
    final hexStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.45);
    canvas.drawPath(_hex(center, r * 0.7), hexStroke);

    // Pulsing ring.
    canvas.drawCircle(
      center,
      r * (0.78 + 0.06 * (0.5 + 0.5 * sin(t * 2 * pi))),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    // Letter P glyph (simple geometric).
    final glyph = Paint()..color = Colors.white;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (spin) {
      // slight oscillation rather than full rotation for subtlety
      canvas.rotate(sin(t * 2 * pi) * 0.04);
    }
    final stem = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(-r * 0.18, 0), width: r * 0.18, height: r * 0.96),
      Radius.circular(r * 0.08),
    );
    canvas.drawRRect(stem, glyph);
    canvas.drawCircle(Offset(r * 0.04, -r * 0.22), r * 0.28, glyph);
    canvas.drawCircle(
      Offset(r * 0.04, -r * 0.22),
      r * 0.13,
      Paint()..color = PFColors.brandStrong,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.t != t;
}
