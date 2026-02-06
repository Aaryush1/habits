import '../../entities/completion.dart';
import '../../repositories/completion_repository.dart';

class GetCompletionsForRange {
  const GetCompletionsForRange(this._completionRepository);

  final CompletionRepository _completionRepository;

  Future<List<Completion>> call(DateTime startDate, DateTime endDate) {
    return _completionRepository.getCompletionsForDateRange(startDate, endDate);
  }
}
