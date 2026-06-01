import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavigation extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/home');
          case 1:
            context.go('/habits');
          case 2:
            context.go('/checklists');
          case 3:
            context.go('/trips');
          case 4:
            context.go('/settings');
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline_rounded),
          selectedIcon: Icon(Icons.add_circle_rounded),
          label: 'Hábitos',
        ),
        NavigationDestination(
          icon: Icon(Icons.checklist_rounded),
          selectedIcon: Icon(Icons.fact_check_rounded),
          label: 'Checklist',
        ),
        NavigationDestination(
          icon: Icon(Icons.flight_takeoff_outlined),
          selectedIcon: Icon(Icons.flight_takeoff_rounded),
          label: 'Viajes',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Ajustes',
        ),
      ],
    );
  }
}
