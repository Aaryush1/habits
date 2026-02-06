import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/habit_stack.dart';
import '../../domain/repositories/stack_repository.dart';
import 'repository_providers.dart';

final stacksProvider =
    AsyncNotifierProvider<StacksNotifier, List<HabitStack>>(StacksNotifier.new);

class StacksNotifier extends AsyncNotifier<List<HabitStack>> {
  StackRepository get _repository => ref.read(stackRepositoryProvider);

  @override
  Future<List<HabitStack>> build() {
    return _repository.getAllLinks();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getAllLinks());
  }

  Future<void> link(HabitStack link) async {
    await _repository.linkHabits(link);
    await reload();
  }

  Future<void> unlink(String previousHabitId, String nextHabitId) async {
    await _repository.unlinkHabits(previousHabitId, nextHabitId);
    await reload();
  }
}
