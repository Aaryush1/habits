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
        child: habitsAsync.when(
          loading: () => const LoadingIndicator(message: 'Loading analytics'),
          error: (error, stackTrace) => Center(
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
                final rate = summary.total == 0
                    ? 0.0
                    : summary.completed / summary.total;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.space16,
                        AppSpacing.space16,
                        AppSpacing.space16,
                        0,
                      ),
                      child: Text(
                        'Analytics',
                        style: AppTypography.displayMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),

                    // Summary cards row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'Completion',
                              value: '${(rate * 100).round()}%',
                              progress: rate,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Completed',
                              value:
                                  '${summary.completed}/${summary.total}',
                              progress: rate,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.space12),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Habits',
                              value: '${habits.length}',
                              progress: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),

                    // Legend
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                      ),
                      child: _buildLegend(),
                    ),
                    const SizedBox(height: AppSpacing.space12),

                    // Grid - fills remaining space
                    Expanded(
                      child: Scrollbar(
                        controller: _horizontalScrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space16,
                          ),
                          child: SizedBox(
                            width: 110.0 + (days.length * 30),
                            child: Column(
                              children: [
                                _HeaderRow(days: days),
                                const Divider(height: 1),
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(
                                      bottom: 16,
                                    ),
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
        if (!_isHabitScheduledOn(habit, day)) continue;
        total++;
        final completion =
            completionMap['${habit.id}_${day.toIso8601String()}'];
        if (completion != null &&
            completion.completionType != HabitCompletionType.skipped) {
          completed++;
        }
      }
    }
    return _Summary(total: total, completed: completed);
  }
}

// --- Private helpers ---

class _Summary {
  const _Summary({required this.total, required this.completed});
  final int total;
  final int completed;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.progress,
  });

  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.headlineLarge),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.days});
  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 110),
          ...days.map((day) {
            final isToday = day == today;
            return SizedBox(
              width: 30,
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(day)[0],
                    style: AppTypography.labelSmall.copyWith(
                      color: isToday
                          ? AppColors.accentGold
                          : AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: isToday
                        ? BoxDecoration(
                            color: AppColors.accentGold,
                            borderRadius: BorderRadius.circular(6),
                          )
                        : null,
                    child: Text(
                      '${day.day}',
                      style: AppTypography.labelSmall.copyWith(
                        color: isToday
                            ? AppColors.textInverse
                            : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HabitGridRow extends StatelessWidget {
  const _HabitGridRow({
    required this.habit,
    required this.days,
    required this.completionMap,
  });

  final Habit habit;
  final List<DateTime> days;
  final Map<String, Completion> completionMap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _parseColor(habit.colorHex) ?? AppColors.accentGold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    habit.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          ...days.map((day) {
            final key = '${habit.id}_${day.toIso8601String()}';
            final completion = completionMap[key];
            final scheduled = _isHabitScheduledOn(habit, day);
            final isCompleted = completion != null &&
                completion.completionType != HabitCompletionType.skipped;
            final isSkipped =
                completion?.completionType == HabitCompletionType.skipped;

            Color color;
            if (!scheduled) {
              color = AppColors.backgroundPrimary;
            } else if (isCompleted) {
              color = AppColors.completionGreen;
            } else if (isSkipped) {
              color = AppColors.skippedGray;
            } else {
              color = AppColors.backgroundTertiary;
            }

            return SizedBox(
              width: 30,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: AppColors.textInverse,
                        )
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final normalized = hex.replaceAll('#', '');
      final value = int.parse(
        normalized.length == 6 ? 'FF$normalized' : normalized,
        radix: 16,
      );
      return Color(value);
    } catch (_) {
      return null;
    }
  }
}

Widget _buildLegend() {
  Widget item(Color color, String label, {bool showCheck = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: showCheck
              ? const Icon(Icons.check_rounded,
                  size: 10, color: AppColors.textInverse)
              : null,
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
      item(AppColors.completionGreen, 'Done', showCheck: true),
      item(AppColors.skippedGray, 'Skipped'),
      item(AppColors.backgroundTertiary, 'Missed'),
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
