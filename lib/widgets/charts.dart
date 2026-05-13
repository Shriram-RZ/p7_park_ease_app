import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Animated bar chart with smooth easing on first paint.
class PFBarChart extends StatelessWidget {
  const PFBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.barColor = PFColors.brand,
    this.height = 180,
    this.maxLabel = '',
  });

  final List<double> values;
  final List<String> labels;
  final Color barColor;
  final double height;
  final String maxLabel;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => SizedBox(
        height: height,
        child: CustomPaint(
          painter: _BarPainter(
            values: values,
            labels: labels,
            color: barColor,
            t: t,
            dark: Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.t,
    required this.dark,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double t;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxV = values.reduce(max).clamp(1.0, double.infinity);
    final n = values.length;
    final gap = 8.0;
    final barW = (size.width - gap * (n - 1)) / n;
    const labelGap = 22.0;
    final chartH = size.height - labelGap;

    final gridP = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = chartH * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridP);
    }

    for (int i = 0; i < n; i++) {
      final v = values[i] / maxV;
      final h = chartH * v * t;
      final x = i * (barW + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartH - h, barW, h),
        const Radius.circular(8),
      );
      final p = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0.55)],
        ).createShader(Rect.fromLTWH(x, chartH - h, barW, h));
      canvas.drawRRect(rect, p);
      // Glow on top.
      canvas.drawCircle(
        Offset(x + barW / 2, chartH - h),
        3,
        Paint()..color = color.withValues(alpha: 0.85),
      );

      // Label.
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            fontSize: 11,
            color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + barW / 2 - tp.width / 2, chartH + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.t != t || old.values != values;
}

/// Animated donut chart used for occupancy.
class PFDonutChart extends StatelessWidget {
  const PFDonutChart({
    super.key,
    required this.value, // 0..1
    this.size = 140,
    this.color = PFColors.brand,
    this.trackColor,
    this.thickness = 12,
    this.center,
  });

  final double value;
  final double size;
  final Color color;
  final Color? trackColor;
  final double thickness;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final track = trackColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08));
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => CustomPaint(
          painter: _DonutPainter(
            value: v,
            color: color,
            track: track,
            thickness: thickness,
          ),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.thickness,
  });
  final double value;
  final Color color;
  final Color track;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - thickness) / 2;

    final trackP = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackP);

    final sweep = value * 2 * pi;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final arcP = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + 2 * pi,
        colors: [color.withValues(alpha: 0.4), color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -pi / 2, sweep, false, arcP);

    // End cap glow.
    if (value > 0) {
      final endAngle = -pi / 2 + sweep;
      final endPos = Offset(
        center.dx + cos(endAngle) * radius,
        center.dy + sin(endAngle) * radius,
      );
      canvas.drawCircle(
        endPos,
        thickness * 0.7,
        Paint()..color = color.withValues(alpha: 0.45),
      );
      canvas.drawCircle(endPos, thickness * 0.35, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.value != value || old.color != color;
}

/// Smooth area line chart for trends.
class PFLineChart extends StatelessWidget {
  const PFLineChart({
    super.key,
    required this.values,
    this.color = PFColors.brand,
    this.height = 140,
  });
  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => SizedBox(
        height: height,
        child: CustomPaint(
          painter: _LinePainter(values: values, color: color, t: t),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.values, required this.color, required this.t});
  final List<double> values;
  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(max);
    final minV = values.reduce(min);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);
    final stepX = size.width / (values.length - 1);
    final path = Path();
    final fill = Path();
    final pts = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final norm = (values[i] - minV) / range;
      final x = stepX * i;
      final y = size.height * (1 - norm) * t + (1 - t) * size.height;
      pts.add(Offset(x, y));
    }
    path.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final p0 = pts[i - 1];
      final p1 = pts[i];
      final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    fill.addPath(path, Offset.zero);
    fill.lineTo(size.width, size.height);
    fill.lineTo(0, size.height);
    fill.close();

    final fillP = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.0)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fill, fillP);

    final strokeP = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokeP);

    // Marker on last point.
    final last = pts.last;
    canvas.drawCircle(last, 5, Paint()..color = color.withValues(alpha: 0.35));
    canvas.drawCircle(last, 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.t != t || old.values != values;
}
