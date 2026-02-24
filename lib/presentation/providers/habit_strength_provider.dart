import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/schedule_utils.dart';
import '../../domain/entities/completion.dart';
import 'completions_provider.dart';
import 'repository_providers.dart';

/// Decay factor for the habit strength algorithm.
/// Higher = faster response to changes, lower = more stable score.
const double _decayFactor = 0.05;

/// A single habit's strength score at a point in time.
class HabitStrengthPoint {
  const HabitStrengthPoint({required this.date, required this.score});
  final DateTime date;
  final double score;
}

/// Overall strength summary across all habits.
class OverallStrength {
  const OverallStrength({
    required this.overallScore,
    required this.perHabit,
    required this.todayCompleted,
    required this.todayTotal,
    required this.bestActiveStreak,
  });

  final double overallScore;
  final List<HabitStrengthEntry> perHabit;
  final int todayCompleted;
  final int todayTotal;
  final int bestActiveStreak;
}

class HabitStrengthEntry {
  const HabitStrengthEntry({
    required this.habitId,
    required this.habitName,
    required this.score,
    this.colorHex,
  });

  final String habitId;
  final String habitName;
  final double score;
  final String? colorHex;
}

/// Computes the current habit strength snapshot for the hub card.
final overallStrengthProvider = FutureProvider<OverallStrength>((ref) async {
  final habitRepo = ref.watch(habitRepositoryProvider);
  final completionRepo = ref.watch(completionRepositoryProvider);
  final revision = ref.watch(completionsRevisionProvider);
  final now = DateTime.now();
  final today = dateOnly(now);
  final cacheKey = '${today.toIso8601String()}#$revision';

  final cached = _overallCache[cacheKey];
  if (cached != null) return cached;

  final habits = await habitRepo.getActiveHabits();
  if (habits.isEmpty) {
    const empty = OverallStrength(
      overallScore: 0,
      perHabit: [],
      todayCompleted: 0,
      todayTotal: 0,
      bestActiveStreak: 0,
    );
    return empty;
  }

  final entries = <HabitStrengthEntry>[];
  var todayCompleted = 0;
  var todayTotal = 0;
  var bestStreak = 0;

  for (final habit in habits) {
    final completions = await completionRepo.getCompletionsByHabit(habit.id);
    final successful = completions
        .where((c) => c.completionType != HabitCompletionType.skipped)
        .map((c) => dateOnly(c.date))
        .toSet();

    final createdDate = dateOnly(habit.createdAt);
    final score = _computeStrength(habit, createdDate, today, successful);

    entries.add(HabitStrengthEntry(
      habitId: habit.id,
      habitName: habit.name,
      score: score,
      colorHex: habit.colorHex,
    ));

    if (isHabitScheduledOn(habit, today)) {
      todayTotal++;
      if (successful.contains(today)) todayCompleted++;
    }

    final streak =
        await completionRepo.getCurrentStreakForHabit(habit.id, today);
    if (streak > bestStreak) bestStreak = streak;
  }

  entries.sort((a, b) => b.score.compareTo(a.score));

  final overallScore = entries.isEmpty
      ? 0.0
      : entries.fold<double>(0, (sum, e) => sum + e.score) / entries.length;

  final result = OverallStrength(
    overallScore: overallScore,
    perHabit: entries,
    todayCompleted: todayCompleted,
    todayTotal: todayTotal,
    bestActiveStreak: bestStreak,
  );

  _overallCache[cacheKey] = result;
  return result;
});

/// Computes historical score data points for the score history chart.
final scoreHistoryProvider =
    FutureProvider.family<List<HabitStrengthPoint>, int>((ref, days) async {
  final habitRepo = ref.watch(habitRepositoryProvider);
  final completionRepo = ref.watch(completionRepositoryProvider);
  final revision = ref.watch(completionsRevisionProvider);
  final now = DateTime.now();
  final today = dateOnly(now);
  final cacheKey = '${today.toIso8601String()}|$days#$revision';

  final cached = _historyCache[cacheKey];
  if (cached != null) return cached;

  final habits = await habitRepo.getActiveHabits();
  if (habits.isEmpty) return const [];

  final startDate = today.subtract(Duration(days: days));

  // Gather all completions in range for all habits
  final allCompletionSets = <String, Set<DateTime>>{};
  for (final habit in habits) {
    final completions = await completionRepo.getCompletionsByHabit(habit.id);
    allCompletionSets[habit.id] = completions
        .where((c) => c.completionType != HabitCompletionType.skipped)
        .map((c) => dateOnly(c.date))
        .toSet();
  }

  // For each day in range, compute average strength across all habits
  final points = <HabitStrengthPoint>[];
  var cursor = startDate;
  while (!cursor.isAfter(today)) {
    var totalScore = 0.0;
    var activeCount = 0;

    for (final habit in habits) {
      final createdDate = dateOnly(habit.createdAt);
      if (cursor.isBefore(createdDate)) continue;

      final score = _computeStrength(
        habit,
        createdDate,
        cursor,
        allCompletionSets[habit.id] ?? {},
      );
      totalScore += score;
      activeCount++;
    }

    final avgScore = activeCount == 0 ? 0.0 : totalScore / activeCount;
    points.add(HabitStrengthPoint(date: cursor, score: avgScore));
    cursor = cursor.add(const Duration(days: 1));
  }

  _historyCache[cacheKey] = points;
  return points;
});

/// Core algorithm: compute habit strength score from creation to endDate.
/// Uses exponential moving average: score = score * (1 - decay) + (completed ? decay : 0)
double _computeStrength(
  dynamic habit,
  DateTime createdDate,
  DateTime endDate,
  Set<DateTime> successfulDates,
) {
  var score = 0.0;
  var cursor = createdDate;
  while (!cursor.isAfter(endDate)) {
    if (isHabitScheduledOn(habit, cursor)) {
      final completed = successfulDates.contains(cursor);
      score = score * (1 - _decayFactor) + (completed ? _decayFactor : 0);
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  // Normalize: after enough completions score approaches 1.0, scale to percentage
  // The max possible score with perfect consistency approaches _decayFactor / _decayFactor = 1.0
  // But for display purposes we want 100% for perfect consistency
  return (score * 20).clamp(0.0, 1.0); // Scale factor to make scores meaningful
}

final Map<String, OverallStrength> _overallCache = {};
final Map<String, List<HabitStrengthPoint>> _historyCache = {};
