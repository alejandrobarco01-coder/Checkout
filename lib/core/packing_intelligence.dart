import '../domain/entities/item.dart';

enum PackingCategory {
  documents,
  electronics,
  health,
  clothing,
  weather,
  money,
  toiletries,
  food,
  other,
}

class PackingSuggestion {
  final String name;
  final double weightKg;
  final String reason;
  final PackingCategory category;

  const PackingSuggestion({
    required this.name,
    required this.weightKg,
    required this.reason,
    required this.category,
  });
}

class PackingIntelligence {
  static const Map<PackingCategory, String> categoryLabels = {
    PackingCategory.documents: 'Documentos',
    PackingCategory.electronics: 'Tecnologia',
    PackingCategory.health: 'Salud',
    PackingCategory.clothing: 'Ropa',
    PackingCategory.weather: 'Clima',
    PackingCategory.money: 'Dinero',
    PackingCategory.toiletries: 'Aseo',
    PackingCategory.food: 'Comida',
    PackingCategory.other: 'Otros',
  };

  static const Map<PackingCategory, String> categoryIcons = {
    PackingCategory.documents: 'ID',
    PackingCategory.electronics: 'USB',
    PackingCategory.health: '+',
    PackingCategory.clothing: 'OUT',
    PackingCategory.weather: 'WX',
    PackingCategory.money: '\$',
    PackingCategory.toiletries: 'KIT',
    PackingCategory.food: 'FOOD',
    PackingCategory.other: 'ITEM',
  };

  static PackingCategory categoryFor(String name) {
    final normalized = _normalize(name);
    if (_matches(normalized, [
      'pasaporte',
      'visa',
      'dni',
      'cedula',
      'identificacion',
      'licencia',
      'seguro',
      'boarding',
      'tiquete',
      'reserva',
      'documento',
    ])) {
      return PackingCategory.documents;
    }
    if (_matches(normalized, [
      'laptop',
      'cargador',
      'adaptador',
      'power bank',
      'bateria',
      'auriculares',
      'audifonos',
      'telefono',
      'tablet',
      'camara',
      'usb',
    ])) {
      return PackingCategory.electronics;
    }
    if (_matches(normalized, [
      'medicamento',
      'medicina',
      'botiquin',
      'receta',
      'bloqueador',
      'protector solar',
      'repelente',
      'tapabocas',
      'alergia',
    ])) {
      return PackingCategory.health;
    }
    if (_matches(normalized, [
      'ropa',
      'camisa',
      'pantalon',
      'zapato',
      'zapatilla',
      'abrigo',
      'chaqueta',
      'traje',
      'sandalia',
      'banador',
      'toalla',
    ])) {
      return PackingCategory.clothing;
    }
    if (_matches(normalized, [
      'paraguas',
      'impermeable',
      'chubasquero',
      'lluvia',
      'gafas de sol',
      'gorro',
      'termico',
    ])) {
      return PackingCategory.weather;
    }
    if (_matches(normalized, [
      'tarjeta',
      'efectivo',
      'dinero',
      'wallet',
      'billetera',
      'moneda',
    ])) {
      return PackingCategory.money;
    }
    if (_matches(normalized, [
      'cepillo',
      'pasta',
      'shampoo',
      'jabon',
      'desodorante',
      'aseo',
      'toiletry',
    ])) {
      return PackingCategory.toiletries;
    }
    if (_matches(normalized, [
      'comida',
      'snack',
      'agua',
      'botella',
      'termo',
      'shaker',
    ])) {
      return PackingCategory.food;
    }
    return PackingCategory.other;
  }

  static bool isCritical(Item item, String exitType) {
    final normalized = _normalize(item.nombre);
    if (_matches(normalized, [
      'pasaporte',
      'visa',
      'dni',
      'cedula',
      'identificacion',
      'seguro',
      'medicamento',
      'medicina',
      'receta',
      'tarjeta',
      'efectivo',
      'telefono',
      'cargador',
      'llaves',
    ])) {
      return true;
    }
    if (exitType == 'trabajo' && _matches(normalized, ['laptop', 'cargador'])) {
      return true;
    }
    if ((exitType == 'viaje' || exitType == 'internacional') &&
        _matches(normalized, ['pasaporte', 'reserva', 'tiquete'])) {
      return true;
    }
    if (exitType == 'medico' &&
        _matches(normalized, ['historial', 'seguro', 'medicamento'])) {
      return true;
    }
    return false;
  }

