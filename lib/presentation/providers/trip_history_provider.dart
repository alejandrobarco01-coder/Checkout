import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/remote/geocoding_api.dart';
import '../../domain/entities/completed_trip.dart';
import '../../domain/entities/forgotten_item.dart';
import '../../domain/entities/item.dart';

/// Historial de salidas completadas e ítems olvidados.
class TripHistoryProvider extends ChangeNotifier {
  List<CompletedTrip> _trips = [];
  List<ForgottenItem> _forgottenItems = [];
  bool _isLoading = false;

  List<CompletedTrip> get trips => _trips;
  List<ForgottenItem> get forgottenItems => _forgottenItems;
  bool get isLoading => _isLoading;

  final _db = DatabaseHelper.instance;
  final _geocoding = GeocodingApi();

  Future<void> loadTrips() async {
    _isLoading = true;
    notifyListeners();
    final rows = await _db.queryAll(AppConstants.tableCompletedTrips);
    _trips = rows.map(CompletedTrip.fromMap).toList()
      ..sort((a, b) => b.fechaSalida.compareTo(a.fechaSalida));
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadForgottenItems() async {
    final rows = await _db.queryAll(AppConstants.tableForgottenItems);
    _forgottenItems = rows.map(ForgottenItem.fromMap).toList()
      ..sort((a, b) => b.veces.compareTo(a.veces));
    notifyListeners();
  }

  Future<void> registerDeparture({
    required String nombre,
    required String tipoSalida,
    required String destino,
    required List<Item> allItems,
    required double porcentaje,
    required double pesoTotal,
  }) async {
    final now = DateTime.now();

    double? lat;
    double? lng;
    if (destino.trim().isNotEmpty) {
      try {
        final results = await _geocoding.search(destino);
        if (results.isNotEmpty) {
          lat = results.first.lat;
          lng = results.first.lng;
        }
      } catch (_) {}
    }

    final trip = CompletedTrip(
      nombre: nombre,
      tipoSalida: tipoSalida,
      destino: destino,
      fechaSalida: now,
      porcentajeCompletado: porcentaje,
      pesoTotalKg: pesoTotal,
      lat: lat,
      lng: lng,
    );
    await _db.insert(AppConstants.tableCompletedTrips, trip.toMap());

    final olvidados = allItems.where((i) => !i.completado).toList();
    for (final item in olvidados) {
      await _recordForgotten(item.nombre, tipoSalida, now);
    }

    await loadTrips();
    await loadForgottenItems();
  }

  Future<void> _recordForgotten(
      String nombre, String tipoSalida, DateTime fecha) async {
    final rows = await _db.queryAll(AppConstants.tableForgottenItems);
    final existing = rows.where((r) =>
        (r['nombre'] as String).toLowerCase() == nombre.toLowerCase() &&
        r['tipo_salida'] == tipoSalida);

    if (existing.isNotEmpty) {
      final row = existing.first;
      await _db.update(
        AppConstants.tableForgottenItems,
        {
          'veces': (row['veces'] as int) + 1,
          'ultima_fecha': fecha.toIso8601String(),
        },
        'id = ?',
        [row['id']],
      );
    } else {
      await _db.insert(AppConstants.tableForgottenItems, {
        'nombre': nombre,
        'tipo_salida': tipoSalida,
        'veces': 1,
        'ultima_fecha': fecha.toIso8601String(),
      });
    }
  }

  Future<void> deleteTrip(int id) async {
    await _db.deleteWhere(AppConstants.tableCompletedTrips, 'id = ?', [id]);
    _trips.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
