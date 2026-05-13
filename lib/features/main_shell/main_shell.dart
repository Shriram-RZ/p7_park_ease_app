import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../analytics/analytics_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../parking_map/parking_map_screen.dart';
import '../tickets/tickets_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1.0,
  );

  static const _tabs = [
    _TabSpec('Home', Icons.dashboard_rounded),
    _TabSpec('Map', Icons.map_rounded),
    _TabSpec('Tickets', Icons.confirmation_number_rounded),
    _TabSpec('Insights', Icons.insights_rounded),
    _TabSpec('Profile', Icons.person_rounded),
  ];

  Widget _bodyFor(int i) {
    switch (i) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const ParkingMapScreen();
      case 2:
        return const TicketsScreen();
      case 3:
        return const AnalyticsScreen();
      case 4:
        return const ProfileScreen();
    }
    return const DashboardScreen();
  }

  void _go(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: ListenableBuilder(
        listenable: AppScope.of(context),
        builder: (_, _) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: _bodyFor(_index),
          ),
        ),
      ),
      bottomNavigationBar: _FloatingNavBar(
        index: _index,
        tabs: _tabs,
        onTap: _go,
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.index,
    required this.tabs,
    required this.onTap,
  });

  final int index;
  final List<_TabSpec> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xFF0B1614).withValues(alpha: 0.78)
                    : Colors.white.withValues(alpha: 0.78),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: PFColors.brand.withValues(alpha: 0.18),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: LayoutBuilder(builder: (context, c) {
                final w = c.maxWidth / tabs.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      left: w * index + 10,
                      top: 10,
                      bottom: 10,
                      width: w - 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: PFColors.brand.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  PFColors.brand.withValues(alpha: 0.45)),
                          boxShadow: [
                            BoxShadow(
                              color: PFColors.brand.withValues(alpha: 0.35),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (int i = 0; i < tabs.length; i++)
                          Expanded(
                            child: InkResponse(
                              onTap: () => onTap(i),
                              radius: 36,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    tabs[i].icon,
                                    color: i == index
                                        ? PFColors.brand
                                        : context.scheme.onSurfaceVariant,
                                    size: 22,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tabs[i].label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: i == index
                                          ? PFColors.brand
                                          : context.scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
