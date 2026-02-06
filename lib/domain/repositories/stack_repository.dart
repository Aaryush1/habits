import '../entities/habit_stack.dart';

abstract class StackRepository {
  Future<void> linkHabits(HabitStack stackLink);
  Future<void> unlinkHabits(String previousHabitId, String nextHabitId);
  Future<List<HabitStack>> getAllLinks();
  Future<List<HabitStack>> getNextLinks(String habitId);
  Future<HabitStack?> getPreviousLink(String habitId);
  Future<List<HabitStack>> getChainForHabit(String habitId);
}
