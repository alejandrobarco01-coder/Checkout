/// Destino seleccionado desde Google Places.
class Destination {
  final String placeId;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final DestinationCategory category;
  final String countryCode;
  final bool isInternational;
  final double? altitude;

  const Destination({
    required this.placeId,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.countryCode,
    required this.isInternational,
    this.altitude,
  });

  Destination copyWith({
    String? placeId,
    String? name,
    String? fullAddress,
    double? latitude,
    double? longitude,
    DestinationCategory? category,
    String? countryCode,
    bool? isInternational,
    double? altitude,
  }) {
    return Destination(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      countryCode: countryCode ?? this.countryCode,
      isInternational: isInternational ?? this.isInternational,
      altitude: altitude ?? this.altitude,
    );
  }
}

enum DestinationCategory {
  beach,
  mountain,
  city,
  rural,
  airport,
  unknown,
}

extension DestinationCategoryX on DestinationCategory {
  String get emoji {
    switch (this) {
      case DestinationCategory.beach:
        return '🏖️';
      case DestinationCategory.mountain:
        return '⛰️';
      case DestinationCategory.city:
        return '🏙️';
      case DestinationCategory.rural:
        return '🌾';
      case DestinationCategory.airport:
        return '✈️';
      case DestinationCategory.unknown:
        return '📍';
    }
  }

  String get label {
    switch (this) {
      case DestinationCategory.beach:
        return 'Playa';
      case DestinationCategory.mountain:
        return 'Montaña';
      case DestinationCategory.city:
        return 'Ciudad';
      case DestinationCategory.rural:
        return 'Rural';
      case DestinationCategory.airport:
        return 'Aeropuerto';
      case DestinationCategory.unknown:
        return 'Destino';
    }
  }

  static DestinationCategory fromString(String value) {
    return DestinationCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DestinationCategory.unknown,
    );
  }
}
