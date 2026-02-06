import '../entities/habit.dart';

abstract class HabitRepository {
  Future<void> createHabit(Habit habit);
  Future<Habit?> getHabitById(String habitId);
  Future<List<Habit>> getAllHabits();
  Future<List<Habit>> getActiveHabits();
  Future<List<Habit>> getArchivedHabits();
  Future<List<Habit>> getHabitsByCategory(String category);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(String habitId);
  Future<void> archiveHabit(String habitId);
  Future<void> unarchiveHabit(String habitId);
  Future<void> reorderHabits(List<String> orderedHabitIds);
}
