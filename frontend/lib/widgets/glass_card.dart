import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Frosted glassmorphism container used throughout ParkFlow.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = PFRadii.lg,
    this.borderColor,
    this.blur = 18,
    this.glow,
    this.height,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final double blur;
  final Color? glow;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Light mode: glass over a near-white bg has nothing to refract, so a more
    // opaque tint + a visible cool border read as a crisp elevated card.
    final tint = dark
        ? const Color(0xFF0F1B19).withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.86);
    final border = borderColor ??
        (dark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFF0F172A).withValues(alpha: 0.08));
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          if (glow != null)
            BoxShadow(
              color: glow!.withValues(alpha: 0.30),
              blurRadius: 36,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: dark
                ? const Color(0xCC000000)
                : const Color(0xFF0F172A).withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint,
              border: Border.all(color: border, width: 1),
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [
                        Colors.white.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.01),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.3),
                      ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Compact pill chip with optional glow used for stat metadata.
class GlowChip extends StatelessWidget {
  const GlowChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = color ?? PFColors.brand;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(PFRadii.pill),
        border: Border.all(color: c.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 11 : 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
