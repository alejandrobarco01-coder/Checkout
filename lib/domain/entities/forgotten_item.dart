/// Entidad de dominio: un ítem que el usuario ha olvidado empacar.
class ForgottenItem {
  final int? id;
  final String nombre;
  final String tipoSalida;
  final int veces;
  final DateTime ultimaFecha;

  const ForgottenItem({
    this.id,
    required this.nombre,
    required this.tipoSalida,
    required this.veces,
    required this.ultimaFecha,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'tipo_salida': tipoSalida,
        'veces': veces,
        'ultima_fecha': ultimaFecha.toIso8601String(),
      };

  factory ForgottenItem.fromMap(Map<String, dynamic> map) => ForgottenItem(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        tipoSalida: map['tipo_salida'] as String,
        veces: map['veces'] as int,
        ultimaFecha: DateTime.parse(map['ultima_fecha'] as String),
      );
}
