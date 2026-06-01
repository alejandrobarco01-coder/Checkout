/// Entidad de dominio: un evento del calendario personal.
class CalendarEvent {
  final int? id;
  final String titulo;
  final String? descripcion;
  final String tipo; // 'viaje', 'cita', 'reunion', 'otro'
  final DateTime fecha;
  final String? hora; // Formato HH:mm
  final String? destino;
  final double? lat;
  final double? lng;
  final int? color; // Color en formato ARGB int

  const CalendarEvent({
    this.id,
    required this.titulo,
    this.descripcion,
    required this.tipo,
    required this.fecha,
    this.hora,
    this.destino,
    this.lat,
    this.lng,
    this.color,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'titulo': titulo,
        'descripcion': descripcion,
        'tipo': tipo,
        'fecha': fecha.toIso8601String().substring(0, 10),
        'hora': hora,
        'destino': destino,
        'lat': lat,
        'lng': lng,
        'color': color,
      };

  factory CalendarEvent.fromMap(Map<String, dynamic> map) => CalendarEvent(
        id: map['id'] as int?,
        titulo: map['titulo'] as String,
        descripcion: map['descripcion'] as String?,
        tipo: map['tipo'] as String? ?? 'otro',
        fecha: DateTime.parse(map['fecha'] as String),
        hora: map['hora'] as String?,
        destino: map['destino'] as String?,
        lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
        lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
        color: map['color'] as int?,
      );
}
