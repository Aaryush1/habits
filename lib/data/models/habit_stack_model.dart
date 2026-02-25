import 'package:hive/hive.dart';
import '../../domain/entities/stack.dart';

class HabitStackModel {
  HabitStackModel({
    required this.id,
    required this.name,
    required this.habitIds,
    required this.createdAt,
    this.description,
    this.iconEmoji,
    this.chainNotificationsEnabled = false,
  });

  String id;
  String name;
  List<String> habitIds;
  DateTime createdAt;
  String? description;
  String? iconEmoji;
  bool chainNotificationsEnabled;

  HabitStack toEntity() {
    return HabitStack(
      id: id,
      name: name,
      habitIds: habitIds,
      createdAt: createdAt,
      description: description,
      iconEmoji: iconEmoji,
      chainNotificationsEnabled: chainNotificationsEnabled,
    );
  }

  static HabitStackModel fromEntity(HabitStack entity) {
    return HabitStackModel(
      id: entity.id,
      name: entity.name,
      habitIds: entity.habitIds,
      createdAt: entity.createdAt,
      description: entity.description,
      iconEmoji: entity.iconEmoji,
      chainNotificationsEnabled: entity.chainNotificationsEnabled,
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
      name: fields[1] as String? ?? '',
      habitIds: (fields[2] as List?)?.cast<String>() ?? <String>[],
      createdAt: fields[3] as DateTime,
      description: fields[4] as String?,
      iconEmoji: fields[5] as String?,
      chainNotificationsEnabled: fields[6] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, HabitStackModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.habitIds)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.iconEmoji)
      ..writeByte(6)
      ..write(obj.chainNotificationsEnabled);
  }
}
