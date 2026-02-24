import '../../domain/entities/habit.dart';

/// Whether [habit] is scheduled on [date], based on its schedule type.
/// Extracted from duplicated helpers across providers and screens.
bool isHabitScheduledOn(Habit habit, DateTime date) {
  switch (habit.scheduleType) {
    case HabitScheduleType.daily:
      return true;
    case HabitScheduleType.weekly:
      final days = habit.scheduleDays ?? const <int>[];
      return days.contains(date.weekday - 1);
    case HabitScheduleType.monthly:
      final dates = habit.scheduleDates ?? const <int>[];
      return dates.contains(date.day);
  }
}

/// Strips time component, returning date-only DateTime.
DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Counts how many days [habit] was scheduled between [startDate] and [endDate] inclusive.
int countScheduledDays(Habit habit, DateTime startDate, DateTime endDate) {
  final start = dateOnly(startDate);
  final end = dateOnly(endDate);
  var count = 0;
  var cursor = start;
  while (!cursor.isAfter(end)) {
    if (isHabitScheduledOn(habit, cursor)) {
      count++;
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return count;
}
