import 'package:flutter_test/flutter_test.dart';
import 'package:checkout/domain/entities/trip_context.dart';
import 'package:checkout/domain/usecases/generate_checklist_with_ai_usecase.dart';
import 'package:checkout/domain/repositories/ai_repository.dart';

/// Mock simple del repositorio de IA para testing.
class MockAIRepository implements AIRepository {
  final AIChecklistResult mockResult;
  MockAIRepository(this.mockResult);

  @override
  Future<AIChecklistResult> generateChecklist(TripContext tripContext) async {
    return mockResult;
  }
}

void main() {
  group('GenerateChecklistWithAIUseCase', () {
    late GenerateChecklistWithAIUseCase useCase;
    late AIChecklistResult mockResult;

    setUp(() {
      const mockResult = AIChecklistResult(items: [
        AIGeneratedItem(
          name: 'Pasaporte',
          quantity: 1,
          category: 'Documentos',
          priority: AIPriority.high,
        ),
        AIGeneratedItem(
          name: 'Bloqueador solar',
          quantity: 1,
          category: 'Higiene',
          priority: AIPriority.medium,
        ),
      ]);
      useCase = GenerateChecklistWithAIUseCase(MockAIRepository(mockResult));
    });

    test('retorna items cuando la descripción es válida', () async {
      final context = const TripContext(
        description: 'Voy a la playa este fin de semana',
        destination: 'Cartagena',
      );

      final result = await useCase(context);

      expect(result.items.length, 2);
      expect(result.items.first.name, 'Pasaporte');
      expect(result.items.first.priority, AIPriority.high);
    });

    test('lanza ArgumentError si la descripción está vacía', () async {
      const context = TripContext(description: '');
      expect(() => useCase(context), throwsA(isA<ArgumentError>()));
    });

    test('lanza ArgumentError si la descripción es solo espacios', () async {
      const context = TripContext(description: '   ');
      expect(() => useCase(context), throwsA(isA<ArgumentError>()));
    });

    test('TripContext.toJson incluye todos los campos proporcionados', () {
      const ctx = TripContext(
        description: 'Viaje de trabajo',
        destination: 'Bogotá',
        travelType: 'trabajo',
        duration: '3 días',
        companions: 'Solo',
      );
      final json = ctx.toJson();

      expect(json['description'], 'Viaje de trabajo');
      expect(json['destination'], 'Bogotá');
      expect(json['travelType'], 'trabajo');
    });

    test('TripContext.toJson omite campos nulos', () {
      const ctx = TripContext(description: 'Viaje simple');
      final json = ctx.toJson();

      expect(json.containsKey('destination'), false);
      expect(json.containsKey('companions'), false);
    });
  });
}
