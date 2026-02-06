import '../../entities/habit.dart';
import '../../repositories/habit_repository.dart';

class GetHabits {
  const GetHabits(this._habitRepository);

  final HabitRepository _habitRepository;

  Future<List<Habit>> call({bool includeArchived = false}) {
    if (includeArchived) {
      return _habitRepository.getAllHabits();
    }
    return _habitRepository.getActiveHabits();
  }
}
