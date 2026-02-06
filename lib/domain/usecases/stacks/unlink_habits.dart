import '../../repositories/stack_repository.dart';

class UnlinkHabits {
  const UnlinkHabits(this._stackRepository);

  final StackRepository _stackRepository;

  Future<void> call(String previousHabitId, String nextHabitId) {
    return _stackRepository.unlinkHabits(previousHabitId, nextHabitId);
  }
}
