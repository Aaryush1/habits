import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import 'repository_providers.dart';

final habitsProvider =
    AsyncNotifierProvider<HabitsNotifier, List<Habit>>(HabitsNotifier.new);

class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  HabitRepository get _repository => ref.read(habitRepositoryProvider);

  @override
  Future<List<Habit>> build() async {
    return _repository.getActiveHabits();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getActiveHabits());
  }

  Future<void> createHabit(Habit habit) async {
    await _repository.createHabit(habit);
    await reload();
  }

  Future<void> updateHabit(Habit habit) async {
    await _repository.updateHabit(habit);
    await reload();
  }

  Future<void> archiveHabit(String habitId) async {
    await _repository.archiveHabit(habitId);
    await reload();
  }

  Future<void> deleteHabit(String habitId) async {
    await _repository.deleteHabit(habitId);
    await reload();
  }

  Future<void> reorderHabits(List<String> orderedHabitIds) async {
    await _repository.reorderHabits(orderedHabitIds);
    await reload();
  }
}
