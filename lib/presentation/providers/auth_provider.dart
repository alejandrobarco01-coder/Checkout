import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';

/// Provider de autenticación.
/// Expone el estado de sesión y opera sobre el JWT.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  bool _isAuthenticated = false;
  bool _isOnboardingCompleted = false;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isOnboardingCompleted => _isOnboardingCompleted;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Se llama al arrancar la app para restaurar la sesión.
  Future<void> init() async {
    _isAuthenticated = await _repo.isAuthenticated();
    _isOnboardingCompleted = await SharedPrefsHelper.instance.getOnboardingCompleted();
    notifyListeners();
  }

  /// Completa el onboarding y actualiza preferences.
  Future<void> completeOnboarding() async {
    await SharedPrefsHelper.instance.setOnboardingCompleted(true);
    _isOnboardingCompleted = true;
    notifyListeners();
  }

  /// Login con email y password.
  /// Devuelve true si fue exitoso.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.login(email, password);
      _isAuthenticated = true;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Error inesperado: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cierra sesión y limpia el JWT.
  Future<void> logout() async {
    await _repo.logout();
    _isAuthenticated = false;
    notifyListeners();
  }
}
