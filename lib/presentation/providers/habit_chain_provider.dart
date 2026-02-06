import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/habit_stack.dart';
import 'repository_providers.dart';
import 'stacks_provider.dart';

final habitChainProvider =
    FutureProvider.family<List<HabitStack>, String>((ref, habitId) async {
  ref.watch(stacksProvider);
  final repository = ref.watch(stackRepositoryProvider);
  return repository.getChainForHabit(habitId);
});
