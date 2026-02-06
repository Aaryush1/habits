import '../../repositories/habit_repository.dart';

class ArchiveHabit {
  const ArchiveHabit(this._habitRepository);

  final HabitRepository _habitRepository;

  Future<void> call(String habitId) {
    return _habitRepository.archiveHabit(habitId);
  }
}
