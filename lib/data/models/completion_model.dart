import 'package:hive/hive.dart';
import '../../domain/entities/completion.dart';

class CompletionModel {
  CompletionModel({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completedAt,
    required this.completionType,
    required this.wasEdited,
    this.skipReason,
    this.note,
  });

  String id;
  String habitId;
  DateTime date;
  DateTime completedAt;
  int completionType;
  String? skipReason;
  String? note;
  bool wasEdited;

  Completion toEntity() {
    return Completion(
      id: id,
      habitId: habitId,
      date: date,
      completedAt: completedAt,
      completionType: HabitCompletionType.values[completionType],
      skipReason: skipReason,
      note: note,
      wasEdited: wasEdited,
    );
  }

  static CompletionModel fromEntity(Completion entity) {
    return CompletionModel(
      id: entity.id,
      habitId: entity.habitId,
      date: entity.date,
      completedAt: entity.completedAt,
      completionType: entity.completionType.index,
      skipReason: entity.skipReason,
      note: entity.note,
      wasEdited: entity.wasEdited,
    );
  }
}

class CompletionModelAdapter extends TypeAdapter<CompletionModel> {
  @override
  final int typeId = 1;

  @override
  CompletionModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }

    return CompletionModel(
      id: fields[0] as String,
      habitId: fields[1] as String,
      date: fields[2] as DateTime,
      completedAt: fields[3] as DateTime,
      completionType: fields[4] as int,
      skipReason: fields[5] as String?,
      note: fields[6] as String?,
      wasEdited: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CompletionModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.completedAt)
      ..writeByte(4)
      ..write(obj.completionType)
      ..writeByte(5)
      ..write(obj.skipReason)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.wasEdited);
  }
}
