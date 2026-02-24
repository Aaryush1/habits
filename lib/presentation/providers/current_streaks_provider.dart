import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'completions_provider.dart';
import 'habits_provider.dart';
import 'repository_providers.dart';

/// Batch-computes current streak for all active habits.
/// Returns a map of habitId to currentStreak.
final currentStreaksProvider = FutureProvider<Map<String, int>>((ref) async {
  final habits = await ref.watch(habitsProvider.future);
  ref.watch(completionsRevisionProvider);
  final completionRepo = ref.watch(completionRepositoryProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final streaks = <String, int>{};
  for (final habit in habits) {
    final streak =
        await completionRepo.getCurrentStreakForHabit(habit.id, today);
    streaks[habit.id] = streak;
  }
  return streaks;
});
