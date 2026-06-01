import '../../core/error/either.dart';
import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class GetTripsByMonthUseCase {
  final TripRepository _repository;

  GetTripsByMonthUseCase(this._repository);

  Future<Result<List<Trip>>> call(int year, int month) =>
      _repository.getTripsByMonth(year, month);
}
