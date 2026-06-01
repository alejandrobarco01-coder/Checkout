import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/error/either.dart';
import '../../data/repositories/checklist_repository_impl.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/entities/destination_recommendation.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/trip.dart';
import '../../domain/usecases/delete_trip_usecase.dart';
import '../../domain/usecases/get_trips_by_month_usecase.dart';
import '../../domain/usecases/save_trip_usecase.dart';
import '../../domain/usecases/watch_upcoming_trips_usecase.dart';

/// Estado del calendario de salidas programadas.
class TripProvider extends ChangeNotifier {
  final GetTripsByMonthUseCase _getTripsByMonth;
  final SaveTripUseCase _saveTrip;
  final DeleteTripUseCase _deleteTrip;
  final WatchUpcomingTripsUseCase _watchUpcoming;
  final ChecklistRepositoryImpl _checklistRepo = ChecklistRepositoryImpl();
  final _uuid = const Uuid();

  Map<DateTime, List<Trip>> _tripsByDay = {};
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Trip> _upcomingTrips = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<Result<List<Trip>>>? _upcomingSub;
  bool _initialized = false;

  TripProvider({TripRepositoryImpl? repository})
      : _getTripsByMonth = GetTripsByMonthUseCase(
          repository ?? TripRepositoryImpl(),
        ),
        _saveTrip = SaveTripUseCase(repository ?? TripRepositoryImpl()),
        _deleteTrip = DeleteTripUseCase(repository ?? TripRepositoryImpl()),
        _watchUpcoming = WatchUpcomingTripsUseCase(
          repository ?? TripRepositoryImpl(),
        );

  Map<DateTime, List<Trip>> get tripsByDay => _tripsByDay;
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  List<Trip> get upcomingTrips => _upcomingTrips;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void init() {
    if (_initialized) return;
    _initialized = true;
    _upcomingSub?.cancel();
    _upcomingSub = _watchUpcoming().listen((result) {
      result.fold(
        (f) => _error = f.message,
        (trips) {
          _upcomingTrips = trips;
          _error = null;
          notifyListeners();
        },
      );
    });
    loadMonth(_focusedDay.year, _focusedDay.month);
  }

  @override
  void dispose() {
    _upcomingSub?.cancel();
    super.dispose();
  }

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
    loadMonth(day.year, day.month);
  }

  void setSelectedDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  Future<void> loadMonth(int year, int month) async {
    _isLoading = true;
    notifyListeners();
    final result = await _getTripsByMonth(year, month);
    result.fold(
      (f) => _error = f.message,
      (trips) {
        _error = null;
        _tripsByDay = _groupByDay(trips);
      },
    );
    _isLoading = false;
    notifyListeners();
  }

  Map<DateTime, List<Trip>> _groupByDay(List<Trip> trips) {
    final map = <DateTime, List<Trip>>{};
    for (final trip in trips) {
      final start = DateTime(
        trip.departureDate.year,
        trip.departureDate.month,
        trip.departureDate.day,
      );
      final end = trip.returnDate != null
          ? DateTime(
              trip.returnDate!.year,
              trip.returnDate!.month,
              trip.returnDate!.day,
            )
          : start;
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        final key = DateTime(d.year, d.month, d.day);
        map.putIfAbsent(key, () => []).add(trip);
      }
    }
    return map;
  }

  List<Trip> tripsOnDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _tripsByDay[key] ?? [];
  }

  Future<Result<Trip>> saveTrip(Trip trip) async {
    final result = await _saveTrip(trip);
    result.fold((_) {}, (_) {
      loadMonth(_focusedDay.year, _focusedDay.month);
    });
    return result;
  }

  Future<Result<void>> deleteTrip(String id) async {
    final result = await _deleteTrip(id);
    result.fold((_) {}, (_) {
      loadMonth(_focusedDay.year, _focusedDay.month);
    });
    return result;
  }

  /// Crea viaje + checklist con recomendaciones y devuelve el id del checklist.
  Future<int?> createTripWithChecklist({
    required String name,
    required TripType type,
    required DateTime departureDate,
    DateTime? returnDate,
    required String destinationName,
    String? destinationPlaceId,
    required List<DestinationRecommendation> recommendations,
    String userId = 'local_user',
  }) async {
    final checklist = Checklist(
      nombre: name,
      tipoSalida: type.checklistTipoSalida,
      fechaCreacion: DateTime.now(),
    );
    final checklistId = await _checklistRepo.create(checklist);

    for (final rec in recommendations) {
      await _checklistRepo.addItem(
        Item(
          checklistId: checklistId,
          nombre: rec.itemName,
          pesoKg: 0,
        ),
      );
    }

    if (recommendations.isEmpty) {
      await _checklistRepo.seedDefaultItems(checklistId, type.checklistTipoSalida);
    }

    final trip = Trip(
      id: _uuid.v4(),
      name: name,
      destinationName: destinationName,
      destinationPlaceId: destinationPlaceId,
      departureDate: departureDate,
      returnDate: returnDate,
      type: type,
      status: TripStatus.upcoming,
      checklistId: checklistId,
      userId: userId,
    );

    final saved = await saveTrip(trip);
    return saved.fold((_) => null, (_) => checklistId);
  }
}
