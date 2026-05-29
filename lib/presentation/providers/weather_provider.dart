import 'package:flutter/material.dart';
import '../../data/datasources/remote/weather_api.dart';
import '../../domain/entities/weather.dart';

/// Estados de carga del clima.
enum WeatherStatus { initial, loading, success, error }

/// Provider del clima.
/// Consume OpenWeatherMap y expone el estado de la petición.
class WeatherProvider extends ChangeNotifier {
  final WeatherApiDataSource _api = WeatherApiDataSource();

  WeatherStatus _status = WeatherStatus.initial;
  Weather? _weather;
  String? _errorMessage;

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
    } on WeatherApiException catch (e) {
      _errorMessage = e.message;
      _status = WeatherStatus.error;
    } catch (e) {
      _errorMessage = 'Error al obtener el clima';
      _status = WeatherStatus.error;
    }

    notifyListeners();
  }

  void reset() {
    _status = WeatherStatus.initial;
    _weather = null;
    _errorMessage = null;
    notifyListeners();
  }
}
