class HabitCategory {
  const HabitCategory({
    required this.id,
    required this.name,
    required this.displayOrder,
    this.colorHex,
  });

  final String id;
  final String name;
  final String? colorHex;
  final int displayOrder;

  HabitCategory copyWith({
    String? id,
    String? name,
    String? colorHex,
    int? displayOrder,
  }) {
    return HabitCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitCategory &&
        other.id == id &&
        other.name == name &&
        other.colorHex == colorHex &&
        other.displayOrder == displayOrder;
  }

  @override
  int get hashCode => Object.hash(id, name, colorHex, displayOrder);
}
