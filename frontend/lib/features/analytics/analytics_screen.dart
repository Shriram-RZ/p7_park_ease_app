import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../widgets/charts.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/parking_grid_background.dart';
import '../../widgets/section_header.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final bookings = state.bookings.all();

    final hourlyOccupancy = List<double>.generate(7, (i) {
      final r = Random(i + 3);
      return 30 + r.nextDouble() * 60;
    });
    final daily = List<double>.generate(7, (i) {
      final r = Random(i + 11);
      return 2 + r.nextDouble() * 6;
    });

    final avgMinutes = bookings.isEmpty
        ? 0
        : bookings
                .map((b) => b.duration.inMinutes)
                .reduce((a, b) => a + b) ~/
            bookings.length;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop())
            : null,
        title: const Text('Insights'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 0.6, animated: false)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatBlock(
                          icon: Icons.timer_rounded,
                          label: 'Avg duration',
                          value: avgMinutes == 0
                              ? '—'
                              : Duration(minutes: avgMinutes).humanLabel,
                          accent: PFColors.brand,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBlock(
                          icon: Icons.event_available_rounded,
                          label: 'Total sessions',
                          value: '${bookings.length}',
                          accent: PFColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SectionHeader(
                    title: 'Weekly usage',
                    subtitle: 'Daily reservations across the last week',
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: PFBarChart(
                      values: daily,
                      labels: const [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SectionHeader(
                    title: 'Occupancy trend',
                    subtitle: 'Smoothed across the past week',
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: PFLineChart(values: hourlyOccupancy),
                  ),
                  const SizedBox(height: 14),
                  const SectionHeader(title: 'Smart insights'),
                  const SizedBox(height: 12),
                  _InsightCard(
                    icon: Icons.location_on_rounded,
                    title: 'You park most on Level F2',
                    body:
                        'About 42% of your sessions end up on the second floor.',
                  ),
                  const SizedBox(height: 10),
                  _InsightCard(
                    icon: Icons.access_time_rounded,
                    title: 'Average session: 1h 42m',
                    body:
                        'Most of your reservations are short stays under 2 hours.',
                  ),
                  const SizedBox(height: 10),
                  _InsightCard(
                    icon: Icons.calendar_today_rounded,
                    title: 'Peak day: Friday',
                    body: 'You parked 3 times on Fridays in the last month.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
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

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PFColors.brand.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: PFColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(body,
                    style: context.text.bodySmall?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
