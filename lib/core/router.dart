import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/checklist_screen.dart';
import '../presentation/screens/checklists_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/conversational_checklist_screen.dart';
import '../presentation/screens/onboarding_screen.dart';
import '../presentation/screens/trips_screen.dart';
import '../presentation/screens/forgotten_items_screen.dart';
import '../presentation/screens/calendar_screen.dart';
import '../presentation/screens/map_screen.dart';
import '../presentation/screens/trip_detail_screen.dart';
import '../presentation/screens/habits_screen.dart';

/// Configuración de navegación con GoRouter.
/// Las rutas protegidas redirigen a /login si no hay JWT.
class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/home',
      refreshListenable: context.read<AuthProvider>(),
      // Redirige a /login si el usuario no está autenticado
      redirect: (context, state) {
        final authProvider = context.read<AuthProvider>();
        final isOnboardingCompleted = authProvider.isOnboardingCompleted;
        final isAuthenticated = authProvider.isAuthenticated;

        final isLoggingIn = state.matchedLocation == '/login';
        final isOnboarding = state.matchedLocation == '/onboarding';

        if (!isOnboardingCompleted) {
          return isOnboarding ? null : '/onboarding';
        }
        if (isOnboardingCompleted && isOnboarding) {
          return isAuthenticated ? '/home' : '/login';
        }
        if (!isAuthenticated && !isLoggingIn) return '/login';
        if (isAuthenticated && isLoggingIn) return '/home';
        return null;
      },
      routes: [
        // Pantalla de onboarding
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: OnboardingScreen(),
          ),
        ),

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

        GoRoute(
          path: '/habits',
          name: 'habits',
          pageBuilder: (context, state) => const MaterialPage(
            child: HabitsScreen(),
          ),
        ),

        GoRoute(
          path: '/habit-calendar',
          name: 'habit-calendar',
          pageBuilder: (context, state) => const MaterialPage(
            child: HabitCalendarScreen(),
          ),
        ),

        GoRoute(
          path: '/habits/calendar',
          name: 'habits-calendar',
          redirect: (context, state) => '/habit-calendar',
        ),

        GoRoute(
          path: '/habit/new/:templateId',
          name: 'habit-new',
          pageBuilder: (context, state) {
            return MaterialPage(
              child: HabitSetupScreen(
                templateId: state.pathParameters['templateId'],
              ),
            );
          },
        ),

        GoRoute(
          path: '/habit/custom',
          name: 'habit-custom',
          pageBuilder: (context, state) => const MaterialPage(
            child: HabitSetupScreen(),
          ),
        ),

        GoRoute(
          path: '/checklists',
          name: 'checklists',
          pageBuilder: (context, state) => const MaterialPage(
            child: ChecklistsScreen(),
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

        // Creación de checklist con IA conversacional
        GoRoute(
          path: '/ai-checklist',
          name: 'ai-checklist',
          pageBuilder: (context, state) => const MaterialPage(
            child: ConversationalChecklistScreen(),
          ),
        ),

        // Historial de Viajes
        GoRoute(
          path: '/trips',
          name: 'trips',
          pageBuilder: (context, state) => const MaterialPage(
            child: TripsScreen(),
          ),
        ),

        GoRoute(
          path: '/trips/:tripId',
          name: 'trip-detail',
          pageBuilder: (context, state) {
            final tripId = state.pathParameters['tripId'] ?? '';
            return MaterialPage(
              child: TripDetailScreen(tripId: tripId),
            );
          },
        ),

        // Ítems olvidados
        GoRoute(
          path: '/forgotten',
          name: 'forgotten',
          pageBuilder: (context, state) => const MaterialPage(
            child: ForgottenItemsScreen(),
          ),
        ),

        // Calendario
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          pageBuilder: (context, state) => const MaterialPage(
            child: CalendarScreen(),
          ),
        ),

        // Mapa
        GoRoute(
          path: '/map',
          name: 'map',
          pageBuilder: (context, state) {
            final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
            final lng = double.tryParse(state.uri.queryParameters['lng'] ?? '');
            final name = state.uri.queryParameters['name'];
            return MaterialPage(
              child: MapScreen(
                  initialLat: lat, initialLng: lng, locationName: name),
            );
          },
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
