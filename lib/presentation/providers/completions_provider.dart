import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/completion.dart';
import '../../domain/repositories/completion_repository.dart';
import 'repository_providers.dart';

final completionsRevisionProvider = StateProvider<int>((ref) => 0);

class DateRangeKey {
  const DateRangeKey({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRangeKey && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

final completionsProvider = AsyncNotifierProvider.family<CompletionsNotifier,
    List<Completion>, DateTime>(CompletionsNotifier.new);

final completionsForRangeProvider =
    FutureProvider.family<List<Completion>, DateRangeKey>((ref, key) async {
  ref.watch(completionsRevisionProvider);
  final repository = ref.watch(completionRepositoryProvider);
  return repository.getCompletionsForDateRange(key.start, key.end);
});

class CompletionsNotifier extends FamilyAsyncNotifier<List<Completion>, DateTime> {
  CompletionRepository get _repository => ref.read(completionRepositoryProvider);

  late final DateTime _targetDate;

  @override
  Future<List<Completion>> build(DateTime arg) async {
    _targetDate = _normalizeDate(arg);
    return _repository.getCompletionsForDate(_targetDate);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.getCompletionsForDate(_targetDate),
    );
  }

  Future<void> toggleCompletion({
    required String habitId,
    HabitCompletionType completionType = HabitCompletionType.full,
    String? note,
  }) async {
    final previousState = state;
    final baseCompletions =
        state.valueOrNull ?? await _repository.getCompletionsForDate(_targetDate);
    final existing = _findByHabit(baseCompletions, habitId);
    final now = DateTime.now();

    if (existing != null) {
      final optimistic = _removeCompletion(
        baseCompletions,
        existing.id,
      );
      state = AsyncData(optimistic);
      try {
        await _repository.deleteCompletion(existing.id);
        ref.read(completionsRevisionProvider.notifier).state++;
      } catch (_) {
        state = previousState;
        rethrow;
      }
      return;
    }

    final completion = Completion(
      id: const Uuid().v4(),
      habitId: habitId,
      date: _targetDate,
      completedAt: now,
      completionType: completionType,
      note: note,
      wasEdited: false,
    );

    final optimistic = <Completion>[
      ...baseCompletions,
      completion,
    ]
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    state = AsyncData(optimistic);

    try {
      await _repository.upsertCompletion(completion);
      ref.read(completionsRevisionProvider.notifier).state++;
    } catch (_) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> skipHabit({
    required String habitId,
    String? skipReason,
    String? note,
  }) async {
    final previousState = state;
    final existing = _findByHabit(state.valueOrNull, habitId);
    final completion = Completion(
      id: existing?.id ?? const Uuid().v4(),
      habitId: habitId,
      date: _targetDate,
      completedAt: DateTime.now(),
      completionType: HabitCompletionType.skipped,
      skipReason: skipReason,
      note: note,
      wasEdited: existing != null,
    );

    final withoutExisting = existing == null
        ? (state.valueOrNull ?? <Completion>[])
        : _removeCompletion(state.valueOrNull ?? <Completion>[], existing.id);
    final optimistic = <Completion>[...withoutExisting, completion]
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    state = AsyncData(optimistic);

    try {
      await _repository.upsertCompletion(completion);
      ref.read(completionsRevisionProvider.notifier).state++;
    } catch (_) {
      state = previousState;
      rethrow;
    }
  }

  Completion? _findByHabit(List<Completion>? completions, String habitId) {
    if (completions == null) {
      return null;
    }
    for (final completion in completions) {
      if (completion.habitId == habitId &&
          _normalizeDate(completion.date) == _targetDate) {
        return completion;
      }
    }
    return null;
  }

  List<Completion> _removeCompletion(
    List<Completion> completions,
    String completionId,
  ) {
    return completions.where((item) => item.id != completionId).toList();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
