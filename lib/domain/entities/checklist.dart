/// Entidad de dominio: Checklist.
/// Es independiente de la base de datos o la API (capa de dominio puro).
class Checklist {
  final int? id;
  final String nombre;
  final String tipoSalida;
  final DateTime fechaCreacion;

  const Checklist({
    this.id,
    required this.nombre,
    required this.tipoSalida,
    required this.fechaCreacion,
  });

  Checklist copyWith({
    int? id,
    String? nombre,
    String? tipoSalida,
    DateTime? fechaCreacion,
  }) {
    return Checklist(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipoSalida: tipoSalida ?? this.tipoSalida,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
