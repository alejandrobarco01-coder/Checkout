import '../../core/error/either.dart';
import '../entities/trip.dart';

abstract class TripRepository {
  Future<Result<List<Trip>>> getTripsByMonth(int year, int month);

  Future<Result<Trip>> getTripById(String id);

  Future<Result<Trip>> saveTrip(Trip trip);

  Future<Result<Trip>> updateTrip(Trip trip);

  Future<Result<void>> deleteTrip(String id);

  Stream<Result<List<Trip>>> watchUpcomingTrips();
}
