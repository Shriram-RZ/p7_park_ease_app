import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/router.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/parking_grid_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Settings'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 0.55, animated: false)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                _Section(
                  title: 'Appearance',
                  children: [
                    _Tile(
                      icon: Icons.dark_mode_rounded,
                      title: 'Theme',
                      subtitle: switch (state.themeMode) {
                        ThemeMode.dark => 'Dark (default)',
                        ThemeMode.light => 'Light',
                        ThemeMode.system => 'System',
                      },
                      trailing: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_rounded)),
                          ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_rounded)),
                          ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto_rounded)),
                        ],
                        selected: {state.themeMode},
                        onSelectionChanged: (s) =>
                            state.setThemeMode(s.first),
                      ),
                    ),
                    _Tile(
                      icon: Icons.motion_photos_pause_rounded,
                      title: 'Reduce motion',
                      subtitle:
                          'Soften background and slot animations',
                      trailing: Switch(
                        value: state.reduceMotion,
                        onChanged: state.setReduceMotion,
                      ),
                    ),
                  ],
                ),
                _Section(
                  title: 'Security',
                  children: [
                    _Tile(
                      icon: Icons.dialpad_rounded,
                      title: state.auth.hasPin() ? 'Change PIN' : 'Create PIN',
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.pinSetup,
                        arguments: {'mode': 'create'},
                      ),
                    ),
                    _Tile(
                      icon: Icons.fingerprint_rounded,
                      title: 'Biometric unlock',
                      subtitle:
                          'Mirror device biometrics (visual demo)',
                      trailing: Switch(
                        value: state.auth.biometricEnabled(),
                        onChanged: (v) async {
                          await state.auth.setBiometricEnabled(v);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(v
                                    ? 'Biometric enabled'
                                    : 'Biometric disabled')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                _Section(
                  title: 'Simulation',
                  children: [
                    _Tile(
                      icon: Icons.local_fire_department_rounded,
                      title: 'Peak traffic',
                      subtitle: 'Simulate rush hour occupancy',
                      trailing: Switch(
                        value: state.simulation.peakMode,
                        onChanged: state.setSimulationPeakMode,
                      ),
                    ),
                    _Tile(
                      icon: Icons.refresh_rounded,
                      title: 'Pulse simulation now',
                      subtitle: 'Force one round of slot mutations',
                      onTap: state.pulseSimulation,
                    ),
                  ],
                ),
                _Section(
                  title: 'Backup & data',
                  children: [
                    _Tile(
                      icon: Icons.download_rounded,
                      title: 'Export bookings as text',
                      subtitle:
                          'Generates a plain-text history snapshot',
                      onTap: () => _showExport(context, state),
                    ),
                  ],
                ),
                _Section(
                  title: 'Account',
                  children: [
                    _Tile(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      subtitle: state.currentUser?.email ?? '',
                      onTap: () async {
                        await state.signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login, (r) => false);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExport(BuildContext context, AppState state) {
    final buffer = StringBuffer('ParkFlow export\n')
      ..writeln('Generated: ${DateTime.now()}')
      ..writeln('---');
    for (final b in state.bookings.all()) {
      buffer.writeln(
          '${b.slotLabel} | F${b.floor} | ${b.startTime} → ${b.endTime} | ${b.status.name}');
    }
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export preview'),
        content: SingleChildScrollView(
          child: Text(buffer.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w800,
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ),
          GlassCard(
            padding: const EdgeInsets.all(8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: context.text.bodySmall?.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
