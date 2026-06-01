import '../entities/trip_context.dart';
import '../repositories/ai_repository.dart';

/// Caso de uso: Generar checklist usando IA con el contexto del viaje.
/// Sigue Clean Architecture: recibe la interfaz abstracta del repositorio.
class GenerateChecklistWithAIUseCase {
  final AIRepository _repository;

  const GenerateChecklistWithAIUseCase(this._repository);

  Future<AIChecklistResult> call(TripContext tripContext) async {
    if (tripContext.description.trim().isEmpty) {
      throw ArgumentError('La descripción del viaje no puede estar vacía.');
    }
    return _repository.generateChecklist(tripContext);
  }
}
