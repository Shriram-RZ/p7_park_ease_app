import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_state.dart';
import '../../app/router.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../data/models/scan_event.dart';
import '../../data/models/ticket.dart';
import '../../widgets/animated_counter.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/parking_grid_background.dart';
import '../../widgets/section_header.dart';

/// Operator console. Shown to users whose role is `operator`. Offers live
/// occupancy, the offline QR scanner, the on-device ticket list, and the
/// scan history — everything an attendant needs at the gate, fully offline.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.currentUser;
    final stats = state.parking.totalStats();
    final tickets = state.tickets.all();
    final scans = state.scans.all();
    final occupancy = stats.total == 0
        ? 0.0
        : (stats.taken + stats.reserved) / stats.total;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: ParkingGridBackground(intensity: 0.55, animated: false),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Header ----
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: PFColors.brand.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: PFColors.brand.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded,
                            color: PFColors.brand),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Operator console',
                                style: context.text.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3)),
                            Text(
                              user?.name ?? 'Gate operator',
                              style: context.text.bodySmall?.copyWith(
                                  color: context.scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sign out',
                        icon: const Icon(Icons.logout_rounded),
                        onPressed: () async {
                          await state.signOut();
                          if (!context.mounted) return;
                          Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.login, (r) => false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ---- Occupancy ----
                  _OccupancyCard(
                    free: stats.free,
                    taken: stats.taken,
                    reserved: stats.reserved,
                    total: stats.total,
                    occupancy: occupancy,
                  ),
                  const SizedBox(height: 16),

                  // ---- Scan CTA ----
                  PFPrimaryButton(
                    label: 'Scan ticket QR',
                    icon: Icons.qr_code_scanner_rounded,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.scanner),
                  ),
                  const SizedBox(height: 24),

                  // ---- Tickets on device ----
                  SectionHeader(
                    title: 'Tickets on device',
                    subtitle:
                        '${tickets.length} issued • validate at the gate',
                  ),
                  const SizedBox(height: 12),
                  if (tickets.isEmpty)
                    const _EmptyHint(
                      icon: Icons.confirmation_number_outlined,
                      text: 'No tickets issued on this device yet.',
                    )
                  else
                    ...tickets.take(20).map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _TicketRow(ticket: t),
                        )),
                  const SizedBox(height: 24),

                  // ---- Scan history ----
                  SectionHeader(
                    title: 'Scan history',
                    subtitle: scans.isEmpty
                        ? 'Validated tickets appear here'
                        : '${scans.length} recent scans',
                    action: scans.isEmpty
                        ? null
                        : TextButton(
                            onPressed: state.clearScanHistory,
                            child: const Text('Clear'),
                          ),
                  ),
                  const SizedBox(height: 12),
                  if (scans.isEmpty)
                    const _EmptyHint(
                      icon: Icons.history_rounded,
                      text: 'Nothing scanned yet. Tap “Scan ticket QR”.',
                    )
                  else
                    ...scans.take(20).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ScanRow(event: e),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupancyCard extends StatelessWidget {
  const _OccupancyCard({
    required this.free,
    required this.taken,
    required this.reserved,
    required this.total,
    required this.occupancy,
  });

  final int free;
  final int taken;
  final int reserved;
  final int total;
  final double occupancy;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glow: PFColors.brand,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedCounter(
                value: (taken + reserved),
                style: context.text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(' / $total occupied',
                    style: context.text.bodyMedium?.copyWith(
                        color: context.scheme.onSurfaceVariant)),
              ),
              const Spacer(),
              GlowChip(
                label: '${(occupancy * 100).round()}% full',
                icon: Icons.local_parking_rounded,
                dense: true,
                color: occupancy > 0.85 ? PFColors.warning : PFColors.brand,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: occupancy.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: context.scheme.outline.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(
                occupancy > 0.85 ? PFColors.warning : PFColors.brand,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatPill(
                  label: 'Free',
                  value: free,
                  color: PFColors.slotAvailable),
              const SizedBox(width: 10),
              _StatPill(
                  label: 'Taken',
                  value: taken,
                  color: PFColors.slotOccupied),
              const SizedBox(width: 10),
              _StatPill(
                  label: 'Reserved',
                  value: reserved,
                  color: PFColors.slotReserved),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(
      {required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCounter(
              value: value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 20),
            ),
            Text(label,
                style: context.text.bodySmall?.copyWith(
                    color: context.scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket});
  final PFTicket ticket;

  Color get _statusColor => switch (ticket.status) {
        TicketStatus.active => PFColors.brand,
        TicketStatus.used => PFColors.info,
        TicketStatus.expired => PFColors.warning,
        TicketStatus.invalid => PFColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.confirmation_number_rounded,
                color: _statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.slotLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  '${ticket.id} • ${ticket.vehiclePlate}',
                  style: context.text.bodySmall?.copyWith(
                      color: context.scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _StatusChip(
              label: ticket.status.name.toUpperCase(), color: _statusColor),
        ],
      ),
    );
  }
}

class _ScanRow extends StatelessWidget {
  const _ScanRow({required this.event});
  final PFScanEvent event;

  Color get _color => switch (event.result) {
        ScanResult.valid => PFColors.brand,
        ScanResult.alreadyUsed => PFColors.warning,
        ScanResult.expired => PFColors.warning,
        ScanResult.invalid => PFColors.danger,
      };

  IconData get _icon => switch (event.result) {
        ScanResult.valid => Icons.check_circle_rounded,
        ScanResult.alreadyUsed => Icons.replay_rounded,
        ScanResult.expired => Icons.schedule_rounded,
        ScanResult.invalid => Icons.cancel_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MMM d • HH:mm:ss').format(event.scannedAt);
    final subtitle = event.slotLabel != null
        ? '${event.slotLabel} • ${event.vehiclePlate ?? '—'}'
        : (event.rawCode ?? 'Unknown code');
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.result.label,
                    style:
                        TextStyle(fontWeight: FontWeight.w800, color: _color)),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                      color: context.scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time,
              style: context.text.bodySmall?.copyWith(
                  color: context.scheme.onSurfaceVariant, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.5),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: context.scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: context.text.bodyMedium?.copyWith(
                    color: context.scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
