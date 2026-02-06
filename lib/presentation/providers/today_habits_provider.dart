import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/habit.dart';
import 'habits_provider.dart';

final todayHabitsProvider = Provider<AsyncValue<List<Habit>>>((ref) {
  final habitsAsync = ref.watch(habitsProvider);
  final now = DateTime.now();
  final weekday = now.weekday; // 1 (Mon) -> 7 (Sun)
  final dayOfMonth = now.day;

  return habitsAsync.whenData((habits) {
    return habits.where((habit) {
      switch (habit.scheduleType) {
        case HabitScheduleType.daily:
          return true;
        case HabitScheduleType.weekly:
          final days = habit.scheduleDays ?? <int>[];
          return days.contains(weekday - 1);
        case HabitScheduleType.monthly:
          final dates = habit.scheduleDates ?? <int>[];
          return dates.contains(dayOfMonth);
      }
    }).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  });
});
