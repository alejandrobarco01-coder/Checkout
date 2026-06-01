/// Recomendación de equipaje según clima y destino.
class DestinationRecommendation {
  final String itemName;
  final String reason;
  final RecommendationPriority priority;
  final RecommendationCategory category;

  const DestinationRecommendation({
    required this.itemName,
    required this.reason,
    required this.priority,
    required this.category,
  });
}

enum RecommendationPriority {
  essential,
  high,
  medium,
  low,
}

enum RecommendationCategory {
  weather,
  destination,
  document,
  health,
  safety,
}

extension RecommendationPriorityX on RecommendationPriority {
  String get label {
    switch (this) {
      case RecommendationPriority.essential:
        return 'Esencial';
      case RecommendationPriority.high:
        return 'Alta';
      case RecommendationPriority.medium:
        return 'Media';
      case RecommendationPriority.low:
        return 'Baja';
    }
  }
}

extension RecommendationCategoryX on RecommendationCategory {
  String get label {
    switch (this) {
      case RecommendationCategory.weather:
        return 'Clima';
      case RecommendationCategory.destination:
        return 'Destino';
      case RecommendationCategory.document:
        return 'Documentos';
      case RecommendationCategory.health:
        return 'Salud';
      case RecommendationCategory.safety:
        return 'Seguridad';
    }
  }

  int get sortOrder {
    switch (this) {
      case RecommendationCategory.document:
        return 0;
      case RecommendationCategory.weather:
        return 1;
      case RecommendationCategory.destination:
        return 2;
      case RecommendationCategory.health:
        return 3;
      case RecommendationCategory.safety:
        return 4;
    }
  }
}
