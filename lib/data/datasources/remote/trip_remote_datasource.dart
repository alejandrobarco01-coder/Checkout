import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/trip_model.dart';

/// Sincronización en background con Firestore (colección `trips`).
class TripRemoteDataSource {
  Future<void> upsertTrip(TripModel trip) async {
    if (kIsWeb) return;
    try {
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(trip.id)
          .set(trip.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore trip sync: $e');
    }
  }

  Future<void> deleteTrip(String id) async {
    if (kIsWeb) return;
    try {
      await FirebaseFirestore.instance.collection('trips').doc(id).delete();
    } catch (e) {
      debugPrint('Firestore trip delete: $e');
    }
  }
}
