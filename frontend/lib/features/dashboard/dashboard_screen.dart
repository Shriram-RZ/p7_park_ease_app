import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_state.dart';
import '../../app/router.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../data/models/booking.dart';
import '../../data/models/vehicle.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/charts.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/parking_grid_background.dart';
import '../../widgets/section_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Driving late';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser;
    final active = state.bookings.activeBooking();
    final stats = state.parking.totalStats();
    final vehicles = state.vehicles.all();
    final activeVehicle = state.vehicles.activeVehicle();
    final occupancy = stats.total == 0
        ? 0.0
        : (stats.taken + stats.reserved) / stats.total;

    return Stack(
      children: [
        const Positioned.fill(child: ParkingGridBackground(intensity: 0.6, animated: false)),
        SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdjuster(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _Avatar(label: user?.initials ?? 'P'),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: context.text.bodyMedium?.copyWith(
                                color: context.scheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              user?.name ?? 'Driver',
                              style: context.text.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _IconBadgeButton(
                        icon: Icons.notifications_rounded,
                        badgeCount: state.notifications.unreadCount(),
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.notifications),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: _ActiveStatusCard(
                    active: active,
                    vehicle: activeVehicle,
                    occupancy: occupancy,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: _QuickActionsGrid(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Live parking overview',
                    subtitle:
                        'Smart simulation across ${PFConstants.floorsCount} floors',
                    action: TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRoutes.parkingMap),
                      child: const Text('Open map'),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: _LiveOverviewCard(
                    free: stats.free,
                    taken: stats.taken,
                    reserved: stats.reserved,
                    total: stats.total,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Your garage',
                    action: TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRoutes.vehicles),
                      child: const Text('Manage'),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (_, i) {
                      if (i == vehicles.length) {
                        return _AddVehicleCard(onTap: () =>
                            Navigator.of(context)
                                .pushNamed(AppRoutes.addVehicle));
                      }
                      final v = vehicles[i];
                      return _VehicleMiniCard(
                        vehicle: v,
                        active: state.vehicles.activeVehicleId() == v.id,
                        onTap: () => state.setActiveVehicle(v.id),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemCount: vehicles.length + 1,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Recent activity',
                    action: TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRoutes.history),
                      child: const Text('All history'),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                sliver: SliverList.separated(
                  itemCount: min(3, state.bookings.all().length),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final b = state.bookings.all()[i];
                    return _HistoryRow(booking: b);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SliverToBoxAdjuster extends StatelessWidget {
  const SliverToBoxAdjuster({super.key});
  @override
  Widget build(BuildContext context) =>
      const SliverToBoxAdapter(child: SizedBox(height: 8));
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PFColors.brand, PFColors.brandGlow],
        ),
        boxShadow: [
          BoxShadow(
            color: PFColors.brand.withValues(alpha: 0.4),
            blurRadius: 16,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16),
      ),
    );
  }
}

class _IconBadgeButton extends StatelessWidget {
  const _IconBadgeButton({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
  });
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: Icon(icon, color: scheme.onSurface, size: 22)),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: PFColors.danger,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveStatusCard extends StatelessWidget {
  const _ActiveStatusCard({
    required this.active,
    required this.vehicle,
    required this.occupancy,
  });
  final PFBooking? active;
  final PFVehicle? vehicle;
  final double occupancy;

  @override
  Widget build(BuildContext context) {
    if (active == null) {
      return GlassCard(
        glow: PFColors.brand,
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: PFColors.brand.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.local_parking_rounded,
                  color: PFColors.brand, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No active booking',
                      style: context.text.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    'Reserve a slot from the parking map.',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: PFColors.brand),
          ],
        ),
      );
    }
    return _ActiveBookingPulseCard(booking: active!, occupancy: occupancy);
  }
}

class _ActiveBookingPulseCard extends StatefulWidget {
  const _ActiveBookingPulseCard(
      {required this.booking, required this.occupancy});
  final PFBooking booking;
  final double occupancy;

  @override
  State<_ActiveBookingPulseCard> createState() =>
      _ActiveBookingPulseCardState();
}

