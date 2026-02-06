class HabitStats {
  const HabitStats({
    required this.habitId,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    required this.totalScheduledDays,
    required this.completionRate,
    this.longestStreakStart,
    this.longestStreakEnd,
    this.lastCompletedAt,
  });

  final String habitId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? longestStreakStart;
  final DateTime? longestStreakEnd;
  final int totalCompletions;
  final int totalScheduledDays;
  final double completionRate;
  final DateTime? lastCompletedAt;

  HabitStats copyWith({
    String? habitId,
    int? currentStreak,
    int? longestStreak,
    DateTime? longestStreakStart,
    DateTime? longestStreakEnd,
    int? totalCompletions,
    int? totalScheduledDays,
    double? completionRate,
    DateTime? lastCompletedAt,
  }) {
    return HabitStats(
      habitId: habitId ?? this.habitId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      longestStreakStart: longestStreakStart ?? this.longestStreakStart,
      longestStreakEnd: longestStreakEnd ?? this.longestStreakEnd,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      totalScheduledDays: totalScheduledDays ?? this.totalScheduledDays,
      completionRate: completionRate ?? this.completionRate,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
    );
  }
}
