import '../../domain/entities/stack.dart';
import '../../domain/repositories/stack_repository.dart';
import '../datasources/local/hive_database.dart';
import '../models/habit_stack_model.dart';

class StackRepositoryImpl implements StackRepository {
  @override
  Future<List<HabitStack>> getAllStacks() async {
    return HiveDatabase.habitStacksBox.values
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<HabitStack?> getStack(String id) async {
    final model = HiveDatabase.habitStacksBox.get(id);
    return model?.toEntity();
  }

  @override
  Future<void> createStack(HabitStack stack) async {
    final model = HabitStackModel.fromEntity(stack);
    await HiveDatabase.habitStacksBox.put(stack.id, model);
  }

  @override
  Future<void> updateStack(HabitStack stack) async {
    final model = HabitStackModel.fromEntity(stack);
    await HiveDatabase.habitStacksBox.put(stack.id, model);
  }

  @override
  Future<void> deleteStack(String id) async {
    await HiveDatabase.habitStacksBox.delete(id);
  }

  @override
  Future<List<HabitStack>> getStacksForHabit(String habitId) async {
    return HiveDatabase.habitStacksBox.values
        .where((model) => model.habitIds.contains(habitId))
        .map((model) => model.toEntity())
        .toList();
  }
}
