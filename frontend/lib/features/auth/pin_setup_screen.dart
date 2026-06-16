import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../app/router.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/parking_grid_background.dart';
import '../../widgets/radar_pulse.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, this.mode = 'create'});
  final String mode; // 'create' | 'verify'

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final List<int> _pin = [];
  String? _firstAttempt;
  String? _error;

  bool get _isCreate => widget.mode == 'create';

  void _onDigit(int d) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin.add(d);
      _error = null;
    });
    HapticFeedback.selectionClick();
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _onComplete);
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin.removeLast());
  }

  Future<void> _onComplete() async {
    final state = AppScope.read(context);
    final pinStr = _pin.join();
    if (_isCreate) {
      if (_firstAttempt == null) {
        setState(() {
          _firstAttempt = pinStr;
          _pin.clear();
        });
        return;
      } else {
        if (_firstAttempt == pinStr) {
          await state.auth.setPin(pinStr);
          if (!mounted) return;
          HapticFeedback.mediumImpact();
          Navigator.of(context).pushReplacementNamed(
            state.isOperator ? AppRoutes.adminShell : AppRoutes.mainShell,
          );
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _pin.clear();
            _firstAttempt = null;
            _error = 'PIN did not match. Try again.';
          });
        }
      }
    } else {
      final ok = state.auth.verifyPin(pinStr);
      if (ok) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          state.isOperator ? AppRoutes.adminShell : AppRoutes.mainShell,
        );
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _pin.clear();
          _error = 'Wrong PIN';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isCreate
        ? (_firstAttempt == null ? 'Create a 4-digit PIN' : 'Confirm your PIN')
        : 'Enter your PIN';
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 0.7)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const RadarPulse(
                    size: 180,
                    color: PFColors.brand,
                    child: Icon(Icons.lock_rounded,
                        size: 48, color: PFColors.brand),
                  ),
                  const SizedBox(height: 24),
                  Text(title, style: context.text.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    _isCreate
                        ? 'PIN unlocks ParkFlow without a password.'
                        : 'Authenticate with your PIN to continue.',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (i) {
                      final filled = i < _pin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: filled ? 22 : 14,
                        height: filled ? 22 : 14,
                        decoration: BoxDecoration(
                          color: filled
                              ? PFColors.brand
                              : context.scheme.outline,
                          shape: BoxShape.circle,
                          boxShadow: filled
                              ? [
                                  BoxShadow(
                                    color: PFColors.brand
                                        .withValues(alpha: 0.5),
                                    blurRadius: 16,
                                  )
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(color: PFColors.danger),
                    ),
                  ],
                  const SizedBox(height: 28),
                  _PinPad(
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                  ),
                  const SizedBox(height: 12),
                  if (_isCreate)
                    PFSecondaryButton(
                      label: 'Skip for now',
                      icon: Icons.fast_forward_rounded,
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(
                        AppScope.read(context).isOperator
                            ? AppRoutes.adminShell
                            : AppRoutes.mainShell,
                      ),
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

class _PinPad extends StatelessWidget {
  const _PinPad({required this.onDigit, required this.onBackspace});
  final void Function(int) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          for (final row in const [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final d in row)
                    _PadKey(label: '$d', onPressed: () => onDigit(d)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 64, height: 64),
                _PadKey(label: '0', onPressed: () => onDigit(0)),
                _PadKey(
                  icon: Icons.backspace_rounded,
                  onPressed: onBackspace,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PadKey extends StatefulWidget {
  const _PadKey({this.label, this.icon, required this.onPressed});
  final String? label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  State<_PadKey> createState() => _PadKeyState();
}

class _PadKeyState extends State<_PadKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    lowerBound: 0.9,
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
      onTapDown: (_) => _c.animateTo(0.9, curve: Curves.easeOut),
      onTapUp: (_) {
        _c.animateTo(1.0, curve: Curves.elasticOut);
        widget.onPressed();
      },
      onTapCancel: () => _c.animateTo(1.0),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.scale(scale: _c.value, child: child),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
                color: PFColors.brand.withValues(alpha: 0.18), width: 1),
          ),
          child: widget.icon != null
              ? Icon(widget.icon, color: PFColors.brand)
              : Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
