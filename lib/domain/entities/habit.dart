import 'package:collection/collection.dart';

enum HabitScheduleType { daily, weekly, monthly }

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.scheduleType,
    required this.displayOrder,
    required this.notificationsEnabled,
    this.archivedAt,
    this.scheduleDays,
    this.scheduleDates,
    this.identityStatement,
    this.implementationTime,
    this.implementationLocation,
    this.twoMinuteVersion,
    this.colorHex,
    this.category,
    this.notes,
    this.notificationTimes,
    this.notificationTriggerHabitId,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? archivedAt;
  final HabitScheduleType scheduleType;
  final List<int>? scheduleDays;
  final List<int>? scheduleDates;
  final String? identityStatement;
  final String? implementationTime;
  final String? implementationLocation;
  final String? twoMinuteVersion;
  final String? colorHex;
  final String? category;
  final String? notes;
  final int displayOrder;
  final bool notificationsEnabled;
  final List<String>? notificationTimes;
  final String? notificationTriggerHabitId;

  Habit copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? archivedAt,
    HabitScheduleType? scheduleType,
    List<int>? scheduleDays,
    List<int>? scheduleDates,
    String? identityStatement,
    String? implementationTime,
    String? implementationLocation,
    String? twoMinuteVersion,
    String? colorHex,
    String? category,
    String? notes,
    int? displayOrder,
    bool? notificationsEnabled,
    List<String>? notificationTimes,
    String? notificationTriggerHabitId,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      scheduleType: scheduleType ?? this.scheduleType,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      scheduleDates: scheduleDates ?? this.scheduleDates,
      identityStatement: identityStatement ?? this.identityStatement,
      implementationTime: implementationTime ?? this.implementationTime,
      implementationLocation:
          implementationLocation ?? this.implementationLocation,
      twoMinuteVersion: twoMinuteVersion ?? this.twoMinuteVersion,
      colorHex: colorHex ?? this.colorHex,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      displayOrder: displayOrder ?? this.displayOrder,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTimes: notificationTimes ?? this.notificationTimes,
      notificationTriggerHabitId:
          notificationTriggerHabitId ?? this.notificationTriggerHabitId,
    );
  }

  static const ListEquality<int> _intListEquality = ListEquality<int>();
  static const ListEquality<String> _stringListEquality =
      ListEquality<String>();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Habit &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.archivedAt == archivedAt &&
        other.scheduleType == scheduleType &&
        _intListEquality.equals(other.scheduleDays, scheduleDays) &&
        _intListEquality.equals(other.scheduleDates, scheduleDates) &&
        other.identityStatement == identityStatement &&
        other.implementationTime == implementationTime &&
        other.implementationLocation == implementationLocation &&
        other.twoMinuteVersion == twoMinuteVersion &&
        other.colorHex == colorHex &&
        other.category == category &&
        other.notes == notes &&
        other.displayOrder == displayOrder &&
        other.notificationsEnabled == notificationsEnabled &&
        _stringListEquality.equals(other.notificationTimes, notificationTimes) &&
        other.notificationTriggerHabitId == notificationTriggerHabitId;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      name,
      createdAt,
      archivedAt,
      scheduleType,
      _intListEquality.hash(scheduleDays),
      _intListEquality.hash(scheduleDates),
      identityStatement,
      implementationTime,
      implementationLocation,
      twoMinuteVersion,
      colorHex,
      category,
      notes,
      displayOrder,
      notificationsEnabled,
      _stringListEquality.hash(notificationTimes),
      notificationTriggerHabitId,
    ]);
  }
}
