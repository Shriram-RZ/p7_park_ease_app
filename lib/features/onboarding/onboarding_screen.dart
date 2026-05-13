import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/router.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/parking_grid_background.dart';
import '../../widgets/radar_pulse.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardData(
      title: 'Find parking instantly',
      subtitle:
          'Discover smart parking with real-time visualization — fully offline.',
      icon: Icons.radar_rounded,
      illustration: _IllustrationKind.radar,
    ),
    _OnboardData(
      title: 'Live slot intelligence',
      subtitle:
          'Animated occupancy across every floor — green for free, red for taken.',
      icon: Icons.grid_view_rounded,
      illustration: _IllustrationKind.slots,
    ),
    _OnboardData(
      title: 'Guided indoor navigation',
      subtitle:
          'Glowing routes lead you to your slot, with floor-aware guidance.',
      icon: Icons.alt_route_rounded,
      illustration: _IllustrationKind.route,
    ),
    _OnboardData(
      title: 'Wallet-style QR tickets',
      subtitle:
          'Issue, store and validate parking passes — no internet required.',
      icon: Icons.qr_code_2_rounded,
      illustration: _IllustrationKind.qr,
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() async {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
    } else {
      final state = AppScope.read(context);
      await state.completeOnboarding();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
    }
  }

  void _skip() async {
    final state = AppScope.read(context);
    await state.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: _skip,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => _OnboardPage(data: _pages[i]),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (i) {
                          final active = i == _page;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? PFColors.brand
                                  : context.scheme.outline,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      PFPrimaryButton(
                        label: _page == _pages.length - 1
                            ? 'Start smart parking'
                            : 'Continue',
                        icon: _page == _pages.length - 1
                            ? Icons.bolt_rounded
                            : Icons.arrow_forward_rounded,
                        onPressed: _next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _IllustrationKind { radar, slots, route, qr }

class _OnboardData {
  const _OnboardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.illustration,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final _IllustrationKind illustration;
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({required this.data});
  final _OnboardData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: _OnboardIllustration(kind: data.illustration),
            ),
          ),
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: PFColors.brand.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(data.icon, color: PFColors.brand),
                    ),
                    const SizedBox(width: 12),
                    const GlowChip(
                      label: 'OFFLINE FIRST',
                      icon: Icons.cloud_off_rounded,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  data.title,
                  style: context.text.displayMedium?.copyWith(
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.subtitle,
                  style: context.text.bodyLarge?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OnboardIllustration extends StatelessWidget {
  const _OnboardIllustration({required this.kind});
  final _IllustrationKind kind;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case _IllustrationKind.radar:
        return const RadarPulse(
          size: 260,
          color: PFColors.brand,
          child: Icon(Icons.local_parking_rounded,
              size: 60, color: PFColors.brand),
        );
      case _IllustrationKind.slots:
        return SizedBox(
          width: 280,
          height: 280,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 25,
            itemBuilder: (_, i) {
              final rng = Random(i);
              final v = rng.nextDouble();
              Color c;
              if (v < 0.45) {
                c = PFColors.brand;
              } else if (v < 0.85) {
                c = PFColors.danger;
              } else {
                c = PFColors.info;
              }
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + i * 30),
                curve: Curves.easeOutBack,
                builder: (_, t, child) => Transform.scale(
                  scale: 0.6 + t * 0.4,
                  child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: c.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: c.withValues(alpha: 0.25),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      case _IllustrationKind.route:
        return CustomPaint(
          size: const Size(280, 240),
          painter: _RoutePainter(),
        );
      case _IllustrationKind.qr:
        return SizedBox(
          width: 240,
          height: 240,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 9,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
              ),
              itemCount: 81,
              itemBuilder: (_, i) {
                final on = Random(i).nextBool();
                return Container(
                  decoration: BoxDecoration(
                    color: on ? PFColors.brand : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ),
        );
    }
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = PFColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final glow = Paint()
      ..color = PFColors.brand.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path()
      ..moveTo(20, size.height - 20)
      ..lineTo(60, size.height - 80)
      ..quadraticBezierTo(120, size.height - 90, 140, size.height - 140)
      ..lineTo(180, size.height - 140)
      ..quadraticBezierTo(220, size.height - 140, 240, size.height - 200)
      ..lineTo(size.width - 30, 30);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, p);

    // Start dot.
    canvas.drawCircle(const Offset(20, 220), 8,
        Paint()..color = PFColors.brand.withValues(alpha: 0.4));
    canvas.drawCircle(
        const Offset(20, 220), 4, Paint()..color = PFColors.brand);

    // Destination pin.
    final dest = Offset(size.width - 30, 30);
    canvas.drawCircle(
        dest, 12, Paint()..color = PFColors.brand.withValues(alpha: 0.35));
    canvas.drawCircle(dest, 6, Paint()..color = PFColors.brand);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
