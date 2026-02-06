import '../../domain/entities/habit_stack.dart';
import '../../domain/repositories/stack_repository.dart';
import '../datasources/local/hive_database.dart';
import '../models/habit_stack_model.dart';

class StackRepositoryImpl implements StackRepository {
  @override
  Future<void> linkHabits(HabitStack stackLink) async {
    final model = HabitStackModel.fromEntity(stackLink);
    await HiveDatabase.habitStacksBox.put(stackLink.id, model);
  }

  @override
  Future<void> unlinkHabits(String previousHabitId, String nextHabitId) async {
    final entries = HiveDatabase.habitStacksBox.toMap().entries;
    for (final entry in entries) {
      final link = entry.value;
      if (link.previousHabitId == previousHabitId &&
          link.nextHabitId == nextHabitId) {
        await HiveDatabase.habitStacksBox.delete(entry.key);
      }
    }
  }

  @override
  Future<List<HabitStack>> getAllLinks() async {
    return HiveDatabase.habitStacksBox.values
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<List<HabitStack>> getNextLinks(String habitId) async {
    return HiveDatabase.habitStacksBox.values
        .where((model) => model.previousHabitId == habitId)
        .map((model) => model.toEntity())
        .toList();
  }

  @override
  Future<HabitStack?> getPreviousLink(String habitId) async {
    for (final model in HiveDatabase.habitStacksBox.values) {
      if (model.nextHabitId == habitId) {
        return model.toEntity();
      }
    }
    return null;
  }

  @override
  Future<List<HabitStack>> getChainForHabit(String habitId) async {
    final allLinks = await getAllLinks();
    final chain = <HabitStack>[];
    final visited = <String>{};
    final queue = <String>[habitId];

    while (queue.isNotEmpty) {
      final currentHabitId = queue.removeAt(0);
      if (!visited.add(currentHabitId)) {
        continue;
      }

      for (final link in allLinks) {
        if (link.previousHabitId == currentHabitId) {
          chain.add(link);
          queue.add(link.nextHabitId);
        } else if (link.nextHabitId == currentHabitId) {
          chain.add(link);
          queue.add(link.previousHabitId);
        }
      }
    }

    final deduped = <String, HabitStack>{};
    for (final link in chain) {
      deduped[link.id] = link;
    }
    return deduped.values.toList();
  }
}
