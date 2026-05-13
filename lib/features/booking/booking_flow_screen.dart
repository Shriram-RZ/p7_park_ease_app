import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../app/router.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../data/models/parking_slot.dart';
import '../../data/models/vehicle.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/parking_grid_background.dart';

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key, required this.slot});
  final PFSlot slot;

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int _step = 0;
  Duration _duration = const Duration(hours: 1);
  PFVehicle? _vehicle;
  bool _busy = false;

  static const List<Duration> _options = [
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
    Duration(hours: 8),
  ];

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    _vehicle = state.vehicles.activeVehicle();
  }

  double get _feeDollars =>
      PFConstants.feePerHour * (_duration.inMinutes / 60.0);

  Future<void> _confirm() async {
    if (_vehicle == null) return;
    setState(() => _busy = true);
    final state = AppScope.read(context);
    final result = await state.reserveSlot(
      slot: widget.slot,
      vehicle: _vehicle!,
      duration: _duration,
    );
    setState(() => _busy = false);
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.bookingSuccess,
      arguments: result,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('Reserve ${widget.slot.label}'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 0.6)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: _StepperHeader(step: _step),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStep(state),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Row(
                    children: [
                      if (_step > 0)
                        Expanded(
                          child: PFSecondaryButton(
                            label: 'Back',
                            icon: Icons.arrow_back_rounded,
                            onPressed: () => setState(() => _step -= 1),
                          ),
                        ),
                      if (_step > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PFPrimaryButton(
                          label: _step == 2 ? 'Confirm reservation' : 'Next',
                          icon: _step == 2
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          loading: _busy,
                          onPressed: _busy
                              ? null
                              : () {
                                  if (_step < 2) {
                                    setState(() => _step += 1);
                                  } else {
                                    _confirm();
                                  }
                                },
                        ),
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

  Widget _buildStep(AppState state) {
    switch (_step) {
      case 0:
        return _DurationStep(
          options: _options,
          duration: _duration,
          onChanged: (d) => setState(() => _duration = d),
        );
      case 1:
        return _VehicleStep(
          vehicles: state.vehicles.all(),
          selected: _vehicle,
          onSelect: (v) => setState(() => _vehicle = v),
        );
      case 2:
      default:
        return _SummaryStep(
          slot: widget.slot,
          duration: _duration,
          vehicle: _vehicle,
          fee: _feeDollars,
        );
    }
  }
}

class _StepperHeader extends StatelessWidget {
  const _StepperHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Duration', 'Vehicle', 'Confirm'];
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i <= step;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active
                        ? PFColors.brand
                        : context.scheme.outline,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color:
                                  PFColors.brand.withValues(alpha: 0.4),
                              blurRadius: 12,
                            )
                          ]
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i].toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                    color: active
                        ? context.scheme.onSurface
                        : context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _DurationStep extends StatelessWidget {
  const _DurationStep({
    required this.options,
    required this.duration,
    required this.onChanged,
  });

  final List<Duration> options;
  final Duration duration;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How long will you park?',
                style: context.text.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Pick a preset or tap the wheel to customise.',
              style: context.text.bodyMedium?.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final opt in options)
                  _DurationChip(
                    label: opt.humanLabel,
                    active: opt == duration,
                    onTap: () => onChanged(opt),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _DurationDial(
              duration: duration,
              maxMinutes: 8 * 60,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
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
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? PFColors.brand.withValues(alpha: 0.18)
              : context.scheme.surfaceContainerHighest,
          border: Border.all(
              color: active
                  ? PFColors.brand
                  : context.scheme.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? PFColors.brand : context.scheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DurationDial extends StatefulWidget {
  const _DurationDial({
    required this.duration,
    required this.maxMinutes,
    required this.onChanged,
  });

  final Duration duration;
  final int maxMinutes;
  final ValueChanged<Duration> onChanged;

  @override
  State<_DurationDial> createState() => _DurationDialState();
}

class _DurationDialState extends State<_DurationDial> {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, c) {
          final size = c.biggest;
          return GestureDetector(
            onPanUpdate: (d) {
              final center = size.center(Offset.zero);
              final local = d.localPosition - center;
              final angle =
                  (local.direction + 2.5) % (2 * 3.1415926); // adjust origin
              final fraction = angle / (2 * 3.1415926);
              final minutes =
                  (fraction * widget.maxMinutes).round().clamp(15, widget.maxMinutes);
              widget.onChanged(Duration(minutes: minutes - (minutes % 15)));
            },
            child: CustomPaint(
              size: size,
              painter: _DialPainter(
                duration: widget.duration,
                maxMinutes: widget.maxMinutes,
                dark: context.isDark,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.duration.humanLabel,
                        style: const TextStyle(
                            fontSize: 38, fontWeight: FontWeight.w900)),
                    Text(
                      'drag to adjust',
                      style: context.text.bodySmall?.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.duration,
    required this.maxMinutes,
    required this.dark,
  });
  final Duration duration;
  final int maxMinutes;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final track = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final progress = duration.inMinutes / maxMinutes;
    final sweep = progress * 2 * 3.1415926;

    final arcP = Paint()
      ..shader = SweepGradient(
        startAngle: -3.1415926 / 2,
        endAngle: -3.1415926 / 2 + 2 * 3.1415926,
        colors: const [PFColors.brand, PFColors.brandGlow],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926 / 2,
      sweep,
      false,
      arcP,
    );

    // Ticks.
    for (int i = 0; i < 12; i++) {
      final a = -3.1415926 / 2 + (i / 12) * 2 * 3.1415926;
      final p1 = center +
          Offset.fromDirection(a, radius - 18);
      final p2 = center + Offset.fromDirection(a, radius - 26);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = (dark ? Colors.white : Colors.black)
              .withValues(alpha: 0.15)
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.duration != duration;
}

class _VehicleStep extends StatelessWidget {
  const _VehicleStep({
    required this.vehicles,
    required this.selected,
    required this.onSelect,
  });
  final List<PFVehicle> vehicles;
  final PFVehicle? selected;
  final ValueChanged<PFVehicle> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick a vehicle', style: context.text.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Switch active vehicle to use for this reservation.',
            style: context.text.bodyMedium?.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          for (final v in vehicles)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onSelect(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: v.color.withValues(alpha: 0.2),
                    border: Border.all(
                      color: v.id == selected?.id
                          ? PFColors.brand
                          : Colors.white.withValues(alpha: 0.08),
                      width: v.id == selected?.id ? 2 : 1,
                    ),
                    boxShadow: v.id == selected?.id
                        ? [
                            BoxShadow(
                              color: PFColors.brand.withValues(alpha: 0.4),
                              blurRadius: 18,
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(v.type.icon, color: Colors.white),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                            Text(v.plate,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                      if (v.id == selected?.id)
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white),
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

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.slot,
    required this.duration,
    required this.vehicle,
    required this.fee,
  });

  final PFSlot slot;
  final Duration duration;
  final PFVehicle? vehicle;
  final double fee;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: GlassCard(
        padding: const EdgeInsets.all(22),
        glow: PFColors.brand,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GlowChip(
              label: 'OFFLINE FEE',
              icon: Icons.shield_rounded,
              dense: true,
            ),
            const SizedBox(height: 14),
            Text(
              '${PFConstants.currencySymbol}${fee.toStringAsFixed(2)}',
              style: context.text.displayLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
              ),
            ),
            Text(
              'for ${duration.humanLabel} of parking',
              style: context.text.bodyMedium?.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            _SummaryRow(
                icon: Icons.local_parking_rounded,
                label: 'Slot',
                value: '${slot.label} • Floor F${slot.floor}'),
            _SummaryRow(
                icon: Icons.directions_car_rounded,
                label: 'Vehicle',
                value:
                    '${vehicle?.name ?? '—'} • ${vehicle?.plate ?? ''}'),
            _SummaryRow(
                icon: Icons.timer_rounded,
                label: 'Duration',
                value: duration.humanLabel),
            _SummaryRow(
                icon: Icons.event_rounded,
                label: 'Expires',
                value:
                    'in ${duration.humanLabel} (offline timer)'),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: PFColors.brand.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: PFColors.brand, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      color: context.scheme.onSurfaceVariant,
                      fontSize: 12,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w700,
                    )),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
