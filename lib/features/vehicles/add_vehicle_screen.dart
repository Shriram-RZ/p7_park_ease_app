import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../data/models/vehicle.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/parking_grid_background.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: '');
  final _plate = TextEditingController(text: '');
  final _notes = TextEditingController(text: '');
  VehicleType _type = VehicleType.car;
  int _colorValue = 0xFF22C55E;
  bool _busy = false;

  static const _palette = [
    0xFF22C55E,
    0xFF0EA5E9,
    0xFFF59E0B,
    0xFFEF4444,
    0xFF8B5CF6,
    0xFF14B8A6,
    0xFFEC4899,
    0xFF111827,
  ];

  @override
  void dispose() {
    _name.dispose();
    _plate.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final state = AppScope.read(context);
    await state.addVehicle(PFVehicle(
      id: 'v_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      name: _name.text.trim(),
      plate: _plate.text.trim(),
      type: _type,
      colorValue: _colorValue,
      notes: _notes.text.trim(),
    ));
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Add vehicle'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 0.6)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LivePreview(
                      name: _name.text.isEmpty ? 'New vehicle' : _name.text,
                      plate: _plate.text.isEmpty ? 'PF · 0000' : _plate.text,
                      type: _type,
                      color: Color(_colorValue),
                    ),
                    const SizedBox(height: 18),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle name',
                              prefixIcon: Icon(Icons.badge_rounded),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Enter a name'
                                    : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _plate,
                            decoration: const InputDecoration(
                              labelText: 'Plate number',
                              prefixIcon: Icon(Icons.confirmation_number_rounded),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Enter a plate'
                                    : null,
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notes,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              prefixIcon: Icon(Icons.notes_rounded),
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type', style: context.text.titleMedium),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: VehicleType.values.map((t) {
                              final active = _type == t;
                              return GestureDetector(
                                onTap: () => setState(() => _type = t),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? PFColors.brand.withValues(alpha: 0.18)
                                        : context.scheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(99),
                                    border: Border.all(
                                      color: active
                                          ? PFColors.brand
                                          : context.scheme.outline
                                              .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(t.icon,
                                          size: 16,
                                          color: active
                                              ? PFColors.brand
                                              : context.scheme.onSurface),
                                      const SizedBox(width: 6),
                                      Text(
                                        t.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: active
                                              ? PFColors.brand
                                              : context.scheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paint color',
                              style: context.text.titleMedium),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _palette.map((c) {
                              final active = c == _colorValue;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _colorValue = c),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Color(c),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: active
                                          ? PFColors.brand
                                          : Colors.white.withValues(alpha: 0.15),
                                      width: active ? 3 : 1,
                                    ),
                                    boxShadow: active
                                        ? [
                                            BoxShadow(
                                              color: Color(c).withValues(
                                                  alpha: 0.5),
                                              blurRadius: 14,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: active
                                      ? const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 18)
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    PFPrimaryButton(
                      label: 'Save vehicle',
                      icon: Icons.save_rounded,
                      loading: _busy,
                      onPressed: _busy ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({
    required this.name,
    required this.plate,
    required this.type,
    required this.color,
  });
  final String name;
  final String plate;
  final VehicleType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.6),
            color.withValues(alpha: 0.18),
          ],
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(type.icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(type.label.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      fontSize: 12)),
            ],
          ),
          const Spacer(),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          Text(plate,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
