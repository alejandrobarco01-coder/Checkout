/// Constantes globales de la aplicación CheckOut.
/// Centraliza todas las configuraciones para facilitar el mantenimiento.
class AppConstants {
  // ──────────────────────────────────────────────
  // API del clima (OpenWeatherMap)
  // Reemplaza con tu clave en: https://openweathermap.org/api
  // ──────────────────────────────────────────────
  static const String weatherApiKey = 'TU_OPENWEATHER_API_KEY';
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  // ──────────────────────────────────────────────
  // Base de datos SQLite
  // ──────────────────────────────────────────────
  static const String dbName = 'checkout.db';
  static const int dbVersion = 3;
  static const String tableChecklists = 'checklists';
  static const String tableItems = 'items';

  /// Salidas programadas (calendario).
  static const String tableTrips = 'trips';

  /// Historial al registrar salida (esquema legado).
  static const String tableCompletedTrips = 'completed_trips';
  static const String tableForgottenItems = 'forgotten_items';
  static const String tableCalendarEvents = 'calendar_events';

  // ──────────────────────────────────────────────
  // Claves para shared_preferences
  // ──────────────────────────────────────────────
  static const String prefCity = 'city';
  static const String prefUseCurrentLocation = 'use_current_location';
  static const String prefCurrentLat = 'current_lat';
  static const String prefCurrentLng = 'current_lng';
  static const String prefCurrentLocationName = 'current_location_name';
  static const String prefDarkMode = 'dark_mode';
  static const String prefLastExitType = 'last_exit_type';
  static const String prefOnboardingCompleted = 'onboarding_completed';

  // ──────────────────────────────────────────────
  // Clave JWT en flutter_secure_storage
  // ──────────────────────────────────────────────
  static const String secureKeyJwt = 'jwt_token';

  // ──────────────────────────────────────────────
  // Tipos de salida disponibles
  // ──────────────────────────────────────────────
  static const List<Map<String, String>> exitTypes = [
    {'id': 'personalizado', 'nombre': 'Personalizado', 'emoji': '✨'},
    {'id': 'compras', 'nombre': 'Compras', 'emoji': '🛒'},
    {'id': 'hogar', 'nombre': 'Hogar', 'emoji': '🏠'},
    {'id': 'gym', 'nombre': 'Gym', 'emoji': '🏋️'},
    {'id': 'medico', 'nombre': 'Médico', 'emoji': '🏥'},
  ];

  // ──────────────────────────────────────────────
  // Ítems predeterminados por tipo (nombre + peso en kg)
  // ──────────────────────────────────────────────
  static const Map<String, List<Map<String, dynamic>>> defaultItems = {
    'personalizado': [],
    'compras': [
      {'nombre': 'Frutas', 'peso_kg': 0.0},
      {'nombre': 'Verduras', 'peso_kg': 0.0},
      {'nombre': 'Pan', 'peso_kg': 0.0},
      {'nombre': 'Leche', 'peso_kg': 0.0},
      {'nombre': 'Huevos', 'peso_kg': 0.0},
      {'nombre': 'Proteína / carne', 'peso_kg': 0.0},
      {'nombre': 'Snacks', 'peso_kg': 0.0},
      {'nombre': 'Aseo del hogar', 'peso_kg': 0.0},
    ],
    'hogar': [
      {'nombre': 'Sacar basura', 'peso_kg': 0.0},
      {'nombre': 'Lavar platos', 'peso_kg': 0.0},
      {'nombre': 'Ordenar habitación', 'peso_kg': 0.0},
      {'nombre': 'Limpiar baño', 'peso_kg': 0.0},
      {'nombre': 'Revisar compras faltantes', 'peso_kg': 0.0},
    ],
    'trabajo': [
      {'nombre': 'Laptop', 'peso_kg': 1.5},
      {'nombre': 'Cargador', 'peso_kg': 0.2},
      {'nombre': 'Cuaderno', 'peso_kg': 0.3},
      {'nombre': 'Tarjeta de identificación', 'peso_kg': 0.01},
      {'nombre': 'Paraguas', 'peso_kg': 0.3},
      {'nombre': 'Auriculares', 'peso_kg': 0.25},
    ],
    'viaje': [
      {'nombre': 'Pasaporte', 'peso_kg': 0.05},
      {'nombre': 'Maleta', 'peso_kg': 3.0},
      {'nombre': 'Cargador universal', 'peso_kg': 0.3},
      {'nombre': 'Ropa (3 cambios)', 'peso_kg': 2.0},
      {'nombre': 'Impermeable', 'peso_kg': 0.5},
      {'nombre': 'Paraguas', 'peso_kg': 0.3},
      {'nombre': 'Medicamentos', 'peso_kg': 0.2},
    ],
    'gym': [
      {'nombre': 'Ropa deportiva', 'peso_kg': 0.5},
      {'nombre': 'Zapatillas deportivas', 'peso_kg': 0.8},
      {'nombre': 'Toalla', 'peso_kg': 0.3},
      {'nombre': 'Botella de agua', 'peso_kg': 0.6},
      {'nombre': 'Guantes de gym', 'peso_kg': 0.1},
    ],
    'medico': [
      {'nombre': 'DNI / Seguro médico', 'peso_kg': 0.05},
      {'nombre': 'Historial médico', 'peso_kg': 0.1},
      {'nombre': 'Lista de medicamentos', 'peso_kg': 0.01},
      {'nombre': 'Botella de agua', 'peso_kg': 0.5},
    ],
    'playa': [
      {'nombre': 'Traje de baño', 'peso_kg': 0.2},
      {'nombre': 'Protector solar', 'peso_kg': 0.2},
      {'nombre': 'Toalla de playa', 'peso_kg': 0.5},
      {'nombre': 'Gafas de sol', 'peso_kg': 0.05},
      {'nombre': 'Impermeable', 'peso_kg': 0.5},
    ],
    'camping': [
      {'nombre': 'Tienda de campaña', 'peso_kg': 3.0},
      {'nombre': 'Saco de dormir', 'peso_kg': 1.5},
      {'nombre': 'Linterna', 'peso_kg': 0.3},
      {'nombre': 'Comida (2 días)', 'peso_kg': 2.0},
      {'nombre': 'Impermeable', 'peso_kg': 0.5},
      {'nombre': 'Paraguas', 'peso_kg': 0.3},
    ],
  };

  // Palabras clave para resaltar ítems cuando llueve
  static const List<String> rainKeywords = [
    'paraguas',
    'impermeable',
    'chubasquero',
    'lluvia',
  ];
}
