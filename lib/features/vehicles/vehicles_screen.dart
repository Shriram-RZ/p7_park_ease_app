import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/router.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../data/models/vehicle.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/parking_grid_background.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final vehicles = state.vehicles.all();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Garage'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 0.6)),
          SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              itemCount: vehicles.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (i == vehicles.length) {
                  return PFPrimaryButton(
                    label: 'Add new vehicle',
                    icon: Icons.add_rounded,
                    onPressed: () => Navigator.of(context)
                        .pushNamed(AppRoutes.addVehicle),
                  );
                }
                final v = vehicles[i];
                return _VehicleHero(
                  vehicle: v,
                  active: state.vehicles.activeVehicleId() == v.id,
                  onSelect: () => state.setActiveVehicle(v.id),
                  onDelete: () => _confirmDelete(context, state, v),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState state, PFVehicle v) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove ${v.name}?'),
        content:
            const Text('This will not affect any past bookings or tickets.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (result == true) {
      await state.removeVehicle(v.id);
    }
  }
}

class _VehicleHero extends StatelessWidget {
  const _VehicleHero({
    required this.vehicle,
    required this.active,
    required this.onSelect,
    required this.onDelete,
  });
  final PFVehicle vehicle;
  final bool active;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              vehicle.color.withValues(alpha: 0.5),
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
                    color: PFColors.brand.withValues(alpha: 0.45),
                    blurRadius: 30,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(vehicle.type.icon, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Text(
                  vehicle.type.label.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1),
                ),
                const Spacer(),
                if (active)
                  const GlowChip(
                    label: 'ACTIVE',
                    icon: Icons.bolt_rounded,
                    dense: true,
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              vehicle.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6),
            ),
            const SizedBox(height: 4),
            Text(
              vehicle.plate,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4),
            ),
            if (vehicle.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(vehicle.notes,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75))),
            ],
          ],
        ),
      ),
    );
  }
}
