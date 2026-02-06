import 'package:hive/hive.dart';
import '../../domain/entities/habit.dart';

class HabitModel {
  HabitModel({
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

  String id;
  String name;
  DateTime createdAt;
  DateTime? archivedAt;
  int scheduleType;
  List<int>? scheduleDays;
  List<int>? scheduleDates;
  String? identityStatement;
  String? implementationTime;
  String? implementationLocation;
  String? twoMinuteVersion;
  String? colorHex;
  String? category;
  String? notes;
  int displayOrder;
  bool notificationsEnabled;
  List<String>? notificationTimes;
  String? notificationTriggerHabitId;

  Habit toEntity() {
    return Habit(
      id: id,
      name: name,
      createdAt: createdAt,
      archivedAt: archivedAt,
      scheduleType: HabitScheduleType.values[scheduleType],
      scheduleDays: scheduleDays,
      scheduleDates: scheduleDates,
      identityStatement: identityStatement,
      implementationTime: implementationTime,
      implementationLocation: implementationLocation,
      twoMinuteVersion: twoMinuteVersion,
      colorHex: colorHex,
      category: category,
      notes: notes,
      displayOrder: displayOrder,
      notificationsEnabled: notificationsEnabled,
      notificationTimes: notificationTimes,
      notificationTriggerHabitId: notificationTriggerHabitId,
    );
  }

  static HabitModel fromEntity(Habit entity) {
    return HabitModel(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
      archivedAt: entity.archivedAt,
      scheduleType: entity.scheduleType.index,
      scheduleDays: entity.scheduleDays,
      scheduleDates: entity.scheduleDates,
      identityStatement: entity.identityStatement,
      implementationTime: entity.implementationTime,
      implementationLocation: entity.implementationLocation,
      twoMinuteVersion: entity.twoMinuteVersion,
      colorHex: entity.colorHex,
      category: entity.category,
      notes: entity.notes,
      displayOrder: entity.displayOrder,
      notificationsEnabled: entity.notificationsEnabled,
      notificationTimes: entity.notificationTimes,
      notificationTriggerHabitId: entity.notificationTriggerHabitId,
    );
  }
}

class HabitModelAdapter extends TypeAdapter<HabitModel> {
  @override
  final int typeId = 0;

  @override
  HabitModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }

    return HabitModel(
      id: fields[0] as String,
      name: fields[1] as String,
      createdAt: fields[2] as DateTime,
      archivedAt: fields[3] as DateTime?,
      scheduleType: fields[4] as int,
      scheduleDays: (fields[5] as List?)?.cast<int>(),
      scheduleDates: (fields[6] as List?)?.cast<int>(),
      identityStatement: fields[7] as String?,
      implementationTime: fields[8] as String?,
      implementationLocation: fields[9] as String?,
      twoMinuteVersion: fields[10] as String?,
      colorHex: fields[11] as String?,
      category: fields[12] as String?,
      notes: fields[13] as String?,
      displayOrder: fields[14] as int,
      notificationsEnabled: fields[15] as bool,
      notificationTimes: (fields[16] as List?)?.cast<String>(),
      notificationTriggerHabitId: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HabitModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.archivedAt)
      ..writeByte(4)
      ..write(obj.scheduleType)
      ..writeByte(5)
      ..write(obj.scheduleDays)
      ..writeByte(6)
      ..write(obj.scheduleDates)
      ..writeByte(7)
      ..write(obj.identityStatement)
      ..writeByte(8)
      ..write(obj.implementationTime)
      ..writeByte(9)
      ..write(obj.implementationLocation)
      ..writeByte(10)
      ..write(obj.twoMinuteVersion)
      ..writeByte(11)
      ..write(obj.colorHex)
      ..writeByte(12)
      ..write(obj.category)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.displayOrder)
      ..writeByte(15)
      ..write(obj.notificationsEnabled)
      ..writeByte(16)
      ..write(obj.notificationTimes)
      ..writeByte(17)
      ..write(obj.notificationTriggerHabitId);
  }
}
