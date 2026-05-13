import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../app/router.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/parking_grid_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      HapticFeedback.lightImpact();
      _shake.forward(from: 0);
      return;
    }
    setState(() => _busy = true);
    final state = AppScope.read(context);
    final ok = await state.auth.signIn(
      email: _email.text,
      password: _password.text,
    );
    setState(() => _busy = false);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.mainShell);
    } else {
      HapticFeedback.mediumImpact();
      _shake.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  Future<void> _continueOffline() async {
    Navigator.of(context).pushReplacementNamed(AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ParkingGridBackground(intensity: 0.85)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: PFColors.brand.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: PFColors.brand.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            color: PFColors.brand),
                      ),
                      const SizedBox(width: 12),
                      Text('ParkFlow',
                          style: context.text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3)),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Text('Welcome back',
                      style: context.text.displayMedium
                          ?.copyWith(height: 1.05)),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your offline parking ecosystem.',
                    style: context.text.bodyLarge?.copyWith(
                        color: context.scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  AnimatedBuilder(
                    animation: _shake,
                    builder: (_, child) {
                      final offset = Curves.elasticIn
                              .transform(_shake.value) *
                          16 *
                          (1 - _shake.value);
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _form,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon:
                                    Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (v) =>
                                  (v == null || !v.contains('@'))
                                      ? 'Enter a valid email'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon:
                                    const Icon(Icons.lock_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.length < 4)
                                      ? 'Minimum 4 characters'
                                      : null,
                            ),
                            const SizedBox(height: 18),
                            PFPrimaryButton(
                              label: 'Sign in',
                              icon: Icons.login_rounded,
                              loading: _busy,
                              onPressed: _busy ? null : _submit,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: PFSecondaryButton(
                                    label: 'PIN',
                                    icon: Icons.dialpad_rounded,
                                    onPressed: () =>
                                        Navigator.of(context).pushNamed(
                                            AppRoutes.pinSetup,
                                            arguments: {'mode': 'verify'}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: PFSecondaryButton(
                                    label: 'Biometric',
                                    icon: Icons.fingerprint_rounded,
                                    onPressed: _submit,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _continueOffline,
                          child: const Text('Create new account'),
                        ),
                      ),
                    ],
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
