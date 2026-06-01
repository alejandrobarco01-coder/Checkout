import '../../domain/entities/destination.dart';

class DestinationModel {
  final String placeId;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final DestinationCategory category;
  final String countryCode;
  final bool isInternational;
  final double? altitude;

  const DestinationModel({
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

  Destination toEntity() => Destination(
        placeId: placeId,
        name: name,
        fullAddress: fullAddress,
        latitude: latitude,
        longitude: longitude,
        category: category,
        countryCode: countryCode,
        isInternational: isInternational,
        altitude: altitude,
      );

  factory DestinationModel.fromMap(Map<String, dynamic> map) => DestinationModel(
        placeId: map['place_id'] as String? ?? map['placeId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        fullAddress: map['full_address'] as String? ?? map['fullAddress'] as String? ?? '',
        latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
        category: DestinationCategoryX.fromString(
          map['category'] as String? ?? 'unknown',
        ),
        countryCode: map['country_code'] as String? ?? map['countryCode'] as String? ?? '',
        isInternational: map['is_international'] as bool? ??
            map['isInternational'] as bool? ??
            false,
        altitude: map['altitude'] != null ? (map['altitude'] as num).toDouble() : null,
      );
}
