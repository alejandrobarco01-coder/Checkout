import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../domain/entities/completed_trip.dart';
import '../providers/trip_history_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/add_trip_bottom_sheet.dart';
import '../widgets/app_bottom_navigation.dart';

/// Historial de viajes registrados al completar una salida.
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripHistoryProvider>().loadTrips();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _exitTypeLabel(String id) {
    final type = AppConstants.exitTypes.firstWhere(
      (t) => t['id'] == id,
      orElse: () => {'emoji': '📋', 'nombre': id},
    );
    return '${type['emoji']} ${type['nombre']}';
  }

  Color _progressColor(double pct) {
    if (pct >= 100) return Colors.green;
    if (pct >= 50) return const Color(0xFF6C5CE7);
    return const Color(0xFFE17055);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripHistoryProvider>();
    final colors = Theme.of(context).colorScheme;
    final tripProv = context.read<TripProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Viajes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Crear viaje',
            onPressed: () => AddTripBottomSheet.show(
              context,
              day: tripProv.selectedDay,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Ver mapa',
            onPressed: () => context.push('/map'),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.trips.isEmpty
              ? _EmptyState(
                  onOpenMap: () => context.push('/map'),
                  onCreateTrip: () => AddTripBottomSheet.show(
                    context,
                    day: tripProv.selectedDay,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.trips.length,
                  itemBuilder: (context, index) {
                    final trip = provider.trips[index];
                    return _TripCard(
                      trip: trip,
                      formatDate: _formatDate,
                      exitTypeLabel: _exitTypeLabel,
                      progressColor: _progressColor,
                      onDelete: () => _confirmDelete(trip),
                      onMap: trip.lat != null && trip.lng != null
                          ? () => context.push(
                                '/map?lat=${trip.lat}&lng=${trip.lng}&name=${Uri.encodeComponent(trip.destino.isNotEmpty ? trip.destino : trip.nombre)}',
                              )
                          : null,
                    )
                        .animate(delay: (index * 50).ms)
                        .fadeIn()
                        .slideY(begin: 0.05);
                  },
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fab_create_trip',
            onPressed: () => AddTripBottomSheet.show(
              context,
              day: context.read<TripProvider>().selectedDay,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Crear viaje'),
            backgroundColor: colors.primary,
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'fab_map',
            onPressed: () => context.push('/map'),
            backgroundColor: colors.secondaryContainer,
            foregroundColor: colors.onSecondaryContainer,
            mini: true,
            tooltip: 'Ver mapa',
            child: const Icon(Icons.map),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigation(selectedIndex: 3),
    );
  }

  Future<void> _confirmDelete(CompletedTrip trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar viaje?'),
        content: Text('Se eliminará el registro de "${trip.nombre}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted && trip.id != null) {
      await context.read<TripHistoryProvider>().deleteTrip(trip.id!);
    }
  }
}

class _TripCard extends StatelessWidget {
  final CompletedTrip trip;
  final String Function(DateTime) formatDate;
  final String Function(String) exitTypeLabel;
  final Color Function(double) progressColor;
  final VoidCallback onDelete;
  final VoidCallback? onMap;

  const _TripCard({
    required this.trip,
    required this.formatDate,
    required this.exitTypeLabel,
    required this.progressColor,
    required this.onDelete,
    this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pct = trip.porcentajeCompletado;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (onMap != null)
                  IconButton(
                    icon: Icon(Icons.location_on, color: colors.primary),
                    onPressed: onMap,
                    tooltip: 'Ver en mapa',
                  ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: colors.error.withOpacity(0.7)),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatDate(trip.fechaSalida),
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            if (trip.destino.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.place, size: 16, color: colors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trip.destino,
                      style:
                          TextStyle(color: colors.onSurface.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(exitTypeLabel(trip.tipoSalida),
                      style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 8,
                      backgroundColor: colors.primary.withOpacity(0.1),
                      color: progressColor(pct),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor(pct),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onOpenMap;
  final VoidCallback onCreateTrip;

  const _EmptyState({required this.onOpenMap, required this.onCreateTrip});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff,
                size: 72, color: colors.primary.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text(
              'Sin viajes registrados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer viaje o explora el mapa para descubrir destinos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreateTrip,
              icon: const Icon(Icons.add),
              label: const Text('Crear viaje'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onOpenMap,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Explorar mapa'),
            ),
          ],
        ),
      ),
    );
  }
}
