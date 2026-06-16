import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/app_state.dart';
import '../../core/theme.dart';
import '../../data/models/scan_event.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';

/// Real offline QR scanner. Decodes ParkFlow ticket QR codes with the device
/// camera and validates them against locally stored tickets — no network.
/// Used by operators at the gate, reachable from the admin dashboard.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  late final AnimationController _beam = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  bool _processing = false;
  PFScanEvent? _result;

  @override
  void dispose() {
    _beam.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _result != null) return;
    String? raw;
    for (final b in capture.barcodes) {
      if (b.rawValue != null && b.rawValue!.isNotEmpty) {
        raw = b.rawValue;
        break;
      }
    }
    if (raw == null) return;

    setState(() => _processing = true);
    HapticFeedback.mediumImpact();
    final state = AppScope.read(context);
    await _controller.stop();
    final res = await state.validateTicketCode(raw);
    if (!mounted) return;
    setState(() {
      _result = res.event;
      _processing = false;
    });
    if (res.event.result.isSuccess) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _scanNext() async {
    setState(() => _result = null);
    await _controller.start();
  }

  Color _colorFor(ScanResult r) => switch (r) {
        ScanResult.valid => PFColors.brand,
        ScanResult.alreadyUsed => PFColors.warning,
        ScanResult.expired => PFColors.warning,
        ScanResult.invalid => PFColors.danger,
      };

  IconData _iconFor(ScanResult r) => switch (r) {
        ScanResult.valid => Icons.verified_rounded,
        ScanResult.alreadyUsed => Icons.replay_rounded,
        ScanResult.expired => Icons.schedule_rounded,
        ScanResult.invalid => Icons.gpp_bad_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final frameColor =
        result != null ? _colorFor(result.result) : PFColors.brand;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ---- Live camera ----
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              fit: BoxFit.cover,
              placeholderBuilder: (_) => const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(color: PFColors.brand),
                ),
              ),
              errorBuilder: (context, error) =>
                  _CameraError(error: error, controller: _controller),
            ),
          ),

          // ---- Dim scrim for contrast ----
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x99000000),
                      Color(0x33000000),
                      Color(0xCC000000),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ---- Scan frame ----
          Center(
            child: AnimatedBuilder(
              animation: _beam,
              builder: (_, _) => _ScanFrame(
                beam: _beam.value,
                color: frameColor,
                scanning: result == null,
              ),
            ),
          ),

          // ---- Top bar ----
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    const GlowChip(
                      label: 'OFFLINE SCANNER',
                      icon: Icons.shield_rounded,
                      dense: true,
                    ),
                    const Spacer(),
                    _TorchButton(controller: _controller),
                  ],
                ),
              ),
            ),
          ),

          // ---- Bottom panel ----
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: result == null
                ? _HintCard(processing: _processing)
                : _ResultCard(
                    event: result,
                    color: _colorFor(result.result),
                    icon: _iconFor(result.result),
                    onScanNext: _scanNext,
                  ),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.processing});
  final bool processing;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          if (processing)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: PFColors.brand),
            )
          else
            const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              processing
                  ? 'Validating ticket…'
                  : 'Point the camera at a ParkFlow ticket QR',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.event,
    required this.color,
    required this.icon,
    required this.onScanNext,
  });

  final PFScanEvent event;
  final Color color;
  final IconData icon;
  final VoidCallback onScanNext;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glow: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.result.label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.slotLabel != null
                          ? '${event.slotLabel} • ${event.vehiclePlate ?? '—'}'
                          : 'Not a recognised ParkFlow ticket',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PFPrimaryButton(
            label: 'Scan next',
            icon: Icons.qr_code_scanner_rounded,
            onPressed: onScanNext,
          ),
        ],
      ),
    );
  }
}

class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.controller});
  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, _) {
        final on = state.torchState == TorchState.on;
        final available = state.torchState != TorchState.unavailable;
        if (!available) return const SizedBox(width: 48);
        return IconButton(
          icon: Icon(
            on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            color: on ? PFColors.warning : Colors.white,
          ),
          onPressed: () => controller.toggleTorch(),
        );
      },
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.controller});
  final MobileScannerException error;
  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    final permissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  permissionDenied
                      ? Icons.no_photography_rounded
                      : Icons.videocam_off_rounded,
                  color: PFColors.danger,
                  size: 48,
                ),
                const SizedBox(height: 14),
                Text(
                  permissionDenied
                      ? 'Camera permission needed'
                      : 'Camera unavailable',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  permissionDenied
                      ? 'Allow camera access in system settings to scan tickets offline.'
                      : 'No camera is available on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 18),
                PFPrimaryButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: () => controller.start(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated bracket frame + sweeping beam drawn over the live camera.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame({
    required this.beam,
    required this.color,
    required this.scanning,
  });
  final double beam;
  final Color color;
  final bool scanning;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 270,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(270, 270),
            painter: _FramePainter(color: color),
          ),
          if (scanning)
            Positioned(
              top: 20 + (230 * beam),
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
                        color: color.withValues(alpha: 0.6), blurRadius: 18),
                  ],
                ),
              ),
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
    const r = 14.0;
    const corner = 36.0;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(20, 20, size.width - 40, size.height - 40),
      const Radius.circular(r),
    );

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
