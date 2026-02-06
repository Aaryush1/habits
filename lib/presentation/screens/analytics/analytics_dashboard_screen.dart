import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

/// Analytics dashboard screen.
class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

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
                'Analytics',
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: AppSpacing.space24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics,
                        size: 64,
                        color: AppColors.accentGold.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      Text(
                        'Your Progress',
                        style: AppTypography.headlineLarge,
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        'Charts and insights will appear here',
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
