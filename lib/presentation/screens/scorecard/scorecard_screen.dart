import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/completion.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/completions_provider.dart';
import '../../providers/habits_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_indicator.dart';

/// Analytics screen showing rolling completion grid.
class ScorecardScreen extends ConsumerStatefulWidget {
  const ScorecardScreen({super.key});

  @override
  ConsumerState<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends ConsumerState<ScorecardScreen> {
  final _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final days = _buildDays();
    final rangeKey = DateRangeKey(start: days.first, end: days.last);
    final completionsAsync = ref.watch(completionsForRangeProvider(rangeKey));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space16),
              Row(
                children: [
                  Expanded(
                    child: Text('Scorecard', style: AppTypography.displayMedium),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: () {
                      ref.invalidate(habitsProvider);
                      ref.invalidate(completionsForRangeProvider(rangeKey));
                    },
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              Text(
                'Rolling ${days.length}-day view',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Expanded(
                child: habitsAsync.when(
                  loading: () => const LoadingIndicator(message: 'Loading scorecard'),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      'Failed to load scorecard',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  data: (habits) {
                    if (habits.isEmpty) {
                      return const EmptyState(
                        title: 'No habits to score',
                        description: 'Create habits first, then track them here.',
                        icon: Icons.grid_view_outlined,
                      );
                    }

                    return completionsAsync.when(
                      loading: () =>
                          const LoadingIndicator(message: 'Loading completions'),
                      error: (error, stackTrace) => Center(
                        child: Text(
                          'Failed to load completions',
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      data: (completions) {
                        final completionMap = _buildCompletionMap(completions);
                        final summary = _buildSummary(
                          habits: habits,
                          days: days,
                          completionMap: completionMap,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${summary.completed}/${summary.total} checks complete',
                              style: AppTypography.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.space8),
                            LinearProgressIndicator(
                              value: summary.total == 0
                                  ? 0
                                  : summary.completed / summary.total,
                              minHeight: 6,
                              backgroundColor: AppColors.backgroundQuaternary,
                            ),
                            const SizedBox(height: AppSpacing.space16),
                            _buildLegend(),
                            const SizedBox(height: AppSpacing.space12),
                            Expanded(
                              child: Scrollbar(
                                controller: _horizontalScrollController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _horizontalScrollController,
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: 120 + (days.length * 34),
                                    child: Column(
                                      children: [
                                        _HeaderRow(days: days),
                                        const SizedBox(height: AppSpacing.space8),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: habits.length,
                                            itemBuilder: (context, index) {
                                              return _HabitGridRow(
                                                habit: habits[index],
                                                days: days,
                                                completionMap: completionMap,
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DateTime> _buildDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const length = 35;
    return List.generate(length, (index) {
      return today.subtract(Duration(days: length - index - 1));
    });
  }

  Map<String, Completion> _buildCompletionMap(List<Completion> completions) {
    final map = <String, Completion>{};
    for (final completion in completions) {
      final day = DateTime(
        completion.date.year,
        completion.date.month,
        completion.date.day,
      );
      map['${completion.habitId}_${day.toIso8601String()}'] = completion;
    }
    return map;
  }

  _Summary _buildSummary({
    required List<Habit> habits,
    required List<DateTime> days,
    required Map<String, Completion> completionMap,
  }) {
    var total = 0;
    var completed = 0;
    for (final habit in habits) {
      for (final day in days) {
        if (!_isHabitScheduledOn(habit, day)) {
          continue;
        }
        total++;
        final completion = completionMap['${habit.id}_${day.toIso8601String()}'];
        if (completion != null &&
            completion.completionType != HabitCompletionType.skipped) {
          completed++;
        }
      }
    }
    return _Summary(total: total, completed: completed);
  }
}

class _Summary {
  const _Summary({required this.total, required this.completed});

  final int total;
  final int completed;
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 120,
          child: Text('Habit'),
        ),
        ...days.map(
          (day) => SizedBox(
            width: 34,
            child: Column(
              children: [
                Text(DateFormat('E').format(day)[0], style: AppTypography.labelSmall),
                Text('${day.day}', style: AppTypography.labelSmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitGridRow extends ConsumerWidget {
  const _HabitGridRow({
    required this.habit,
    required this.days,
    required this.completionMap,
  });

  final Habit habit;
  final List<DateTime> days;
  final Map<String, Completion> completionMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              habit.name,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall,
            ),
          ),
          ...days.map((day) {
            final key = '${habit.id}_${day.toIso8601String()}';
            final completion = completionMap[key];
            final scheduled = _isHabitScheduledOn(habit, day);
            final isCompleted = completion != null &&
                completion.completionType != HabitCompletionType.skipped;
            final isSkipped = completion?.completionType == HabitCompletionType.skipped;
            final color = !scheduled
                ? AppColors.backgroundQuaternary
                : isCompleted
                    ? AppColors.completionGreen
                    : isSkipped
                        ? AppColors.skippedGray
                        : AppColors.borderSubtle;
            return SizedBox(
              width: 34,
              child: _cell(color: color),
            );
          }),
        ],
      ),
    );
  }

  Widget _cell({required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        height: 22,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

Widget _buildLegend() {
  Widget item(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }

  return Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      item(AppColors.completionGreen, 'Complete'),
      item(AppColors.skippedGray, 'Skipped'),
      item(AppColors.borderSubtle, 'Incomplete'),
      item(AppColors.backgroundQuaternary, 'Not scheduled'),
    ],
  );
}

bool _isHabitScheduledOn(Habit habit, DateTime date) {
  switch (habit.scheduleType) {
    case HabitScheduleType.daily:
      return true;
    case HabitScheduleType.weekly:
      final days = habit.scheduleDays ?? const <int>[];
      return days.contains(date.weekday - 1);
    case HabitScheduleType.monthly:
      final dates = habit.scheduleDates ?? const <int>[];
      return dates.contains(date.day);
  }
}
