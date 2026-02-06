import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/completion.dart';
import '../../domain/entities/habit.dart';
import 'completions_provider.dart';
import 'repository_providers.dart';

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalHabits,
    required this.completedToday,
    required this.todayCompletionRate,
    required this.weekCompletionRate,
    required this.bestCurrentStreak,
  });

  final int totalHabits;
  final int completedToday;
  final double todayCompletionRate;
  final double weekCompletionRate;
  final int bestCurrentStreak;
}

final analyticsProvider = FutureProvider<AnalyticsSummary>((ref) async {
  final habitRepository = ref.watch(habitRepositoryProvider);
  final completionRepository = ref.watch(completionRepositoryProvider);
  final revision = ref.watch(completionsRevisionProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final cacheKey = '${today.toIso8601String()}#$revision';

  final cached = _analyticsCache[cacheKey];
  if (cached != null) {
    return cached;
  }

  final habits = await habitRepository.getActiveHabits();
  final completionsToday = await completionRepository.getCompletionsForDate(today);
  final successfulToday = completionsToday
      .where((c) => c.completionType != HabitCompletionType.skipped)
      .map((c) => c.habitId)
      .toSet();

  final scheduledToday =
      habits.where((habit) => _isHabitScheduledOn(habit, today)).length;
  final completedToday = habits
      .where((habit) => successfulToday.contains(habit.id))
      .length;

  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  final completionsWeek =
      await completionRepository.getCompletionsForDateRange(weekStart, weekEnd);
  final successfulByDay = <DateTime, Set<String>>{};
  for (final completion in completionsWeek) {
    if (completion.completionType == HabitCompletionType.skipped) {
      continue;
    }
    final day = DateTime(
      completion.date.year,
      completion.date.month,
      completion.date.day,
    );
    successfulByDay.putIfAbsent(day, () => <String>{}).add(completion.habitId);
  }

  var weekScheduled = 0;
  var weekCompleted = 0;
  for (var i = 0; i < 7; i++) {
    final day = weekStart.add(Duration(days: i));
    final dayCompletions = successfulByDay[day] ?? <String>{};
    for (final habit in habits) {
      if (_isHabitScheduledOn(habit, day)) {
        weekScheduled++;
        if (dayCompletions.contains(habit.id)) {
          weekCompleted++;
        }
      }
    }
  }

  final streaks = await Future.wait(
    habits.map(
      (habit) => completionRepository.getCurrentStreakForHabit(habit.id, today),
    ),
  );
  final bestCurrentStreak = streaks.isEmpty
      ? 0
      : streaks.reduce((value, element) => value > element ? value : element);

  final summary = AnalyticsSummary(
    totalHabits: habits.length,
    completedToday: completedToday,
    todayCompletionRate: scheduledToday == 0 ? 0 : completedToday / scheduledToday,
    weekCompletionRate: weekScheduled == 0 ? 0 : weekCompleted / weekScheduled,
    bestCurrentStreak: bestCurrentStreak,
  );

  _analyticsCache[cacheKey] = summary;
  return summary;
});

final Map<String, AnalyticsSummary> _analyticsCache = {};

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
