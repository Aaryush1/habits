import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/schedule_utils.dart';
import '../../domain/entities/completion.dart';
import 'completions_provider.dart';
import 'repository_providers.dart';

class StreakAnalytics {
  const StreakAnalytics({
    required this.activeStreaks,
    required this.personalRecords,
    required this.atRisk,
    required this.streakTimeline,
  });

  final List<ActiveStreak> activeStreaks;
  final List<PersonalRecord> personalRecords;
  final List<AtRiskHabit> atRisk;
  final List<StreakPeriod> streakTimeline;
}

class ActiveStreak {
  const ActiveStreak({
    required this.habitId,
    required this.habitName,
    required this.length,
    this.colorHex,
  });

  final String habitId;
  final String habitName;
  final int length;
  final String? colorHex;
}

class PersonalRecord {
  const PersonalRecord({
    required this.habitId,
    required this.habitName,
    required this.length,
    required this.startDate,
    required this.endDate,
    this.colorHex,
  });

  final String habitId;
  final String habitName;
  final int length;
  final DateTime startDate;
  final DateTime endDate;
  final String? colorHex;
}

class AtRiskHabit {
  const AtRiskHabit({
    required this.habitId,
    required this.habitName,
    required this.currentStreak,
    this.colorHex,
  });

  final String habitId;
  final String habitName;
  final int currentStreak;
  final String? colorHex;
}

class StreakPeriod {
  const StreakPeriod({
    required this.habitId,
    required this.habitName,
    required this.startDate,
    required this.endDate,
    required this.length,
    this.colorHex,
  });

  final String habitId;
  final String habitName;
  final DateTime startDate;
  final DateTime endDate;
  final int length;
  final String? colorHex;
}

final streakAnalyticsProvider = FutureProvider<StreakAnalytics>((ref) async {
  final habitRepo = ref.watch(habitRepositoryProvider);
  final completionRepo = ref.watch(completionRepositoryProvider);
  final revision = ref.watch(completionsRevisionProvider);
  final now = DateTime.now();
  final today = dateOnly(now);
  final cacheKey = '${today.toIso8601String()}#$revision';

  final cached = _streakCache[cacheKey];
  if (cached != null) return cached;

  final habits = await habitRepo.getActiveHabits();
  final activeStreaks = <ActiveStreak>[];
  final personalRecords = <PersonalRecord>[];
  final atRisk = <AtRiskHabit>[];
  final allPeriods = <StreakPeriod>[];

  for (final habit in habits) {
    final streak = await completionRepo.getCurrentStreakForHabit(habit.id, today);

    if (streak > 0) {
      activeStreaks.add(ActiveStreak(
        habitId: habit.id,
        habitName: habit.name,
        length: streak,
        colorHex: habit.colorHex,
      ));

      // Check if at risk: scheduled today but not completed
      final todayCompletions = await completionRepo.getCompletionsForDate(today);
      final completedToday = todayCompletions.any(
        (c) =>
            c.habitId == habit.id &&
            c.completionType != HabitCompletionType.skipped,
      );
      if (isHabitScheduledOn(habit, today) && !completedToday) {
        atRisk.add(AtRiskHabit(
          habitId: habit.id,
          habitName: habit.name,
          currentStreak: streak,
          colorHex: habit.colorHex,
        ));
      }
    }

    // Compute all streak periods and find personal record
    final completions = await completionRepo.getCompletionsByHabit(habit.id);
    final successful = completions
        .where((c) => c.completionType != HabitCompletionType.skipped)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final periods = _findStreakPeriods(habit, successful);
    for (final period in periods) {
      allPeriods.add(StreakPeriod(
        habitId: habit.id,
        habitName: habit.name,
        startDate: period.start,
        endDate: period.end,
        length: period.length,
        colorHex: habit.colorHex,
      ));
    }

    if (periods.isNotEmpty) {
      final best = periods.reduce(
        (a, b) => a.length >= b.length ? a : b,
      );
      personalRecords.add(PersonalRecord(
        habitId: habit.id,
        habitName: habit.name,
        length: best.length,
        startDate: best.start,
        endDate: best.end,
        colorHex: habit.colorHex,
      ));
    }
  }

  activeStreaks.sort((a, b) => b.length.compareTo(a.length));
  personalRecords.sort((a, b) => b.length.compareTo(a.length));
  atRisk.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));

  final result = StreakAnalytics(
    activeStreaks: activeStreaks,
    personalRecords: personalRecords,
    atRisk: atRisk,
    streakTimeline: allPeriods,
  );

  _streakCache[cacheKey] = result;
  return result;
});

class _StreakSpan {
  const _StreakSpan({required this.start, required this.end, required this.length});
  final DateTime start;
  final DateTime end;
  final int length;
}

/// Find all consecutive-day streak periods from a sorted list of completions.
List<_StreakSpan> _findStreakPeriods(dynamic habit, List<Completion> completions) {
  if (completions.isEmpty) return const [];

  final periods = <_StreakSpan>[];
  var streakStart = dateOnly(completions.first.date);
  var previous = streakStart;
  var length = 1;

  for (var i = 1; i < completions.length; i++) {
    final date = dateOnly(completions[i].date);
    if (date == previous) continue; // same day duplicate

    final diff = date.difference(previous).inDays;
    if (diff == 1) {
      length++;
      previous = date;
    } else {
      if (length >= 2) {
        periods.add(_StreakSpan(start: streakStart, end: previous, length: length));
      }
      streakStart = date;
      previous = date;
      length = 1;
    }
  }

  // Close the last streak
  if (length >= 2) {
    periods.add(_StreakSpan(start: streakStart, end: previous, length: length));
  }

  return periods;
}

final Map<String, StreakAnalytics> _streakCache = {};
