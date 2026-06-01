import 'package:flutter/material.dart';
import '../../data/datasources/remote/weather_api.dart';
import '../../domain/entities/weather.dart';
import '../../core/notification_service.dart';

/// Recomendación simple: nombre y emoji
class WeatherRecommendation {
  final String nombre;
  final String emoji;
  WeatherRecommendation(this.nombre, this.emoji);
}

/// Estados de carga del clima.
enum WeatherStatus { initial, loading, success, error }

/// Provider del clima.
/// Consume OpenWeatherMap y expone el estado de la petición.
class WeatherProvider extends ChangeNotifier {
  final WeatherApiDataSource _api = WeatherApiDataSource();

  WeatherStatus _status = WeatherStatus.initial;
  Weather? _weather;
  String? _errorMessage;
  List<WeatherRecommendation> _recommendations = [];

  List<WeatherRecommendation> get recommendations => _recommendations;

  WeatherStatus get status => _status;
  Weather? get weather => _weather;
  String? get errorMessage => _errorMessage;
  bool get isRaining => _weather?.esLluvia ?? false;

  Future<void> fetchWeather(String city) async {
    if (_status == WeatherStatus.loading) return;

    _status = WeatherStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _weather = await _api.getWeather(city);
      _status = WeatherStatus.success;
      // Generar recomendaciones basadas en el clima
      _generateRecommendations();
      // Notificar al usuario para cambios importantes
      _maybeNotify();
    } on WeatherApiException catch (e) {
      _errorMessage = e.message;
      _status = WeatherStatus.error;
      debugPrint('⚠️ Error obteniendo clima: ${e.message}');
      // Usar recomendaciones por defecto si falla la API
      _useDefaultRecommendations();
    } catch (e) {
      _errorMessage = e.toString();
      _status = WeatherStatus.error;
      debugPrint('⚠️ Error inesperado: $e');
      _useDefaultRecommendations();
    }

    notifyListeners();
  }

  Future<void> fetchWeatherByCoordinates({
    required double lat,
    required double lng,
    String label = 'Ubicación actual',
  }) async {
    if (_status == WeatherStatus.loading) return;

    _status = WeatherStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _weather = await _api.getWeatherByCoordinates(
        lat: lat,
        lng: lng,
        label: label,
      );
      _status = WeatherStatus.success;
      _generateRecommendations();
      _maybeNotify();
    } on WeatherApiException catch (e) {
      _errorMessage = e.message;
      _status = WeatherStatus.error;
      debugPrint('⚠️ Error obteniendo clima: ${e.message}');
      _useDefaultRecommendations();
    } catch (e) {
      _errorMessage = e.toString();
      _status = WeatherStatus.error;
      debugPrint('⚠️ Error inesperado: $e');
      _useDefaultRecommendations();
    }

    notifyListeners();
  }

  /// Recomendaciones por defecto cuando la API falla
  void _useDefaultRecommendations() {
    _recommendations = [
      WeatherRecommendation('Bolsa', '🎒'),
      WeatherRecommendation('Botella de agua', '💧'),
      WeatherRecommendation('Teléfono', '📱'),
      WeatherRecommendation('Dinero', '💰'),
    ];
  }

  void _generateRecommendations() {
    _recommendations = [];
    if (_weather == null) return;

    final desc = _weather!.descripcion.toLowerCase();
    final temp = _weather!.temperatura;
    final hum = _weather!.humedad;

    // Lluvia
    if (_weather!.esLluvia || desc.contains('lluv')) {
      _recommendations.addAll([
        WeatherRecommendation('Paraguas', '☔️'),
        WeatherRecommendation('Chubasquero', '🧥'),
        WeatherRecommendation('Zapatos impermeables', '👢'),
      ]);
    }

    // Nieve
    if (desc.contains('nieve')) {
      _recommendations.addAll([
        WeatherRecommendation('Botas', '🥾'),
        WeatherRecommendation('Guantes', '🧤'),
      ]);
    }

    // Temperatura
    if (temp <= 5) {
      _recommendations.addAll([
        WeatherRecommendation('Abrigo', '🧥'),
        WeatherRecommendation('Bufanda', '🧣'),
        WeatherRecommendation('Guantes', '🧤'),
      ]);
    } else if (temp <= 8) {
      _recommendations.addAll([
        WeatherRecommendation('Abrigo', '🧥'),
        WeatherRecommendation('Bufanda', '🧣'),
      ]);
    } else if (temp <= 15) {
      _recommendations.add(WeatherRecommendation('Chaqueta ligera', '🧥'));
    } else if (temp >= 25) {
      _recommendations.addAll([
        WeatherRecommendation('Protector solar', '🧴'),
        WeatherRecommendation('Gorra', '🧢'),
        WeatherRecommendation('Botella de agua', '💧'),
      ]);
    }

    // Humedad alta
    if (hum >= 80 &&
        !_recommendations.any((r) => r.nombre.contains('Botella'))) {
      _recommendations.add(WeatherRecommendation('Botella de agua', '💧'));
    }

    // SIEMPRE mostrar esenciales si no hay nada recomendado
    if (_recommendations.isEmpty) {
      _recommendations.addAll([
        WeatherRecommendation('Bolsa', '🎒'),
        WeatherRecommendation('Botella de agua', '💧'),
      ]);
    }

    notifyListeners();
  }

  Future<void> _maybeNotify() async {
    if (_weather == null) return;

    final desc = _weather!.descripcion.toLowerCase();
    try {
      if (_weather!.esLluvia || desc.contains('lluv')) {
        await NotificationService.instance.showNotification(
            title: 'Atención: lluvia',
            body:
                'Se espera lluvia. Te recomendamos llevar paraguas y chubasquero.');
      } else if (_weather!.temperatura <= 5) {
        await NotificationService.instance.showNotification(
            title: 'Frío extremo',
            body: 'Hace mucho frío. Lleva abrigo y guantes.');
      }
    } catch (e) {
      debugPrint('Notificación falló: $e');
    }
  }

  void reset() {
    _status = WeatherStatus.initial;
    _weather = null;
    _errorMessage = null;
    notifyListeners();
  }
}
