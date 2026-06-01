import 'dart:async';

import '../../../core/constants.dart';
import '../../../domain/entities/trip.dart';
import '../../models/trip_model.dart';
import 'database_helper.dart';

/// SQLite / web como fuente primaria de salidas programadas.
class TripLocalDataSource {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _upcomingController = StreamController<List<TripModel>>.broadcast();

  Stream<List<TripModel>> get upcomingStream => _upcomingController.stream;

  Future<List<TripModel>> getAll() async {
    final rows = await _db.queryAll(AppConstants.tableTrips);
    return rows.map(TripModel.fromMap).toList();
  }

  Future<List<TripModel>> getByMonth(int year, int month) async {
    final all = await getAll();
    final monthEnd = DateTime(year, month + 1, 0);
    return all.where((trip) {
      for (var day = 1; day <= monthEnd.day; day++) {
        if (trip.toEntity().occursOn(DateTime(year, month, day))) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  Future<TripModel?> getById(String id) async {
    final rows = await _db.queryWhere(
      AppConstants.tableTrips,
      'id = ?',
      [id],
    );
    if (rows.isEmpty) return null;
    return TripModel.fromMap(rows.first);
  }

  Future<TripModel> insert(TripModel trip) async {
    await _db.insert(AppConstants.tableTrips, trip.toMap());
    await _emitUpcoming();
    return trip;
  }

  Future<TripModel> update(TripModel trip) async {
    await _db.update(
      AppConstants.tableTrips,
      trip.toMap(),
      'id = ?',
      [trip.id],
    );
    await _emitUpcoming();
    return trip;
  }

  Future<void> delete(String id) async {
    await _db.deleteWhere(AppConstants.tableTrips, 'id = ?', [id]);
    await _emitUpcoming();
  }

  Future<List<TripModel>> getUpcoming() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final all = await getAll();
    return all
        .where((t) {
          if (t.status == TripStatus.cancelled ||
              t.status == TripStatus.completed) {
            return false;
          }
          final dep = DateTime(
            t.departureDate.year,
            t.departureDate.month,
            t.departureDate.day,
          );
          return !dep.isBefore(today);
        })
        .toList()
      ..sort((a, b) => a.departureDate.compareTo(b.departureDate));
  }

  Future<void> _emitUpcoming() async {
    final upcoming = await getUpcoming();
    if (!_upcomingController.isClosed) {
      _upcomingController.add(upcoming);
    }
  }

  void dispose() {
    _upcomingController.close();
  }
}