  static int readinessScore({
    required List<Item> items,
    required String exitType,
  }) {
    if (items.isEmpty) return 0;
    final completed =
        items.where((item) => item.completado).length / items.length;
    final critical = items.where((item) => isCritical(item, exitType)).toList();
    final criticalDone = critical.isEmpty
        ? 1.0
        : critical.where((item) => item.completado).length / critical.length;
    final overweightPenalty =
        totalWeight(items) > recommendedWeight(exitType) ? 0.08 : 0.0;
    final score =
        ((completed * 0.58) + (criticalDone * 0.42) - overweightPenalty) * 100;
    return score.clamp(0, 100).round();
  }

  static double recommendedWeight(String exitType) {
    switch (exitType) {
      case 'trabajo':
      case 'gym':
      case 'medico':
        return 5;
      case 'playa':
        return 8;
      case 'camping':
        return 14;
      case 'viaje':
      default:
        return 12;
    }
  }

  static double totalWeight(List<Item> items) {
    return items.fold<double>(0, (sum, item) => sum + item.pesoKg);
  }

  static List<PackingSuggestion> suggestions({
    required List<Item> items,
    required String exitType,
    bool isRaining = false,
    double? temperature,
  }) {
    final base = switch (exitType) {
      'compras' => <PackingSuggestion>[
          const PackingSuggestion(
            name: 'Arroz o pasta',
            weightKg: 0,
            reason: 'Despensa',
            category: PackingCategory.food,
          ),
          const PackingSuggestion(
            name: 'Proteina para la semana',
            weightKg: 0,
            reason: 'Comidas',
            category: PackingCategory.food,
          ),
          const PackingSuggestion(
            name: 'Fruta de temporada',
            weightKg: 0,
            reason: 'Salud',
            category: PackingCategory.food,
          ),
          const PackingSuggestion(
            name: 'Verduras',
            weightKg: 0,
            reason: 'Salud',
            category: PackingCategory.food,
          ),
          const PackingSuggestion(
            name: 'Papel higienico',
            weightKg: 0,
            reason: 'Hogar',
            category: PackingCategory.toiletries,
          ),
          const PackingSuggestion(
            name: 'Jabon o detergente',
            weightKg: 0,
            reason: 'Limpieza',
            category: PackingCategory.toiletries,
          ),
        ],
      'hogar' => <PackingSuggestion>[
          const PackingSuggestion(
            name: 'Revisar nevera',
            weightKg: 0,
            reason: 'Orden',
            category: PackingCategory.food,
          ),
          const PackingSuggestion(
            name: 'Limpiar superficies',
            weightKg: 0,
            reason: 'Limpieza',
            category: PackingCategory.toiletries,
          ),
          const PackingSuggestion(
            name: 'Organizar pendientes',
            weightKg: 0,
            reason: 'Rutina',
            category: PackingCategory.other,
          ),
        ],
      'trabajo' => <PackingSuggestion>[
          const PackingSuggestion(
            name: 'Agenda o notas',
            weightKg: 0.12,
            reason: 'Reunion',
            category: PackingCategory.documents,
          ),
          const PackingSuggestion(
            name: 'Tarjeta de acceso',
            weightKg: 0.01,
            reason: 'Entrada',
            category: PackingCategory.documents,
          ),
          const PackingSuggestion(
            name: 'Snack rapido',
            weightKg: 0.1,
            reason: 'Jornada larga',
            category: PackingCategory.food,
          ),
        ],
      'viaje' => <PackingSuggestion>[
          const PackingSuggestion(
            name: 'Copia offline de reservas',
            weightKg: 0.01,
            reason: 'Sin internet',
            category: PackingCategory.documents,
          ),
          const PackingSuggestion(
            name: 'Adaptador universal',
            weightKg: 0.22,
            reason: 'Energia',
            category: PackingCategory.electronics,
          ),
          const PackingSuggestion(
            name: 'Bolsa para ropa sucia',
            weightKg: 0.05,
            reason: 'Orden',
            category: PackingCategory.clothing,
          ),
        ],
      'gym' => <PackingSuggestion>[
          const PackingSuggestion(
            name: 'Shaker o termo',
            weightKg: 0.25,
            reason: 'Hidratacion',
            category: PackingCategory.food,
          ),
          const PackingSuggestion(
            name: 'Candado para locker',
            weightKg: 0.08,
            reason: 'Seguridad',
            category: PackingCategory.other,
          ),
          const PackingSuggestion(
            name: 'Audifonos deportivos',
            weightKg: 0.08,
            reason: 'Entreno',
            category: PackingCategory.electronics,
          ),
          const PackingSuggestion(
            name: 'Cambio de camiseta',
            weightKg: 0.2,
            reason: 'Post entreno',
            category: PackingCategory.clothing,
          ),
        ],
      'medico' => <PackingSuggestion>[
          const PackingSuggestion(
            name: 'Orden o autorizacion',
            weightKg: 0.01,
            reason: 'Consulta',
            category: PackingCategory.documents,
          ),
          const PackingSuggestion(
            name: 'Resultados recientes',
            weightKg: 0.05,
            reason: 'Diagnostico',
            category: PackingCategory.documents,
          ),
          const PackingSuggestion(
            name: 'Preguntas para el doctor',
            weightKg: 0.01,
            reason: 'Seguimiento',
            category: PackingCategory.health,
          ),
        ],
      'playa' => <PackingSuggestion>[
          const PackingSuggestion(
            name: 'Bolsa impermeable',
            weightKg: 0.12,
            reason: 'Proteccion',
            category: PackingCategory.weather,
          ),
          const PackingSuggestion(
            name: 'Repelente',
            weightKg: 0.18,
            reason: 'Salud',
            category: PackingCategory.health,
          ),
          const PackingSuggestion(
            name: 'Sandalias',
            weightKg: 0.35,
            reason: 'Arena',
            category: PackingCategory.clothing,
          ),
          const PackingSuggestion(
            name: 'Bolsa para ropa mojada',
            weightKg: 0.06,
            reason: 'Regreso',
            category: PackingCategory.other,
          ),
        ],
      'camping' => <PackingSuggestion>[
          const PackingSuggestion(
            name: 'Navaja multiuso',
            weightKg: 0.16,
            reason: 'Campo',
            category: PackingCategory.other,
          ),
          const PackingSuggestion(
            name: 'Filtro de agua',
            weightKg: 0.1,
            reason: 'Hidratacion',
            category: PackingCategory.food,
          ),
          const PackingSuggestion(
            name: 'Bateria externa',
            weightKg: 0.28,
            reason: 'Emergencia',
            category: PackingCategory.electronics,
          ),
          const PackingSuggestion(
            name: 'Repelente',
            weightKg: 0.18,
            reason: 'Insectos',
            category: PackingCategory.health,
          ),
        ],
      'personalizado' => <PackingSuggestion>[
          const PackingSuggestion(
            name: 'Prioridad principal',
            weightKg: 0,
            reason: 'Personal',
            category: PackingCategory.other,
          ),
          const PackingSuggestion(
            name: 'Recordatorio importante',
            weightKg: 0,
            reason: 'Personal',
            category: PackingCategory.other,
          ),
        ],
      _ => <PackingSuggestion>[
          const PackingSuggestion(
            name: 'Elemento importante',
            weightKg: 0,
            reason: 'Base',
            category: PackingCategory.other,
          ),
          const PackingSuggestion(
            name: 'Recordatorio del plan',
            weightKg: 0,
            reason: 'Personal',
            category: PackingCategory.other,
          ),
        ],
    };

    final suggestions = List<PackingSuggestion>.from(base);

    if (isRaining && exitType != 'compras' && exitType != 'hogar') {
      suggestions.addAll(const [
        PackingSuggestion(
          name: 'Paraguas compacto',
          weightKg: 0.3,
          reason: 'Lluvia',
          category: PackingCategory.weather,
        ),
        PackingSuggestion(
          name: 'Funda impermeable',
          weightKg: 0.08,
          reason: 'Lluvia',
          category: PackingCategory.weather,
        ),
      ]);
    }

    if (temperature != null &&
        temperature > 27 &&
        exitType != 'compras' &&
        exitType != 'hogar') {
      suggestions.add(const PackingSuggestion(
        name: 'Electrolitos',
        weightKg: 0.05,
        reason: 'Calor',
        category: PackingCategory.health,
      ));
    }

    final existing = items.map((item) => _normalize(item.nombre)).toSet();
    return suggestions.where((suggestion) {
      final normalized = _normalize(suggestion.name);
      return !existing.any(
          (item) => item.contains(normalized) || normalized.contains(item));
    }).toList();
  }

  static bool _matches(String value, List<String> keywords) {
    return keywords.any((keyword) => value.contains(_normalize(keyword)));
  }

  static String _normalize(String value) {
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    final lowered = value.toLowerCase();
    return lowered.split('').map((char) => accents[char] ?? char).join();
  }
}
