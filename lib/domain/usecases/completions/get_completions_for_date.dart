import '../../entities/completion.dart';
import '../../repositories/completion_repository.dart';

class GetCompletionsForDate {
  const GetCompletionsForDate(this._completionRepository);

  final CompletionRepository _completionRepository;

  Future<List<Completion>> call(DateTime date) {
    return _completionRepository.getCompletionsForDate(date);
  }
}
