import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

/// Settings screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space16),
              Text(
                'Settings',
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: AppSpacing.space24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.settings,
                        size: 64,
                        color: AppColors.accentGold.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      Text(
                        'App Settings',
                        style: AppTypography.headlineLarge,
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        'Configure your preferences',
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
