import 'package:hive/hive.dart';
import '../../domain/entities/habit_stack.dart';

class HabitStackModel {
  HabitStackModel({
    required this.id,
    required this.previousHabitId,
    required this.nextHabitId,
    required this.createdAt,
  });

  String id;
  String previousHabitId;
  String nextHabitId;
  DateTime createdAt;

  HabitStack toEntity() {
    return HabitStack(
      id: id,
      previousHabitId: previousHabitId,
      nextHabitId: nextHabitId,
      createdAt: createdAt,
    );
  }

  static HabitStackModel fromEntity(HabitStack entity) {
    return HabitStackModel(
      id: entity.id,
      previousHabitId: entity.previousHabitId,
      nextHabitId: entity.nextHabitId,
      createdAt: entity.createdAt,
    );
  }
}

class HabitStackModelAdapter extends TypeAdapter<HabitStackModel> {
  @override
  final int typeId = 2;

  @override
  HabitStackModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }

    return HabitStackModel(
      id: fields[0] as String,
      previousHabitId: fields[1] as String,
      nextHabitId: fields[2] as String,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HabitStackModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.previousHabitId)
      ..writeByte(2)
      ..write(obj.nextHabitId)
      ..writeByte(3)
      ..write(obj.createdAt);
  }
}
