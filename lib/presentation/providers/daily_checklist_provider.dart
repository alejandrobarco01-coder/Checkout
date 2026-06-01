import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../data/datasources/local/shared_prefs_helper.dart';
import '../../domain/entities/daily_checklist.dart';

/// Provider para gestionar el checklist diario del usuario
class DailyChecklistProvider extends ChangeNotifier {
  List<DailyChecklistItem> _items = [];
  bool _isLoading = false;

  List<DailyChecklistItem> get items => _items;
  bool get isLoading => _isLoading;
  
  int get completedCount => _items.where((item) => item.completado).length;
  int get totalCount => _items.length;
  double get completionPercentage => totalCount == 0 ? 0 : (completedCount / totalCount) * 100;
  bool get allCompleted => completedCount == totalCount && totalCount > 0;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final savedItems = await SharedPrefsHelper.instance.getDailyChecklist();
      if (savedItems.isNotEmpty) {
        _items = savedItems;
      } else {
        // Inicializar con items predeterminados
        _items = DailyChecklistDefaults.defaultItems
            .asMap()
            .entries
            .map((entry) => DailyChecklistItem(
              id: entry.value['id'],
              nombre: entry.value['nombre'],
              emoji: entry.value['emoji'],
              completado: false,
              orden: entry.key,
            ))
            .toList();
        await saveDailyChecklist();
      }
    } catch (e) {
      debugPrint('Error al cargar daily checklist: $e');
      _initializeDefaults();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initializeDefaults() {
    _items = DailyChecklistDefaults.defaultItems
        .asMap()
        .entries
        .map((entry) => DailyChecklistItem(
          id: entry.value['id'],
          nombre: entry.value['nombre'],
          emoji: entry.value['emoji'],
          completado: false,
          orden: entry.key,
        ))
        .toList();
  }

  Future<void> toggleItem(String itemId) async {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(completado: !_items[index].completado);
      await saveDailyChecklist();
      notifyListeners();
    }
  }

  Future<void> addItem(String nombre, String emoji) async {
    final newItem = DailyChecklistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      emoji: emoji,
      completado: false,
      orden: _items.length,
    );
    _items.add(newItem);
    await saveDailyChecklist();
    notifyListeners();
  }

  Future<void> removeItem(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);
    await saveDailyChecklist();
    notifyListeners();
  }

  Future<void> resetDaily() async {
    _items = _items.map((item) => item.copyWith(completado: false)).toList();
    await saveDailyChecklist();
    notifyListeners();
  }

  Future<void> saveDailyChecklist() async {
    try {
      await SharedPrefsHelper.instance.saveDailyChecklist(_items);
    } catch (e) {
      debugPrint('Error al guardar daily checklist: $e');
    }
  }
}
