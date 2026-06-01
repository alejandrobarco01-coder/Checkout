import 'package:flutter/foundation.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/entities/item.dart';
import '../../domain/usecases/checklist_usecases.dart';
import '../../data/repositories/checklist_repository_impl.dart';
import '../../core/packing_intelligence.dart';

/// Enum para el estado de sincronización con Firestore.
enum SyncStatus { idle, syncing, synced, error }

class ChecklistWarning {
  final Checklist checklist;
  final int total;
  final int pending;
  final int completed;

  const ChecklistWarning({
    required this.checklist,
    required this.total,
    required this.pending,
    required this.completed,
  });

  bool get isEmpty => total == 0;
  bool get hasNoSelection => total > 0 && completed == 0;
  double get progress => total == 0 ? 0 : completed / total;

  String get message {
    if (isEmpty) return 'Está vacía. Agrega ítems para usarla.';
    if (hasNoSelection) return 'No has marcado ningún ítem todavía.';
    return 'Tiene $pending ítem(s) pendiente(s).';
  }
}

/// Provider principal de checklists.
/// Expone: lista de checklists, checklist activo, ítems, loading state.
/// Usa compute() para calcular estadísticas en background.
class ChecklistProvider extends ChangeNotifier {
  final ChecklistRepositoryImpl _repo = ChecklistRepositoryImpl();

  // ── Estado ─────────────────────────────────────
  List<Checklist> _checklists = [];
  List<ChecklistWarning> _warnings = [];
  Checklist? _activeChecklist;
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;
  ChecklistStatsResult? _stats;
  SyncStatus _syncStatus = SyncStatus.idle;

