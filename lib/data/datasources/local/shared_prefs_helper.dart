import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/constants.dart';
import '../../../domain/entities/daily_checklist.dart';

/// Helper para shared_preferences.
/// Gestiona: ciudad, modo oscuro, último tipo de salida.
class SharedPrefsHelper {
  SharedPrefsHelper._();
  static final SharedPrefsHelper instance = SharedPrefsHelper._();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Ciudad del usuario ──────────────────────────
  Future<String> getCity() async {
    final p = await _prefs;
    return p.getString(AppConstants.prefCity) ?? 'Madrid';
  }

  Future<void> setCity(String city) async {
    final p = await _prefs;
    await p.setString(AppConstants.prefCity, city);
    await p.setBool(AppConstants.prefUseCurrentLocation, false);
  }

  Future<bool> getUseCurrentLocation() async {
    final p = await _prefs;
    return p.getBool(AppConstants.prefUseCurrentLocation) ?? false;
  }

  Future<({double lat, double lng, String name})?> getCurrentLocation() async {
    final p = await _prefs;
    final lat = p.getDouble(AppConstants.prefCurrentLat);
    final lng = p.getDouble(AppConstants.prefCurrentLng);
    if (lat == null || lng == null) return null;
    return (
      lat: lat,
      lng: lng,
      name: p.getString(AppConstants.prefCurrentLocationName) ??
          'Ubicación actual',
    );
  }

  Future<void> setCurrentLocation({
    required double lat,
    required double lng,
    String name = 'Ubicación actual',
  }) async {
    final p = await _prefs;
    await p.setBool(AppConstants.prefUseCurrentLocation, true);
    await p.setDouble(AppConstants.prefCurrentLat, lat);
    await p.setDouble(AppConstants.prefCurrentLng, lng);
    await p.setString(AppConstants.prefCurrentLocationName, name);
  }

  // ── Modo oscuro ─────────────────────────────────
  Future<bool> getDarkMode() async {
    final p = await _prefs;
    return p.getBool(AppConstants.prefDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final p = await _prefs;
    await p.setBool(AppConstants.prefDarkMode, value);
  }

  // ── Nombre de tema (light, dark, sunset) ────────
  Future<String> getThemeName() async {
    final p = await _prefs;
    return p.getString('theme_name') ?? 'light';
  }

  Future<void> setThemeName(String name) async {
    final p = await _prefs;
    await p.setString('theme_name', name);
  }

  // ── Último tipo de salida ───────────────────────
  Future<String?> getLastExitType() async {
    final p = await _prefs;
    return p.getString(AppConstants.prefLastExitType);
  }

  Future<void> setLastExitType(String type) async {
    final p = await _prefs;
    await p.setString(AppConstants.prefLastExitType, type);
  }

  // ── Onboarding ──────────────────────────────────
  Future<bool> getOnboardingCompleted() async {
    final p = await _prefs;
    return p.getBool(AppConstants.prefOnboardingCompleted) ?? false;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    final p = await _prefs;
    await p.setBool(AppConstants.prefOnboardingCompleted, value);
  }

  // ── Daily Checklist ──────────────────────────────
  Future<List<DailyChecklistItem>> getDailyChecklist() async {
    final p = await _prefs;
    final json = p.getString('daily_checklist');
    if (json == null || json.isEmpty) return [];

    try {
      final decoded = jsonDecode(json) as List;
      return decoded
          .map((item) => DailyChecklistItem(
                id: item['id'] as String,
                nombre: item['nombre'] as String,
                emoji: item['emoji'] as String,
                completado: item['completado'] as bool? ?? false,
                orden: item['orden'] as int? ?? 0,
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveDailyChecklist(List<DailyChecklistItem> items) async {
    final p = await _prefs;
    final json = jsonEncode(items
        .map((item) => {
              'id': item.id,
              'nombre': item.nombre,
              'emoji': item.emoji,
              'completado': item.completado,
              'orden': item.orden,
            })
        .toList());
    await p.setString('daily_checklist', json);
  }
}
