import '../../repositories/completion_repository.dart';

class UncompleteHabit {
  const UncompleteHabit(this._completionRepository);

  final CompletionRepository _completionRepository;

  Future<void> call(String completionId) {
    return _completionRepository.deleteCompletion(completionId);
  }
}
