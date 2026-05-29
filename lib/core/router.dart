import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/checklist_screen.dart';
import '../presentation/screens/settings_screen.dart';

/// Configuración de navegación con GoRouter.
/// Las rutas protegidas redirigen a /login si no hay JWT.
class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/home',
      // Redirige a /login si el usuario no está autenticado
      redirect: (context, state) {
        final authProvider = context.read<AuthProvider>();
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';

        if (!isAuthenticated && !isLoggingIn) return '/login';
        if (isAuthenticated && isLoggingIn) return '/home';
        return null;
      },
      routes: [
        // Pantalla de login con autenticación JWT
        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LoginScreen(),
          ),
        ),

        // Pantalla principal: lista de tipos de salida
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (context, state) => const MaterialPage(
            child: HomeScreen(),
          ),
        ),

        // Checklist activo: recibe el id como parámetro de ruta
        GoRoute(
          path: '/checklist/:id',
          name: 'checklist',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
            return MaterialPage(
              child: ChecklistScreen(checklistId: id),
            );
          },
        ),

        // Configuración y perfil
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => const MaterialPage(
            child: SettingsScreen(),
          ),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text('Ruta no encontrada: ${state.error}'),
        ),
      ),
    );
  }
}
