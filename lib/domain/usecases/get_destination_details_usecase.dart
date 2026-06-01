import '../../core/error/either.dart';
import '../entities/destination.dart';
import '../repositories/destination_repository.dart';

class GetDestinationDetailsUseCase {
  final DestinationRepository _repository;

  GetDestinationDetailsUseCase(this._repository);

  Future<Result<Destination>> call(String placeId) =>
      _repository.getDestinationDetails(placeId);
}
