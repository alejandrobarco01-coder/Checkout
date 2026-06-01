import '../../core/error/either.dart';
import '../entities/destination.dart';
import '../entities/destination_recommendation.dart';
import '../entities/weather.dart';

abstract class DestinationRepository {
  Future<Result<List<Destination>>> searchDestinations(String query);

  Future<Result<Destination>> getDestinationDetails(String placeId);

  Future<Result<List<DestinationRecommendation>>> getRecommendations({
    required Destination destination,
    Weather? weather,
    required bool isInternationalTrip,
  });
}
