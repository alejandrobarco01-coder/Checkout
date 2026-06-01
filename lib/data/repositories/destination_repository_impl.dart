import '../../core/error/either.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/destination_recommendation.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/destination_repository.dart';
import '../datasources/local/recommendation_local_datasource.dart';
import '../datasources/remote/places_remote_datasource.dart';

class DestinationRepositoryImpl implements DestinationRepository {
  final PlacesRemoteDataSource _places;
  final RecommendationLocalDataSource _recommendations;

  DestinationRepositoryImpl({
    PlacesRemoteDataSource? places,
    RecommendationLocalDataSource? recommendations,
  })  : _places = places ?? PlacesRemoteDataSource(),
        _recommendations = recommendations ?? RecommendationLocalDataSource();

  @override
  Future<Result<List<Destination>>> searchDestinations(String query) async {
    try {
      final models = await _places.searchDestinations(query);
      return Right(models.map((m) => m.toEntity()).toList());
    } on PlacesException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Result<Destination>> getDestinationDetails(String placeId) async {
    try {
      final model = await _places.getDestinationDetails(placeId);
      return Right(model.toEntity());
    } on PlacesException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<DestinationRecommendation>>> getRecommendations({
    required Destination destination,
    Weather? weather,
    required bool isInternationalTrip,
  }) async {
    try {
      final list = _recommendations.buildRecommendations(
        destination: destination,
        weather: weather,
        isInternationalTrip: isInternationalTrip,
      );
      return Right(list);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
