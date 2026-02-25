import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/stack.dart';
import '../../domain/repositories/stack_repository.dart';
import 'repository_providers.dart';

final stacksProvider =
    AsyncNotifierProvider<StacksNotifier, List<HabitStack>>(StacksNotifier.new);

class StacksNotifier extends AsyncNotifier<List<HabitStack>> {
  StackRepository get _repository => ref.read(stackRepositoryProvider);

  @override
  Future<List<HabitStack>> build() {
    return _repository.getAllStacks();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getAllStacks());
  }

  Future<void> createStack(HabitStack stack) async {
    await _repository.createStack(stack);
    await reload();
  }

  Future<void> updateStack(HabitStack stack) async {
    await _repository.updateStack(stack);
    await reload();
  }

  Future<void> deleteStack(String id) async {
    await _repository.deleteStack(id);
    await reload();
  }
}

/// Returns all stacks containing the given habit ID.
final stacksForHabitProvider =
    FutureProvider.family<List<HabitStack>, String>((ref, habitId) async {
  ref.watch(stacksProvider);
  final repository = ref.watch(stackRepositoryProvider);
  return repository.getStacksForHabit(habitId);
});
