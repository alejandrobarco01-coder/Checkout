import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants.dart';
import '../../../domain/entities/weather.dart';

/// Fuente de datos remota: OpenWeatherMap API.
/// Maneja estados: loading, success, error.
class WeatherApiDataSource {
  /// Obtiene el clima actual para una ciudad.
  /// Lanza [WeatherApiException] si la petición falla.
  Future<Weather> getWeather(String city) async {
    final uri = Uri.parse(
      '${AppConstants.weatherBaseUrl}/weather'
      '?q=${Uri.encodeComponent(city)}'
      '&appid=${AppConstants.weatherApiKey}'
      '&units=metric'
      '&lang=es',
    );

    final response = await http.get(uri).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw WeatherApiException('Tiempo de espera agotado'),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseWeather(json);
    } else if (response.statusCode == 401) {
      throw WeatherApiException('API Key inválida');
    } else if (response.statusCode == 404) {
      throw WeatherApiException('Ciudad no encontrada: $city');
    } else {
      throw WeatherApiException('Error HTTP ${response.statusCode}');
    }
  }

  Weather _parseWeather(Map<String, dynamic> json) {
    final weatherList = json['weather'] as List;
    final weatherData = weatherList.first as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>;

    final descripcion = weatherData['description'] as String? ?? '';
    final icono = weatherData['icon'] as String? ?? '01d';
    final id = weatherData['id'] as int? ?? 800;

    // Códigos 2xx, 3xx y 5xx son lluvia/tormenta/llovizna en OWM
    final esLluvia = id < 700;

    return Weather(
      ciudad: json['name'] as String? ?? '',
      temperatura: (main['temp'] as num).toDouble(),
      descripcion: descripcion,
      icono: icono,
      esLluvia: esLluvia,
    );
  }
}

class WeatherApiException implements Exception {
  final String message;
  const WeatherApiException(this.message);
  @override
  String toString() => 'WeatherApiException: $message';
}
