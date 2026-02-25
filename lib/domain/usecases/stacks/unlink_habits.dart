import '../../repositories/stack_repository.dart';

class UnlinkHabits {
  const UnlinkHabits(this._stackRepository);

  final StackRepository _stackRepository;

  Future<void> call(String stackId) {
    return _stackRepository.deleteStack(stackId);
  }
}
