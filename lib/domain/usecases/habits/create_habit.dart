import '../../entities/habit.dart';
import '../../repositories/habit_repository.dart';

class CreateHabit {
  const CreateHabit(this._habitRepository);

  final HabitRepository _habitRepository;

  Future<void> call(Habit habit) {
    return _habitRepository.createHabit(habit);
  }
}
