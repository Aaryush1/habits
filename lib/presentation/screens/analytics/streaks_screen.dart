import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/color_utils.dart';
import '../../providers/streak_analytics_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class StreaksScreen extends ConsumerWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streaksAsync = ref.watch(streakAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Streaks')),
      body: SafeArea(
        child: streaksAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading streaks'),
          error: (_, _) => const Center(child: Text('Failed to load')),
          data: (data) => ListView(
            padding: const EdgeInsets.all(AppSpacing.space16),
            children: [
              // At Risk section
              if (data.atRisk.isNotEmpty) ...[
                _SectionTitle(
                  title: 'At Risk',
                  subtitle:
                      'Scheduled today but not completed — don\'t break the chain!',
                  color: AppColors.missedCoral,
                ),
                const SizedBox(height: AppSpacing.space8),
                ...data.atRisk.map((h) => _AtRiskTile(habit: h)),
                const SizedBox(height: AppSpacing.space20),
              ],

              // Active streaks
              _SectionTitle(
                title: 'Active Streaks',
                subtitle: '${data.activeStreaks.length} habits on a roll',
              ),
              const SizedBox(height: AppSpacing.space8),
              if (data.activeStreaks.isEmpty)
                _EmptyMessage('No active streaks. Complete a habit to start one!')
              else
                ...data.activeStreaks.map((s) => _StreakTile(streak: s)),
              const SizedBox(height: AppSpacing.space20),

              // Personal records
              _SectionTitle(
                title: 'Personal Records',
                subtitle: 'Longest streak per habit',
              ),
              const SizedBox(height: AppSpacing.space8),
              if (data.personalRecords.isEmpty)
                _EmptyMessage('Complete habits for 2+ days to see records here.')
              else
                ...data.personalRecords.map((r) => _RecordTile(record: r)),
              const SizedBox(height: AppSpacing.space20),

              // Streak timeline
              if (data.streakTimeline.isNotEmpty) ...[
                _SectionTitle(
                  title: 'Streak Timeline',
                  subtitle: 'All streak periods across all habits',
                ),
                const SizedBox(height: AppSpacing.space8),
                _StreakTimeline(periods: data.streakTimeline),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.color,
  });

  final String title;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headlineMedium.copyWith(color: color),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
      ],
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
      ),
    );
  }
}

class _AtRiskTile extends StatelessWidget {
  const _AtRiskTile({required this.habit});
  final AtRiskHabit habit;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(habit.colorHex) ?? AppColors.accentGold;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space8),
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.missedCoralSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.missedCoral.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.missedCoral,
          ),
          const SizedBox(width: 10),
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(habit.habitName, style: AppTypography.bodyMedium),
          ),
          Text(
            '${habit.currentStreak}d streak',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.missedCoral,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakTile extends StatelessWidget {
  const _StreakTile({required this.streak});
  final ActiveStreak streak;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(streak.colorHex) ?? AppColors.accentGold;
    final fireSize = (streak.length / 7).clamp(1.0, 3.0) * 8 + 12;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space8),
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: fireSize,
            color: streak.length >= 7
                ? AppColors.accentGold
                : AppColors.textTertiary,
          ),
          const SizedBox(width: 10),
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(streak.habitName, style: AppTypography.bodyMedium),
          ),
          Text(
            '${streak.length} days',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.accentGold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record});
  final PersonalRecord record;

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(record.colorHex) ?? AppColors.accentGold;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space8),
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, size: 20, color: AppColors.accentGold),
          const SizedBox(width: 10),
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.habitName, style: AppTypography.bodyMedium),
                Text(
                  '${DateFormat('MMM d').format(record.startDate)} – ${DateFormat('MMM d').format(record.endDate)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${record.length}d',
            style: AppTypography.headlineLarge,
          ),
        ],
      ),
    );
  }
}

class _StreakTimeline extends StatelessWidget {
  const _StreakTimeline({required this.periods});
  final List<StreakPeriod> periods;

  @override
  Widget build(BuildContext context) {
    // Sort by start date descending (most recent first)
    final sorted = List<StreakPeriod>.from(periods)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final display = sorted.take(15).toList(); // Cap for performance

    return Column(
      children: display.map((period) {
        final color = parseHexColor(period.colorHex) ?? AppColors.accentGold;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  period.habitName,
                  style: AppTypography.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${period.length}d  (${DateFormat('M/d').format(period.startDate)}–${DateFormat('M/d').format(period.endDate)})',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
