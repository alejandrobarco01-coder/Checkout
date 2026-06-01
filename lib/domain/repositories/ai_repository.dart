import '../entities/trip_context.dart';

/// Interfaz abstracta del repositorio de IA (dominio puro).
/// La implementación concreta vive en data/repositories/ai_repository_impl.dart.
abstract class AIRepository {
  /// Envía el contexto del viaje a la IA y devuelve la checklist generada.
  Future<AIChecklistResult> generateChecklist(TripContext tripContext);
}
