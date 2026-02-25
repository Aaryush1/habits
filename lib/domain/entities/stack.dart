import 'package:collection/collection.dart';

/// A HabitStack is a named, ordered group of habits to be done in sequence.
class HabitStack {
  const HabitStack({
    required this.id,
    required this.name,
    required this.habitIds,
    required this.createdAt,
    this.description,
    this.iconEmoji,
    this.chainNotificationsEnabled = false,
  });

  final String id;
  final String name;

  /// Ordered list of habit IDs — the sequence to perform habits in.
  final List<String> habitIds;

  final DateTime createdAt;
  final String? description;
  final String? iconEmoji;

  /// Whether to send chain-prompt notifications when next habit is due.
  final bool chainNotificationsEnabled;

  HabitStack copyWith({
    String? id,
    String? name,
    List<String>? habitIds,
    DateTime? createdAt,
    String? description,
    String? iconEmoji,
    bool? chainNotificationsEnabled,
  }) {
    return HabitStack(
      id: id ?? this.id,
      name: name ?? this.name,
      habitIds: habitIds ?? this.habitIds,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      chainNotificationsEnabled:
          chainNotificationsEnabled ?? this.chainNotificationsEnabled,
    );
  }

  static const ListEquality<String> _listEquality = ListEquality<String>();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitStack &&
        other.id == id &&
        other.name == name &&
        _listEquality.equals(other.habitIds, habitIds) &&
        other.createdAt == createdAt &&
        other.description == description &&
        other.iconEmoji == iconEmoji &&
        other.chainNotificationsEnabled == chainNotificationsEnabled;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      name,
      _listEquality.hash(habitIds),
      createdAt,
      description,
      iconEmoji,
      chainNotificationsEnabled,
    ]);
  }
}
