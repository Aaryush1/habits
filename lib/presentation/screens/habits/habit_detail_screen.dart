import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/habit_stats_provider.dart';
import '../../providers/habits_provider.dart';
import '../../providers/heatmap_provider.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/charts/heatmap_grid.dart';
import '../../widgets/charts/progress_ring.dart';
import '../../widgets/charts/stat_card.dart';
import '../../widgets/common/loading_indicator.dart';
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
    final today = DateTime.now();
    final start = today.subtract(const Duration(days: 34));
    final heatmapAsync = ref.watch(
      heatmapProvider(
        HeatmapQuery(
          startDate: DateTime(start.year, start.month, start.day),
          endDate: DateTime(today.year, today.month, today.day),
          habitId: habitId,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: habitSnapshot == null
                ? null
                : () async {
                    final edited = await showHabitFormSheet(
                      context: context,
                      initialHabit: habitSnapshot,
                      defaultDisplayOrder: habitSnapshot.displayOrder,
                    );
                    if (edited == null || !context.mounted) {
                      return;
                    }
                    await ref.read(habitsProvider.notifier).updateHabit(edited);
                    ref.invalidate(_habitProvider(habitId));
                    ref.invalidate(habitStatsProvider(habitId));
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: habitAsync.when(
            loading: () => const LoadingIndicator(message: 'Loading habit'),
            error: (error, stackTrace) => Center(
              child: Text(
                'Failed to load habit',
                style: AppTypography.bodyMedium,
              ),
            ),
            data: (habit) {
              if (habit == null) {
                return Center(
                  child: Text('Habit not found', style: AppTypography.bodyMedium),
                );
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 80),
                children: [
                  Text(habit.name, style: AppTypography.displayMedium),
                  const SizedBox(height: AppSpacing.space8),
                  Text(_scheduleLabel(habit), style: AppTypography.bodyMedium),
                  if (habit.identityStatement != null) ...[
                    const SizedBox(height: AppSpacing.space12),
                    Text(
                      '"${habit.identityStatement}"',
                      style: AppTypography.bodyMedium.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.accentGold,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.space20),
                  statsAsync.when(
                    loading: () =>
                        const LoadingIndicator(message: 'Loading analytics'),
                    error: (error, stackTrace) =>
                        const Text('Stats unavailable right now'),
                    data: (stats) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analytics Glimpse',
                            style: AppTypography.headlineLarge,
                          ),
                          const SizedBox(height: AppSpacing.space12),
                          Row(
                            children: [
                              ProgressRing(
                                progress: stats.completionRate,
                                label: '${(stats.completionRate * 100).round()}%',
                                size: 112,
                                strokeWidth: 10,
                              ),
                              const SizedBox(width: AppSpacing.space12),
                              Expanded(
                                child: Column(
                                  children: [
                                    StatCard(
                                      label: 'Current Streak',
                                      value: '${stats.currentStreak}',
                                    ),
                                    const SizedBox(height: AppSpacing.space8),
                                    StatCard(
                                      label: 'Longest Streak',
                                      value: '${stats.longestStreak}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space16),
                          StatCard(
                            label: 'Completions',
                            value: '${stats.totalCompletions}',
                            subtitle:
                                'Scheduled: ${stats.totalScheduledDays} days',
                          ),
                          const SizedBox(height: AppSpacing.space16),
                          heatmapAsync.when(
                            loading: () => const LoadingIndicator(),
                            error: (error, stackTrace) =>
                                const Text('Heatmap unavailable'),
                            data: (points) => HeatmapGrid(
                              values: points
                                  .map((point) => point.count > 0 ? 4 : 0)
                                  .toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _scheduleLabel(Habit habit) {
    switch (habit.scheduleType) {
      case HabitScheduleType.daily:
        return 'Daily schedule';
      case HabitScheduleType.weekly:
        final days = habit.scheduleDays ?? const <int>[];
        if (days.isEmpty) {
          return 'Weekly schedule';
        }
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return 'Weekly: ${days.map((day) => labels[day]).join(', ')}';
      case HabitScheduleType.monthly:
        final dates = habit.scheduleDates ?? const <int>[];
        if (dates.isEmpty) {
          return 'Monthly schedule';
        }
        return 'Monthly: ${dates.join(', ')}';
    }
  }
}

final _habitProvider = FutureProvider.family<Habit?, String>((ref, habitId) async {
  final repository = ref.watch(habitRepositoryProvider);
  return repository.getHabitById(habitId);
});
