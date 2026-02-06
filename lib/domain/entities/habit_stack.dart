class HabitStack {
  const HabitStack({
    required this.id,
    required this.previousHabitId,
    required this.nextHabitId,
    required this.createdAt,
  });

  final String id;
  final String previousHabitId;
  final String nextHabitId;
  final DateTime createdAt;

  HabitStack copyWith({
    String? id,
    String? previousHabitId,
    String? nextHabitId,
    DateTime? createdAt,
  }) {
    return HabitStack(
      id: id ?? this.id,
      previousHabitId: previousHabitId ?? this.previousHabitId,
      nextHabitId: nextHabitId ?? this.nextHabitId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitStack &&
        other.id == id &&
        other.previousHabitId == previousHabitId &&
        other.nextHabitId == nextHabitId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, previousHabitId, nextHabitId, createdAt);
}
