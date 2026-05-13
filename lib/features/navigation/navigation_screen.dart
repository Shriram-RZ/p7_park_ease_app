import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../data/models/parking_slot.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/parking_grid_background.dart';
import '../../widgets/radar_pulse.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key, this.slot});
  final PFSlot? slot;

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _routeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..forward();
  late final AnimationController _walker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();
  bool _arrived = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _arrived = true);
    });
  }

  @override
  void dispose() {
    _routeCtrl.dispose();
    _walker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final slot = widget.slot ??
        () {
          final active = state.bookings.activeBooking();
          if (active != null) return state.parking.byId(active.slotId);
          return null;
        }();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Indoor navigation'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 0.6)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: PFColors.brand.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.alt_route_rounded,
                              color: PFColors.brand),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slot != null
                                    ? 'Heading to ${slot.label}'
                                    : 'No active route',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800),
                              ),
                              Text(
                                slot != null
                                    ? 'Floor F${slot.floor} • approx. ${slot.walkingDistance}m'
                                    : 'Reserve a slot to enable navigation.',
                                style: context.text.bodySmall?.copyWith(
                                    color: context.scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_routeCtrl, _walker]),
                        builder: (_, _) => CustomPaint(
                          painter: _NavMapPainter(
                            t: _routeCtrl.value,
                            walker: _walker.value,
                            dark: context.isDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_arrived)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: GlassCard(
                      glow: PFColors.brand,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const RadarPulse(
                              size: 120,
                              color: PFColors.brand,
                              child: Icon(Icons.flag_rounded,
                                  color: PFColors.brand, size: 38)),
                          const SizedBox(height: 12),
                          const Text('Arrived at destination',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            'Tap check-in when you have parked.',
                            style: context.text.bodySmall?.copyWith(
                              color: context.scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          PFPrimaryButton(
                            label: 'Check in',
                            icon: Icons.check_circle_rounded,
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavMapPainter extends CustomPainter {
  _NavMapPainter(
      {required this.t, required this.walker, required this.dark});
  final double t;
  final double walker;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? const [Color(0xFF071614), Color(0xFF03100D)]
            : const [Color(0xFFEFF5F1), Color(0xFFF7FAF8)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(16)),
      bg,
    );

    // Floor outline.
    final outline = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final outlineRect = Rect.fromLTWH(20, 20, size.width - 40, size.height - 40);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outlineRect, const Radius.circular(20)),
      outline,
    );

    // Pillars (decorative blocks).
    final rng = Random(2);
    final pillarP = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.06);
    for (int i = 0; i < 8; i++) {
      final w = 24.0 + rng.nextInt(20);
      final h = 24.0 + rng.nextInt(20);
      final x = outlineRect.left + 10 +
          rng.nextDouble() * (outlineRect.width - w - 20);
      final y = outlineRect.top + 10 +
          rng.nextDouble() * (outlineRect.height - h - 20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h), const Radius.circular(6)),
        pillarP,
      );
    }

    // Build a route: entry (bottom-left) → corner → destination (top-right).
    final start = Offset(outlineRect.left + 20, outlineRect.bottom - 20);
    final mid1 = Offset(outlineRect.left + outlineRect.width * 0.35,
        outlineRect.bottom - 20);
    final mid2 = Offset(outlineRect.left + outlineRect.width * 0.35,
        outlineRect.top + outlineRect.height * 0.45);
    final mid3 = Offset(outlineRect.right - outlineRect.width * 0.28,
        outlineRect.top + outlineRect.height * 0.45);
    final dest = Offset(outlineRect.right - 30, outlineRect.top + 40);

    final fullPath = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(mid1.dx, mid1.dy)
      ..lineTo(mid2.dx, mid2.dy)
      ..lineTo(mid3.dx, mid3.dy)
      ..lineTo(dest.dx, dest.dy);

    final metric = fullPath.computeMetrics().first;
    final visiblePath =
        metric.extractPath(0, metric.length * t.clamp(0.0, 1.0));

    final glow = Paint()
      ..color = PFColors.brand.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(visiblePath, glow);
    final line = Paint()
      ..color = PFColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(visiblePath, line);

    // Animated beacon along visible path.
    final beaconPos = metric.getTangentForOffset(
        metric.length * (t.clamp(0.0, 1.0)) * 0.95);
    if (beaconPos != null) {
      canvas.drawCircle(beaconPos.position, 16,
          Paint()..color = PFColors.brand.withValues(alpha: 0.35));
      canvas.drawCircle(beaconPos.position, 7,
          Paint()..color = PFColors.brand);
    }

    // Walker dot oscillating along the start segment for liveliness.
    final walkP = metric.getTangentForOffset(metric.length *
        (walker * 0.7).clamp(0.0, t.clamp(0.0, 1.0)));
    if (walkP != null) {
      canvas.drawCircle(walkP.position, 5, Paint()..color = Colors.white);
    }

    // Entry pad.
    _drawPad(canvas, start, label: 'YOU', color: PFColors.info);
    // Destination flag.
    _drawDestination(canvas, dest);
  }

  void _drawPad(Canvas canvas, Offset pos,
      {required String label, required Color color}) {
    final rect = Rect.fromCenter(center: pos, width: 56, height: 28);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()..color = color.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
  }

  void _drawDestination(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 18,
        Paint()..color = PFColors.brand.withValues(alpha: 0.25));
    canvas.drawCircle(pos, 9, Paint()..color = PFColors.brand);
    canvas.drawCircle(pos, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _NavMapPainter old) =>
      old.t != t || old.walker != walker;
}
