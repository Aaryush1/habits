import '../../entities/completion.dart';
import '../../repositories/completion_repository.dart';

class SkipHabit {
  const SkipHabit(this._completionRepository);

  final CompletionRepository _completionRepository;

  Future<void> call(Completion completion) {
    return _completionRepository.upsertCompletion(completion);
  }
}
