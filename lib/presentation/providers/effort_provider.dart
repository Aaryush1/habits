import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/schedule_utils.dart';
import '../../domain/entities/completion.dart';
import 'completions_provider.dart';
import 'habits_provider.dart';
import 'repository_providers.dart';

/// Daily effort: completed minutes / scheduled minutes for today.
class DailyEffort {
  const DailyEffort({
    required this.completedMinutes,
    required this.scheduledMinutes,
  });

  final int completedMinutes;
  final int scheduledMinutes;

  double get rate =>
      scheduledMinutes == 0 ? 0.0 : completedMinutes / scheduledMinutes;
}

/// Effort data for a single habit.
class HabitEffort {
  const HabitEffort({
    required this.habitId,
    required this.habitName,
    required this.durationMinutes,
    required this.totalCompletedMinutes,
    required this.totalScheduledMinutes,
  });

  final String habitId;
  final String habitName;
  final int durationMinutes;
  final int totalCompletedMinutes;
  final int totalScheduledMinutes;

  double get rate =>
      totalScheduledMinutes == 0 ? 0.0 : totalCompletedMinutes / totalScheduledMinutes;
}

final dailyEffortProvider = FutureProvider<DailyEffort>((ref) async {
  final habits = await ref.watch(habitsProvider.future);
  ref.watch(completionsRevisionProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final completionRepo = ref.watch(completionRepositoryProvider);
  final todayCompletions = await completionRepo.getCompletionsForDate(today);

  final completedIds = <String>{};
  for (final c in todayCompletions) {
    if (c.completionType != HabitCompletionType.skipped) {
      completedIds.add(c.habitId);
    }
  }

  var scheduledMinutes = 0;
  var completedMinutes = 0;

  for (final habit in habits) {
    if (habit.durationMinutes == null) continue;
    if (!isHabitScheduledOn(habit, today)) continue;
    scheduledMinutes += habit.durationMinutes!;
    if (completedIds.contains(habit.id)) {
      completedMinutes += habit.durationMinutes!;
    }
  }

  return DailyEffort(
    completedMinutes: completedMinutes,
    scheduledMinutes: scheduledMinutes,
  );
});

/// Weighted overall score: sum(strength * duration) / sum(duration).
/// Falls back to unweighted if no habits have duration.
final weightedOverallScoreProvider = FutureProvider<double?>((ref) async {
  final habits = await ref.watch(habitsProvider.future);
  ref.watch(completionsRevisionProvider);
  final completionRepo = ref.watch(completionRepositoryProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  var totalWeight = 0.0;
  var weightedSum = 0.0;

  for (final habit in habits) {
    if (habit.durationMinutes == null) continue;
    final duration = habit.durationMinutes!.toDouble();

    // Compute habit strength inline (same algorithm as habit_strength_provider)
    final completions = await completionRepo.getCompletionsByHabit(habit.id);
    final completedDates = <DateTime>{};
    for (final c in completions) {
      if (c.completionType != HabitCompletionType.skipped) {
        completedDates.add(dateOnly(c.date));
      }
    }

    const decay = 0.05;
    var score = 0.0;
    var cursor = dateOnly(habit.createdAt);
    while (!cursor.isAfter(today)) {
      if (isHabitScheduledOn(habit, cursor)) {
        final completed = completedDates.contains(cursor);
        score = score * (1 - decay) + (completed ? decay : 0);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    final strength = (score * 20).clamp(0.0, 1.0);

    weightedSum += strength * duration;
    totalWeight += duration;
  }

  if (totalWeight == 0) return null;
  return weightedSum / totalWeight;
});
