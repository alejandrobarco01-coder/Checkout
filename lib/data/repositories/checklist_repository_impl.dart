import '../../core/constants.dart';
import '../../domain/entities/checklist.dart';
import '../../domain/entities/item.dart';
import '../models/checklist_model.dart';
import '../models/item_model.dart';
import '../datasources/local/database_helper.dart';
import '../../domain/usecases/checklist_usecases.dart';

/// Implementación del repositorio de checklists.
/// Une el DatabaseHelper (SQLite) con la capa de dominio.
class ChecklistRepositoryImpl implements ChecklistRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  Future<List<Checklist>> getAll() async {
    final maps = await _db.queryAll(AppConstants.tableChecklists);
    return maps.map((m) => ChecklistModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<Checklist?> getById(int id) async {
    final maps = await _db.queryWhere(
      AppConstants.tableChecklists,
      'id = ?',
      [id],
    );
    if (maps.isEmpty) return null;
    return ChecklistModel.fromMap(maps.first).toEntity();
  }

  @override
  Future<int> create(Checklist checklist) async {
    final model = ChecklistModel.fromEntity(checklist);
    return _db.insert(AppConstants.tableChecklists, model.toMap());
  }

  @override
  Future<void> delete(int id) async {
    // Elimina también los ítems asociados (FK)
    await _db.deleteWhere(AppConstants.tableItems, 'checklist_id = ?', [id]);
    await _db.deleteWhere(AppConstants.tableChecklists, 'id = ?', [id]);
  }

  @override
  Future<List<Item>> getItems(int checklistId) async {
    final maps = await _db.queryWhere(
      AppConstants.tableItems,
      'checklist_id = ?',
      [checklistId],
    );
    return maps.map((m) => ItemModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<int> addItem(Item item) async {
    final model = ItemModel.fromEntity(item);
    return _db.insert(AppConstants.tableItems, model.toMap());
  }

  @override
  Future<void> toggleItem(Item item) async {
    final updated = item.copyWith(completado: !item.completado);
    final model = ItemModel.fromEntity(updated);
    await _db.update(
      AppConstants.tableItems,
      model.toMap(),
      'id = ?',
      [item.id],
    );
  }

  @override
  Future<void> deleteItem(int itemId) async {
    await _db.deleteWhere(AppConstants.tableItems, 'id = ?', [itemId]);
  }

  /// Inserta los ítems predeterminados para un tipo de salida.
  Future<void> seedDefaultItems(int checklistId, String tipoSalida) async {
    final defaults = AppConstants.defaultItems[tipoSalida] ?? [];
    for (final d in defaults) {
      final item = Item(
        checklistId: checklistId,
        nombre: d['nombre'] as String,
        pesoKg: (d['peso_kg'] as num).toDouble(),
      );
      await addItem(item);
    }
  }
}
