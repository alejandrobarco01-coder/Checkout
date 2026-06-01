import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../domain/entities/calendar_event.dart';

class CalendarProvider extends ChangeNotifier {
  List<CalendarEvent> _events = [];
  bool _isLoading = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<CalendarEvent> get events => _events;
  bool get isLoading => _isLoading;
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;

  final _db = DatabaseHelper.instance;

  List<CalendarEvent> eventsForDay(DateTime day) {
    return _events.where((e) {
      return e.fecha.year == day.year &&
          e.fecha.month == day.month &&
          e.fecha.day == day.day;
    }).toList();
  }

  void setSelectedDay(DateTime day) {
    _selectedDay = day;
    _focusedDay = day;
    notifyListeners();
  }

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();
    final rows = await _db.queryAll(AppConstants.tableCalendarEvents);
    _events = rows.map(CalendarEvent.fromMap).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    _isLoading = false;
    notifyListeners();
  }

  Future<CalendarEvent> addEvent({
    required String titulo,
    String? descripcion,
    required String tipo,
    required DateTime fecha,
    String? hora,
    String? destino,
    double? lat,
    double? lng,
    int? color,
  }) async {
    final event = CalendarEvent(
      titulo: titulo,
      descripcion: descripcion,
      tipo: tipo,
      fecha: fecha,
      hora: hora,
      destino: destino,
      lat: lat,
      lng: lng,
      color: color,
    );
    final id = await _db.insert(AppConstants.tableCalendarEvents, event.toMap());
    final saved = CalendarEvent(
      id: id,
      titulo: event.titulo,
      descripcion: event.descripcion,
      tipo: event.tipo,
      fecha: event.fecha,
      hora: event.hora,
      destino: event.destino,
      lat: event.lat,
      lng: event.lng,
      color: event.color,
    );
    _events.add(saved);
    _events.sort((a, b) => a.fecha.compareTo(b.fecha));
    notifyListeners();
    return saved;
  }

  Future<void> deleteEvent(int id) async {
    await _db.deleteWhere(AppConstants.tableCalendarEvents, 'id = ?', [id]);
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
