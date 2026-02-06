import '../../entities/habit_stack.dart';
import '../../repositories/stack_repository.dart';

class LinkHabits {
  const LinkHabits(this._stackRepository);

  final StackRepository _stackRepository;

  Future<void> call(HabitStack stackLink) {
    return _stackRepository.linkHabits(stackLink);
  }
}
