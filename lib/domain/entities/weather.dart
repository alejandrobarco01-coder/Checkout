/// Entidad de dominio: datos del clima.
class Weather {
  final String ciudad;
  final double temperatura;
  final String descripcion;
  final String icono;
  final bool esLluvia;
  final double humedad;

  const Weather({
    required this.ciudad,
    required this.temperatura,
    required this.descripcion,
    required this.icono,
    required this.esLluvia,
    this.humedad = 0,
  });

  String get iconUrl => 'https://openweathermap.org/img/wn/$icono@2x.png';
}
