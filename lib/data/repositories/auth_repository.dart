import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';

/// Repositorio de autenticación JWT.
/// El JWT se guarda exclusivamente en flutter_secure_storage.
/// El login es mock (acepta cualquier email/password válido).
/// En producción, reemplaza _mockLogin con una llamada real a tu API.
class AuthRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ──────────────────────────────────────────────
  // Login: genera un JWT mock y lo persiste
  // ──────────────────────────────────────────────
  Future<String> login(String email, String password) async {
    // Simula retardo de red
    await Future.delayed(const Duration(seconds: 1));

    // Validación básica (en producción: POST /auth/login)
    if (email.isEmpty || password.length < 6) {
      throw AuthException('Credenciales inválidas');
    }

    // Genera un JWT mock con payload base64
    final payload = base64Url.encode(
      utf8.encode(jsonEncode({
        'sub': email,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now()
                .add(const Duration(hours: 24))
                .millisecondsSinceEpoch ~/
            1000,
      })),
    );
    final mockJwt = 'eyJhbGciOiJIUzI1NiJ9.$payload.MOCK_SIGNATURE';

    // Persiste en almacenamiento seguro
    await _storage.write(key: AppConstants.secureKeyJwt, value: mockJwt);
    return mockJwt;
  }

  // ──────────────────────────────────────────────
  // Logout: elimina el JWT del almacenamiento
  // ──────────────────────────────────────────────
  Future<void> logout() async {
    await _storage.delete(key: AppConstants.secureKeyJwt);
  }

  // ──────────────────────────────────────────────
  // Verifica si existe un token válido al arrancar
  // ──────────────────────────────────────────────
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: AppConstants.secureKeyJwt);
    if (token == null) return false;
    // Decodifica el payload para verificar expiración
    try {
      final parts = token.split('.');
      if (parts.length < 2) return false;
      final payloadJson = utf8.decode(base64Url.decode(
        base64Url.normalize(parts[1]),
      ));
      final data = jsonDecode(payloadJson) as Map<String, dynamic>;
      final exp = data['exp'] as int? ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000)
          .isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// Devuelve el token para usarlo en headers HTTP: "Bearer <token>"
  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.secureKeyJwt);
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}
