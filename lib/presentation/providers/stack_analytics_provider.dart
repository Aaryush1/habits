import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/schedule_utils.dart';
import '../../domain/entities/completion.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/stack.dart';
import 'completions_provider.dart';
import 'repository_providers.dart';
import 'stacks_provider.dart';

/// Completion funnel for a single habit in the stack context:
/// what % of scheduled days was this habit completed (over last 90 days).
class StackHabitFunnelEntry {
  const StackHabitFunnelEntry({
    required this.habitId,
    required this.habitName,
    required this.completionRate,
    required this.completedDays,
    required this.scheduledDays,
    this.colorHex,
  });

  final String habitId;
  final String habitName;
  final double completionRate;
  final int completedDays;
  final int scheduledDays;
  final String? colorHex;
}

/// Analytics data for a single stack.
class StackAnalytics {
  const StackAnalytics({
    required this.stack,
    required this.funnel,
    required this.fullChainRate,
    required this.weakestLinkIndex,
    required this.analyzedDays,
  });

  final HabitStack stack;

  /// Funnel entries in the order habits appear in the stack.
  final List<StackHabitFunnelEntry> funnel;

  /// Fraction of days where ALL stack habits were completed (out of analyzed days).
  final double fullChainRate;

  /// Index (in funnel) of the habit with the lowest completion rate.
  /// -1 if funnel is empty.
  final int weakestLinkIndex;

  /// Number of calendar days analyzed (lookback window).
  final int analyzedDays;
}

/// Provider for analytics for a specific stack ID.
/// Caches results per (stackId, date, revision) key.
final stackAnalyticsProvider =
    FutureProvider.family<StackAnalytics?, String>((ref, stackId) async {
  ref.watch(completionsRevisionProvider);
  ref.watch(stacksProvider);

  final habitRepo = ref.watch(habitRepositoryProvider);
  final completionRepo = ref.watch(completionRepositoryProvider);
  final stackRepo = ref.watch(stackRepositoryProvider);

  final stack = await stackRepo.getStack(stackId);
  if (stack == null) return null;
  if (stack.habitIds.isEmpty) {
    return StackAnalytics(
      stack: stack,
      funnel: const [],
      fullChainRate: 0,
      weakestLinkIndex: -1,
      analyzedDays: 0,
    );
  }

  final now = dateOnly(DateTime.now());
  final lookbackDays = 90;
  final startDate = now.subtract(Duration(days: lookbackDays - 1));

  // Fetch all active habits
  final allHabits = await habitRepo.getActiveHabits();
  final habitMap = {for (final h in allHabits) h.id: h};

  // Build funnel per habit in stack order
  final funnel = <StackHabitFunnelEntry>[];
  final habitRates = <double>[];

  for (final habitId in stack.habitIds) {
    final habit = habitMap[habitId];
    if (habit == null) continue;

    final completions = await completionRepo.getCompletionsByHabit(habitId);
    final successfulDates = completions
        .where((c) =>
            c.completionType != HabitCompletionType.skipped &&
            !dateOnly(c.date).isBefore(startDate) &&
            !dateOnly(c.date).isAfter(now))
        .map((c) => dateOnly(c.date))
        .toSet();

    final scheduledDays = countScheduledDays(habit, startDate, now);
    final completedDays = successfulDates.length;
    final rate = scheduledDays == 0 ? 0.0 : completedDays / scheduledDays;

    habitRates.add(rate);
    funnel.add(StackHabitFunnelEntry(
      habitId: habitId,
      habitName: habit.name,
      completionRate: rate,
      completedDays: completedDays,
      scheduledDays: scheduledDays,
      colorHex: habit.colorHex,
    ));
  }

  // Full chain rate: fraction of days where ALL habits in stack were completed.
  // We consider the union of scheduled days for all habits in the stack.
  final fullChainRate = await _computeFullChainRate(
    stack.habitIds,
    habitMap,
    completionRepo,
    startDate,
    now,
  );

  // Weakest link: index of habit with lowest completion rate
  int weakestLinkIndex = -1;
  if (funnel.isNotEmpty) {
    var minRate = double.infinity;
    for (var i = 0; i < funnel.length; i++) {
      if (funnel[i].completionRate < minRate) {
        minRate = funnel[i].completionRate;
        weakestLinkIndex = i;
      }
    }
  }

  return StackAnalytics(
    stack: stack,
    funnel: funnel,
    fullChainRate: fullChainRate,
    weakestLinkIndex: weakestLinkIndex,
    analyzedDays: lookbackDays,
  );
});

/// Provider for analytics for all stacks.
final allStacksAnalyticsProvider =
    FutureProvider<List<StackAnalytics>>((ref) async {
  ref.watch(completionsRevisionProvider);
  final stacksAsync = ref.watch(stacksProvider);
  final stacks = stacksAsync.valueOrNull ?? [];

  final results = <StackAnalytics>[];
  for (final stack in stacks) {
    final analytics = await ref.read(stackAnalyticsProvider(stack.id).future);
    if (analytics != null) results.add(analytics);
  }
  return results;
});

Future<double> _computeFullChainRate(
  List<String> habitIds,
  Map<String, Habit> habitMap,
  dynamic completionRepo,
  DateTime startDate,
  DateTime endDate,
) async {
  if (habitIds.isEmpty) return 0.0;

  // Build set of completed dates per habit
  final completedPerHabit = <String, Set<DateTime>>{};
  for (final habitId in habitIds) {
    final completions =
        await completionRepo.getCompletionsByHabit(habitId) as List;
    completedPerHabit[habitId] = completions
        .where((c) =>
            (c as dynamic).completionType != HabitCompletionType.skipped &&
            !dateOnly((c as dynamic).date).isBefore(startDate) &&
            !dateOnly((c as dynamic).date).isAfter(endDate))
        .map((c) => dateOnly((c as dynamic).date))
        .toSet();
  }

  // For each day in the window, check if all habits that are scheduled were completed
  var totalDays = 0;
  var fullChainDays = 0;
  var cursor = startDate;

  while (!cursor.isAfter(endDate)) {
    // Find habits scheduled on this day
    final scheduledHabitIds = habitIds.where((id) {
      final habit = habitMap[id];
      return habit != null && isHabitScheduledOn(habit, cursor);
    }).toList();

    if (scheduledHabitIds.isNotEmpty) {
      totalDays++;
      final allCompleted = scheduledHabitIds
          .every((id) => completedPerHabit[id]?.contains(cursor) ?? false);
      if (allCompleted) fullChainDays++;
    }

    cursor = cursor.add(const Duration(days: 1));
  }

  return totalDays == 0 ? 0.0 : fullChainDays / totalDays;
}
