import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/color_utils.dart';
import '../../providers/stack_analytics_provider.dart';

/// Horizontal funnel chart showing each habit's completion rate in stack order.
/// Bars shrink as completion rate drops, visually highlighting the bottleneck.
class StackFunnelChart extends StatelessWidget {
  const StackFunnelChart({
    super.key,
    required this.analytics,
  });

  final StackAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    if (analytics.funnel.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: AppSpacing.borderRadiusLarge,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...analytics.funnel.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isWeakest = index == analytics.weakestLinkIndex;
            return _FunnelRow(
              entry: item,
              isWeakest: isWeakest,
              stepNumber: index + 1,
            );
          }),
          const SizedBox(height: AppSpacing.space12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: AppSpacing.space12),
          // Full chain rate summary
          Row(
            children: [
              const Icon(
                Icons.link_rounded,
                size: 16,
                color: AppColors.completionGreen,
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                'Full chain completed: ${(analytics.fullChainRate * 100).round()}% of days',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.completionGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FunnelRow extends StatelessWidget {
  const _FunnelRow({
    required this.entry,
    required this.isWeakest,
    required this.stepNumber,
  });

  final StackHabitFunnelEntry entry;
  final bool isWeakest;
  final int stepNumber;

  @override
  Widget build(BuildContext context) {
    final barColor = isWeakest
        ? AppColors.missedCoral
        : (parseHexColor(entry.colorHex) ?? AppColors.accentGold);

    final ratePercent = (entry.completionRate * 100).round();
    final rateLabel = '$ratePercent%';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Step badge
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$stepNumber',
                  style: AppTypography.labelSmall.copyWith(
                    color: barColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  entry.habitName,
                  style: AppTypography.headlineSmall.copyWith(
                    color: isWeakest
                        ? AppColors.missedCoral
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                rateLabel,
                style: AppTypography.dataSmall.copyWith(
                  color: barColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isWeakest) ...[
                const SizedBox(width: AppSpacing.space4),
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: AppColors.missedCoral,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          // Funnel bar
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              return Stack(
                children: [
                  // Background track
                  Container(
                    height: 8,
                    width: maxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundQuaternary,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                  // Fill bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 8,
                    width: maxWidth * entry.completionRate.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '${entry.completedDays} of ${entry.scheduledDays} scheduled days',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
