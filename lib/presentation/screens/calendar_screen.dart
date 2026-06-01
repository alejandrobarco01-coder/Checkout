import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/trip.dart';
import '../providers/trip_provider.dart';
import '../widgets/add_trip_bottom_sheet.dart';
import '../widgets/trip_calendar_widget.dart';

/// Calendario de salidas programadas con panel de próximos viajes.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _navIndex = 1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final tripProv = context.watch<TripProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario de viajes'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: TripCalendarWidget(),
          ),
          const Divider(height: 1),
          Expanded(
            child: tripProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _UpcomingPanel(
                    upcoming: tripProv.upcomingTrips,
                    selectedDayTrips:
                        tripProv.tripsOnDay(tripProv.selectedDay),
                    onNewTrip: () => AddTripBottomSheet.show(
                      context,
                      day: tripProv.selectedDay,
                    ),
                    onTripTap: (trip) {
                      if (trip.checklistId != null) {
                        context.push('/checklist/${trip.checklistId}');
                      } else {
                        context.push('/trips/${trip.id}');
                      }
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddTripBottomSheet.show(
          context,
          day: tripProv.selectedDay,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nueva salida'),
        backgroundColor: colors.primary,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          setState(() => _navIndex = i);
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              break;
            case 2:
              context.go('/trips');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month), label: 'Calendario'),
          NavigationDestination(icon: Icon(Icons.flight), label: 'Viajes'),
        ],
      ),
    );
  }
}

class _UpcomingPanel extends StatelessWidget {
  final List<Trip> upcoming;
  final List<Trip> selectedDayTrips;
  final VoidCallback onNewTrip;
  final void Function(Trip trip) onTripTap;

  const _UpcomingPanel({
    required this.upcoming,
    required this.selectedDayTrips,
    required this.onNewTrip,
    required this.onTripTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'PRÓXIMAS SALIDAS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: colors.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Nueva salida +'),
                onPressed: onNewTrip,
              ),
              const SizedBox(width: 8),
              ...upcoming.map((trip) => _TripChip(trip: trip, onTap: () => onTripTap(trip))),
            ],
          ),
        ),
        if (selectedDayTrips.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'SALIDAS EL DÍA SELECCIONADO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: colors.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          ...selectedDayTrips.map(
            (t) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(t.type.colorValue).withOpacity(0.2),
                child: Text(t.type.emoji, style: const TextStyle(fontSize: 16)),
              ),
              title: Text(t.name),
              subtitle: Text(t.destinationName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onTripTap(t),
            ),
          ),
        ],
        if (upcoming.isEmpty && selectedDayTrips.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Center(
              child: Text(
                'Sin salidas programadas. Toca "Nueva salida +" para planificar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }
}

class _TripChip extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const _TripChip({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final days = trip.daysUntilDeparture;
    final label = days == 0
        ? 'Hoy'
        : days == 1
            ? 'Mañana'
            : 'En $days días';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Color(trip.type.colorValue),
            shape: BoxShape.circle,
          ),
        ),
        label: Text('${trip.name} · $label'),
        onPressed: onTap,
      ),
    );
  }
}
