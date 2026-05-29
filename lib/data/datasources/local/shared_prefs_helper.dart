import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants.dart';

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

  // ── Último tipo de salida ───────────────────────
  Future<String?> getLastExitType() async {
    final p = await _prefs;
    return p.getString(AppConstants.prefLastExitType);
  }

  Future<void> setLastExitType(String type) async {
    final p = await _prefs;
    await p.setString(AppConstants.prefLastExitType, type);
  }
}
