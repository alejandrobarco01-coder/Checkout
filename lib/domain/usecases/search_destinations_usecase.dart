import '../../core/error/either.dart';
import '../entities/destination.dart';
import '../repositories/destination_repository.dart';

class SearchDestinationsUseCase {
  final DestinationRepository _repository;

  SearchDestinationsUseCase(this._repository);

  Future<Result<List<Destination>>> call(String query) =>
      _repository.searchDestinations(query);
}
