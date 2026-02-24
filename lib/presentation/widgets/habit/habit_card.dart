import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../common/app_card.dart';
import 'habit_checkbox.dart';
import 'streak_dots.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.id,
    required this.name,
    required this.scheduleLabel,
    required this.isCompleted,
    required this.onToggle,
    this.color,
    this.identityStatement,
    this.trailing,
    this.onTap,
    this.showCheckbox = true,
    this.streakLength = 0,
  });

  final String id;
  final String name;
  final String scheduleLabel;
  final bool isCompleted;
  final ValueChanged<bool> onToggle;
  final Color? color;
  final String? identityStatement;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showCheckbox;
  final int streakLength;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.accentGold;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.bodyLarge),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  scheduleLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (identityStatement case final statement?) ...[
                  const SizedBox(height: AppSpacing.space8),
                  Text(
                    statement,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.space8),
                StreakDots(length: streakLength),
              ],
            ),
          ),
          if (showCheckbox) ...[
            const SizedBox(width: AppSpacing.space8),
            HabitCheckbox(value: isCompleted, onChanged: onToggle),
          ],
          ...?(trailing != null ? [trailing!] : null),
        ],
      ),
    );
  }
}
