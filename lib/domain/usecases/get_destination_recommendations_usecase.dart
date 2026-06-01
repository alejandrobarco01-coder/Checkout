import '../../core/error/either.dart';
import '../entities/destination.dart';
import '../entities/destination_recommendation.dart';
import '../entities/weather.dart';
import '../repositories/destination_repository.dart';

class GetDestinationRecommendationsUseCase {
  final DestinationRepository _repository;

  GetDestinationRecommendationsUseCase(this._repository);

  Future<Result<List<DestinationRecommendation>>> call({
    required Destination destination,
    Weather? weather,
    required bool isInternationalTrip,
  }) =>
      _repository.getRecommendations(
        destination: destination,
        weather: weather,
        isInternationalTrip: isInternationalTrip,
      );
}
