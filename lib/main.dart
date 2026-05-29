import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/checklist_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/weather_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Punto de entrada de CheckOut.
/// Inicializa Firebase (si está configurado), carga el estado
/// de sesión y preferencias, luego monta el árbol de providers.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
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

  runApp(
    MultiProvider(
      // Inyecta todos los providers en el árbol desde el root
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => ChecklistProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
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
    final authProvider = context.watch<AuthProvider>();

    // GoRouter se recrea cuando cambia el estado de autenticación
    // para que el redirect funcione correctamente.
    final router = AppRouter.createRouter(context);

    return MaterialApp.router(
      title: 'CheckOut',
      debugShowCheckedModeBanner: false,

      // Temas claro/oscuro controlados por ThemeProvider
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,

      // Navegación con GoRouter
      routerConfig: router,
    );
  }
}
