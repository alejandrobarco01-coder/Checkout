import 'package:flutter/material.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';

/// Provider del tema claro/oscuro.
/// Persiste la preferencia con shared_preferences.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Carga la preferencia guardada al iniciar.
  Future<void> init() async {
    _isDarkMode = await SharedPrefsHelper.instance.getDarkMode();
    notifyListeners();
  }

  /// Alterna el tema y persiste la elección.
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await SharedPrefsHelper.instance.setDarkMode(_isDarkMode);
    notifyListeners();
  }
}
