import '../../core/error/either.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class SaveTripUseCase {
  final TripRepository _repository;

  SaveTripUseCase(this._repository);

  Future<Result<Trip>> call(Trip trip) => _repository.saveTrip(trip);
}
