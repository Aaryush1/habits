import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/color_utils.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/habit_stats_provider.dart';
import '../../providers/habit_strength_provider.dart';
import '../../providers/habits_provider.dart';
import '../../providers/heatmap_provider.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/charts/progress_ring.dart';
import '../../widgets/common/loading_indicator.dart';
import '../analytics/full_heatmap_screen.dart';
import '../analytics/habit_rankings_screen.dart';
import 'habit_form_sheet.dart';

class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({
    super.key,
    required this.habitId,
  });

  final String habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitAsync = ref.watch(_habitProvider(habitId));
    final habitSnapshot = habitAsync.valueOrNull;
    final statsAsync = ref.watch(habitStatsProvider(habitId));
    final strengthAsync = ref.watch(overallStrengthProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 83)); // 12 weeks
    final heatmapAsync = ref.watch(
      heatmapProvider(
        HeatmapQuery(
          startDate: start,
          endDate: today,
          habitId: habitId,
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: habitAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading habit'),
          error: (_, _) => const Center(child: Text('Failed to load habit')),
          data: (habit) {
            if (habit == null) {
              return Center(
                child: Text('Habit not found', style: AppTypography.bodyMedium),
              );
            }

            final habitColor =
                parseHexColor(habit.colorHex) ?? AppColors.accentGold;

            return CustomScrollView(
              slivers: [
                // --- Color gradient header ---
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          habitColor.withValues(alpha: 0.25),
                          AppColors.backgroundPrimary,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space16,
                      AppSpacing.space16,
                      AppSpacing.space16,
                      AppSpacing.space20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back + Edit row
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: habitSnapshot == null
                                  ? null
                                  : () => _openEdit(context, ref, habitSnapshot),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space8),
                        // Habit name
                        Text(habit.name, style: AppTypography.displayMedium),
                        const SizedBox(height: AppSpacing.space8),
                        // Tags row: category, schedule, duration
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (habit.category != null)
                              _Pill(label: habit.category!, color: habitColor),
                            _Pill(
                              label: _scheduleLabel(habit),
                              color: AppColors.textTertiary,
                            ),
                            if (habit.durationMinutes != null)
                              _Pill(
                                label: '${habit.durationMinutes} min',
                                color: AppColors.twoMinuteBlue,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space16,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // --- Identity & Intentions Card ---
                      if (_hasIntentionData(habit))
                        _IntentionsCard(habit: habit, color: habitColor),

                      // --- Streak Hero ---
                      statsAsync.when(
                        loading: () => const SizedBox(height: 100),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (stats) => _StreakHero(
                          currentStreak: stats.currentStreak,
                          longestStreak: stats.longestStreak,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space16),

                      // --- Stats Grid (2x2) ---
                      statsAsync.when(
                        loading: () =>
                            const LoadingIndicator(message: 'Loading stats'),
                        error: (_, _) =>
                            const Text('Stats unavailable'),
                        data: (stats) {
                          // Find this habit's strength from the overall provider
                          final habitStrength =
                              strengthAsync.valueOrNull?.perHabit
                                  .where((e) => e.habitId == habitId)
                                  .firstOrNull
                                  ?.score;

                          return _StatsGrid(
                            completionRate: stats.completionRate,
                            habitStrength: habitStrength,
                            totalCompletions: stats.totalCompletions,
                            totalScheduledDays: stats.totalScheduledDays,
                            durationMinutes: habit.durationMinutes,
                            habitColor: habitColor,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.space20),

                      // --- Heatmap ---
                      Text('Activity', style: AppTypography.headlineMedium),
                      const SizedBox(height: AppSpacing.space8),
                      heatmapAsync.when(
                        loading: () => const SizedBox(height: 90),
                        error: (_, _) =>
                            const Text('Heatmap unavailable'),
                        data: (points) =>
                            _HabitHeatmap(points: points, color: habitColor),
                      ),
                      const SizedBox(height: AppSpacing.space24),

                      // --- Quick Actions ---
                      Text('Quick Actions', style: AppTypography.headlineMedium),
                      const SizedBox(height: AppSpacing.space8),
                      _QuickAction(
                        icon: Icons.leaderboard_rounded,
                        label: 'View in Rankings',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HabitRankingsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      _QuickAction(
                        icon: Icons.grid_on_rounded,
                        label: 'Full Heatmap',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FullHeatmapScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      _QuickAction(
                        icon: Icons.edit_rounded,
                        label: 'Edit Habit',
                        onTap: habitSnapshot == null
                            ? null
                            : () => _openEdit(context, ref, habitSnapshot),
                      ),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _hasIntentionData(Habit habit) {
    return habit.identityStatement != null ||
        habit.implementationTime != null ||
        habit.implementationLocation != null ||
        habit.twoMinuteVersion != null;
  }

  Future<void> _openEdit(
      BuildContext context, WidgetRef ref, Habit habit) async {
    final edited = await showHabitFormSheet(
      context: context,
      initialHabit: habit,
      defaultDisplayOrder: habit.displayOrder,
    );
    if (edited == null || !context.mounted) return;
    await ref.read(habitsProvider.notifier).updateHabit(edited);
    ref.invalidate(_habitProvider(habitId));
    ref.invalidate(habitStatsProvider(habitId));
  }

  String _scheduleLabel(Habit habit) {
    switch (habit.scheduleType) {
      case HabitScheduleType.daily:
        return 'Daily';
      case HabitScheduleType.weekly:
        final days = habit.scheduleDays ?? const <int>[];
        if (days.isEmpty) return 'Weekly';
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days.map((day) => labels[day]).join(', ');
      case HabitScheduleType.monthly:
        final dates = habit.scheduleDates ?? const <int>[];
        if (dates.isEmpty) return 'Monthly';
        return 'Monthly: ${dates.join(', ')}';
    }
  }
}

final _habitProvider =
    FutureProvider.family<Habit?, String>((ref, habitId) async {
  final repository = ref.watch(habitRepositoryProvider);
  return repository.getHabitById(habitId);
});

// --- Private Widgets ---

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _IntentionsCard extends StatelessWidget {
  const _IntentionsCard({required this.habit, required this.color});
  final Habit habit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space16),
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (habit.identityStatement != null) ...[
            Text(
              '"${habit.identityStatement}"',
              style: AppTypography.identityStatement.copyWith(color: color),
            ),
            const SizedBox(height: AppSpacing.space8),
          ],
          if (habit.implementationTime != null ||
              habit.implementationLocation != null) ...[
            Row(
              children: [
                if (habit.implementationTime != null) ...[
                  Icon(Icons.schedule_rounded,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    habit.implementationTime!,
                    style: AppTypography.bodySmall,
                  ),
                ],
                if (habit.implementationTime != null &&
                    habit.implementationLocation != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('|',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.borderMedium)),
                  ),
                if (habit.implementationLocation != null) ...[
                  Icon(Icons.place_rounded,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      habit.implementationLocation!,
                      style: AppTypography.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
          if (habit.twoMinuteVersion != null)
            Row(
              children: [
                Icon(Icons.bolt_rounded,
                    size: 14, color: AppColors.twoMinuteBlue),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Start with: ${habit.twoMinuteVersion}',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.twoMinuteBlue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({
    required this.currentStreak,
    required this.longestStreak,
  });

  final int currentStreak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    // Scale fire icon by streak length
    final fireSize = currentStreak >= 30
        ? 36.0
        : currentStreak >= 7
            ? 28.0
            : 20.0;
    final fireColor = currentStreak >= 30
        ? AppColors.accentGold
        : currentStreak >= 7
            ? AppColors.accentGold
            : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          // Current streak
          Expanded(
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: fireSize, color: fireColor),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$currentStreak',
                      style: AppTypography.dataLarge,
                    ),
                    Text(
                      'Current Streak',
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppColors.borderSubtle,
          ),
          // Longest streak
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_rounded,
                      size: 22, color: AppColors.accentGoldMuted),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$longestStreak',
                        style: AppTypography.dataMedium,
                      ),
                      Text(
                        'Longest',
                        style: AppTypography.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.completionRate,
    required this.habitStrength,
    required this.totalCompletions,
    required this.totalScheduledDays,
    required this.durationMinutes,
    required this.habitColor,
  });

  final double completionRate;
  final double? habitStrength;
  final int totalCompletions;
  final int totalScheduledDays;
  final int? durationMinutes;
  final Color habitColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                child: Column(
                  children: [
                    ProgressRing(
                      progress: completionRate,
                      label: '${(completionRate * 100).round()}%',
                      size: 64,
                      strokeWidth: 6,
                    ),
                    const SizedBox(height: 6),
                    Text('Completion Rate', style: AppTypography.labelSmall),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: _StatTile(
                child: Column(
                  children: [
                    ProgressRing(
                      progress: habitStrength ?? 0,
                      label: habitStrength != null
                          ? '${(habitStrength! * 100).round()}%'
                          : '--',
                      size: 64,
                      strokeWidth: 6,
                    ),
                    const SizedBox(height: 6),
                    Text('Habit Strength', style: AppTypography.labelSmall),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space8),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                child: Column(
                  children: [
                    Text('$totalCompletions',
                        style: AppTypography.dataMedium),
                    const SizedBox(height: 2),
                    Text('of $totalScheduledDays scheduled',
                        style: AppTypography.labelSmall),
                    const SizedBox(height: 2),
                    Text('Completions', style: AppTypography.labelSmall),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space8),
            Expanded(
              child: _StatTile(
                child: durationMinutes != null
                    ? Column(
                        children: [
                          Text(
                            '${totalCompletions * durationMinutes!}',
                            style: AppTypography.dataMedium
                                .copyWith(color: AppColors.twoMinuteBlue),
                          ),
                          const SizedBox(height: 2),
                          Text('min invested',
                              style: AppTypography.labelSmall),
                          const SizedBox(height: 2),
                          Text('Total Effort',
                              style: AppTypography.labelSmall),
                        ],
                      )
                    : Column(
                        children: [
                          Text('--',
                              style: AppTypography.dataMedium
                                  .copyWith(color: AppColors.textTertiary)),
                          const SizedBox(height: 2),
                          Text('Set duration',
                              style: AppTypography.labelSmall),
                          const SizedBox(height: 2),
                          Text('to track effort',
                              style: AppTypography.labelSmall),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Center(child: child),
    );
  }
}

class _HabitHeatmap extends StatelessWidget {
  const _HabitHeatmap({required this.points, required this.color});
  final List<HeatmapPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Text('No data yet',
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textTertiary));
    }

    final firstDay = points.first.date;
    final startPadding = (firstDay.weekday - 1) % 7;
    final maxCount =
        points.fold<int>(1, (a, p) => a > p.count ? a : p.count);

    // Build gradient from the habit's color
    final gradient = [
      AppColors.backgroundTertiary,
      color.withValues(alpha: 0.25),
      color.withValues(alpha: 0.45),
      color.withValues(alpha: 0.70),
      color,
    ];

    final cells = <int>[
      ...List.filled(startPadding, -1),
      ...points.map((p) => p.count),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: SizedBox(
        height: 7 * 11.0 + 6 * 2.0,
        child: Row(
          children: _buildColumns(cells, maxCount, gradient),
        ),
      ),
    );
  }

  List<Widget> _buildColumns(
      List<int> cells, int maxCount, List<Color> gradient) {
    final columns = <Widget>[];
    for (var col = 0; col * 7 < cells.length; col++) {
      final columnCells = <Widget>[];
      for (var row = 0; row < 7; row++) {
        final idx = col * 7 + row;
        if (idx >= cells.length || cells[idx] == -1) {
          columnCells.add(const SizedBox(width: 9, height: 9));
        } else {
          final count = cells[idx];
          final level =
              maxCount == 0 ? 0 : ((count / maxCount) * 4).ceil().clamp(0, 4);
          columnCells.add(Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: gradient[level],
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundSecondary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textTertiary),
              const SizedBox(width: 12),
              Text(label, style: AppTypography.bodyMedium),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
