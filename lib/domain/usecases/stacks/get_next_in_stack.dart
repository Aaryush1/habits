import '../../entities/habit_stack.dart';
import '../../repositories/stack_repository.dart';

class GetNextInStack {
  const GetNextInStack(this._stackRepository);

  final StackRepository _stackRepository;

  Future<List<HabitStack>> call(String habitId) {
    return _stackRepository.getNextLinks(habitId);
  }
}
