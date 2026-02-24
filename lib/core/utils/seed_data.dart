import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../domain/entities/completion.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/completion_repository.dart';
import '../../domain/repositories/habit_repository.dart';
import 'schedule_utils.dart';

const _uuid = Uuid();
final _rng = Random(42); // Fixed seed for reproducible results

/// Generates realistic seed data: 7 habits with 90 days of varied completion patterns.
Future<void> generateSeedData({
  required HabitRepository habitRepo,
  required CompletionRepository completionRepo,
}) async {
  final now = DateTime.now();
  final today = dateOnly(now);

  final habits = _buildHabits(today);

  for (final habit in habits) {
    await habitRepo.createHabit(habit);
  }

  for (final habit in habits) {
    final completions = _generateCompletions(habit, today);
    for (final completion in completions) {
      await completionRepo.upsertCompletion(completion);
    }
  }
}

List<Habit> _buildHabits(DateTime today) {
  return [
    // 1. Daily powerhouse — near-perfect 90 days, "the anchor habit"
    Habit(
      id: _uuid.v4(),
      name: 'Morning Meditation',
      createdAt: today.subtract(const Duration(days: 90)),
      scheduleType: HabitScheduleType.daily,
      displayOrder: 0,
      notificationsEnabled: false,
      identityStatement: 'I am someone who starts each day with stillness',
      colorHex: 'E8A838', // Gold
      category: 'Mindfulness',
      durationMinutes: 10,
      implementationTime: '6:30 AM',
      implementationLocation: 'Living room cushion',
      twoMinuteVersion: 'Sit and take 5 deep breaths',
    ),
    // 2. Daily with strong start, fell off 3 weeks ago
    Habit(
      id: _uuid.v4(),
      name: 'Read 20 Pages',
      createdAt: today.subtract(const Duration(days: 75)),
      scheduleType: HabitScheduleType.daily,
      displayOrder: 1,
      notificationsEnabled: false,
      identityStatement: 'I am a reader',
      colorHex: '6B9BD2', // Sky
      category: 'Learning',
      durationMinutes: 30,
      implementationTime: 'Before bed',
      implementationLocation: 'Bedroom',
      twoMinuteVersion: 'Read one page',
    ),
    // 3. Daily inconsistent — hovers around 55%
    Habit(
      id: _uuid.v4(),
      name: 'Drink 8 Glasses of Water',
      createdAt: today.subtract(const Duration(days: 60)),
      scheduleType: HabitScheduleType.daily,
      displayOrder: 2,
      notificationsEnabled: false,
      colorHex: '5BC0BE', // Teal
      category: 'Health',
      durationMinutes: 2,
    ),
    // 4. Weekly (Mon/Wed/Fri) — good consistency 80%+
    Habit(
      id: _uuid.v4(),
      name: 'Gym Workout',
      createdAt: today.subtract(const Duration(days: 80)),
      scheduleType: HabitScheduleType.weekly,
      scheduleDays: [0, 2, 4], // Mon, Wed, Fri
      displayOrder: 3,
      notificationsEnabled: false,
      identityStatement: 'I am an athlete',
      colorHex: '7DB87D', // Sage
      category: 'Fitness',
      durationMinutes: 45,
      implementationTime: '7:00 AM',
      implementationLocation: 'Local gym',
      twoMinuteVersion: 'Put on gym clothes and do 5 push-ups',
    ),
    // 5. Daily — brand new, only 10 days old, building momentum
    Habit(
      id: _uuid.v4(),
      name: 'Journal Before Bed',
      createdAt: today.subtract(const Duration(days: 10)),
      scheduleType: HabitScheduleType.daily,
      displayOrder: 4,
      notificationsEnabled: false,
      identityStatement: 'I am someone who reflects on my day',
      colorHex: 'B088D4', // Lavender
      category: 'Mindfulness',
      durationMinutes: 15,
      implementationTime: '9:30 PM',
      implementationLocation: 'Desk',
      twoMinuteVersion: 'Write one sentence about today',
    ),
    // 6. Daily — stalled, was doing OK but hasn't been done in 12 days
    Habit(
      id: _uuid.v4(),
      name: 'Practice Guitar',
      createdAt: today.subtract(const Duration(days: 50)),
      scheduleType: HabitScheduleType.daily,
      displayOrder: 5,
      notificationsEnabled: false,
      colorHex: 'D4726A', // Coral
      category: 'Creative',
      durationMinutes: 20,
      twoMinuteVersion: 'Pick up the guitar and play one chord',
    ),
    // 7. Monthly (1st and 15th) — consistent
    Habit(
      id: _uuid.v4(),
      name: 'Budget Review',
      createdAt: today.subtract(const Duration(days: 90)),
      scheduleType: HabitScheduleType.monthly,
      scheduleDates: [1, 15],
      displayOrder: 6,
      notificationsEnabled: false,
      colorHex: 'E07B53', // Tangerine
      category: 'Finance',
      durationMinutes: 30,
    ),
  ];
}

