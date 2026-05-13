import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/parking_slot.dart';

/// Renders the parking floor: aisles, slots, cars, entry/exit, legend.
class ParkingMapPainter extends CustomPainter {
  ParkingMapPainter({
    required this.slots,
    required this.selectedId,
    required this.pulse, // 0..1
    required this.carT, // 0..1
    required this.dark,
    this.routeTarget,
    this.routeT = 0,
  });

  final List<PFSlot> slots;
  final String? selectedId;
  final double pulse;
  final double carT;
  final bool dark;
  final String? routeTarget;
  final double routeT;

  static const int side = 6;
  static const double slotW = 64;
  static const double slotH = 88;
  static const double aisleGap = 60;
  static const double padding = 40;

  static const int rowsPerBand = side ~/ 2;

  static Size canvasSize() {
    final w = padding * 2 + slotW * side + 12 * (side - 1);
    final h = padding * 2 + slotH * rowsPerBand * 2 + aisleGap;
    return Size(w, h);
  }

  Offset _slotTopLeft(PFSlot s) {
    final col = s.col;
    final bool topRow = s.row < rowsPerBand;
    final rowInBand = topRow ? s.row : s.row - rowsPerBand;
    final x = padding + col * (slotW + 12);
    final y = padding + rowInBand * slotH +
        (topRow ? 0 : slotH * rowsPerBand + aisleGap);
    return Offset(x, y);
  }

  Rect _slotRect(PFSlot s) {
    final tl = _slotTopLeft(s);
    return Rect.fromLTWH(tl.dx, tl.dy, slotW, slotH);
  }

