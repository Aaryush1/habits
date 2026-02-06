import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class StreakDots extends StatelessWidget {
  const StreakDots({
    super.key,
    required this.length,
    this.maxDots = 7,
  });

  final int length;
  final int maxDots;

  @override
  Widget build(BuildContext context) {
    final count = length < maxDots ? length : maxDots;
    return Row(
      children: List.generate(
        maxDots,
        (index) => Container(
          margin: const EdgeInsets.only(right: AppSpacing.space4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < count ? AppColors.completionGreen : AppColors.borderSubtle,
          ),
        ),
      ),
    );
  }
}
