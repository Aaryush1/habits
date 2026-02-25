import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Empty state widget with a circular icon background and gold FilledButton CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.illustrationColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Size of the icon inside the circle. Defaults to 64.
  final double iconSize;

  /// Optional tint override for the circle background. Defaults to backgroundTertiary.
  final Color? illustrationColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconCircle(
              icon: icon,
              iconSize: iconSize,
              bgColor: illustrationColor ?? AppColors.backgroundTertiary,
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(
                  begin: const Offset(0.75, 0.75),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: AppSpacing.space24),
            Text(
              title,
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 150.ms, duration: 350.ms)
                .slideY(begin: 0.2, end: 0, delay: 150.ms, duration: 350.ms),
            const SizedBox(height: AppSpacing.space8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 350.ms),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.space24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: AppColors.textInverse,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLarge),
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textInverse,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 350.ms)
                  .slideY(begin: 0.3, end: 0, delay: 350.ms, duration: 350.ms),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    required this.iconSize,
    required this.bgColor,
  });

  final IconData icon;
  final double iconSize;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    final circleSize = iconSize * 1.75;
    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: AppColors.accentGold,
      ),
    );
  }
}
