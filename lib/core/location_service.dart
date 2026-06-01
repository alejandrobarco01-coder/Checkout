import 'package:geolocator/geolocator.dart';

class CurrentLocation {
  final double lat;
  final double lng;

  const CurrentLocation({
    required this.lat,
    required this.lng,
  });
}

class LocationService {
  LocationService._();
  static final instance = LocationService._();

  Future<CurrentLocation> getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationServiceException(
        'Activa la ubicación del dispositivo para detectar tu zona.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationServiceException(
        'Permiso de ubicación denegado.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'El permiso de ubicación está bloqueado. Actívalo en ajustes.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );

    return CurrentLocation(
      lat: position.latitude,
      lng: position.longitude,
    );
  }
}

class LocationServiceException implements Exception {
  final String message;

  const LocationServiceException(this.message);

  @override
  String toString() => message;
}
