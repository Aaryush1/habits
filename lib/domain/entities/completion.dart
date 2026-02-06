enum HabitCompletionType { full, twoMinute, skipped }

class Completion {
  const Completion({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completedAt,
    required this.completionType,
    required this.wasEdited,
    this.skipReason,
    this.note,
  });

  final String id;
  final String habitId;
  final DateTime date;
  final DateTime completedAt;
  final HabitCompletionType completionType;
  final String? skipReason;
  final String? note;
  final bool wasEdited;

  Completion copyWith({
    String? id,
    String? habitId,
    DateTime? date,
    DateTime? completedAt,
    HabitCompletionType? completionType,
    String? skipReason,
    String? note,
    bool? wasEdited,
  }) {
    return Completion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      completedAt: completedAt ?? this.completedAt,
      completionType: completionType ?? this.completionType,
      skipReason: skipReason ?? this.skipReason,
      note: note ?? this.note,
      wasEdited: wasEdited ?? this.wasEdited,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Completion &&
        other.id == id &&
        other.habitId == habitId &&
        other.date == date &&
        other.completedAt == completedAt &&
        other.completionType == completionType &&
        other.skipReason == skipReason &&
        other.note == note &&
        other.wasEdited == wasEdited;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      habitId,
      date,
      completedAt,
      completionType,
      skipReason,
      note,
      wasEdited,
    );
  }
}
