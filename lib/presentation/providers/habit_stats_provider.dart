import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/completion.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_stats.dart';
import 'completions_provider.dart';
import 'repository_providers.dart';

final habitStatsProvider =
    FutureProvider.family<HabitStats, String>((ref, habitId) async {
  final habitRepository = ref.watch(habitRepositoryProvider);
  final completionRepository = ref.watch(completionRepositoryProvider);
  final revision = ref.watch(completionsRevisionProvider);
  final cacheKey = '$habitId#$revision';
  final cached = _habitStatsCache[cacheKey];
  if (cached != null) {
    return cached;
  }

  final habit = await habitRepository.getHabitById(habitId);
  if (habit == null) {
    const empty = HabitStats(
      habitId: '',
      currentStreak: 0,
      longestStreak: 0,
      totalCompletions: 0,
      totalScheduledDays: 0,
      completionRate: 0,
    );
    return empty;
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final completions = await completionRepository.getCompletionsByHabit(habitId);
  final successful = completions
      .where((c) => c.completionType != HabitCompletionType.skipped)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final currentStreak =
      await completionRepository.getCurrentStreakForHabit(habitId, today);
  final longest = _calculateLongestStreak(successful);
  final scheduledDays = _countScheduledDays(habit, today);
  final totalCompletions = successful.length;
  final completionRate =
      scheduledDays == 0 ? 0.0 : totalCompletions / scheduledDays;
  final lastCompletedAt =
      successful.isEmpty ? null : successful.last.completedAt;

  final stats = HabitStats(
    habitId: habit.id,
    currentStreak: currentStreak,
    longestStreak: longest.length,
    longestStreakStart: longest.start,
    longestStreakEnd: longest.end,
    totalCompletions: totalCompletions,
    totalScheduledDays: scheduledDays,
    completionRate: completionRate,
    lastCompletedAt: lastCompletedAt,
  );

  _habitStatsCache[cacheKey] = stats;
  return stats;
});

class _StreakWindow {
  const _StreakWindow({required this.length, this.start, this.end});

  final int length;
  final DateTime? start;
  final DateTime? end;
}

_StreakWindow _calculateLongestStreak(List<Completion> completions) {
  if (completions.isEmpty) {
    return const _StreakWindow(length: 0);
  }

  var bestLength = 1;
  var bestStart = _asDateOnly(completions.first.date);
  var bestEnd = _asDateOnly(completions.first.date);

  var currentLength = 1;
  var currentStart = _asDateOnly(completions.first.date);
  var previous = _asDateOnly(completions.first.date);

  for (var i = 1; i < completions.length; i++) {
    final date = _asDateOnly(completions[i].date);
    final dayDiff = date.difference(previous).inDays;
    if (dayDiff == 1) {
      currentLength++;
    } else if (dayDiff > 1) {
      currentLength = 1;
      currentStart = date;
    }
    if (currentLength > bestLength) {
      bestLength = currentLength;
      bestStart = currentStart;
      bestEnd = date;
    }
    previous = date;
  }

  return _StreakWindow(length: bestLength, start: bestStart, end: bestEnd);
}

int _countScheduledDays(Habit habit, DateTime endDate) {
  final startDate = DateTime(
    habit.createdAt.year,
    habit.createdAt.month,
    habit.createdAt.day,
  );
  var count = 0;
  var cursor = startDate;
  while (!cursor.isAfter(endDate)) {
    if (_isHabitScheduledOn(habit, cursor)) {
      count++;
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return count;
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

DateTime _asDateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

final Map<String, HabitStats> _habitStatsCache = {};
