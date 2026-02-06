import '../entities/completion.dart';

abstract class CompletionRepository {
  Future<void> upsertCompletion(Completion completion);
  Future<void> deleteCompletion(String completionId);
  Future<Completion?> getCompletionById(String completionId);
  Future<List<Completion>> getCompletionsByHabit(String habitId);
  Future<List<Completion>> getCompletionsForDate(DateTime date);
  Future<List<Completion>> getCompletionsForDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<int> getCurrentStreakForHabit(String habitId, DateTime today);
}
