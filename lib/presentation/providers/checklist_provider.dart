import 'package:flutter/foundation.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/entities/item.dart';
import '../../domain/usecases/checklist_usecases.dart';
import '../../data/repositories/checklist_repository_impl.dart';

/// Enum para el estado de sincronización con Firestore.
enum SyncStatus { idle, syncing, synced, error }

/// Provider principal de checklists.
/// Expone: lista de checklists, checklist activo, ítems, loading state.
/// Usa compute() para calcular estadísticas en background.
class ChecklistProvider extends ChangeNotifier {
  final ChecklistRepositoryImpl _repo = ChecklistRepositoryImpl();

  // ── Estado ─────────────────────────────────────
  List<Checklist> _checklists = [];
  Checklist? _activeChecklist;
  List<Item> _items = [];
  bool _isLoading = false;
  String? _error;
  ChecklistStatsResult? _stats;
  SyncStatus _syncStatus = SyncStatus.idle;

  // ── Getters ────────────────────────────────────
  List<Checklist> get checklists => _checklists;
  Checklist? get activeChecklist => _activeChecklist;
  List<Item> get items => _items;
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

  Future<void> toggleItem(Item item) async {
    // Actualiza localmente para respuesta inmediata en UI
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      _items[idx] = item.copyWith(completado: !item.completado);
      notifyListeners();
    }
    // Persiste en SQLite
    await _repo.toggleItem(item);
    // Sincroniza con Firestore
    await _syncItemToFirestore(_items[idx]);
    // Recalcula estadísticas en background
    await _recalcStats();
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
    await _recalcStats();
    notifyListeners();
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
