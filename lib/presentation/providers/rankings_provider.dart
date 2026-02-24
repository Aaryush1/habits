import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/schedule_utils.dart';
import '../../domain/entities/completion.dart';
import 'completions_provider.dart';
import 'repository_providers.dart';

enum HabitStatus { onFire, steady, needsAttention, stalled }

class RankedHabit {
  const RankedHabit({
    required this.habitId,
    required this.habitName,
    required this.completionRate,
    required this.currentStreak,
    required this.totalCompletions,
    required this.habitStrength,
    required this.status,
    this.colorHex,
  });

  final String habitId;
  final String habitName;
  final double completionRate;
  final int currentStreak;
  final int totalCompletions;
  final double habitStrength;
  final HabitStatus status;
  final String? colorHex;
}

enum RankingSortField { completionRate, currentStreak, totalCompletions, habitStrength }

final rankingsProvider = FutureProvider<List<RankedHabit>>((ref) async {
  final habitRepo = ref.watch(habitRepositoryProvider);
  final completionRepo = ref.watch(completionRepositoryProvider);
  final revision = ref.watch(completionsRevisionProvider);
  final now = DateTime.now();
  final today = dateOnly(now);
  final cacheKey = '${today.toIso8601String()}#$revision';

  final cached = _rankingsCache[cacheKey];
  if (cached != null) return cached;

  final habits = await habitRepo.getActiveHabits();
  final ranked = <RankedHabit>[];

  for (final habit in habits) {
    final completions = await completionRepo.getCompletionsByHabit(habit.id);
    final successful = completions
        .where((c) => c.completionType != HabitCompletionType.skipped)
        .toList();
    final successfulDates = successful.map((c) => dateOnly(c.date)).toSet();

    final createdDate = dateOnly(habit.createdAt);
    final scheduledDays = countScheduledDays(habit, createdDate, today);
    final completionRate =
        scheduledDays == 0 ? 0.0 : successful.length / scheduledDays;

    final streak =
        await completionRepo.getCurrentStreakForHabit(habit.id, today);

    // Compute strength using same algorithm as habit_strength_provider
    final strength = _computeStrength(habit, createdDate, today, successfulDates);

    final status = _classifyStatus(completionRate);

    ranked.add(RankedHabit(
      habitId: habit.id,
      habitName: habit.name,
      completionRate: completionRate,
      currentStreak: streak,
      totalCompletions: successful.length,
      habitStrength: strength,
      status: status,
      colorHex: habit.colorHex,
    ));
  }

  // Default sort: by completion rate descending
  ranked.sort((a, b) => b.completionRate.compareTo(a.completionRate));

  _rankingsCache[cacheKey] = ranked;
  return ranked;
});

HabitStatus _classifyStatus(double rate) {
  if (rate > 0.9) return HabitStatus.onFire;
  if (rate > 0.7) return HabitStatus.steady;
  if (rate > 0.5) return HabitStatus.needsAttention;
  return HabitStatus.stalled;
}

double _computeStrength(
  dynamic habit,
  DateTime createdDate,
  DateTime endDate,
  Set<DateTime> successfulDates,
) {
  const decay = 0.05;
  var score = 0.0;
  var cursor = createdDate;
  while (!cursor.isAfter(endDate)) {
    if (isHabitScheduledOn(habit, cursor)) {
      final completed = successfulDates.contains(cursor);
      score = score * (1 - decay) + (completed ? decay : 0);
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return (score * 20).clamp(0.0, 1.0);
}

final Map<String, List<RankedHabit>> _rankingsCache = {};
