import '../../domain/entities/trip.dart';

class TripModel {
  final String id;
  final String name;
  final String destinationName;
  final String? destinationPlaceId;
  final DateTime departureDate;
  final DateTime? returnDate;
  final TripType type;
  final TripStatus status;
  final int? checklistId;
  final String userId;

  const TripModel({
    required this.id,
    required this.name,
    required this.destinationName,
    this.destinationPlaceId,
    required this.departureDate,
    this.returnDate,
    required this.type,
    required this.status,
    this.checklistId,
    required this.userId,
  });

  factory TripModel.fromEntity(Trip trip) => TripModel(
        id: trip.id,
        name: trip.name,
        destinationName: trip.destinationName,
        destinationPlaceId: trip.destinationPlaceId,
        departureDate: trip.departureDate,
        returnDate: trip.returnDate,
        type: trip.type,
        status: trip.status,
        checklistId: trip.checklistId,
        userId: trip.userId,
      );

  Trip toEntity() => Trip(
        id: id,
        name: name,
        destinationName: destinationName,
        destinationPlaceId: destinationPlaceId,
        departureDate: departureDate,
        returnDate: returnDate,
        type: type,
        status: status,
        checklistId: checklistId,
        userId: userId,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'destination_name': destinationName,
        'destination_place_id': destinationPlaceId,
        'departure_date': departureDate.toIso8601String(),
        'return_date': returnDate?.toIso8601String(),
        'type': type.name,
        'status': status.name,
        'checklist_id': checklistId,
        'user_id': userId,
      };

  factory TripModel.fromMap(Map<String, dynamic> map) => TripModel(
        id: map['id'] as String,
        name: map['name'] as String,
        destinationName: map['destination_name'] as String? ?? '',
        destinationPlaceId: map['destination_place_id'] as String?,
        departureDate: DateTime.parse(map['departure_date'] as String),
        returnDate: map['return_date'] != null
            ? DateTime.parse(map['return_date'] as String)
            : null,
        type: TripTypeX.fromString(map['type'] as String? ?? 'casual'),
        status: TripStatusX.fromString(map['status'] as String? ?? 'upcoming'),
        checklistId: map['checklist_id'] as int?,
        userId: map['user_id'] as String? ?? 'local_user',
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'destination_name': destinationName,
        'destination_place_id': destinationPlaceId,
        'departure_date': departureDate.toIso8601String(),
        'return_date': returnDate?.toIso8601String(),
        'type': type.name,
        'status': status.name,
        'checklist_id': checklistId,
        'user_id': userId,
        'updated_at': DateTime.now().toIso8601String(),
      };
}
