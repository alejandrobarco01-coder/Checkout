import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/router.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/checklist_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/weather_provider.dart';
import 'presentation/providers/ai_checklist_provider.dart';
import 'presentation/providers/trip_provider.dart';
import 'presentation/providers/trip_history_provider.dart';
import 'presentation/providers/destination_provider.dart';
import 'presentation/providers/calendar_provider.dart';
import 'presentation/providers/daily_checklist_provider.dart';
import 'presentation/providers/habit_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/notification_service.dart';

/// Punto de entrada de CheckOut.
/// Inicializa Firebase (si está configurado), carga el estado
/// de sesión y preferencias, luego monta el árbol de providers.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('No se cargó .env: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase no configurado: $e');
  }

  // Crea los providers antes de iniciar la app
  final authProvider = AuthProvider();
  final themeProvider = ThemeProvider();

  // Carga sesión JWT y preferencia de tema antes de mostrar la UI
  await Future.wait([
    authProvider.init(),
    themeProvider.init(),
  ]);

  // Inicializar servicio de notificaciones
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('No se pudo inicializar NotificationService: $e');
  }

  runApp(
    MultiProvider(
      // Inyecta todos los providers en el árbol desde el root
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => ChecklistProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => AIChecklistProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()..init()),
        ChangeNotifierProvider(create: (_) => TripHistoryProvider()),
        ChangeNotifierProvider(create: (_) => DestinationProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => DailyChecklistProvider()..init()),
        ChangeNotifierProvider(create: (_) => HabitProvider()..init()),
      ],
      child: const CheckOutApp(),
    ),
  );
}

class CheckOutApp extends StatelessWidget {
  const CheckOutApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // GoRouter se recrea cuando cambia el estado de autenticación
    // para que el redirect funcione correctamente.
    final router = AppRouter.createRouter(context);

    return MaterialApp.router(
      title: 'CheckOut',
      debugShowCheckedModeBanner: false,

      // Temas controlados por ThemeProvider
      theme: themeProvider.currentTheme,
      themeMode: ThemeMode.light,

      // Navegación con GoRouter
      routerConfig: router,
    );
  }
}
