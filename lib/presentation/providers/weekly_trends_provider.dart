import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/schedule_utils.dart';
import '../../domain/entities/completion.dart';
import 'completions_provider.dart';
import 'repository_providers.dart';

class WeeklyTrends {
  const WeeklyTrends({
    required this.weeks,
    required this.dayOfWeekRates,
    required this.thisWeekDelta,
    required this.dailyCompletions,
  });

  /// Completion rate per week for last N weeks (most recent last).
  final List<WeekSummary> weeks;

  /// Average completion rate by weekday (index 0=Mon, 6=Sun).
  final List<double> dayOfWeekRates;

  /// Delta between this week and last week (positive = improvement).
  final double thisWeekDelta;

  /// Per-day completions for the current week (for the 7-day bar chart).
  final List<int> dailyCompletions;
}

class WeekSummary {
  const WeekSummary({
    required this.weekStart,
    required this.completionRate,
    required this.completed,
    required this.scheduled,
    this.effortCompletedMin = 0,
    this.effortScheduledMin = 0,
  });

  final DateTime weekStart;
  final double completionRate;
  final int completed;
  final int scheduled;
  final int effortCompletedMin;
  final int effortScheduledMin;

  double get effortRate =>
      effortScheduledMin == 0 ? 0.0 : effortCompletedMin / effortScheduledMin;
}

class WeekDayDetail {
  const WeekDayDetail({
    required this.date,
    required this.completedHabits,
    required this.missedHabits,
    required this.totalScheduled,
  });

  final DateTime date;
  final List<String> completedHabits;
  final List<String> missedHabits;
  final int totalScheduled;
}

/// Number of weeks to compute trends for.
const int _weekCount = 4;

final weeklyTrendsProvider = FutureProvider<WeeklyTrends>((ref) async {
  final habitRepo = ref.watch(habitRepositoryProvider);
  final completionRepo = ref.watch(completionRepositoryProvider);
  final revision = ref.watch(completionsRevisionProvider);
  final now = DateTime.now();
  final today = dateOnly(now);
  final cacheKey = '${today.toIso8601String()}#$revision';

  final cached = _weeklyCache[cacheKey];
  if (cached != null) return cached;

  final habits = await habitRepo.getActiveHabits();
  if (habits.isEmpty) {
    const empty = WeeklyTrends(
      weeks: [],
      dayOfWeekRates: [0, 0, 0, 0, 0, 0, 0],
      thisWeekDelta: 0,
      dailyCompletions: [0, 0, 0, 0, 0, 0, 0],
    );
    return empty;
  }

  // Calculate the start of the current week (Monday)
  final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
  final rangeStart =
      currentWeekStart.subtract(Duration(days: (_weekCount - 1) * 7));

  final completions = await completionRepo.getCompletionsForDateRange(
    rangeStart,
    today,
  );

  // Build completion set for fast lookup
  final completedSet = <String>{};
  for (final c in completions) {
    if (c.completionType != HabitCompletionType.skipped) {
      final d = dateOnly(c.date);
      completedSet.add('${c.habitId}_${d.toIso8601String()}');
    }
  }

  // Compute per-week summaries
  final weeks = <WeekSummary>[];
  for (var w = 0; w < _weekCount; w++) {
    final weekStart = rangeStart.add(Duration(days: w * 7));
    var scheduled = 0;
    var completed = 0;
    var effortScheduled = 0;
    var effortCompleted = 0;

    for (var d = 0; d < 7; d++) {
      final day = weekStart.add(Duration(days: d));
      if (day.isAfter(today)) break;
      for (final habit in habits) {
        if (isHabitScheduledOn(habit, day)) {
          scheduled++;
          final key = '${habit.id}_${day.toIso8601String()}';
          final done = completedSet.contains(key);
          if (done) completed++;
          // Track effort for habits with durationMinutes
          if (habit.durationMinutes != null) {
            effortScheduled += habit.durationMinutes!;
            if (done) effortCompleted += habit.durationMinutes!;
          }
        }
      }
    }

    weeks.add(WeekSummary(
      weekStart: weekStart,
      completionRate: scheduled == 0 ? 0 : completed / scheduled,
      completed: completed,
      scheduled: scheduled,
      effortCompletedMin: effortCompleted,
      effortScheduledMin: effortScheduled,
    ));
  }

  // Day-of-week averages (across all weeks in range)
  final dayScheduled = List.filled(7, 0);
  final dayCompleted = List.filled(7, 0);
  var cursor = rangeStart;
  while (!cursor.isAfter(today)) {
    final dow = cursor.weekday - 1; // 0=Mon, 6=Sun
    for (final habit in habits) {
      if (isHabitScheduledOn(habit, cursor)) {
        dayScheduled[dow]++;
        final key = '${habit.id}_${cursor.toIso8601String()}';
        if (completedSet.contains(key)) dayCompleted[dow]++;
      }
    }
    cursor = cursor.add(const Duration(days: 1));
  }

  final dayOfWeekRates = List.generate(7, (i) {
    return dayScheduled[i] == 0 ? 0.0 : dayCompleted[i] / dayScheduled[i];
  });

  // This week's daily completions (for bar chart)
  final dailyCompletions = List.filled(7, 0);
  for (var d = 0; d < 7; d++) {
    final day = currentWeekStart.add(Duration(days: d));
    if (day.isAfter(today)) break;
    for (final habit in habits) {
      if (isHabitScheduledOn(habit, day)) {
        final key = '${habit.id}_${day.toIso8601String()}';
        if (completedSet.contains(key)) dailyCompletions[d]++;
      }
    }
  }

  // Week-over-week delta
  final thisWeekRate = weeks.isNotEmpty ? weeks.last.completionRate : 0.0;
  final lastWeekRate =
      weeks.length >= 2 ? weeks[weeks.length - 2].completionRate : 0.0;
  final delta = thisWeekRate - lastWeekRate;

  final result = WeeklyTrends(
    weeks: weeks,
    dayOfWeekRates: dayOfWeekRates,
    thisWeekDelta: delta,
    dailyCompletions: dailyCompletions,
  );

  _weeklyCache[cacheKey] = result;
  return result;
});

