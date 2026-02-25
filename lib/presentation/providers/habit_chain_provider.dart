import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/stack.dart';
import 'repository_providers.dart';
import 'stacks_provider.dart';

/// Returns all stacks that contain the given habit ID.
final habitChainProvider =
    FutureProvider.family<List<HabitStack>, String>((ref, habitId) async {
  ref.watch(stacksProvider);
  final repository = ref.watch(stackRepositoryProvider);
  return repository.getStacksForHabit(habitId);
});
