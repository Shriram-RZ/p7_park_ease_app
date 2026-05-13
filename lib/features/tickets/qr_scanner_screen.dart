import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/extensions.dart';
import '../../core/theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _beam = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  _ScanState _state = _ScanState.scanning;
  String? _resultLabel;

  @override
  void dispose() {
    _beam.dispose();
    _ring.dispose();
    super.dispose();
  }

  Future<void> _simulateScan() async {
    setState(() => _state = _ScanState.validating);
    _ring.forward(from: 0);
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 1200));
    final state = AppScope.read(context);
    final ticket = state.tickets.all().isNotEmpty
        ? state.tickets.all().first
        : null;
    if (!mounted) return;
    if (ticket != null) {
      setState(() {
        _state = _ScanState.success;
        _resultLabel = '${ticket.slotLabel} • ${ticket.vehiclePlate}';
      });
      HapticFeedback.mediumImpact();
    } else {
      setState(() {
        _state = _ScanState.invalid;
        _resultLabel = 'No matching ticket on this device.';
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Faux camera surface.
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF0B1F1B),
                    Colors.black,
                  ],
                  radius: 1.1,
                ),
              ),
              child: CustomPaint(painter: _NoisePainter()),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_beam, _ring]),
              builder: (_, _) => _ScanFrame(
                beam: _beam.value,
                ring: _ring.value,
                state: _state,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    const GlowChip(
                      label: 'OFFLINE SCANNER',
                      icon: Icons.shield_rounded,
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 32,
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    switch (_state) {
                      _ScanState.scanning => 'Align a ParkFlow QR inside the frame',
                      _ScanState.validating => 'Validating ticket…',
                      _ScanState.success => 'Ticket valid',
                      _ScanState.invalid => 'Ticket invalid',
                    },
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  if (_resultLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _resultLabel!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  PFPrimaryButton(
                    label: _state == _ScanState.scanning
                        ? 'Simulate scan'
                        : 'Reset scanner',
                    icon: _state == _ScanState.scanning
                        ? Icons.qr_code_scanner_rounded
                        : Icons.refresh_rounded,
                    onPressed: () {
                      if (_state == _ScanState.scanning) {
                        _simulateScan();
                      } else {
                        setState(() {
                          _state = _ScanState.scanning;
                          _resultLabel = null;
                        });
                      }
                    },
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

enum _ScanState { scanning, validating, success, invalid }

class _ScanFrame extends StatelessWidget {
  const _ScanFrame({
    required this.beam,
    required this.ring,
    required this.state,
  });
  final double beam;
  final double ring;
  final _ScanState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _ScanState.scanning => PFColors.brand,
      _ScanState.validating => PFColors.info,
      _ScanState.success => PFColors.brand,
      _ScanState.invalid => PFColors.danger,
    };
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        children: [
          // Frame.
          CustomPaint(
            size: const Size(280, 280),
            painter: _FramePainter(color: color),
          ),
          // Beam.
          if (state == _ScanState.scanning)
            Positioned(
              top: 20 + (240 * beam),
              left: 20,
              right: 20,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0),
                      color,
                      color.withValues(alpha: 0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
          if (state == _ScanState.success)
            Center(
              child: Transform.scale(
                scale: 0.5 + ring * 1.2,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: PFColors.brand.withValues(alpha: 0.6),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: PFColors.brand.withValues(alpha: 0.3),
                          blurRadius: 30)
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 80),
                  ),
                ),
              ),
            ),
          if (state == _ScanState.invalid)
            const Center(
              child: Icon(Icons.cancel_rounded,
                  color: PFColors.danger, size: 80),
            ),
        ],
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = 14.0;
    final corner = 36.0;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(20, 20, size.width - 40, size.height - 40),
      Radius.circular(r),
    );
    // Corners.
    void drawCorner(Offset from, Offset to1, Offset to2) {
      final p = Path()
        ..moveTo(to1.dx, to1.dy)
        ..lineTo(from.dx, from.dy)
        ..lineTo(to2.dx, to2.dy);
      canvas.drawPath(p, stroke);
    }

    drawCorner(
      Offset(rect.left, rect.top),
      Offset(rect.left + corner, rect.top),
      Offset(rect.left, rect.top + corner),
    );
    drawCorner(
      Offset(rect.right, rect.top),
      Offset(rect.right - corner, rect.top),
      Offset(rect.right, rect.top + corner),
    );
    drawCorner(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + corner, rect.bottom),
      Offset(rect.left, rect.bottom - corner),
    );
    drawCorner(
      Offset(rect.right, rect.bottom),
      Offset(rect.right - corner, rect.bottom),
      Offset(rect.right, rect.bottom - corner),
    );

    // Faint full outline.
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant _FramePainter old) => old.color != color;
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.02);
    for (int i = 0; i < 90; i++) {
      final x = (i * 37) % size.width.toInt();
      final y = (i * 73) % size.height.toInt();
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
