import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.headlineLarge),
              ...?(subtitle != null
                  ? [
                      const SizedBox(height: AppSpacing.space4),
                      Text(subtitle!, style: AppTypography.bodySmall),
                    ]
                  : null),
            ],
          ),
        ),
        ...[trailing].whereType<Widget>(),
      ],
    );
  }
}
