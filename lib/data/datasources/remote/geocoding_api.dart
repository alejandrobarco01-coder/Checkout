import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resultado de geocoding con Nominatim/Overpass/Google.
class GeocodingResult {
  final String displayName;
  final double lat;
  final double lng;

  const GeocodingResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });
}

/// Cliente HTTP para búsqueda de destinos vía Nominatim, Overpass y Google Places.
class GeocodingApi {
  static const _nominatimBase = 'https://nominatim.openstreetmap.org';

  // Servidores espejo de Overpass de alta velocidad para tolerancia a fallos
  static const _overpassEndpoints = [
    'https://lz4.overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://overpass-api.de/api/interpreter',
    'https://z.overpass-api.de/api/interpreter',
  ];

  /// Búsqueda de POIs cercanos usando Google Places API (New)
  /// Retorna null si no hay API key configurada, para hacer fallback a OpenStreetMap.
  Future<List<GeocodingResult>?> searchNearbyGoogle({
    required String placeType, // ej: "gym", "supermarket", "hospital"
    required double lat,
    required double lng,
    double radiusMeters = 3000,
  }) async {
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ??
        dotenv.env['GOOGLE_MAPS_API_KEY'] ??
        '';
    if (apiKey.isEmpty) return null; // No hay clave, usar OSM

    final uri =
        Uri.parse('https://places.googleapis.com/v1/places:searchNearby');
    final body = jsonEncode({
      "includedTypes": [placeType],
      "maxResultCount": 15,
      "locationRestriction": {
        "circle": {
          "center": {"latitude": lat, "longitude": lng},
          "radius": radiusMeters
        }
      }
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'X-Goog-Api-Key': apiKey,
              'X-Goog-FieldMask':
                  'places.displayName,places.formattedAddress,places.location',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final places = data['places'] as List? ?? [];

      return places.map((p) {
        final map = p as Map<String, dynamic>;
        final name = map['displayName']?['text'] as String? ?? 'Sin nombre';
        final address = map['formattedAddress'] as String? ?? '';
        final location = map['location'] as Map<String, dynamic>?;

        final displayName = address.isNotEmpty ? '$name — $address' : name;

        return GeocodingResult(
          displayName: displayName,
          lat: (location?['latitude'] as num?)?.toDouble() ?? 0,
          lng: (location?['longitude'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
    } catch (e) {
      return null;
    }
  }

  /// Búsqueda general de texto vía Nominatim.
  Future<List<GeocodingResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('$_nominatimBase/search').replace(queryParameters: {
      'q': query.trim(),
      'format': 'json',
      'limit': '5',
    });

    final response = await http.get(
      uri,
      headers: {'User-Agent': 'CheckOut/1.0'},
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as List;
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return GeocodingResult(
        displayName: map['display_name'] as String? ?? query,
        lat: double.parse(map['lat'] as String),
        lng: double.parse(map['lon'] as String),
      );
    }).toList();
  }

  /// Búsqueda de POIs (puntos de interés) cercanos usando Overpass API.
  /// [overpassFilter] es el filtro OSM, ej: `["amenity"="supermarket"]`
  Future<List<GeocodingResult>> searchByOsmTag({
    required String overpassFilter,
    required double lat,
    required double lng,
    double radiusMeters = 3000,
    int limit = 10,
  }) async {
    // Si el filtro utiliza expresiones regulares (operador ~ y |), lo optimizamos
    // transformándolo en múltiples consultas indexadas directas. Es 10x más rápido.
    String subQueries = '';
    if (overpassFilter.contains('~') && overpassFilter.contains('|')) {
      final match =
          RegExp(r'\["([^"]+)"\s*~\s*"([^"]+)"\]').firstMatch(overpassFilter);
      if (match != null) {
        final key = match.group(1)!;
        final values = match.group(2)!.split('|');
        final nodes = values
            .map((val) =>
                '  node["$key"="$val"](around:$radiusMeters,$lat,$lng);')
            .join('\n');
        final ways = values
            .map((val) =>
                '  way["$key"="$val"](around:$radiusMeters,$lat,$lng);')
            .join('\n');
        subQueries = '$nodes\n$ways';
      }
    }

    if (subQueries.isEmpty) {
      subQueries = '''
  node$overpassFilter(around:$radiusMeters,$lat,$lng);
  way$overpassFilter(around:$radiusMeters,$lat,$lng);
''';
    }

    final query = '''
[out:json][timeout:8];
(
$subQueries
);
out center $limit;
''';

    // Rotación de servidores espejo en caso de fallos o lentitud
    for (final endpoint in _overpassEndpoints) {
      try {
        final response = await http.post(
          Uri.parse(endpoint),
          body: {'data': query}, // Codificado correctamente como formulario
          headers: {'User-Agent': 'CheckOut/1.0'},
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode != 200) {
          continue; // Intenta con el siguiente servidor espejo
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = data['elements'] as List? ?? [];

        final results = <GeocodingResult>[];
        for (final el in elements) {
          final map = el as Map<String, dynamic>;
          double? elLat = (map['lat'] as num?)?.toDouble();
          double? elLng = (map['lon'] as num?)?.toDouble();

          // Para ways, usar el centro
          if (elLat == null && map['center'] != null) {
            final center = map['center'] as Map<String, dynamic>;
            elLat = (center['lat'] as num?)?.toDouble();
            elLng = (center['lon'] as num?)?.toDouble();
          }

          if (elLat == null || elLng == null) continue;

          final tags = map['tags'] as Map<String, dynamic>? ?? {};
          final name = tags['name'] as String? ??
              tags['brand'] as String? ??
              'Sin nombre';
          final addr = tags['addr:street'] as String? ?? '';
          final displayName = addr.isNotEmpty ? '$name — $addr' : name;

          results.add(GeocodingResult(
            displayName: displayName,
            lat: elLat,
            lng: elLng,
          ));

          if (results.length >= limit) break;
        }

        if (results.isNotEmpty) {
          return results; // Éxito
        }
      } catch (e) {
        // Ignora el error y salta al siguiente servidor espejo
        continue;
      }
    }
    return [];
  }

  /// Búsqueda de playas en todo el país usando Nominatim.
  /// Primero obtiene el nombre del país desde la ubicación actual
  /// y luego busca playas en ese país.
  Future<List<GeocodingResult>> searchBeachesInCountry({
    required double lat,
    required double lng,
  }) async {
    // 1. Reverse geocoding para obtener el país
    String country = '';
    try {
      final reverseUri =
          Uri.parse('$_nominatimBase/reverse').replace(queryParameters: {
        'lat': '$lat',
        'lon': '$lng',
        'format': 'json',
        'zoom': '3',
      });
      final reverseRes = await http.get(
        reverseUri,
        headers: {'User-Agent': 'CheckOut/1.0'},
      );
      if (reverseRes.statusCode == 200) {
        final reverseData = jsonDecode(reverseRes.body) as Map<String, dynamic>;
        final address = reverseData['address'] as Map<String, dynamic>? ?? {};
        country = address['country'] as String? ?? '';
      }
    } catch (_) {}

    // 2. Buscar playas en el país encontrado usando Overpass con área grande
    // Si no tenemos país, fallback a búsqueda cercana
    if (country.isEmpty) {
      return searchByOsmTag(
        overpassFilter: '["natural"="beach"]',
        lat: lat,
        lng: lng,
        radiusMeters: 150000,
      );
    }

    // Búsqueda Overpass en una región amplia del país (radio de 500km)
    return searchByOsmTag(
      overpassFilter: '["natural"="beach"]',
      lat: lat,
      lng: lng,
      radiusMeters: 500000,
      limit: 15,
    );
  }

  /// Búsqueda cercana genérica via Nominatim (fallback).
  Future<List<GeocodingResult>> searchNearby({
    required String query,
    required double lat,
    required double lng,
  }) async {
    if (query.trim().isEmpty) return [];

    const delta = 0.08;
    final uri = Uri.parse('$_nominatimBase/search').replace(queryParameters: {
      'q': query.trim(),
      'format': 'json',
      'limit': '8',
      'bounded': '1',
      'viewbox': '${lng - delta},${lat + delta},${lng + delta},${lat - delta}',
    });

    final response = await http.get(
      uri,
      headers: {'User-Agent': 'CheckOut/1.0'},
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as List;
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return GeocodingResult(
        displayName: map['display_name'] as String? ?? query,
        lat: double.parse(map['lat'] as String),
        lng: double.parse(map['lon'] as String),
      );
    }).toList();
  }
}
