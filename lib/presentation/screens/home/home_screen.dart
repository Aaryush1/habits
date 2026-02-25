import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../domain/entities/completion.dart';
import '../../../domain/entities/habit.dart';
import '../../providers/completions_provider.dart';
import '../../providers/current_streaks_provider.dart';
import '../../providers/effort_provider.dart';
import '../../providers/habits_provider.dart';
import '../../providers/today_completions_provider.dart';
import '../../providers/today_habits_provider.dart';
import '../../../app/router.dart';
import '../../providers/stacks_provider.dart';
import '../habits/habit_form_sheet.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/milestone_celebration.dart';
import '../../widgets/habit/habit_card.dart';
import '../habits/habit_detail_screen.dart';

/// Home screen showing today's habits.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayHabitsAsync = ref.watch(todayHabitsProvider);
    final todayCompletionsAsync = ref.watch(todayCompletionsProvider);
    final streaksAsync = ref.watch(currentStreaksProvider);
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
                      // Distinguish: no habits exist at all vs just none today.
                      final totalHabits =
                          ref.read(habitsProvider).valueOrNull?.length ?? 0;
                      if (totalHabits == 0) {
                        // Brand-new user — encourage first habit creation.
                        return EmptyState(
                          title: 'Your first habit starts here',
                          description:
                              'Small actions, done consistently, add up to remarkable results. What will you start today?',
                          icon: Icons.rocket_launch_outlined,
                          actionLabel: 'Create First Habit',
                          onAction: () async {
                            final newHabit = await showHabitFormSheet(
                              context: context,
                              defaultDisplayOrder: 0,
                            );
                            if (newHabit == null || !context.mounted) return;
                            await ref
                                .read(habitsProvider.notifier)
                                .createHabit(newHabit);
                          },
                        );
                      }
                      // Has habits, just none scheduled today.
                      return const EmptyState(
                        title: 'Nothing scheduled today',
                        description:
                            'Enjoy the rest — your habits will be here when you need them.',
                        icon: Icons.wb_sunny_outlined,
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
                      color: AppColors.accentGold,
                      onRefresh: () async {
                        await Future.wait([
                          ref.read(habitsProvider.notifier).reload(),
                          ref
                              .read(completionsProvider(todayKey).notifier)
                              .reload(),
                        ]);
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _DailyProgressCard(
                            completed: completedCount,
                            total: habits.length,
                            effortAsync: ref.watch(dailyEffortProvider),
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
                                  final streak = streaksAsync.valueOrNull?[habit.id] ?? 0;
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
                                      streakLength: streak,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          fadeSlideRoute(
                                            (_) => HabitDetailScreen(habitId: habit.id),
                                          ),
                                        );
                                      },
                                      onToggle: (_) {
                                        // Light haptic on every toggle.
                                        HapticFeedback.lightImpact();
                                        final wasCompleted = isCompleted;
                                        ref
                                            .read(completionsProvider(todayKey).notifier)
                                            .toggleCompletion(habitId: habit.id)
                                            .then((_) {
                                          // Only check milestone when marking complete.
                                          if (!wasCompleted && context.mounted) {
                                            // Wait two frames for streak provider to recompute.
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                if (!context.mounted) return;
                                                final newStreak =
                                                    ref.read(currentStreaksProvider).valueOrNull?[habit.id] ?? 0;
                                                showMilestoneCelebration(
                                                  context,
                                                  streak: newStreak,
                                                  habitName: habit.name,
                                                );
                                              });
                                            });

                                            // Chain prompt: check if next habit in stack is pending
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (!context.mounted) return;
                                              _showChainPromptIfNeeded(
                                                context,
                                                ref,
                                                completedHabitId: habit.id,
                                                completionByHabitId: completionByHabitId,
                                              );
                                            });
                                          }
                                        });
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
        onPressed: () async {
          final habitsCount = ref.read(habitsProvider).valueOrNull?.length ?? 0;
          final newHabit = await showHabitFormSheet(
            context: context,
            defaultDisplayOrder: habitsCount,
          );
          if (newHabit == null) return;
          await ref.read(habitsProvider.notifier).createHabit(newHabit);
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

  /// Checks if the completed habit is part of a stack and if the next habit
  /// in that stack is not yet completed today. If so, shows a floating snackbar.
  static void _showChainPromptIfNeeded(
    BuildContext context,
    WidgetRef ref, {
    required String completedHabitId,
    required Map<String, bool> completionByHabitId,
  }) {
    final stacks = ref.read(stacksProvider).valueOrNull ?? [];

    for (final stack in stacks) {
      final idx = stack.habitIds.indexOf(completedHabitId);
      if (idx < 0 || idx >= stack.habitIds.length - 1) continue;

      final nextHabitId = stack.habitIds[idx + 1];
      final nextAlreadyDone = completionByHabitId[nextHabitId] ?? false;
      if (nextAlreadyDone) continue;

      // Find next habit name
      final allHabits = ref.read(habitsProvider).valueOrNull ?? [];
      final nextHabit = allHabits.where((h) => h.id == nextHabitId).firstOrNull;
      if (nextHabit == null) continue;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          content: Text(
            '${stack.iconEmoji != null ? '${stack.iconEmoji!} ' : ''}'
            'Next in "${stack.name}": ${nextHabit.name}',
          ),
        ),
      );
      // Only show one prompt
      return;
    }
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({
    required this.completed,
    required this.total,
    required this.effortAsync,
  });

  final int completed;
  final int total;
  final AsyncValue<DailyEffort> effortAsync;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    final effort = effortAsync.valueOrNull;
    final showEffort =
        effort != null && effort.scheduledMinutes > 0;

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
          Text('$completed of $total complete',
              style: AppTypography.headlineLarge),
          if (showEffort) ...[
            const SizedBox(height: 4),
            Text(
              '${effort.completedMinutes} of ${effort.scheduledMinutes} min invested',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.twoMinuteBlue),
            ),
          ],
          const SizedBox(height: AppSpacing.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.backgroundQuaternary,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
            ),
          ),
          if (showEffort) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: effort.rate,
                minHeight: 4,
                backgroundColor: AppColors.backgroundQuaternary,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.twoMinuteBlue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
