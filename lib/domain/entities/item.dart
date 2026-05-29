/// Entidad de dominio: Item de un checklist.
class Item {
  final int? id;
  final int checklistId;
  final String nombre;
  final bool completado;
  final double pesoKg;

  const Item({
    this.id,
    required this.checklistId,
    required this.nombre,
    this.completado = false,
    this.pesoKg = 0.0,
  });

  Item copyWith({
    int? id,
    int? checklistId,
    String? nombre,
    bool? completado,
    double? pesoKg,
  }) {
    return Item(
      id: id ?? this.id,
      checklistId: checklistId ?? this.checklistId,
      nombre: nombre ?? this.nombre,
      completado: completado ?? this.completado,
      pesoKg: pesoKg ?? this.pesoKg,
    );
  }
}
