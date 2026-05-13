import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_state.dart';
import '../../core/constants.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../data/models/booking.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/parking_grid_background.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'All';

  bool _matches(PFBooking b) {
    final now = DateTime.now();
    switch (_filter) {
      case 'Today':
        return b.startTime.year == now.year &&
            b.startTime.month == now.month &&
            b.startTime.day == now.day;
      case 'Week':
        return now.difference(b.startTime).inDays < 7;
      case 'Month':
        return now.difference(b.startTime).inDays < 31;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items =
        state.bookings.all().where(_matches).toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Parking history'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 0.55)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: GlassCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: ['All', 'Today', 'Week', 'Month']
                          .map((label) {
                        final active = _filter == label;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = label),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active
                                    ? PFColors.brand.withValues(alpha: 0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active
                                      ? PFColors.brand
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: active
                                      ? PFColors.brand
                                      : context.scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.history_rounded,
                                    color: PFColors.brand, size: 40),
                                const SizedBox(height: 8),
                                const Text('No bookings yet',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  'Reservations will appear here.',
                                  style: context.text.bodyMedium?.copyWith(
                                    color: context.scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 8, 20, 120),
                          itemCount: items.length,
                          itemBuilder: (_, i) => _TimelineRow(
                            booking: items[i],
                            first: i == 0,
                            last: i == items.length - 1,
                            index: i,
                          ),
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

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.booking,
    required this.first,
    required this.last,
    required this.index,
  });
  final PFBooking booking;
  final bool first;
  final bool last;
  final int index;

  Color get _statusColor => switch (booking.status) {
        BookingStatus.active => PFColors.brand,
        BookingStatus.upcoming => PFColors.info,
        BookingStatus.completed => PFColors.brandStrong,
        BookingStatus.expired => PFColors.warning,
        BookingStatus.cancelled => PFColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d • HH:mm');
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 40),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 24),
          child: child,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  SizedBox(
                    height: 22,
                    child: first
                        ? null
                        : Container(
                            width: 2,
                            color: context.scheme.outline,
                          ),
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _statusColor.withValues(alpha: 0.6),
                          blurRadius: 12,
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: last
                        ? const SizedBox.shrink()
                        : Container(
                            width: 2,
                            color: context.scheme.outline,
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(booking.slotLabel,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          GlowChip(
                            label: booking.status.name.toUpperCase(),
                            color: _statusColor,
                            dense: true,
                          ),
                          const Spacer(),
                          Text(
                              '${PFConstants.currencySymbol}${(booking.feeCents / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${df.format(booking.startTime)} → ${df.format(booking.endTime)}',
                        style: context.text.bodySmall?.copyWith(
                            color: context.scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${booking.vehicleName} • ${booking.vehiclePlate} • ${booking.duration.humanLabel}',
                        style: context.text.bodySmall?.copyWith(
                            color: context.scheme.onSurfaceVariant),
                      ),
                    ],
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
