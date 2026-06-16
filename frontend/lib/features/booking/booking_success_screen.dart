import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/router.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../data/models/booking.dart';
import '../../data/models/ticket.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/parking_grid_background.dart';

class BookingSuccessScreen extends StatefulWidget {
  const BookingSuccessScreen({
    super.key,
    required this.booking,
    required this.ticket,
  });

  final PFBooking booking;
  final PFTicket ticket;

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _particles = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _entry.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive QR: scales with screen width, clamped for tiny/large devices.
    final double qrSize =
        (MediaQuery.sizeOf(context).width * 0.26).clamp(84.0, 120.0).toDouble();
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 1.1)),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _particles,
                builder: (_, _) => CustomPaint(
                  painter: _ConfettiPainter(t: _particles.value),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil(
                                AppRoutes.mainShell, (r) => false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _entry,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [PFColors.brand, PFColors.brandGlow],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: PFColors.brand.withValues(alpha: 0.6),
                            blurRadius: 48,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 56),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _entry,
                      curve: const Interval(0.4, 1),
                    ),
                    child: Column(
                      children: [
                        Text('Reservation confirmed',
                            style: context.text.displayMedium
                                ?.copyWith(height: 1.05)),
                        const SizedBox(height: 6),
                        Text(
                          'Slot ${widget.booking.slotLabel} is yours on Level F${widget.booking.floor}.',
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium?.copyWith(
                            color: context.scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _entry,
                      curve: const Interval(0.5, 1),
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      glow: PFColors.brand,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: widget.ticket.qrPayload,
                              size: qrSize,
                              version: QrVersions.auto,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF0F172A),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.ticket.id,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.booking.slotLabel} • ${widget.booking.vehiclePlate}',
                                  style: context.text.bodyMedium?.copyWith(
                                    color: context.scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const GlowChip(
                                  label: 'OFFLINE TICKET',
                                  icon: Icons.shield_rounded,
                                  dense: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  PFPrimaryButton(
                    label: 'Start navigation',
                    icon: Icons.alt_route_rounded,
                    onPressed: () {
                      Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.navigation);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: PFSecondaryButton(
                          label: 'View ticket',
                          icon: Icons.confirmation_number_rounded,
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed(AppRoutes.mainShell),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PFSecondaryButton(
                          label: 'Home',
                          icon: Icons.home_rounded,
                          onPressed: () => Navigator.of(context)
                              .pushNamedAndRemoveUntil(
                                  AppRoutes.mainShell, (r) => false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);
    for (int i = 0; i < 60; i++) {
      final ang = rng.nextDouble() * 2 * pi;
      final speed = 80 + rng.nextDouble() * 240;
      final cx = size.width / 2 + cos(ang) * speed * t;
      final cy = size.height / 2.4 + sin(ang) * speed * t;
      final c = [
        PFColors.brand,
        PFColors.brandGlow,
        PFColors.info,
        Colors.white,
      ][rng.nextInt(4)];
      canvas.drawCircle(
        Offset(cx, cy),
        4 * (1 - t).clamp(0.0, 1.0),
        Paint()..color = c.withValues(alpha: 0.85 * (1 - t).clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
