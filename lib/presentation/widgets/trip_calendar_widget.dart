import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../domain/entities/trip.dart';
import '../providers/trip_provider.dart';

/// Calendario mensual con dots por tipo de viaje y selección de rango.
class TripCalendarWidget extends StatefulWidget {
  final void Function(DateTime? start, DateTime? end)? onRangeChanged;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final bool rangeSelectionEnabled;

  const TripCalendarWidget({
    super.key,
    this.onRangeChanged,
    this.rangeStart,
    this.rangeEnd,
    this.rangeSelectionEnabled = false,
  });

  @override
  State<TripCalendarWidget> createState() => _TripCalendarWidgetState();
}

class _TripCalendarWidgetState extends State<TripCalendarWidget> {
  RangeSelectionMode _rangeMode = RangeSelectionMode.toggledOff;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.rangeStart;
    _rangeEnd = widget.rangeEnd;
    _rangeMode = widget.rangeSelectionEnabled
        ? RangeSelectionMode.toggledOn
        : RangeSelectionMode.toggledOff;
  }

  @override
  Widget build(BuildContext context) {
    final tripProv = context.watch<TripProvider>();
    final colors = Theme.of(context).colorScheme;

    return TableCalendar<Trip>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: tripProv.focusedDay,
      rangeStartDay: _rangeStart,
      rangeEndDay: _rangeEnd,
      rangeSelectionMode: _rangeMode,
      selectedDayPredicate: (day) => isSameDay(tripProv.selectedDay, day),
      eventLoader: tripProv.tripsOnDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarFormat: CalendarFormat.month,
      availableGestures: AvailableGestures.all,
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        leftChevronIcon: Icon(Icons.chevron_left, color: colors.primary),
        rightChevronIcon: Icon(Icons.chevron_right, color: colors.primary),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: colors.primary.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
        rangeStartDecoration: BoxDecoration(
          color: colors.primary.withOpacity(0.85),
          shape: BoxShape.circle,
        ),
        rangeEndDecoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
        withinRangeDecoration: BoxDecoration(
          color: colors.primary.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markerSize: 6,
        markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return null;
          final shown = events.take(3).toList();
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: shown.map((trip) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Color(trip.type.colorValue),
                  shape: BoxShape.circle,
                ),
              );
            }).toList(),
          );
        },
      ),
      onDaySelected: (selected, focused) {
        if (_rangeMode == RangeSelectionMode.toggledOn) {
          setState(() {
            if (_rangeStart == null) {
              _rangeStart = selected;
            } else if (_rangeEnd == null && !selected.isBefore(_rangeStart!)) {
              _rangeEnd = selected;
              widget.onRangeChanged?.call(_rangeStart, _rangeEnd);
            } else {
              _rangeStart = selected;
              _rangeEnd = null;
              widget.onRangeChanged?.call(_rangeStart, null);
            }
          });
        }
        tripProv.setSelectedDay(selected);
        tripProv.setFocusedDay(focused);
      },
      onRangeSelected: (start, end, focused) {
        setState(() {
          _rangeStart = start;
          _rangeEnd = end;
        });
        widget.onRangeChanged?.call(start, end);
        tripProv.setFocusedDay(focused);
      },
      onPageChanged: (focused) => tripProv.setFocusedDay(focused),
    );
  }

}
