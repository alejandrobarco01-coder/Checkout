import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/trip.dart';
import '../providers/trip_provider.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  Trip? _trip;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Carga simple vía repositorio expuesto en provider (mes actual).
    final prov = context.read<TripProvider>();
    await prov.loadMonth(prov.focusedDay.year, prov.focusedDay.month);
    Trip? found;
    for (final list in prov.tripsByDay.values) {
      for (final t in list) {
        if (t.id == widget.tripId) found = t;
      }
    }
    _trip = found;
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del viaje')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : trip == null
              ? const Center(child: Text('Viaje no encontrado'))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trip.type.emoji} ${trip.name}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(trip.destinationName),
                      const SizedBox(height: 16),
                      Text(
                        'Salida: ${_fmt(trip.departureDate)}',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      if (trip.returnDate != null)
                        Text(
                          'Regreso: ${_fmt(trip.returnDate!)}',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      const Spacer(),
                      if (trip.checklistId != null)
                        FilledButton.icon(
                          onPressed: () =>
                              context.push('/checklist/${trip.checklistId}'),
                          icon: const Icon(Icons.checklist),
                          label: const Text('Abrir checklist'),
                        ),
                    ],
                  ),
                ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
