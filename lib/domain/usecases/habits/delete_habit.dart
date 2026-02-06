import '../../repositories/habit_repository.dart';

class DeleteHabit {
  const DeleteHabit(this._habitRepository);

  final HabitRepository _habitRepository;

  Future<void> call(String habitId) {
    return _habitRepository.deleteHabit(habitId);
  }
}
