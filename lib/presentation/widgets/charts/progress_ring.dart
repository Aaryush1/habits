import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.label,
    this.size = 84,
    this.strokeWidth = 8,
  });

  final double progress;
  final String label;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: clamped,
            strokeWidth: strokeWidth,
            backgroundColor: AppColors.borderSubtle,
          ),
          SizedBox(
            width: size * 0.56,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: AppTypography.labelMedium),
            ),
          ),
        ],
      ),
    );
  }
}
