import '../../domain/entities/item.dart';

/// Modelo de datos para ítems en SQLite.
class ItemModel {
  final int? id;
  final int checklistId;
  final String nombre;
  final bool completado;
  final double pesoKg;

  const ItemModel({
    this.id,
    required this.checklistId,
    required this.nombre,
    required this.completado,
    required this.pesoKg,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] as int?,
      checklistId: map['checklist_id'] as int,
      nombre: map['nombre'] as String,
      completado: (map['completado'] as int) == 1,
      pesoKg: (map['peso_kg'] as num).toDouble(),
    );
  }

  factory ItemModel.fromEntity(Item entity) {
    return ItemModel(
      id: entity.id,
      checklistId: entity.checklistId,
      nombre: entity.nombre,
      completado: entity.completado,
      pesoKg: entity.pesoKg,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'checklist_id': checklistId,
      'nombre': nombre,
      'completado': completado ? 1 : 0,
      'peso_kg': pesoKg,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  Item toEntity() {
    return Item(
      id: id,
      checklistId: checklistId,
      nombre: nombre,
      completado: completado,
      pesoKg: pesoKg,
    );
  }
}
