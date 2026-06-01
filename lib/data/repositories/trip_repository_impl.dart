import '../../core/error/either.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/local/trip_local_datasource.dart';
import '../datasources/remote/trip_remote_datasource.dart';
import '../models/trip_model.dart';

class TripRepositoryImpl implements TripRepository {
  final TripLocalDataSource _local;
  final TripRemoteDataSource _remote;

  TripRepositoryImpl({
    TripLocalDataSource? local,
    TripRemoteDataSource? remote,
  })  : _local = local ?? TripLocalDataSource(),
        _remote = remote ?? TripRemoteDataSource();

  @override
  Future<Result<List<Trip>>> getTripsByMonth(int year, int month) async {
    try {
      final models = await _local.getByMonth(year, month);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<Trip>> getTripById(String id) async {
    try {
      final model = await _local.getById(id);
      if (model == null) {
        return const Left(CacheFailure('Viaje no encontrado'));
      }
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<Trip>> saveTrip(Trip trip) async {
    try {
      final model = TripModel.fromEntity(trip);
      await _local.insert(model);
      _remote.upsertTrip(model);
      return Right(trip);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<Trip>> updateTrip(Trip trip) async {
    try {
      final model = TripModel.fromEntity(trip);
      await _local.update(model);
      _remote.upsertTrip(model);
      return Right(trip);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteTrip(String id) async {
    try {
      await _local.delete(id);
      _remote.deleteTrip(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<Result<List<Trip>>> watchUpcomingTrips() async* {
    try {
      final initial = await _local.getUpcoming();
      yield Right(initial.map((m) => m.toEntity()).toList());
      await for (final models in _local.upcomingStream) {
        yield Right(models.map((m) => m.toEntity()).toList());
      }
    } catch (e) {
      yield Left(CacheFailure(e.toString()));
    }
  }
}
