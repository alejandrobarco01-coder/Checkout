import '../../domain/entities/checklist.dart';

/// Modelo de datos para la capa de persistencia SQLite.
/// Convierte entre Map (SQLite) y entidad de dominio.
class ChecklistModel {
  final int? id;
  final String nombre;
  final String tipoSalida;
  final String fechaCreacion; // Guardado como ISO 8601

  const ChecklistModel({
    this.id,
    required this.nombre,
    required this.tipoSalida,
    required this.fechaCreacion,
  });

  factory ChecklistModel.fromMap(Map<String, dynamic> map) {
    return ChecklistModel(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      tipoSalida: map['tipo_salida'] as String,
      fechaCreacion: map['fecha_creacion'] as String,
    );
  }

  factory ChecklistModel.fromEntity(Checklist entity) {
    return ChecklistModel(
      id: entity.id,
      nombre: entity.nombre,
      tipoSalida: entity.tipoSalida,
      fechaCreacion: entity.fechaCreacion.toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'tipo_salida': tipoSalida,
      'fecha_creacion': fechaCreacion,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  Checklist toEntity() {
    return Checklist(
      id: id,
      nombre: nombre,
      tipoSalida: tipoSalida,
      fechaCreacion: DateTime.parse(fechaCreacion),
    );
  }
}
