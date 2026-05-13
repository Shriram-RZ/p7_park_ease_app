import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Premium CTA button with subtle press animation and a glowing accent.
class PFPrimaryButton extends StatefulWidget {
  const PFPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  @override
  State<PFPrimaryButton> createState() => _PFPrimaryButtonState();
}

class _PFPrimaryButtonState extends State<PFPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    lowerBound: 0.96,
    upperBound: 1.0,
    value: 1.0,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;
    final child = AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _ctrl.value,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PFRadii.md),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: disabled
                  ? [
                      PFColors.brand.withValues(alpha: 0.35),
                      PFColors.brandGlow.withValues(alpha: 0.25),
                    ]
                  : const [
                      PFColors.brand,
                      PFColors.brandGlow,
                    ],
            ),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: PFColors.brand.withValues(alpha: 0.45),
                      blurRadius: 26,
                      spreadRadius: 1,
                      offset: const Offset(0, 12),
                    ),
                  ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown: (_) {
        if (!disabled) _ctrl.animateTo(0.96, curve: Curves.easeOut);
      },
      onTapUp: (_) {
        _ctrl.animateTo(1.0, curve: Curves.elasticOut);
        if (!disabled) widget.onPressed!();
      },
      onTapCancel: () => _ctrl.animateTo(1.0, curve: Curves.elasticOut),
      child: widget.expanded
          ? SizedBox(width: double.infinity, child: child)
          : child,
    );
  }
}

class PFSecondaryButton extends StatelessWidget {
  const PFSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: dark ? Colors.white : PFColors.lightTextPrimary,
        side: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
      ),
    );
  }
}
