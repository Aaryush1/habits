import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class HabitCheckbox extends StatelessWidget {
  const HabitCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.color,
    this.size = 28,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.completionGreen;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? accent : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: value ? accent : AppColors.borderMedium,
            width: 2,
          ),
        ),
        child: value
            ? Icon(
                Icons.check_rounded,
                size: size * 0.6,
                color: AppColors.textInverse,
              )
            : null,
      ),
    );
  }
}
