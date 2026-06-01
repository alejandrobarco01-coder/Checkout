import '../../core/error/either.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class WatchUpcomingTripsUseCase {
  final TripRepository _repository;

  WatchUpcomingTripsUseCase(this._repository);

  Stream<Result<List<Trip>>> call() => _repository.watchUpcomingTrips();
}
