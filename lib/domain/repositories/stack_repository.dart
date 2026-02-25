import '../entities/stack.dart';

abstract class StackRepository {
  Future<List<HabitStack>> getAllStacks();
  Future<HabitStack?> getStack(String id);
  Future<void> createStack(HabitStack stack);
  Future<void> updateStack(HabitStack stack);
  Future<void> deleteStack(String id);

  /// Returns all stacks that contain the given habit ID.
  Future<List<HabitStack>> getStacksForHabit(String habitId);
}
