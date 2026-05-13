import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_state.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../data/models/notification.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/parking_grid_background.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(PFNotificationType t) => switch (t) {
        PFNotificationType.reservation => Icons.event_available_rounded,
        PFNotificationType.expiry => Icons.timer_off_rounded,
        PFNotificationType.confirmation => Icons.check_circle_rounded,
        PFNotificationType.system => Icons.notifications_rounded,
        PFNotificationType.navigation => Icons.alt_route_rounded,
      };

  Color _colorFor(PFNotificationType t) => switch (t) {
        PFNotificationType.reservation => PFColors.info,
        PFNotificationType.expiry => PFColors.warning,
        PFNotificationType.confirmation => PFColors.brand,
        PFNotificationType.system => PFColors.brand,
        PFNotificationType.navigation => PFColors.brandGlow,
      };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = state.notifications.all();
    final df = DateFormat('MMM d • HH:mm');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => state.markNotificationsRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 0.55)),
          SafeArea(
            child: items.isEmpty
                ? Center(
                    child: GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_off_rounded,
                              size: 40, color: PFColors.brand),
                          const SizedBox(height: 8),
                          Text('Nothing new',
                              style: context.text.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            "We'll alert you for upcoming reservations and expiries.",
                            textAlign: TextAlign.center,
                            style: context.text.bodySmall?.copyWith(
                              color: context.scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final n = items[i];
                      final color = _colorFor(n.type);
                      return Dismissible(
                        key: ValueKey(n.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          color: PFColors.brand.withValues(alpha: 0.2),
                          child: const Icon(Icons.mark_email_read_rounded,
                              color: PFColors.brand),
                        ),
                        onDismissed: (_) => state.markNotificationRead(n.id),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          borderColor: n.read
                              ? null
                              : color.withValues(alpha: 0.4),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(_iconFor(n.type), color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                        if (!n.read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                    color: color.withValues(
                                                        alpha: 0.5),
                                                    blurRadius: 10)
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(n.body,
                                        style: context.text.bodySmall?.copyWith(
                                          color:
                                              context.scheme.onSurfaceVariant,
                                        )),
                                    const SizedBox(height: 4),
                                    Text(df.format(n.createdAt),
                                        style: context.text.bodySmall?.copyWith(
                                          color:
                                              context.scheme.onSurfaceVariant,
                                          fontSize: 11,
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
