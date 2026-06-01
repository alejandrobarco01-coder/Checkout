import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/entities/weather.dart';

/// Fuente de datos remota: Open-Meteo.
/// Maneja estados: loading, success, error.
class WeatherApiDataSource {
  /// Obtiene el clima actual para una ciudad.
  /// Lanza [WeatherApiException] si la petición falla.
  Future<Weather> getWeather(String city) async {
    final place = await _geocode(city);
    return getWeatherByCoordinates(
      lat: place.lat,
      lng: place.lng,
      label: place.name,
    );
  }

  Future<Weather> getWeatherByCoordinates({
    required double lat,
    required double lng,
    String label = 'Ubicación actual',
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lng',
      'current': 'temperature_2m,relative_humidity_2m,weather_code',
      'timezone': 'auto',
    });

    final response = await http.get(uri).timeout(
          const Duration(seconds: 10),
          onTimeout: () =>
              throw WeatherApiException('Tiempo de espera agotado'),
        );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseWeather(json, label);
    } else {
      throw WeatherApiException('Error HTTP ${response.statusCode}');
    }
  }

  Future<_WeatherPlace> _geocode(String city) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': city.trim().isEmpty ? 'Madrid' : city.trim(),
      'count': '1',
      'language': 'es',
      'format': 'json',
    });

    final response = await http.get(uri).timeout(
          const Duration(seconds: 10),
          onTimeout: () =>
              throw WeatherApiException('Tiempo de espera agotado'),
        );

    if (response.statusCode != 200) {
      throw WeatherApiException('No se pudo buscar la ciudad');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = json['results'] as List? ?? [];
    if (results.isEmpty) {
      throw WeatherApiException('Ciudad no encontrada: $city');
    }

    final first = results.first as Map<String, dynamic>;
    return _WeatherPlace(
      name: first['name'] as String? ?? city,
      lat: (first['latitude'] as num).toDouble(),
      lng: (first['longitude'] as num).toDouble(),
    );
  }

  Weather _parseWeather(Map<String, dynamic> json, String city) {
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final code = (current['weather_code'] as num?)?.toInt() ?? 0;
    final description = _descriptionFor(code);

    final rainCodes = {
      51,
      53,
      55,
      56,
      57,
      61,
      63,
      65,
      66,
      67,
      80,
      81,
      82,
      95,
      96,
      99,
    };

    return Weather(
      ciudad: city,
      temperatura: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      descripcion: description,
      icono: '01d',
      esLluvia: rainCodes.contains(code),
      humedad: (current['relative_humidity_2m'] as num?)?.toDouble() ?? 0,
    );
  }

  String _descriptionFor(int code) {
    if (code == 0) return 'despejado';
    if (code == 1) return 'mayormente despejado';
    if (code == 2) return 'parcialmente nublado';
    if (code == 3) return 'nublado';
    if (code == 45 || code == 48) return 'niebla';
    if (code >= 51 && code <= 57) return 'llovizna';
    if (code >= 61 && code <= 67) return 'lluvia';
    if (code >= 71 && code <= 77) return 'nieve';
    if (code >= 80 && code <= 82) return 'chubascos';
    if (code >= 95) return 'tormenta';
    return 'clima variable';
  }
}

class _WeatherPlace {
  final String name;
  final double lat;
  final double lng;

  const _WeatherPlace({
    required this.name,
    required this.lat,
    required this.lng,
  });
}

class WeatherApiException implements Exception {
  final String message;
  const WeatherApiException(this.message);
  @override
  String toString() => 'WeatherApiException: $message';
}
