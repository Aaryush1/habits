import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.headlineLarge),
        if (subtitle != null) Text(subtitle!, style: AppTypography.bodySmall),
      ],
    );
  }
}