List<Completion> _generateCompletions(Habit habit, DateTime today) {
  final completions = <Completion>[];
  final createdDate = dateOnly(habit.createdAt);
  var cursor = createdDate;

  while (!cursor.isAfter(today)) {
    if (!isHabitScheduledOn(habit, cursor)) {
      cursor = cursor.add(const Duration(days: 1));
      continue;
    }

    final shouldComplete = _shouldComplete(habit, cursor, today);
    if (shouldComplete) {
      completions.add(Completion(
        id: _uuid.v4(),
        habitId: habit.id,
        date: cursor,
        completedAt: cursor.add(Duration(hours: 8 + _rng.nextInt(12))),
        completionType: HabitCompletionType.full,
        wasEdited: false,
      ));
    } else if (_rng.nextDouble() < 0.08) {
      // Occasionally mark as skipped instead of just missing
      completions.add(Completion(
        id: _uuid.v4(),
        habitId: habit.id,
        date: cursor,
        completedAt: cursor.add(Duration(hours: 20 + _rng.nextInt(3))),
        completionType: HabitCompletionType.skipped,
        skipReason: 'Busy day',
        wasEdited: false,
      ));
    }

    cursor = cursor.add(const Duration(days: 1));
  }

  return completions;
}

bool _shouldComplete(Habit habit, DateTime date, DateTime today) {
  final daysAgo = today.difference(date).inDays;
  final name = habit.name;

  if (name == 'Morning Meditation') {
    // Near-perfect: 93% completion, occasional miss on weekends
    if (date.weekday >= 6 && _rng.nextDouble() < 0.15) return false;
    return _rng.nextDouble() < 0.95;
  }

  if (name == 'Read 20 Pages') {
    // Strong start, fell off ~20 days ago
    if (daysAgo < 20) return _rng.nextDouble() < 0.15; // rare recent
    if (daysAgo < 40) return _rng.nextDouble() < 0.45; // declining
    return _rng.nextDouble() < 0.88; // strong early
  }

  if (name == 'Drink 8 Glasses of Water') {
    // Inconsistent ~55%, slightly better on weekdays
    final base = date.weekday <= 5 ? 0.60 : 0.40;
    return _rng.nextDouble() < base;
  }

  if (name == 'Gym Workout') {
    // Good consistency 82%
    return _rng.nextDouble() < 0.82;
  }

  if (name == 'Journal Before Bed') {
    // New habit, building: first few days perfect, then slight drop
    if (daysAgo > 7) return true; // first 3 days always
    return _rng.nextDouble() < 0.75;
  }

  if (name == 'Practice Guitar') {
    // Stalled: decent up to 12 days ago, nothing since
    if (daysAgo < 12) return false;
    if (daysAgo < 25) return _rng.nextDouble() < 0.50; // declining
    return _rng.nextDouble() < 0.70; // decent early
  }

  if (name == 'Budget Review') {
    // Monthly, quite consistent 85%
    return _rng.nextDouble() < 0.85;
  }

  return _rng.nextDouble() < 0.5;
}
