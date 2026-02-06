import '../../repositories/habit_repository.dart';

class ReorderHabits {
  const ReorderHabits(this._habitRepository);

  final HabitRepository _habitRepository;

  Future<void> call(List<String> orderedHabitIds) {
    return _habitRepository.reorderHabits(orderedHabitIds);
  }
}
