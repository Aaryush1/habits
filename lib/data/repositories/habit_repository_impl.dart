import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../datasources/local/hive_database.dart';
import '../models/habit_model.dart';

class HabitRepositoryImpl implements HabitRepository {
  @override
  Future<void> createHabit(Habit habit) async {
    final model = HabitModel.fromEntity(habit);
    await HiveDatabase.habitsBox.put(habit.id, model);
  }

  @override
  Future<Habit?> getHabitById(String habitId) async {
    final model = HiveDatabase.habitsBox.get(habitId);
    return model?.toEntity();
  }

  @override
  Future<List<Habit>> getAllHabits() async {
    final habits = HiveDatabase.habitsBox.values
        .map((model) => model.toEntity())
        .toList();
    habits.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return habits;
  }

  @override
  Future<List<Habit>> getActiveHabits() async {
    final habits = HiveDatabase.habitsBox.values
        .where((model) => model.archivedAt == null)
        .map((model) => model.toEntity())
        .toList();
    habits.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return habits;
  }

  @override
  Future<List<Habit>> getArchivedHabits() async {
    final habits = HiveDatabase.habitsBox.values
        .where((model) => model.archivedAt != null)
        .map((model) => model.toEntity())
        .toList();
    habits.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return habits;
  }

  @override
  Future<List<Habit>> getHabitsByCategory(String category) async {
    final habits = HiveDatabase.habitsBox.values
        .where((model) => model.category == category && model.archivedAt == null)
        .map((model) => model.toEntity())
        .toList();
    habits.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return habits;
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final model = HabitModel.fromEntity(habit);
    await HiveDatabase.habitsBox.put(habit.id, model);
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await HiveDatabase.habitsBox.delete(habitId);
  }

  @override
  Future<void> archiveHabit(String habitId) async {
    final existing = HiveDatabase.habitsBox.get(habitId);
    if (existing == null) {
      return;
    }
    existing.archivedAt = DateTime.now();
    await HiveDatabase.habitsBox.put(habitId, existing);
  }

  @override
  Future<void> unarchiveHabit(String habitId) async {
    final existing = HiveDatabase.habitsBox.get(habitId);
    if (existing == null) {
      return;
    }
    existing.archivedAt = null;
    await HiveDatabase.habitsBox.put(habitId, existing);
  }

  @override
  Future<void> reorderHabits(List<String> orderedHabitIds) async {
    for (var i = 0; i < orderedHabitIds.length; i++) {
      final habitId = orderedHabitIds[i];
      final model = HiveDatabase.habitsBox.get(habitId);
      if (model == null) {
        continue;
      }
      model.displayOrder = i;
      await HiveDatabase.habitsBox.put(habitId, model);
    }
  }
}
