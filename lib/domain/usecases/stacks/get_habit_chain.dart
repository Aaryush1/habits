import '../../entities/habit_stack.dart';
import '../../repositories/stack_repository.dart';

class GetHabitChain {
  const GetHabitChain(this._stackRepository);

  final StackRepository _stackRepository;

  Future<List<HabitStack>> call(String habitId) {
    return _stackRepository.getChainForHabit(habitId);
  }
}
