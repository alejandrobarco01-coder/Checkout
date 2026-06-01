import 'package:flutter/material.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';
import '../../core/theme.dart';

/// Provider del tema. Soporta: claro, oscuro y sunset.
/// Persiste la elección con shared_preferences.
class ThemeProvider extends ChangeNotifier {
  String _themeName = 'light';

  String get themeName => _themeName;
  bool get isDarkMode => _themeName == 'dark';

  ThemeMode get themeMode {
    if (_themeName == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  /// Retorna el ThemeData correspondiente al tema seleccionado.
  ThemeData get currentTheme {
    switch (_themeName) {
      case 'dark':
        return AppTheme.darkTheme;
      case 'sunset':
        return AppTheme.sunsetTheme;
      case 'light':
      default:
        return AppTheme.lightTheme;
    }
  }

  /// Carga la preferencia guardada al iniciar.
  Future<void> init() async {
    _themeName = await SharedPrefsHelper.instance.getThemeName();
    notifyListeners();
  }

  /// Establece un nuevo tema y lo persiste.
  Future<void> setTheme(String name) async {
    if (_themeName == name) return;
    _themeName = name;
    await SharedPrefsHelper.instance.setThemeName(name);
    // Para retrocompatibilidad
    await SharedPrefsHelper.instance.setDarkMode(name == 'dark');
    notifyListeners();
  }

  /// Alterna el tema (para uso rápido si es necesario).
  Future<void> toggleTheme() async {
    if (_themeName == 'light') {
      await setTheme('dark');
    } else if (_themeName == 'dark') {
      await setTheme('sunset');
    } else {
      await setTheme('light');
    }
  }
}
