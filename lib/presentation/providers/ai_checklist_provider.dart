import 'package:flutter/foundation.dart';
import '../../domain/entities/trip_context.dart';
import '../../domain/usecases/generate_checklist_with_ai_usecase.dart';
import '../../data/repositories/ai_repository_impl.dart';

// Re-export ChatMessage para usarlo desde la pantalla
export '../../domain/entities/trip_context.dart'
    show AIChecklistResult, AIGeneratedItem, AIPriority, ChatMessage;

/// Estados posibles del flujo de IA.
enum AIStatus { idle, thinking, success, error }

/// Provider que gestiona el estado de la generación de checklist con IA.
/// Conecta la UI con el caso de uso GenerateChecklistWithAIUseCase.
class AIChecklistProvider extends ChangeNotifier {
  final GenerateChecklistWithAIUseCase _useCase = GenerateChecklistWithAIUseCase(
    AIRepositoryImpl(),
  );

  AIStatus _status = AIStatus.idle;
  AIStatus get status => _status;
  bool get isThinking => _status == AIStatus.thinking;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  AIChecklistResult? _lastResult;
  AIChecklistResult? get lastResult => _lastResult;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Envía el mensaje del usuario y obtiene la respuesta de la IA.
  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    // Agrega mensaje del usuario
    _messages.add(ChatMessage(
      text: userText,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _status = AIStatus.thinking;
    _errorMessage = null;
    notifyListeners();

    try {
      final tripContext = TripContext(description: userText);
      final result = await _useCase(tripContext);
      _lastResult = result;

      // Construir respuesta amigable de la IA
      final itemCount = result.items.length;
      final highPriority =
          result.items.where((i) => i.priority == AIPriority.high).length;

      final responseText =
          '¡Listo! Generé una lista con **$itemCount items** para tu viaje. '
          '$highPriority de ellos son de alta prioridad 🎒\n\n'
          'Revisa la vista previa aquí abajo y guárdala cuando estés conforme.';

      _messages.add(ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
        checklistResult: result,
      ));
      _status = AIStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _messages.add(ChatMessage(
        text: '❌ Ocurrió un error: $_errorMessage',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _status = AIStatus.error;
    }

    notifyListeners();
  }

  /// Regenera la checklist con el último mensaje del usuario.
  Future<void> regenerate() async {
    final lastUserMsg = _messages.lastWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(text: '', isUser: true, timestamp: DateTime.now()),
    );
    if (lastUserMsg.text.isEmpty) return;
    // Quita el último mensaje del bot y regenera
    if (_messages.isNotEmpty && !_messages.last.isUser) {
      _messages.removeLast();
    }
    _lastResult = null;
    notifyListeners();
    await sendMessage(lastUserMsg.text);
  }

  /// Limpia la conversación para comenzar de nuevo.
  void reset() {
    _messages.clear();
    _lastResult = null;
    _status = AIStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
