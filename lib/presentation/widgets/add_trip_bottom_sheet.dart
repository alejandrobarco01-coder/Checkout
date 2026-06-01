import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/trip.dart';
import '../providers/destination_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/weather_provider.dart';
import 'destination_search_widget.dart';
import 'trip_calendar_widget.dart';

/// Formulario para crear salida + checklist desde el calendario.
class AddTripBottomSheet extends StatefulWidget {
  final DateTime? initialDay;

  const AddTripBottomSheet({super.key, this.initialDay});

  static Future<void> show(BuildContext context, {DateTime? day}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTripBottomSheet(initialDay: day),
    );
  }

  @override
  State<AddTripBottomSheet> createState() => _AddTripBottomSheetState();
}

class _AddTripBottomSheetState extends State<AddTripBottomSheet> {
  final _nameCtrl = TextEditingController();
  TripType _type = TripType.casual;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final day = widget.initialDay ?? DateTime.now();
    _rangeStart = DateTime(day.year, day.month, day.day);
    _rangeEnd = _rangeStart;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DestinationProvider>().clearSelection();
      context.read<DestinationProvider>().clearSearch();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isInternational => _type == TripType.international;

  Future<void> _createTrip() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Escribe un nombre para el viaje');
      return;
    }
    if (_rangeStart == null) {
      _snack('Selecciona al menos la fecha de salida');
      return;
    }

    final destProv = context.read<DestinationProvider>();
    final destination = destProv.selectedDestination;
    if (destination == null) {
      _snack('Selecciona un destino');
      return;
    }

    setState(() => _saving = true);

    final checklistId = await context.read<TripProvider>().createTripWithChecklist(
          name: name,
          type: _type,
          departureDate: _rangeStart!,
          returnDate: _sameDay(_rangeStart!, _rangeEnd) ? null : _rangeEnd,
          destinationName: destination.name,
          destinationPlaceId: destination.placeId,
          recommendations: destProv.recommendations,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (checklistId == null) {
      _snack('No se pudo guardar el viaje');
      return;
    }

    Navigator.pop(context);
    context.push('/checklist/$checklistId');
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return true;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottom),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nueva salida',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del viaje',
                  prefixIcon: Icon(Icons.flight_takeoff),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tipo de salida',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TripType.values.map((t) {
                  final selected = _type == t;
                  return FilterChip(
                    selected: selected,
                    label: Text('${t.emoji} ${t.label}'),
                    avatar: Icon(
                      _iconForType(t),
                      size: 18,
                      color: selected ? colors.onPrimary : colors.primary,
                    ),
                    onSelected: (_) {
                      setState(() => _type = t);
                      final dest = context.read<DestinationProvider>().selectedDestination;
                      if (dest != null) {
                        context.read<DestinationProvider>().refreshRecommendations(
                              weather: context.read<WeatherProvider>().weather,
                              isInternationalTrip: t == TripType.international,
                            );
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Fechas (mantén pulsado un día y elige el rango)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              TripCalendarWidget(
                rangeSelectionEnabled: true,
                rangeStart: _rangeStart,
                rangeEnd: _rangeEnd,
                onRangeChanged: (start, end) {
                  setState(() {
                    _rangeStart = start;
                    _rangeEnd = end ?? start;
                  });
                },
              ),
              if (_rangeStart != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _sameDay(_rangeStart, _rangeEnd)
                        ? 'Salida: ${_format(_rangeStart!)}'
                        : '${_format(_rangeStart!)} → ${_format(_rangeEnd ?? _rangeStart!)}',
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Destino',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              DestinationSearchWidget(
                isInternationalTrip: _isInternational,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _createTrip,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.checklist_rtl),
                label: const Text('Crear viaje y generar checklist'),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconForType(TripType t) {
    switch (t) {
      case TripType.beach:
        return Icons.beach_access;
      case TripType.work:
        return Icons.work_outline;
      case TripType.mountain:
        return Icons.terrain;
      case TripType.city:
        return Icons.location_city;
      case TripType.casual:
        return Icons.backpack_outlined;
      case TripType.international:
        return Icons.public;
    }
  }

  String _format(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
