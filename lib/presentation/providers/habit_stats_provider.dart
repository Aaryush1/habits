import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/schedule_utils.dart';
import '../../domain/entities/completion.dart';
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
  final scheduledDays = countScheduledDays(habit, dateOnly(habit.createdAt), today);
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
  var bestStart = dateOnly(completions.first.date);
  var bestEnd = dateOnly(completions.first.date);

  var currentLength = 1;
  var currentStart = dateOnly(completions.first.date);
  var previous = dateOnly(completions.first.date);

  for (var i = 1; i < completions.length; i++) {
    final date = dateOnly(completions[i].date);
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

final Map<String, HabitStats> _habitStatsCache = {};
