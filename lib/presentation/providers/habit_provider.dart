import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/habit.dart';

class HabitProvider extends ChangeNotifier {
  static const _storageKey = 'active_habits';
  final _uuid = const Uuid();

  List<ActiveHabit> _habits = [];
  bool _isLoading = false;

  List<ActiveHabit> get habits => _habits;
  bool get isLoading => _isLoading;

  List<ActiveHabit> get activeHabits {
    final sorted = List<ActiveHabit>.from(_habits);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        _habits = decoded
            .map((item) => ActiveHabit.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      } catch (_) {
        _habits = [];
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHabit({
    required String templateId,
    required String name,
    required String emoji,
    required HabitCategory category,
    required HabitGoalType goalType,
    required String unit,
    required int target,
    required String description,
    required int colorValue,
  }) async {
    final habit = ActiveHabit(
      id: _uuid.v4(),
      templateId: templateId,
      name: name,
      emoji: emoji,
      category: category,
      goalType: goalType,
      unit: unit,
      target: target,
      description: description,
      colorValue: colorValue,
      logs: const [],
      createdAt: DateTime.now(),
    );
    _habits = [habit, ..._habits];
    await _persist();
  }

  Future<void> deleteHabit(String id) async {
    _habits = _habits.where((habit) => habit.id != id).toList();
    await _persist();
  }

  Future<void> addProgress(String id, int delta) async {
    _updateToday(id, valueDelta: delta);
    await _persist();
  }

  Future<void> addElapsedSeconds(String id, int seconds) async {
    if (seconds <= 0) return;
    _updateToday(id, elapsedDelta: seconds);
    await _persist();
  }

  HabitLog todayLog(ActiveHabit habit) {
    final key = todayKey();
    return habit.logs.firstWhere(
      (log) => log.dateKey == key,
      orElse: () => HabitLog(dateKey: key),
    );
  }

  HabitLog logForDate(ActiveHabit habit, DateTime date) {
    final key = dateKey(date);
    return habit.logs.firstWhere(
      (log) => log.dateKey == key,
      orElse: () => HabitLog(dateKey: key),
    );
  }

  bool isCompletedOn(ActiveHabit habit, DateTime date) {
    final log = logForDate(habit, date);
    if (_isTimer(habit)) {
      final minutes = (log.elapsedSeconds / 60).floor();
      if (_isLimit(habit)) return minutes > 0 && minutes <= habit.target;
      return minutes >= habit.target;
    }
    if (_isLimit(habit)) return log.value <= habit.target && log.value > 0;
    return log.value >= habit.target;
  }

  int currentStreak(ActiveHabit habit) {
    var streak = 0;
    var cursor = DateTime.now();
    for (var i = 0; i < 370; i++) {
      if (isCompletedOn(habit, cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int monthCompletedDays(ActiveHabit habit, DateTime month) {
    var count = 0;
    final days = _daysInMonth(month.year, month.month);
    for (var day = 1; day <= days; day++) {
      if (isCompletedOn(habit, DateTime(month.year, month.month, day))) count++;
    }
    return count;
  }

  double monthlyScore(DateTime month) {
    if (_habits.isEmpty) return 0;
    final now = DateTime.now();
    final daysInMonth = _daysInMonth(month.year, month.month);
    final maxDay = month.year == now.year && month.month == now.month
        ? now.day
        : daysInMonth;
    final totalTargets = _habits.length * maxDay;
    if (totalTargets == 0) return 0;
    var completed = 0;
    for (final habit in _habits) {
      for (var day = 1; day <= maxDay; day++) {
        if (isCompletedOn(habit, DateTime(month.year, month.month, day))) {
          completed++;
        }
      }
    }
    return completed / totalTargets;
  }

  double progressFor(ActiveHabit habit) {
    if (habit.target <= 0) return 0;
    final log = todayLog(habit);
    final current =
        _isTimer(habit) ? (log.elapsedSeconds / 60).round() : log.value;
    if (_isLimit(habit)) {
      return current <= habit.target ? current / habit.target : 1;
    }
    return (current / habit.target).clamp(0, 1);
  }

  bool isOverLimit(ActiveHabit habit) {
    if (!_isLimit(habit)) return false;
    final log = todayLog(habit);
    final current =
        _isTimer(habit) ? (log.elapsedSeconds / 60).round() : log.value;
    return current > habit.target;
  }

  String statusText(ActiveHabit habit) {
    final log = todayLog(habit);
    if (_isTimer(habit)) {
      final minutes = (log.elapsedSeconds / 60).floor();
      return '$minutes/${habit.target}${habit.unit}';
    }
    return '${log.value}/${habit.target} ${habit.unit}';
  }

  String aiRecommendation(ActiveHabit habit) {
    if (!isOverLimit(habit)) return '';
    switch (habit.templateId) {
      case 'less_games':
        return 'Pausa ahora, deja el control fuera de vista y cambia a una actividad corta de 10 minutos: caminar, ducha o ordenar tu espacio.';
      case 'less_alcohol':
        return 'Alterna con agua, come algo ligero y evita comprar mas hoy. Si esto se repite, baja el limite por etapas y busca apoyo cercano.';
      case 'less_smoking':
        return 'Retrasa el siguiente cigarrillo 10 minutos, respira lento y cambia el contexto fisico. Repite el retraso antes de decidir.';
      case 'less_sugar':
        return 'Toma agua, come una fruta o proteina y deja el dulce fuera de alcance. No intentes compensar: vuelve al plan en la siguiente comida.';
      default:
        return 'Detectamos que pasaste tu limite. Reduce friccion: aleja el disparador, cambia de lugar y elige una accion pequena de reemplazo.';
    }
  }

  static String todayKey() {
    return dateKey(DateTime.now());
  }

  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _updateToday(String id, {int valueDelta = 0, int elapsedDelta = 0}) {
    _habits = _habits.map((habit) {
      if (habit.id != id) return habit;
      final key = todayKey();
      final logs = List<HabitLog>.from(habit.logs);
      final index = logs.indexWhere((log) => log.dateKey == key);
      final current = index == -1 ? HabitLog(dateKey: key) : logs[index];
      final updated = current.copyWith(
        value: (current.value + valueDelta).clamp(0, 99999),
        elapsedSeconds:
            (current.elapsedSeconds + elapsedDelta).clamp(0, 999999),
      );
      if (index == -1) {
        logs.add(updated);
      } else {
        logs[index] = updated;
      }
      return habit.copyWith(logs: logs);
    }).toList();
    notifyListeners();
  }

  bool _isTimer(ActiveHabit habit) {
    return habit.goalType == HabitGoalType.timer ||
        habit.goalType == HabitGoalType.limit;
  }

  bool _isLimit(ActiveHabit habit) {
    return habit.goalType == HabitGoalType.limit ||
        habit.goalType == HabitGoalType.reduce;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_habits.map((habit) => habit.toJson()).toList()),
    );
    notifyListeners();
  }
}