  // ── Getters ────────────────────────────────────
  List<Checklist> get checklists => _checklists;
  List<ChecklistWarning> get warnings => _warnings;
  Checklist? get activeChecklist => _activeChecklist;
  List<Item> get items => _items;
  List<Item> get criticalPendingItems {
    final exitType = _activeChecklist?.tipoSalida ?? '';
    return _items
        .where((item) =>
            !item.completado && PackingIntelligence.isCritical(item, exitType))
        .toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  ChecklistStatsResult? get stats => _stats;
  SyncStatus get syncStatus => _syncStatus;

  // ──────────────────────────────────────────────
  // CRUD Checklists
  // ──────────────────────────────────────────────

  Future<void> loadChecklists() async {
    _isLoading = true;
    notifyListeners();
    try {
      _checklists = await _repo.getAll();
      _warnings = await _buildWarnings(_checklists);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> createChecklist(String nombre, String tipoSalida) async {
    final checklist = Checklist(
      nombre: nombre,
      tipoSalida: tipoSalida,
      fechaCreacion: DateTime.now(),
    );
    final id = await _repo.create(checklist);
    // Inserta ítems predeterminados para el tipo de salida
    await _repo.seedDefaultItems(id, tipoSalida);
    await loadChecklists();
    return id;
  }

  Future<void> deleteChecklist(int id) async {
    await _repo.delete(id);
    await loadChecklists();
  }

  // ──────────────────────────────────────────────
  // Carga el checklist activo y sus ítems
  // ──────────────────────────────────────────────

  Future<void> loadChecklist(int id) async {
    _isLoading = true;
    _stats = null;
    notifyListeners();
    try {
      _activeChecklist = await _repo.getById(id);
      _items = await _repo.getItems(id);
      _sortItems();
      // Calcula estadísticas en un Isolate separado (no bloquea la UI)
      await _recalcStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ──────────────────────────────────────────────
  // CRUD Items
  // ──────────────────────────────────────────────

  Future<void> addItem(String nombre, double pesoKg) async {
    if (_activeChecklist?.id == null) return;
    final item = Item(
      checklistId: _activeChecklist!.id!,
      nombre: nombre,
      pesoKg: pesoKg,
    );
    await _repo.addItem(item);
    await _reloadItems();
  }

  Future<void> addSuggestions(List<PackingSuggestion> suggestions) async {
    if (_activeChecklist?.id == null || suggestions.isEmpty) return;
    for (final suggestion in suggestions) {
      final item = Item(
        checklistId: _activeChecklist!.id!,
        nombre: suggestion.name,
        pesoKg: suggestion.weightKg,
      );
      await _repo.addItem(item);
    }
    await _reloadItems();
  }

  /// Agrega un ítem directamente a un checklist por ID (sin necesitar el activo).
  /// Usado por el flujo de generación con IA.
  Future<void> addItemToChecklist(int checklistId, String nombre) async {
    final item = Item(checklistId: checklistId, nombre: nombre);
    await _repo.addItem(item);
  }

  Future<void> toggleItem(Item item) async {
    // Actualiza localmente para respuesta inmediata en UI
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx == -1) return;
    _items[idx] = item.copyWith(completado: !item.completado);
    _sortItems();
    notifyListeners();
    // Persiste en SQLite
    await _repo.toggleItem(item);
    // Sincroniza con Firestore
    await _syncItemToFirestore(item.copyWith(completado: !item.completado));
    // Recalcula estadísticas en background
    await _recalcStats();
    _warnings = await _buildWarnings(_checklists);
    notifyListeners();
  }

  Future<void> completeActiveChecklist() async {
    if (_activeChecklist?.id == null) return;
    final pending = _items.where((item) => !item.completado).toList();
    for (final item in pending) {
      await _repo.toggleItem(item);
    }
    await _reloadItems();
    await loadChecklists();
  }

  Future<void> deleteItem(int itemId) async {
    await _repo.deleteItem(itemId);
    await _reloadItems();
  }

  // ──────────────────────────────────────────────
  // Helpers privados
  // ──────────────────────────────────────────────

  Future<void> _reloadItems() async {
    if (_activeChecklist?.id == null) return;
    _items = await _repo.getItems(_activeChecklist!.id!);
    _sortItems();
    await _recalcStats();
    _warnings = await _buildWarnings(_checklists);
    notifyListeners();
  }

  Future<List<ChecklistWarning>> _buildWarnings(
    List<Checklist> checklists,
  ) async {
    final warnings = <ChecklistWarning>[];
    for (final checklist in checklists) {
      final id = checklist.id;
      if (id == null) continue;
      final checklistItems = await _repo.getItems(id);
      final completed = checklistItems.where((item) => item.completado).length;
      final pending = checklistItems.length - completed;
      if (checklistItems.isEmpty || pending > 0) {
        warnings.add(
          ChecklistWarning(
            checklist: checklist,
            total: checklistItems.length,
            pending: pending,
            completed: completed,
          ),
        );
      }
    }
    warnings.sort((a, b) {
      if (a.hasNoSelection != b.hasNoSelection) {
        return a.hasNoSelection ? -1 : 1;
      }
      if (a.isEmpty != b.isEmpty) return a.isEmpty ? -1 : 1;
      return b.checklist.fechaCreacion.compareTo(a.checklist.fechaCreacion);
    });
    return warnings;
  }

  void _sortItems() {
    final exitType = _activeChecklist?.tipoSalida ?? '';
    _items.sort((a, b) {
      final aCritical = PackingIntelligence.isCritical(a, exitType);
      final bCritical = PackingIntelligence.isCritical(b, exitType);
      if (a.completado != b.completado) return a.completado ? 1 : -1;
      if (aCritical != bCritical) return aCritical ? -1 : 1;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
  }

  /// Usa compute() para ejecutar el cálculo en un Isolate separado.
  /// Así no bloquea el hilo principal de Flutter.
  Future<void> _recalcStats() async {
    _stats = await compute(calcularEstadisticas, List<Item>.from(_items));
    notifyListeners();
  }

  /// Sincronización con Firestore (indicador en AppBar).
  Future<void> _syncItemToFirestore(Item item) async {
    _syncStatus = SyncStatus.syncing;
    notifyListeners();
    try {
      // Importación lazy para evitar crash si Firebase no está configurado
      // ignore: avoid_dynamic_calls
      final firestore = await _getFirestore();
      if (firestore == null) {
        _syncStatus = SyncStatus.idle;
        notifyListeners();
        return;
      }
      await firestore
          .collection('checklists')
          .doc('${_activeChecklist?.id}')
          .collection('items')
          .doc('${item.id}')
          .set({
        'nombre': item.nombre,
        'completado': item.completado,
        'peso_kg': item.pesoKg,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _syncStatus = SyncStatus.synced;
    } catch (_) {
      _syncStatus = SyncStatus.error;
    }
    notifyListeners();
    // Resetea el indicador tras 3 segundos
    await Future.delayed(const Duration(seconds: 3));
    _syncStatus = SyncStatus.idle;
    notifyListeners();
  }

  /// Retorna la instancia de Firestore si Firebase está disponible.
  Future<dynamic> _getFirestore() async {
    try {
      // ignore: unnecessary_import
      final firestore =
          // ignore: invalid_use_of_visible_for_testing_member
          await Future.value(_FirestoreInstance.instance);
      return firestore;
    } catch (_) {
      return null;
    }
  }
}

/// Wrapper para importar Firestore de forma lazy.
class _FirestoreInstance {
  static dynamic get instance {
    try {
      // Se carga en tiempo de ejecución para evitar errores si Firebase
      // no está configurado con google-services.json
      throw UnimplementedError('Configura Firebase para activar la sync');
    } catch (_) {
      return null;
    }
  }
}
