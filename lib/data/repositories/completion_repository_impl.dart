import 'dart:collection';

import '../../domain/entities/completion.dart';
import '../../domain/repositories/completion_repository.dart';
import '../datasources/local/hive_database.dart';
import '../models/completion_model.dart';

class CompletionRepositoryImpl implements CompletionRepository {
  @override
  Future<void> upsertCompletion(Completion completion) async {
    final model = CompletionModel.fromEntity(completion);
    await HiveDatabase.completionsBox.put(completion.id, model);
  }

  @override
  Future<void> deleteCompletion(String completionId) async {
    await HiveDatabase.completionsBox.delete(completionId);
  }

  @override
  Future<Completion?> getCompletionById(String completionId) async {
    final model = HiveDatabase.completionsBox.get(completionId);
    return model?.toEntity();
  }

  @override
  Future<List<Completion>> getCompletionsByHabit(String habitId) async {
    final completions = HiveDatabase.completionsBox.values
        .where((model) => model.habitId == habitId)
        .map((model) => model.toEntity())
        .toList();
    completions.sort((a, b) => a.date.compareTo(b.date));
    return completions;
  }

  @override
  Future<List<Completion>> getCompletionsForDate(DateTime date) async {
    final target = _asDateOnly(date);
    final completions = HiveDatabase.completionsBox.values
        .where((model) => _asDateOnly(model.date) == target)
        .map((model) => model.toEntity())
        .toList();
    completions.sort((a, b) => a.completedAt.compareTo(b.completedAt));
    return completions;
  }

  @override
  Future<List<Completion>> getCompletionsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final start = _asDateOnly(startDate);
    final end = _asDateOnly(endDate);

    final completions = HiveDatabase.completionsBox.values.where((model) {
      final date = _asDateOnly(model.date);
      return !date.isBefore(start) && !date.isAfter(end);
    }).map((model) => model.toEntity()).toList();

    completions.sort((a, b) => a.date.compareTo(b.date));
    return completions;
  }

  @override
  Future<int> getCurrentStreakForHabit(String habitId, DateTime today) async {
    final completions = await getCompletionsByHabit(habitId);
    if (completions.isEmpty) {
      return 0;
    }

    final successfulDays = HashSet<DateTime>();
    for (final completion in completions) {
      if (completion.completionType != HabitCompletionType.skipped) {
        successfulDays.add(_asDateOnly(completion.date));
      }
    }

    var streak = 0;
    var cursor = _asDateOnly(today);

    while (successfulDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  DateTime _asDateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
