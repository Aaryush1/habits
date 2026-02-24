import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/completion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../providers/effort_provider.dart';
import '../../providers/habit_strength_provider.dart';
import '../../providers/heatmap_provider.dart';
import '../../providers/rankings_provider.dart';
import '../../providers/streak_analytics_provider.dart';
import '../../providers/weekly_trends_provider.dart';
import '../../providers/completions_provider.dart';
import '../../providers/habits_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../scorecard/scorecard_screen.dart';
import 'score_history_screen.dart';
import 'weekly_trends_screen.dart';
import 'streaks_screen.dart';
import 'full_heatmap_screen.dart';
import 'habit_rankings_screen.dart';

class AnalyticsHubScreen extends ConsumerWidget {
  const AnalyticsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading analytics'),
          error: (e, _) => Center(
            child: Text('Failed to load data', style: AppTypography.bodyMedium),
          ),
          data: (habits) {
            if (habits.isEmpty) {
              return Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.space16),
                    Text('Analytics', style: AppTypography.displayMedium),
                    const Expanded(
                      child: EmptyState(
                        title: 'No habits yet',
                        description:
                            'Create habits from the Habits tab to see your analytics here.',
                        icon: Icons.analytics_outlined,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space16,
              ),
              children: [
                Text('Analytics', style: AppTypography.displayMedium),
                const SizedBox(height: AppSpacing.space20),
                _OverallScoreCard(ref: ref),
                const SizedBox(height: AppSpacing.space12),
                _WeeklyReportCard(ref: ref),
                const SizedBox(height: AppSpacing.space12),
                _StreaksCard(ref: ref),
                const SizedBox(height: AppSpacing.space12),
                _HeatmapCard(ref: ref),
                const SizedBox(height: AppSpacing.space12),
                _HabitRankingsCard(ref: ref),
                const SizedBox(height: AppSpacing.space12),
                _ScorecardPreviewCard(ref: ref),
                const SizedBox(height: AppSpacing.space24),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- Hub Cards ---

class _OverallScoreCard extends StatelessWidget {
  const _OverallScoreCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final strengthAsync = ref.watch(overallStrengthProvider);
    final effortAsync = ref.watch(dailyEffortProvider);

    return _HubCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ScoreHistoryScreen()),
      ),
      child: strengthAsync.when(
        loading: () => const _CardShimmer(height: 80),
        error: (_, _) => const _CardError(),
        data: (data) {
          final effort = effortAsync.valueOrNull;
          final showEffort =
              effort != null && effort.scheduledMinutes > 0;

          return Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: data.overallScore.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: AppColors.borderSubtle,
                      valueColor: AlwaysStoppedAnimation(
                        _scoreColor(data.overallScore),
                      ),
                    ),
                    Text(
                      '${(data.overallScore * 100).round()}',
                      style: AppTypography.headlineLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overall Score',
                        style: AppTypography.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Today: ${data.todayCompleted}/${data.todayTotal} done  |  Best streak: ${data.bestActiveStreak}d',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (showEffort) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${effort.completedMinutes}/${effort.scheduledMinutes} min invested',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.twoMinuteBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WeeklyReportCard extends StatelessWidget {
  const _WeeklyReportCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final trendsAsync = ref.watch(weeklyTrendsProvider);

    return _HubCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WeeklyTrendsScreen()),
      ),
      child: trendsAsync.when(
        loading: () => const _CardShimmer(height: 80),
        error: (_, _) => const _CardError(),
        data: (data) {
          final thisWeek = data.weeks.isNotEmpty ? data.weeks.last : null;
          final rate = thisWeek?.completionRate ?? 0;
          final delta = data.thisWeekDelta;
          final deltaPrefix = delta >= 0 ? '+' : '';
          final maxDaily = data.dailyCompletions.fold<int>(
            1,
            (a, b) => a > b ? a : b,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Report',
                          style: AppTypography.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${(rate * 100).round()}%',
                              style: AppTypography.headlineLarge,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: delta >= 0
                                    ? AppColors.completionGreenSubtle
                                    : AppColors.missedCoralSubtle,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$deltaPrefix${(delta * 100).round()}%',
                                style: AppTypography.labelSmall.copyWith(
                                  color: delta >= 0
                                      ? AppColors.completionGreen
                                      : AppColors.missedCoral,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space12),
              // Mini 7-day bar chart
              SizedBox(
                height: 32,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final value = i < data.dailyCompletions.length
                        ? data.dailyCompletions[i]
                        : 0;
                    final height =
                        maxDaily == 0 ? 0.0 : (value / maxDaily) * 28 + 4;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          height: height,
                          decoration: BoxDecoration(
                            color: value > 0
                                ? AppColors.accentGold
                                : AppColors.backgroundQuaternary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StreaksCard extends StatelessWidget {
  const _StreaksCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final streaksAsync = ref.watch(streakAnalyticsProvider);

    return _HubCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StreaksScreen()),
      ),
      child: streaksAsync.when(
        loading: () => const _CardShimmer(height: 72),
        error: (_, _) => const _CardError(),
        data: (data) {
          final top3 = data.activeStreaks.take(3).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Streaks',
                      style: AppTypography.headlineMedium,
                    ),
                  ),
                  if (data.atRisk.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.missedCoralSubtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${data.atRisk.length} at risk',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.missedCoral,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
              if (top3.isEmpty)
                Text(
                  'No active streaks yet',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                ...top3.map((streak) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: streak.length >= 7
                                ? AppColors.accentGold
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              streak.habitName,
                              style: AppTypography.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${streak.length}d',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.accentGold,
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 83)); // ~12 weeks
    final heatmapAsync = ref.watch(heatmapProvider(
      HeatmapQuery(startDate: start, endDate: today),
    ));

    return _HubCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FullHeatmapScreen()),
      ),
      child: heatmapAsync.when(
        loading: () => const _CardShimmer(height: 80),
        error: (_, _) => const _CardError(),
        data: (points) {
          // Align to start on Monday
          final firstDay = points.isNotEmpty ? points.first.date : today;
          final startPadding = (firstDay.weekday - 1) % 7;
          final maxCount = points.fold<int>(
            1,
            (a, p) => a > p.count ? a : p.count,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Activity',
                      style: AppTypography.headlineMedium,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
              SizedBox(
                height: 7 * 11.0 + 6 * 2.0, // 7 rows of 11px + 6 gaps of 2px
                child: Row(
                  children: _buildHeatmapColumns(
                    points,
                    startPadding,
                    maxCount,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildHeatmapColumns(
    List<HeatmapPoint> points,
    int startPadding,
    int maxCount,
  ) {
    // Build a flat list padded to start on Monday, then split into 7-row columns
    final cells = <int>[
      ...List.filled(startPadding, -1), // -1 = empty
      ...points.map((p) => p.count),
    ];

    final columns = <Widget>[];
    for (var col = 0; col * 7 < cells.length; col++) {
      final columnCells = <Widget>[];
      for (var row = 0; row < 7; row++) {
        final idx = col * 7 + row;
        if (idx >= cells.length || cells[idx] == -1) {
          columnCells.add(const SizedBox(width: 9, height: 9));
        } else {
          final count = cells[idx];
          final level = maxCount == 0
              ? 0
              : ((count / maxCount) * 4).ceil().clamp(0, 4);
          columnCells.add(Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: AppColors.heatmapGradient[level],
              borderRadius: BorderRadius.circular(2),
            ),
          ));
        }
      }
      columns.add(Column(
        mainAxisSize: MainAxisSize.min,
        children: columnCells,
      ));
    }
    return columns;
  }
}

class _HabitRankingsCard extends StatelessWidget {
  const _HabitRankingsCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final rankingsAsync = ref.watch(rankingsProvider);

    return _HubCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HabitRankingsScreen()),
      ),
      child: rankingsAsync.when(
        loading: () => const _CardShimmer(height: 64),
        error: (_, _) => const _CardError(),
        data: (ranked) {
          final top = ranked.take(2).toList();
          final bottom =
              ranked.length > 2 ? [ranked.last] : <RankedHabit>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Habit Rankings',
                      style: AppTypography.headlineMedium,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space8),
              if (ranked.isEmpty)
                Text(
                  'No data yet',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else ...[
                ...top.map((h) => _rankRow(h, isTop: true)),
                if (bottom.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '...',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  ...bottom.map((h) => _rankRow(h, isTop: false)),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _rankRow(RankedHabit h, {required bool isTop}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          _StatusBadge(status: h.status),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              h.habitName,
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${(h.completionRate * 100).round()}%',
            style: AppTypography.labelMedium.copyWith(
              color: isTop ? AppColors.completionGreen : AppColors.missedCoral,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScorecardPreviewCard extends StatelessWidget {
  const _ScorecardPreviewCard({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    final completionsAsync = ref.watch(
      completionsForRangeProvider(DateRangeKey(start: start, end: today)),
    );
    final habitsAsync = ref.watch(habitsProvider);

    return _HubCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ScorecardScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Scorecard',
                  style: AppTypography.headlineMedium,
                ),
              ),
              Text(
                '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(today)}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          habitsAsync.when(
            loading: () => const SizedBox(height: 24),
            error: (_, _) => const SizedBox.shrink(),
            data: (habits) => completionsAsync.when(
              loading: () => const SizedBox(height: 24),
              error: (_, _) => const SizedBox.shrink(),
              data: (completions) {
                final total = habits.length * 7;
                final done = completions
                    .where((c) =>
                        c.completionType != HabitCompletionType.skipped)
                    .length;
                return Text(
                  '${habits.length} habits tracked  |  $done/$total completed this week',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Shared Widgets ---

class _HubCard extends StatelessWidget {
  const _HubCard({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CardShimmer extends StatelessWidget {
  const _CardShimmer({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _CardError extends StatelessWidget {
  const _CardError();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Unable to load',
      style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final HabitStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      HabitStatus.onFire => (AppColors.completionGreen, Icons.local_fire_department_rounded),
      HabitStatus.steady => (AppColors.accentGold, Icons.trending_up_rounded),
      HabitStatus.needsAttention => (AppColors.accentGoldMuted, Icons.trending_down_rounded),
      HabitStatus.stalled => (AppColors.missedCoral, Icons.pause_circle_outline_rounded),
    };

    return Icon(icon, size: 16, color: color);
  }
}

Color _scoreColor(double score) {
  if (score > 0.75) return AppColors.completionGreen;
  if (score > 0.5) return AppColors.accentGold;
  return AppColors.missedCoral;
}
