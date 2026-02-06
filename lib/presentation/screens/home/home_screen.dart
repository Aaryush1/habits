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
import '../../providers/today_completions_provider.dart';
import '../../providers/today_habits_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/habit/habit_card.dart';
import '../habits/habit_detail_screen.dart';

/// Home screen showing today's habits.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayHabitsAsync = ref.watch(todayHabitsProvider);
    final todayCompletionsAsync = ref.watch(todayCompletionsProvider);
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space16),
              Text(
                DateFormat('EEEE').format(now),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                DateFormat('MMMM d').format(now),
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: AppSpacing.space24),
              Expanded(
                child: todayHabitsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      'Failed to load habits',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  data: (habits) {
                    if (habits.isEmpty) {
                      return EmptyState(
                        title: 'No habits today',
                        description:
                            'Create a habit and it will show up here when scheduled.',
                        icon: Icons.event_available_outlined,
                        actionLabel: 'Go To Habits',
                        onAction: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Use the Habits tab to create one'),
                            ),
                          );
                        },
                      );
                    }

                    final completionByHabitId = <String, bool>{};
                    todayCompletionsAsync.whenData((completions) {
                      for (final completion in completions) {
                        completionByHabitId[completion.habitId] =
                            completion.completionType != HabitCompletionType.skipped;
                      }
                    });

                    final completedCount = habits
                        .where((habit) => completionByHabitId[habit.id] ?? false)
                        .length;
                    final groupedHabits = _groupByCategory(habits);

                    return RefreshIndicator(
                      onRefresh: () => ref.read(habitsProvider.notifier).reload(),
                      child: ListView(
                        children: [
                          _DailyProgressCard(
                            completed: completedCount,
                            total: habits.length,
                          ),
                          const SizedBox(height: AppSpacing.space16),
                          const SectionHeader(
                            title: 'Today\'s Habits',
                            subtitle: 'Tap to mark complete',
                          ),
                          const SizedBox(height: AppSpacing.space12),
                          ...groupedHabits.entries.map((entry) {
                            final category = entry.key;
                            final categoryHabits = entry.value;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.space8,
                                  ),
                                  child: Text(
                                    category,
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                ...categoryHabits.map((habit) {
                                  final isCompleted =
                                      completionByHabitId[habit.id] ?? false;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.space12,
                                    ),
                                    child: HabitCard(
                                      id: habit.id,
                                      name: habit.name,
                                      scheduleLabel: _scheduleLabel(habit),
                                      isCompleted: isCompleted,
                                      identityStatement: habit.identityStatement,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                HabitDetailScreen(habitId: habit.id),
                                          ),
                                        );
                                      },
                                      onToggle: (_) {
                                        ref
                                            .read(completionsProvider(todayKey).notifier)
                                            .toggleCompletion(habitId: habit.id);
                                      },
                                    ),
                                  );
                                }),
                              ],
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'home_fab',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create habits from the Habits tab')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Habit'),
      ),
    );
  }

  Map<String, List<Habit>> _groupByCategory(List<Habit> habits) {
    final grouped = <String, List<Habit>>{};
    for (final habit in habits) {
      final category = (habit.category == null || habit.category!.isEmpty)
          ? 'General'
          : habit.category!;
      grouped.putIfAbsent(category, () => <Habit>[]).add(habit);
    }
    return grouped;
  }

  String _scheduleLabel(Habit habit) {
    switch (habit.scheduleType) {
      case HabitScheduleType.daily:
        return 'Daily';
      case HabitScheduleType.weekly:
        final days = habit.scheduleDays ?? const <int>[];
        if (days.isEmpty) {
          return 'Weekly';
        }
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days.map((day) => labels[day]).join(', ');
      case HabitScheduleType.monthly:
        final dates = habit.scheduleDates ?? const <int>[];
        if (dates.isEmpty) {
          return 'Monthly';
        }
        return 'Dates: ${dates.join(', ')}';
    }
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: AppSpacing.borderRadiusLarge,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Progress',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text('$completed of $total complete', style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.backgroundQuaternary,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
            ),
          ),
        ],
      ),
    );
  }
}
