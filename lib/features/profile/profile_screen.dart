import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/router.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/parking_grid_background.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser;
    final vehicles = state.vehicles.all();
    final bookings = state.bookings.all();
    return Stack(
      children: [
        const Positioned.fill(child: ParkingGridBackground(intensity: 0.55)),
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(22),
                  glow: PFColors.brand,
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            PFColors.brand,
                            PFColors.brandGlow,
                          ]),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user?.initials ?? 'P',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? 'Guest driver',
                                style: context.text.headlineMedium),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'no-email@local',
                              style: context.text.bodyMedium?.copyWith(
                                color: context.scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _StatMini(
                        label: 'Vehicles',
                        value: '${vehicles.length}',
                        icon: Icons.directions_car_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatMini(
                        label: 'Sessions',
                        value: '${bookings.length}',
                        icon: Icons.event_available_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatMini(
                        label: 'Tickets',
                        value: '${state.tickets.all().length}',
                        icon: Icons.confirmation_number_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GlassCard(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _NavTile(
                        icon: Icons.directions_car_rounded,
                        label: 'Garage',
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.vehicles),
                      ),
                      _NavTile(
                        icon: Icons.history_rounded,
                        label: 'Parking history',
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.history),
                      ),
                      _NavTile(
                        icon: Icons.notifications_rounded,
                        label: 'Notifications',
                        badge: state.notifications.unreadCount(),
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.notifications),
                      ),
                      _NavTile(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.settings),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PFColors.brand, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4)),
          Text(label,
              style: context.text.bodySmall?.copyWith(
                color: context.scheme.onSurfaceVariant,
              )),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: PFColors.brand.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: PFColors.brand, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            if (badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PFColors.danger,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            Icon(Icons.chevron_right_rounded,
                color: context.scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
