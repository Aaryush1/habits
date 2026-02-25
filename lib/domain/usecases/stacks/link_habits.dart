import '../../entities/stack.dart';
import '../../repositories/stack_repository.dart';

class LinkHabits {
  const LinkHabits(this._stackRepository);

  final StackRepository _stackRepository;

  Future<void> call(HabitStack stack) {
    return _stackRepository.createStack(stack);
  }
}