class _ActiveBookingPulseCardState extends State<_ActiveBookingPulseCard> {
  late final Stream<DateTime> _tick = Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _tick,
      builder: (_, snap) {
        final now = snap.data ?? DateTime.now();
        final remaining = widget.booking.remaining(now);
        final total = widget.booking.duration.inSeconds.toDouble();
        final progress = total == 0
            ? 0.0
            : (1 - remaining.inSeconds / total).clamp(0.0, 1.0);
        return GlassCard(
          glow: PFColors.brand,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: PFDonutChart(
                  value: progress,
                  size: 96,
                  thickness: 9,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        remaining.clockLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'left',
                        style: context.text.bodySmall?.copyWith(
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GlowChip(
                      label: 'ACTIVE PARKING',
                      icon: Icons.bolt_rounded,
                      dense: true,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Slot ${widget.booking.slotLabel}',
                      style: context.text.headlineMedium
                          ?.copyWith(height: 1.05),
                    ),
                    Text(
                      'Level F${widget.booking.floor} • ${widget.booking.vehiclePlate}',
                      style: context.text.bodyMedium?.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction('Find', Icons.search_rounded, AppRoutes.parkingMap),
      _QuickAction('Scan', Icons.qr_code_scanner_rounded, AppRoutes.scanner),
      _QuickAction('Vehicles', Icons.directions_car_rounded, AppRoutes.vehicles),
      _QuickAction('History', Icons.history_rounded, AppRoutes.history),
      _QuickAction('Navigate', Icons.alt_route_rounded, AppRoutes.navigation),
      _QuickAction(
          'Insights', Icons.insights_rounded, AppRoutes.analytics),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (_, i) => _QuickActionCard(action: actions[i]),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({required this.action});
  final _QuickAction action;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    lowerBound: 0.94,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.animateTo(0.94, curve: Curves.easeOut),
      onTapUp: (_) {
        _c.animateTo(1.0, curve: Curves.elasticOut);
        Navigator.of(context).pushNamed(widget.action.route);
      },
      onTapCancel: () => _c.animateTo(1.0),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) =>
            Transform.scale(scale: _c.value, child: child),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: PFColors.brand.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.action.icon,
                    color: PFColors.brand, size: 20),
              ),
              Text(
                widget.action.label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveOverviewCard extends StatelessWidget {
  const _LiveOverviewCard({
    required this.free,
    required this.taken,
    required this.reserved,
    required this.total,
  });

  final int free;
  final int taken;
  final int reserved;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : free / total;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          PFDonutChart(
            value: progress,
            size: 120,
            thickness: 12,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedCounter(
                  value: free,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text('free',
                    style: context.text.bodySmall?.copyWith(
                        color: context.scheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Across all floors',
                    style: context.text.bodySmall?.copyWith(
                        color: context.scheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text('$total slots',
                    style: context.text.titleLarge
                        ?.copyWith(letterSpacing: -0.4)),
                const SizedBox(height: 14),
                _Legend(color: PFColors.brand, label: 'Available', value: free),
                const SizedBox(height: 6),
                _Legend(
                    color: PFColors.danger, label: 'Occupied', value: taken),
                const SizedBox(height: 6),
                _Legend(
                    color: PFColors.info,
                    label: 'Reserved',
                    value: reserved),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(
      {required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: context.text.bodyMedium?.copyWith(
              color: context.scheme.onSurfaceVariant,
            )),
        const Spacer(),
        Text('$value',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _VehicleMiniCard extends StatelessWidget {
  const _VehicleMiniCard({
    required this.vehicle,
    required this.active,
    required this.onTap,
  });

  final PFVehicle vehicle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              vehicle.color.withValues(alpha: 0.45),
              vehicle.color.withValues(alpha: 0.18),
            ],
          ),
          border: Border.all(
            color: active
                ? PFColors.brand
                : Colors.white.withValues(alpha: 0.08),
            width: active ? 1.5 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: PFColors.brand.withValues(alpha: 0.4),
                    blurRadius: 24,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(vehicle.type.icon, color: Colors.white),
                const SizedBox(width: 8),
                Text(vehicle.type.label.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const Spacer(),
                if (active)
                  const GlowChip(
                    label: 'ACTIVE',
                    icon: Icons.flash_on_rounded,
                    dense: true,
                  ),
              ],
            ),
            const Spacer(),
            Text(vehicle.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            Text(vehicle.plate,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AddVehicleCard extends StatelessWidget {
  const _AddVehicleCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedAddCard(
        width: 160,
        label: 'Add vehicle',
        icon: Icons.add_rounded,
      ),
    );
  }
}

class DottedAddCard extends StatelessWidget {
  const DottedAddCard({
    super.key,
    required this.width,
    required this.label,
    required this.icon,
  });
  final double width;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: dark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        border: Border.all(
          color: PFColors.brand.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: PFColors.brand.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: PFColors.brand),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: PFColors.brand,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.booking});
  final PFBooking booking;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d • HH:mm');
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PFColors.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_parking_rounded,
                color: PFColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.slotLabel,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                Text(
                  '${df.format(booking.startTime)} • ${booking.duration.humanLabel}',
                  style: context.text.bodySmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text('${PFConstants.currencySymbol}${(booking.feeCents / 100).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
