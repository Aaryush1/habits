import '../../entities/habit.dart';
import '../../repositories/habit_repository.dart';

class UpdateHabit {
  const UpdateHabit(this._habitRepository);

  final HabitRepository _habitRepository;

  Future<void> call(Habit habit) {
    return _habitRepository.updateHabit(habit);
  }
}
