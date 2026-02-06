import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class HeatmapGrid extends StatelessWidget {
  const HeatmapGrid({
    super.key,
    required this.values,
  });

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.space4,
      runSpacing: AppSpacing.space4,
      children: values.map((value) {
        final clamped = value.clamp(0, 4);
        final color = AppColors.heatmapGradient[clamped];
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }).toList(),
    );
  }
}
