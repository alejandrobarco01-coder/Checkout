import '../entities/checklist.dart';
import '../entities/item.dart';
import '../../core/packing_intelligence.dart';

/// Casos de uso del checklist.
/// Cada clase encapsula una única operación de negocio.

// ──────────────────────────────────────────────
// Datos calculados en background (para Isolate)
// ──────────────────────────────────────────────

/// Parámetros pasados al Isolate de cálculo.
class ChecklistStats {
  final List<Item> items;
  const ChecklistStats(this.items);
}

/// Resultado devuelto por el Isolate.
class ChecklistStatsResult {
  final double porcentajeCompletado;
  final double pesoTotalKg;
  final double pesoCompletadoKg;
  final int totalItems;
  final int completedItems;
  final int pendingItems;
  final int criticalItems;
  final int criticalCompletedItems;

  const ChecklistStatsResult({
    required this.porcentajeCompletado,
    required this.pesoTotalKg,
    required this.pesoCompletadoKg,
    required this.totalItems,
    required this.completedItems,
    required this.pendingItems,
    required this.criticalItems,
    required this.criticalCompletedItems,
  });
}

/// Función top-level para usar con compute().
/// Debe ser top-level (no método de clase) para ejecutarse en Isolate.
ChecklistStatsResult calcularEstadisticas(List<Item> items) {
  if (items.isEmpty) {
    return const ChecklistStatsResult(
      porcentajeCompletado: 0,
      pesoTotalKg: 0,
      pesoCompletadoKg: 0,
      totalItems: 0,
      completedItems: 0,
      pendingItems: 0,
      criticalItems: 0,
      criticalCompletedItems: 0,
    );
  }
  final completedItems = items.where((i) => i.completado).length;
  final criticalItems =
      items.where((i) => PackingIntelligence.isCritical(i, '')).toList();
  final porcentaje = (completedItems / items.length) * 100;
  final pesoTotal = PackingIntelligence.totalWeight(items);
  final pesoCompletado = items
      .where((i) => i.completado)
      .fold<double>(0, (sum, i) => sum + i.pesoKg);
  return ChecklistStatsResult(
    porcentajeCompletado: porcentaje,
    pesoTotalKg: pesoTotal,
    pesoCompletadoKg: pesoCompletado,
    totalItems: items.length,
    completedItems: completedItems,
    pendingItems: items.length - completedItems,
    criticalItems: criticalItems.length,
    criticalCompletedItems: criticalItems.where((i) => i.completado).length,
  );
}

// ──────────────────────────────────────────────
// Casos de uso simples (delegados al repositorio)
// ──────────────────────────────────────────────

abstract class ChecklistRepository {
  Future<List<Checklist>> getAll();
  Future<Checklist?> getById(int id);
  Future<int> create(Checklist checklist);
  Future<void> delete(int id);
  Future<List<Item>> getItems(int checklistId);
  Future<int> addItem(Item item);
  Future<void> toggleItem(Item item);
  Future<void> deleteItem(int itemId);
}