/// Detail for each day of the current week — used in the expanded view.
final weekDayDetailProvider =
    FutureProvider<List<WeekDayDetail>>((ref) async {
  final habitRepo = ref.watch(habitRepositoryProvider);
  final completionRepo = ref.watch(completionRepositoryProvider);
  ref.watch(completionsRevisionProvider);
  final now = DateTime.now();
  final today = dateOnly(now);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));

  final habits = await habitRepo.getActiveHabits();
  final completions = await completionRepo.getCompletionsForDateRange(
    weekStart,
    today,
  );

  final completedMap = <String, Set<String>>{};
  for (final c in completions) {
    if (c.completionType != HabitCompletionType.skipped) {
      final d = dateOnly(c.date).toIso8601String();
      completedMap.putIfAbsent(d, () => {}).add(c.habitId);
    }
  }

  final details = <WeekDayDetail>[];
  for (var d = 0; d < 7; d++) {
    final day = weekStart.add(Duration(days: d));
    if (day.isAfter(today)) break;

    final dayKey = day.toIso8601String();
    final doneIds = completedMap[dayKey] ?? {};
    final completedNames = <String>[];
    final missedNames = <String>[];

    for (final habit in habits) {
      if (isHabitScheduledOn(habit, day)) {
        if (doneIds.contains(habit.id)) {
          completedNames.add(habit.name);
        } else {
          missedNames.add(habit.name);
        }
      }
    }

    details.add(WeekDayDetail(
      date: day,
      completedHabits: completedNames,
      missedHabits: missedNames,
      totalScheduled: completedNames.length + missedNames.length,
    ));
  }

  return details;
});

final Map<String, WeeklyTrends> _weeklyCache = {};
