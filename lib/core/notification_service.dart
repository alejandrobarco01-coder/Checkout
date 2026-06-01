import 'dart:io';
import 'package:flutter/foundation.dart';

// Stub: flutter_local_notifications no soporta web
// Usamos una implementación simplificada con fallback
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    
    // No-op para web
    if (kIsWeb) {
      debugPrint('✓ NotificationService initialized for Web (logging mode)');
      return;
    }

    // En móvil se podría integrar flutter_local_notifications aquí
    debugPrint('✓ NotificationService initialized for Mobile');
  }

  Future<void> showNotification({required String title, required String body}) async {
    if (kIsWeb) {
      // Fallback para web: registrar en consola y mostrar log visual
      debugPrint('🔔 [NOTIFICATION] $title: $body');
      return;
    }

    // En móvil se enviaría notificación local aquí
    debugPrint('🔔 [NOTIFICATION] $title: $body');
  }
}

