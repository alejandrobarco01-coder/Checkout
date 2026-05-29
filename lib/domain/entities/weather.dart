/// Entidad de dominio: datos del clima.
class Weather {
  final String ciudad;
  final double temperatura;
  final String descripcion;
  final String icono;
  final bool esLluvia;

  const Weather({
    required this.ciudad,
    required this.temperatura,
    required this.descripcion,
    required this.icono,
    required this.esLluvia,
  });

  String get iconUrl => 'https://openweathermap.org/img/wn/$icono@2x.png';
}
