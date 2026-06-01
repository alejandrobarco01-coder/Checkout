import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../models/destination_model.dart';
import '../../../domain/entities/destination.dart';

/// Google Places API (New) vía HTTP.
class PlacesRemoteDataSource {
  static const _baseUrl = 'https://places.googleapis.com/v1';
  static const _nominatimBase = 'https://nominatim.openstreetmap.org';

  String get _apiKey =>
      dotenv.env['GOOGLE_PLACES_API_KEY'] ??
      dotenv.env['GOOGLE_MAPS_API_KEY'] ??
      '';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
      };

  Future<List<DestinationModel>> searchDestinations(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return [];
    if (_apiKey.isEmpty) return _searchWithNominatim(cleanQuery);

    final uri = Uri.parse('$_baseUrl/places:autocomplete');
    final body = jsonEncode({
      'input': cleanQuery,
      'languageCode': 'es',
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {
              ..._headers,
              'X-Goog-FieldMask':
                  'suggestions.placePrediction.placeId,suggestions.placePrediction.text,suggestions.placePrediction.structuredFormat',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint(
          'Places autocomplete: ${response.statusCode} ${response.body}',
        );
        return _searchWithNominatim(cleanQuery);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final suggestions = json['suggestions'] as List? ?? [];
      final results = <DestinationModel>[];

      for (final raw in suggestions.take(5)) {
        final suggestion = raw as Map<String, dynamic>;
        final prediction =
            suggestion['placePrediction'] as Map<String, dynamic>?;
        if (prediction == null) continue;
        final placeId = prediction['placeId'] as String? ?? '';
        final text = prediction['text'] as Map<String, dynamic>?;
        final mainText = text?['text'] as String? ?? '';
        final structured =
            prediction['structuredFormat'] as Map<String, dynamic>?;
        final secondary =
            structured?['secondaryText']?['text'] as String? ?? '';

        results.add(
          DestinationModel(
            placeId: placeId,
            name: mainText,
            fullAddress:
                secondary.isNotEmpty ? '$mainText, $secondary' : mainText,
            latitude: 0,
            longitude: 0,
            category: DestinationCategory.unknown,
            countryCode: '',
            isInternational: false,
          ),
        );
      }
      if (results.isNotEmpty) return results;
    } catch (e) {
      debugPrint('Places autocomplete fallback: $e');
    }

    return _searchWithNominatim(cleanQuery);
  }

  Future<DestinationModel> getDestinationDetails(String placeId) async {
    if (_apiKey.isEmpty) {
      throw const PlacesException('Configura GOOGLE_PLACES_API_KEY en .env');
    }

    final uri = Uri.parse('$_baseUrl/places/$placeId');
    final response = await http.get(
      uri,
      headers: {
        ..._headers,
        'X-Goog-FieldMask':
            'id,displayName,formattedAddress,location,addressComponents,types',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw PlacesException(
          'No se pudo obtener el lugar (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final location = json['location'] as Map<String, dynamic>?;
    final lat = (location?['latitude'] as num?)?.toDouble() ?? 0;
    final lng = (location?['longitude'] as num?)?.toDouble() ?? 0;
    final displayName = json['displayName'] as Map<String, dynamic>?;
    final name = displayName?['text'] as String? ?? '';
    final formattedAddress = json['formattedAddress'] as String? ?? name;
    final types = (json['types'] as List?)?.cast<String>() ?? [];
    final components =
        (json['addressComponents'] as List?)?.cast<Map<String, dynamic>>() ??
            [];

    var countryCode = '';
    for (final c in components) {
      final typesList = (c['types'] as List?)?.cast<String>() ?? [];
      if (typesList.contains('country')) {
        countryCode = c['shortText'] as String? ?? '';
        break;
      }
    }

    final category = _inferCategory(types);
    final isInternational = countryCode.isNotEmpty && countryCode != 'CO';

    return DestinationModel(
      placeId: placeId,
      name: name,
      fullAddress: formattedAddress,
      latitude: lat,
      longitude: lng,
      category: category,
      countryCode: countryCode,
      isInternational: isInternational,
      altitude: category == DestinationCategory.mountain ? 2500 : null,
    );
  }

  DestinationCategory _inferCategory(List<String> types) {
    final joined = types.join(' ').toLowerCase();
    if (joined.contains('beach') || joined.contains('natural_feature')) {
      return joined.contains('beach')
          ? DestinationCategory.beach
          : DestinationCategory.mountain;
    }
    if (joined.contains('airport')) return DestinationCategory.airport;
    if (joined.contains('locality') ||
        joined.contains('administrative_area') ||
        joined.contains('sublocality')) {
      return DestinationCategory.city;
    }
    if (joined.contains('park') || joined.contains('campground')) {
      return DestinationCategory.mountain;
    }
    if (joined.contains('tourist_attraction')) {
      return DestinationCategory.city;
    }
    return DestinationCategory.unknown;
  }

  /// Búsqueda real de respaldo cuando Google Places no está disponible.
  Future<List<DestinationModel>> _searchWithNominatim(String query) async {
    final uri = Uri.parse('$_nominatimBase/search').replace(queryParameters: {
      'q': query,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '5',
      'accept-language': 'es',
    });

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'CheckOut/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List;
      return data.map((item) {
        final map = item as Map<String, dynamic>;
        final address = map['address'] as Map<String, dynamic>? ?? {};
        final displayName = map['display_name'] as String? ?? query;
        final name = map['name'] as String? ??
            address['city'] as String? ??
            address['town'] as String? ??
            address['village'] as String? ??
            address['state'] as String? ??
            query;

        final lat = double.tryParse(map['lat'] as String? ?? '') ?? 0;
        final lng = double.tryParse(map['lon'] as String? ?? '') ?? 0;
        final countryCode =
            (address['country_code'] as String? ?? '').toUpperCase();

        return DestinationModel(
          placeId: 'osm_${map['osm_type']}_${map['osm_id']}',
          name: name,
          fullAddress: displayName,
          latitude: lat,
          longitude: lng,
          category: _inferNominatimCategory(map),
          countryCode: countryCode,
          isInternational: countryCode.isNotEmpty && countryCode != 'CO',
        );
      }).toList();
    } catch (e) {
      debugPrint('Nominatim destination search: $e');
      return [];
    }
  }

  DestinationCategory _inferNominatimCategory(Map<String, dynamic> map) {
    final source = [
      map['class'],
      map['type'],
      map['category'],
      map['name'],
      map['display_name'],
    ].whereType<String>().join(' ').toLowerCase();

    if (source.contains('beach')) return DestinationCategory.beach;
    if (source.contains('airport')) return DestinationCategory.airport;
    if (source.contains('mountain') ||
        source.contains('peak') ||
        source.contains('camp') ||
        source.contains('park')) {
      return DestinationCategory.mountain;
    }
    if (source.contains('village') || source.contains('farm')) {
      return DestinationCategory.rural;
    }
    if (source.contains('city') ||
        source.contains('town') ||
        source.contains('administrative') ||
        source.contains('place')) {
      return DestinationCategory.city;
    }
    return DestinationCategory.unknown;
  }
}

class PlacesException implements Exception {
  final String message;
  const PlacesException(this.message);
  @override
  String toString() => message;
}
