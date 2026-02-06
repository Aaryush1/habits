import 'package:flutter/material.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.space16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: AppSpacing.borderRadiusMedium,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusMedium,
            boxShadow: AppShadows.card,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
