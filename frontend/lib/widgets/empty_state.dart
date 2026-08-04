import 'package:flutter/material.dart';

import '../core/extensions.dart';
import '../core/theme.dart';
import 'gradient_button.dart';

/// Friendly empty-state placeholder: glowing icon + copy + optional CTA.
class PFEmptyState extends StatelessWidget {
  const PFEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PFSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PFColors.brand.withValues(alpha: 0.12),
                border: Border.all(
                  color: PFColors.brand.withValues(alpha: 0.30),
                ),
                boxShadow: PFShadows.glow(PFColors.brand, opacity: 0.18),
              ),
              child: Icon(icon, size: 38, color: PFColors.brand),
            ),
            const SizedBox(height: PFSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.titleLarge,
            ),
            const SizedBox(height: PFSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium
                  ?.copyWith(color: context.scheme.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: PFSpacing.lg),
              PFPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
