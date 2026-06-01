import '../../core/error/either.dart';
import '../repositories/trip_repository.dart';

class DeleteTripUseCase {
  final TripRepository _repository;

  DeleteTripUseCase(this._repository);

  Future<Result<void>> call(String id) => _repository.deleteTrip(id);
}
