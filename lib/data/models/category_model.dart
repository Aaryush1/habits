import 'package:hive/hive.dart';
import '../../domain/entities/category.dart';

class CategoryModel {
  CategoryModel({
    required this.id,
    required this.name,
    required this.displayOrder,
    this.colorHex,
  });

  String id;
  String name;
  String? colorHex;
  int displayOrder;

  HabitCategory toEntity() {
    return HabitCategory(
      id: id,
      name: name,
      colorHex: colorHex,
      displayOrder: displayOrder,
    );
  }

  static CategoryModel fromEntity(HabitCategory entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      colorHex: entity.colorHex,
      displayOrder: entity.displayOrder,
    );
  }
}

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 3;

  @override
  CategoryModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }

    return CategoryModel(
      id: fields[0] as String,
      name: fields[1] as String,
      colorHex: fields[2] as String?,
      displayOrder: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorHex)
      ..writeByte(3)
      ..write(obj.displayOrder);
  }
}
