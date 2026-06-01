/// Entidad de dominio: Contexto del viaje descrito por el usuario.
/// Usada como input para la generación de checklists con IA.
class TripContext {
  final String description;
  final String? destination;
  final String? travelType;
  final String? duration;
  final String? companions;

  const TripContext({
    required this.description,
    this.destination,
    this.travelType,
    this.duration,
    this.companions,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        if (destination != null) 'destination': destination,
        if (travelType != null) 'travelType': travelType,
        if (duration != null) 'duration': duration,
        if (companions != null) 'companions': companions,
      };
}

/// Entidad: Item generado por la IA.
class AIGeneratedItem {
  final String name;
  final int quantity;
  final String category;
  final AIPriority priority;

  const AIGeneratedItem({
    required this.name,
    required this.quantity,
    required this.category,
    required this.priority,
  });

  factory AIGeneratedItem.fromJson(Map<String, dynamic> json) {
    return AIGeneratedItem(
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      category: json['category'] as String? ?? 'General',
      priority: AIPriority.fromString(json['priority'] as String? ?? 'medium'),
    );
  }
}

enum AIPriority {
  high,
  medium,
  low;

  static AIPriority fromString(String s) {
    switch (s.toLowerCase()) {
      case 'high':
        return AIPriority.high;
      case 'low':
        return AIPriority.low;
      default:
        return AIPriority.medium;
    }
  }

  String get label {
    switch (this) {
      case AIPriority.high:
        return 'Alta';
      case AIPriority.medium:
        return 'Media';
      case AIPriority.low:
        return 'Baja';
    }
  }
}

/// Resultado completo de la generación de IA.
class AIChecklistResult {
  final List<AIGeneratedItem> items;

  const AIChecklistResult({required this.items});

  factory AIChecklistResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return AIChecklistResult(
      items: rawItems
          .map((e) => AIGeneratedItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Mensaje de chat para la pantalla conversacional.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AIChecklistResult? checklistResult;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.checklistResult,
  });
}
