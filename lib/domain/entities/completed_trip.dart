/// Registro histórico al completar una salida (esquema SQLite legado).
class CompletedTrip {
  final int? id;
  final String nombre;
  final String tipoSalida;
  final String destino;
  final DateTime fechaSalida;
  final double porcentajeCompletado;
  final double pesoTotalKg;
  final double? lat;
  final double? lng;

  const CompletedTrip({
    this.id,
    required this.nombre,
    required this.tipoSalida,
    required this.destino,
    required this.fechaSalida,
    required this.porcentajeCompletado,
    required this.pesoTotalKg,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'nombre': nombre,
        'tipo_salida': tipoSalida,
        'destino': destino,
        'fecha_salida': fechaSalida.toIso8601String(),
        'porcentaje': porcentajeCompletado,
        'peso_total_kg': pesoTotalKg,
        'lat': lat,
        'lng': lng,
      };

  factory CompletedTrip.fromMap(Map<String, dynamic> map) => CompletedTrip(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        tipoSalida: map['tipo_salida'] as String,
        destino: map['destino'] as String? ?? '',
        fechaSalida: DateTime.parse(map['fecha_salida'] as String),
        porcentajeCompletado: (map['porcentaje'] as num).toDouble(),
        pesoTotalKg: (map['peso_total_kg'] as num).toDouble(),
        lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
        lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
      );
}
