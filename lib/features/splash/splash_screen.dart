import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/router.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../widgets/animated_logo.dart';
import '../../widgets/parking_grid_background.dart';
import '../../widgets/radar_pulse.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2800), _route);
  }

  void _route() {
    if (!mounted) return;
    final state = AppScope.read(context);
    String next;
    if (!state.onboardingComplete) {
      next = AppRoutes.onboarding;
    } else if (state.currentUser == null) {
      next = AppRoutes.login;
    } else {
      next = AppRoutes.mainShell;
    }
    Navigator.of(context).pushReplacementNamed(next);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 1.2)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, child) {
                    final s = Curves.easeOutBack.transform(
                      _ctrl.value.clamp(0.0, 1.0),
                    );
                    return Opacity(
                      opacity: _ctrl.value.clamp(0.0, 1.0),
                      child: Transform.scale(scale: s, child: child),
                    );
                  },
                  child: const RadarPulse(
                    size: 220,
                    color: PFColors.brand,
                    child: AnimatedLogo(size: 96),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _ctrl,
                    curve: const Interval(0.4, 1.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'ParkFlow',
                        style: context.text.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Smart offline parking ecosystem',
                        style: context.text.bodyMedium?.copyWith(
                          color: context.scheme.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 36,
            child: Center(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, _) => Opacity(
                  opacity: (_ctrl.value * 1.4 - 0.4).clamp(0.0, 1.0),
                  child: Text(
                    'Offline · Realtime · Premium',
                    style: TextStyle(
                      letterSpacing: 6,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