  PFSlot? slotAt(Offset local) {
    for (final s in slots) {
      if (_slotRect(s).inflate(2).contains(local)) return s;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final mapSize = canvasSize();
    // Background.
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? const [Color(0xFF03100D), Color(0xFF071614)]
            : const [Color(0xFFF7FAF8), Color(0xFFEFF5F1)],
      ).createShader(Offset.zero & mapSize);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Offset.zero & mapSize, const Radius.circular(24)),
        bg);

    // Aisle.
    final aisleRect = Rect.fromLTWH(
      padding - 12,
      padding + slotH * rowsPerBand + 4,
      mapSize.width - (padding - 12) * 2,
      aisleGap - 8,
    );
    final aisle = Paint()
      ..color = dark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.04);
    canvas.drawRRect(
      RRect.fromRectAndRadius(aisleRect, const Radius.circular(14)),
      aisle,
    );
    // Lane markers (dashed line).
    final dashPaint = Paint()
      ..color = PFColors.brand.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final midY = aisleRect.center.dy;
    const dash = 14.0;
    const gap = 12.0;
    for (double x = aisleRect.left + 6; x < aisleRect.right - 6; x += dash + gap) {
      canvas.drawLine(Offset(x, midY), Offset(x + dash, midY), dashPaint);
    }

    // Entry / Exit pads.
    _drawPad(canvas, Offset(40, padding + slotH * 0.5), label: 'ENTRY');
    _drawPad(
        canvas,
        Offset(mapSize.width - 40,
            padding + slotH * rowsPerBand + aisleGap + slotH * (rowsPerBand - 0.5)),
        label: 'EXIT');

    // Slots.
    for (final s in slots) {
      _drawSlot(canvas, s);
    }

    // Animated car along the aisle.
    final carX = aisleRect.left + 12 +
        (aisleRect.width - 24) * ((carT * 1.2) % 1.0);
    _drawCar(canvas, Offset(carX, midY), PFColors.brand);
    final car2X = aisleRect.left + 12 +
        (aisleRect.width - 24) * ((1 - (carT * 0.8) % 1.0));
    _drawCar(canvas, Offset(car2X, midY - 2), PFColors.info);

    // Route to selected target.
    if (routeTarget != null) {
      final tgt = slots.firstWhere(
        (s) => s.id == routeTarget,
        orElse: () => slots.first,
      );
      _drawRoute(canvas, aisleRect, tgt);
    }
  }

  void _drawPad(Canvas canvas, Offset pos, {required String label}) {
    final rect = Rect.fromCenter(center: pos, width: 56, height: 32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = PFColors.brand.withValues(alpha: 0.3),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
  }

  void _drawSlot(Canvas canvas, PFSlot s) {
    final rect = _slotRect(s);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    final isSelected = s.id == selectedId;
    final color = switch (s.status) {
      SlotStatus.available => PFColors.brand,
      SlotStatus.occupied => PFColors.danger,
      SlotStatus.reserved => PFColors.info,
      SlotStatus.selected => PFColors.slotSelected,
      SlotStatus.disabled => PFColors.slotDisabled,
    };
    final fillAlpha = switch (s.status) {
      SlotStatus.occupied => 0.55,
      SlotStatus.reserved => 0.35,
      SlotStatus.disabled => 0.2,
      _ => 0.18,
    };

    // Glow for selected/available.
    if (isSelected || s.status == SlotStatus.available) {
      final pulseAlpha = isSelected ? 0.55 : 0.28 + 0.2 * sin(pulse * 2 * pi);
      canvas.drawRRect(
        rr.inflate(isSelected ? 6 : 2),
        Paint()
          ..color = color.withValues(alpha: pulseAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    canvas.drawRRect(
      rr,
      Paint()..color = color.withValues(alpha: fillAlpha),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.4 : 1.4
        ..color = color.withValues(alpha: isSelected ? 1.0 : 0.65),
    );

    // Slot label.
    final tp = TextPainter(
      text: TextSpan(
        text: s.label.split('-').last,
        style: TextStyle(
          color: dark ? Colors.white : Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(rect.left + 8, rect.top + 6),
    );

    // Icons (charger / accessibility).
    final iconY = rect.bottom - 18;
    if (s.hasCharger) {
      _drawIconBolt(canvas, Offset(rect.left + 10, iconY), color);
    }
    if (s.disabledAccess) {
      _drawAccessibility(canvas, Offset(rect.right - 16, iconY), color);
    }

    // Occupied car illustration.
    if (s.status == SlotStatus.occupied) {
      _drawParkedCar(canvas, rect, color);
    }
  }

  void _drawIconBolt(Canvas canvas, Offset o, Color c) {
    final p = Paint()..color = c.withValues(alpha: 0.9);
    final path = Path()
      ..moveTo(o.dx + 4, o.dy)
      ..lineTo(o.dx, o.dy + 6)
      ..lineTo(o.dx + 3, o.dy + 6)
      ..lineTo(o.dx + 1, o.dy + 12)
      ..lineTo(o.dx + 8, o.dy + 4)
      ..lineTo(o.dx + 4, o.dy + 4)
      ..close();
    canvas.drawPath(path, p);
  }

  void _drawAccessibility(Canvas canvas, Offset o, Color c) {
    final p = Paint()..color = c.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(o.dx + 4, o.dy + 6), 4, p);
    canvas.drawCircle(Offset(o.dx + 4, o.dy + 6), 1.5,
        Paint()..color = dark ? Colors.black : Colors.white);
  }

  void _drawParkedCar(Canvas canvas, Rect rect, Color c) {
    final body = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.center.dy + 6),
      width: rect.width - 16,
      height: rect.height - 36,
    );
    final rr = RRect.fromRectAndRadius(body, const Radius.circular(8));
    canvas.drawRRect(rr, Paint()..color = c.withValues(alpha: 0.6));
    canvas.drawRRect(
        rr.deflate(4),
        Paint()
          ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.18));
    // Windshield.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(body.left + 6, body.top + 6, body.width - 12, 8),
        const Radius.circular(4),
      ),
      Paint()..color = c.withValues(alpha: 0.9),
    );
  }

  void _drawCar(Canvas canvas, Offset pos, Color color) {
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: pos, width: 40, height: 18),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      r.inflate(3),
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(r, Paint()..color = color);
    // Headlights.
    canvas.drawCircle(Offset(pos.dx + 18, pos.dy), 2,
        Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  void _drawRoute(Canvas canvas, Rect aisle, PFSlot target) {
    final entry = Offset(40, padding + slotH / 2);
    final slotR = _slotRect(target);
    final mid = aisle.center;

    final path = Path()
      ..moveTo(entry.dx, entry.dy)
      ..lineTo(mid.dx - 100, mid.dy)
      ..lineTo(slotR.center.dx, mid.dy)
      ..lineTo(slotR.center.dx, slotR.center.dy);

    final glow = Paint()
      ..color = PFColors.brand.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, glow);

    // Animated dash effect.
    final dash = Paint()
      ..color = PFColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_dashed(path, routeT), dash);
  }

  Path _dashed(Path source, double t) {
    final out = Path();
    final metric = source.computeMetrics().first;
    const dashLen = 14.0;
    const gapLen = 10.0;
    final total = metric.length;
    double d = (t * (dashLen + gapLen)) % (dashLen + gapLen);
    while (d < total) {
      final end = (d + dashLen).clamp(0.0, total);
      out.addPath(metric.extractPath(d, end), Offset.zero);
      d += dashLen + gapLen;
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant ParkingMapPainter old) =>
      old.slots != slots ||
      old.selectedId != selectedId ||
      old.pulse != pulse ||
      old.carT != carT ||
      old.routeT != routeT ||
      old.routeTarget != routeTarget;
}
