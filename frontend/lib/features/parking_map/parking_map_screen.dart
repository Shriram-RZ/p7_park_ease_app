import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../app/router.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../data/models/parking_slot.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/parking_grid_background.dart';
import 'parking_map_painter.dart';

class ParkingMapScreen extends StatefulWidget {
  const ParkingMapScreen({super.key});

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen>
    with TickerProviderStateMixin {
  int _floor = 1;
  String? _selectedId;
  final TransformationController _transformCtrl = TransformationController();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  late final AnimationController _carT = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();
  late final AnimationController _routeT = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    _carT.dispose();
    _routeT.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  void _showSlotSheet(PFSlot slot) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SlotSheet(
        slot: slot,
        onReserve: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pushNamed(
            AppRoutes.bookingFlow,
            arguments: slot,
          );
        },
        onNavigate: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pushNamed(
            AppRoutes.navigation,
            arguments: slot,
          );
        },
        onFavorite: () {
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved ${slot.label} to favorites')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final slots = state.parking.byFloor(_floor);
    final stats = state.parking.stats()[_floor]!;
    final size = ParkingMapPainter.canvasSize();
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: const Text('Parking map'),
        actions: [
          IconButton(
            onPressed: () => state.setSimulationPeakMode(
                !state.simulation.peakMode),
            tooltip: 'Toggle peak simulation',
            icon: Icon(
              state.simulation.peakMode
                  ? Icons.local_fire_department_rounded
                  : Icons.bolt_rounded,
              color: state.simulation.peakMode
                  ? PFColors.danger
                  : PFColors.brand,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 0.6, animated: false)),
          SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                _FloorBar(
                  selected: _floor,
                  onSelect: (f) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _floor = f;
                      _selectedId = null;
                    });
                  },
                  stats: stats,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: GlassCard(
                      padding: const EdgeInsets.all(8),
                      child: ListenableBuilder(
                        listenable: state,
                        builder: (_, _) => InteractiveViewer(
                          transformationController: _transformCtrl,
                          minScale: 0.5,
                          maxScale: 3.0,
                          boundaryMargin: const EdgeInsets.all(80),
                          child: AnimatedBuilder(
                            animation: Listenable.merge(
                                [_pulse, _carT, _routeT]),
                            builder: (_, _) => GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (d) {
                                final painter = ParkingMapPainter(
                                  slots: slots,
                                  selectedId: _selectedId,
                                  pulse: _pulse.value,
                                  carT: _carT.value,
                                  routeT: _routeT.value,
                                  dark: context.isDark,
                                  routeTarget: _selectedId,
                                );
                                final hit = painter.slotAt(d.localPosition);
                                if (hit != null) {
                                  setState(() => _selectedId = hit.id);
                                  _showSlotSheet(hit);
                                }
                              },
                              child: SizedBox(
                                width: size.width,
                                height: size.height,
                                child: CustomPaint(
                                  painter: ParkingMapPainter(
                                    slots: slots,
                                    selectedId: _selectedId,
                                    pulse: _pulse.value,
                                    carT: _carT.value,
                                    routeT: _routeT.value,
                                    dark: context.isDark,
                                    routeTarget: _selectedId,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                  child: Row(
                    children: const [
                      _LegendDot(color: PFColors.brand, label: 'Free'),
                      SizedBox(width: 14),
                      _LegendDot(color: PFColors.danger, label: 'Taken'),
                      SizedBox(width: 14),
                      _LegendDot(color: PFColors.info, label: 'Reserved'),
                      Spacer(),
                      _LegendDot(
                          color: PFColors.slotDisabled, label: 'Disabled'),
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

class _FloorBar extends StatelessWidget {
  const _FloorBar({
    required this.selected,
    required this.onSelect,
    required this.stats,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final ({int total, int free, int taken, int reserved}) stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            for (int i = 1; i <= PFConstants.floorsCount; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _FloorChip(
                  label: 'F$i',
                  active: i == selected,
                  onTap: () => onSelect(i),
                ),
              ),
            const Spacer(),
            const Icon(Icons.local_parking_rounded,
                color: PFColors.brand, size: 18),
            const SizedBox(width: 4),
            Text(
              '${stats.free}/${stats.total}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorChip extends StatelessWidget {
  const _FloorChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? PFColors.brand.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: active
                  ? PFColors.brand
                  : context.scheme.outline.withValues(alpha: 0.5)),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: PFColors.brand.withValues(alpha: 0.4),
                    blurRadius: 14,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
              color: active ? PFColors.brand : context.scheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.scheme.onSurfaceVariant)),
      ],
    );
  }
}

class _SlotSheet extends StatelessWidget {
  const _SlotSheet({
    required this.slot,
    required this.onReserve,
    required this.onNavigate,
    required this.onFavorite,
  });

  final PFSlot slot;
  final VoidCallback onReserve;
  final VoidCallback onNavigate;
  final VoidCallback onFavorite;

  Color get _statusColor => switch (slot.status) {
        SlotStatus.available => PFColors.brand,
        SlotStatus.occupied => PFColors.danger,
        SlotStatus.reserved => PFColors.info,
        SlotStatus.selected => PFColors.slotSelected,
        SlotStatus.disabled => PFColors.slotDisabled,
      };

  String get _statusLabel => switch (slot.status) {
        SlotStatus.available => 'Available now',
        SlotStatus.occupied => 'Currently occupied',
        SlotStatus.reserved => 'Reserved',
        SlotStatus.selected => 'Selected',
        SlotStatus.disabled => 'Accessibility only',
      };

  @override
  Widget build(BuildContext context) {
    final available = slot.status == SlotStatus.available;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.scheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GlowChip(
                      label: _statusLabel.toUpperCase(),
                      icon: Icons.circle,
                      color: _statusColor,
                      dense: true,
                    ),
                    const Spacer(),
                    if (slot.hasCharger)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: GlowChip(
                            label: 'EV', icon: Icons.bolt_rounded, dense: true),
                      ),
                    if (slot.disabledAccess)
                      const GlowChip(
                          label: 'A11Y',
                          icon: Icons.accessible_rounded,
                          color: PFColors.info,
                          dense: true),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Slot ${slot.label}',
                  style: context.text.displayMedium?.copyWith(height: 1),
                ),
                Text(
                  'Level F${slot.floor} • ${slot.walkingDistance}m to elevator',
                  style: context.text.bodyMedium?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _StatColumn(
                      label: 'Score',
                      value: '${(slot.score * 100).round()}%',
                    ),
                    _StatColumn(
                      label: 'Size',
                      value: slot.size.name,
                    ),
                    _StatColumn(
                      label: 'Walk',
                      value: '${slot.walkingDistance}m',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (available)
                  PFPrimaryButton(
                    label: 'Reserve now',
                    icon: Icons.event_available_rounded,
                    onPressed: onReserve,
                  )
                else
                  PFPrimaryButton(
                    label: 'Slot unavailable',
                    icon: Icons.block_rounded,
                    onPressed: null,
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: PFSecondaryButton(
                        label: 'Navigate',
                        icon: Icons.alt_route_rounded,
                        onPressed: onNavigate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PFSecondaryButton(
                        label: 'Favorite',
                        icon: Icons.bookmark_rounded,
                        onPressed: onFavorite,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.scheme.outline.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: context.scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
