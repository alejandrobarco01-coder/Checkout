/// Salida programada en el calendario de viajes.
class Trip {
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

  const Trip({
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

  bool get isMultiDay =>
      returnDate != null && !isSameCalendarDay(departureDate, returnDate!);

  bool get isSingleDay =>
      returnDate == null || isSameCalendarDay(departureDate, returnDate!);

  bool occursOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(
      departureDate.year,
      departureDate.month,
      departureDate.day,
    );
    final end = returnDate != null
        ? DateTime(returnDate!.year, returnDate!.month, returnDate!.day)
        : start;
    return !d.isBefore(start) && !d.isAfter(end);
  }

  int get daysUntilDeparture {
    final today = DateTime.now();
    final start = DateTime(
      departureDate.year,
      departureDate.month,
      departureDate.day,
    );
    final now = DateTime(today.year, today.month, today.day);
    return start.difference(now).inDays;
  }

  Trip copyWith({
    String? id,
    String? name,
    String? destinationName,
    String? destinationPlaceId,
    DateTime? departureDate,
    DateTime? returnDate,
    bool clearReturnDate = false,
    TripType? type,
    TripStatus? status,
    int? checklistId,
    bool clearChecklistId = false,
    String? userId,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      destinationName: destinationName ?? this.destinationName,
      destinationPlaceId: destinationPlaceId ?? this.destinationPlaceId,
      departureDate: departureDate ?? this.departureDate,
      returnDate: clearReturnDate ? null : (returnDate ?? this.returnDate),
      type: type ?? this.type,
      status: status ?? this.status,
      checklistId:
          clearChecklistId ? null : (checklistId ?? this.checklistId),
      userId: userId ?? this.userId,
    );
  }
}

bool isSameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

enum TripType {
  beach,
  work,
  mountain,
  city,
  casual,
  international,
}

enum TripStatus {
  upcoming,
  inProgress,
  completed,
  cancelled,
}

extension TripTypeX on TripType {
  String get label {
    switch (this) {
      case TripType.beach:
        return 'Playa';
      case TripType.work:
        return 'Trabajo';
      case TripType.mountain:
        return 'Montaña';
      case TripType.city:
        return 'Ciudad';
      case TripType.casual:
        return 'Casual';
      case TripType.international:
        return 'Internacional';
    }
  }

  String get emoji {
    switch (this) {
      case TripType.beach:
        return '🏖️';
      case TripType.work:
        return '💼';
      case TripType.mountain:
        return '⛰️';
      case TripType.city:
        return '🏙️';
      case TripType.casual:
        return '🎒';
      case TripType.international:
        return '🌍';
    }
  }

  /// Color del dot en el calendario.
  int get colorValue {
    switch (this) {
      case TripType.beach:
        return 0xFFE17055;
      case TripType.work:
        return 0xFF6C5CE7;
      case TripType.mountain:
        return 0xFF00B894;
      case TripType.city:
        return 0xFF0984E3;
      case TripType.casual:
        return 0xFFF1C40F;
      case TripType.international:
        return 0xFF00CEC9;
    }
  }

  /// Mapeo al tipo de checklist existente en [AppConstants.exitTypes].
  String get checklistTipoSalida {
    switch (this) {
      case TripType.beach:
        return 'playa';
      case TripType.work:
        return 'trabajo';
      case TripType.mountain:
        return 'camping';
      case TripType.city:
      case TripType.casual:
      case TripType.international:
        return 'viaje';
    }
  }

  static TripType fromString(String value) {
    return TripType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TripType.casual,
    );
  }
}

extension TripStatusX on TripStatus {
  static TripStatus fromString(String value) {
    return TripStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TripStatus.upcoming,
    );
  }
}
