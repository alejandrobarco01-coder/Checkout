import '../../../domain/entities/destination.dart';
import '../../../domain/entities/destination_recommendation.dart';
import '../../../domain/entities/weather.dart';

/// Reglas internas de recomendaciones (clima + destino).
class RecommendationLocalDataSource {
  List<DestinationRecommendation> buildRecommendations({
    required Destination destination,
    Weather? weather,
    required bool isInternationalTrip,
  }) {
    final items = <DestinationRecommendation>[];
    final temp = weather?.temperatura;
    final humidity = weather?.humedad ?? 0;
    final raining = weather?.esLluvia ?? false;
    final destinationText =
        '${destination.name} ${destination.fullAddress}'.toLowerCase();

    bool mentionsAny(List<String> words) {
      return words.any(destinationText.contains);
    }

    final isIslandOrBeach = destination.category == DestinationCategory.beach ||
        mentionsAny([
          'playa',
          'beach',
          'isla',
          'island',
          'archipiélago',
          'archipielago',
          'san andrés',
          'san andres',
          'providencia',
          'cartagena',
          'santa marta',
        ]);
    final isMountain = destination.category == DestinationCategory.mountain ||
        mentionsAny([
          'montaña',
          'montana',
          'mountain',
          'cerro',
          'nevado',
          'parque nacional',
          'salento',
          'filandia',
          'manizales',
          'villa de leyva',
        ]);
    final isRural = destination.category == DestinationCategory.rural ||
        mentionsAny([
          'vereda',
          'finca',
          'rural',
          'granja',
          'farm',
          'pueblo',
        ]);
    final isAirport = destination.category == DestinationCategory.airport ||
        mentionsAny(['aeropuerto', 'airport']);
    final isWarmValleyOrCity = mentionsAny([
      'valle del cauca',
      'tuluá',
      'tulua',
      'cali',
      'palmira',
      'buga',
      'medellín',
      'medellin',
      'barranquilla',
      'cúcuta',
      'cucuta',
    ]);

    void add(
      String name,
      String reason,
      RecommendationPriority priority,
      RecommendationCategory category,
    ) {
      if (items.any((i) => i.itemName.toLowerCase() == name.toLowerCase())) {
        return;
      }
      items.add(
        DestinationRecommendation(
          itemName: name,
          reason: reason,
          priority: priority,
          category: category,
        ),
      );
    }

    if (temp != null && temp > 28) {
      add(
        'Bloqueador solar',
        'Temperatura máx ${temp.round()}°C',
        RecommendationPriority.essential,
        RecommendationCategory.weather,
      );
      add(
        'Gafas de sol',
        'Temperatura máx ${temp.round()}°C',
        RecommendationPriority.high,
        RecommendationCategory.weather,
      );
    }

    if (temp != null && temp < 15) {
      add(
        'Chaqueta',
        'Temperatura ${temp.round()}°C',
        RecommendationPriority.essential,
        RecommendationCategory.weather,
      );
    }

    if (raining || humidity > 70) {
      add(
        'Paraguas',
        raining ? 'Pronóstico de lluvia' : 'Humedad ${humidity.round()}%',
        RecommendationPriority.high,
        RecommendationCategory.weather,
      );
    }

    if (isIslandOrBeach) {
      add(
        'Traje de baño',
        'Plan de playa o isla en ${destination.name}',
        RecommendationPriority.essential,
        RecommendationCategory.destination,
      );
      add(
        'Sandalias o zapatos de agua',
        'Arena, muelles o zonas húmedas',
        RecommendationPriority.high,
        RecommendationCategory.destination,
      );
      add(
        'Bolsa impermeable',
        'Protege celular y documentos cerca del agua',
        RecommendationPriority.medium,
        RecommendationCategory.safety,
      );
      add(
        'Repelente',
        'Zonas costeras suelen tener más mosquitos',
        RecommendationPriority.medium,
        RecommendationCategory.health,
      );
    } else if (isMountain) {
      add(
        'Ropa en capas',
        'Clima variable en zona de montaña',
        RecommendationPriority.essential,
        RecommendationCategory.destination,
      );
      add(
        'Chaqueta ligera',
        'Las tardes pueden enfriar más rápido',
        RecommendationPriority.high,
        RecommendationCategory.weather,
      );
      add(
        'Linterna pequeña',
        'Útil para caminos, miradores o hospedajes rurales',
        RecommendationPriority.medium,
        RecommendationCategory.safety,
      );
    } else if (isRural) {
      add(
        'Zapatos cerrados',
        'Terreno rural o caminos destapados',
        RecommendationPriority.high,
        RecommendationCategory.destination,
      );
      add(
        'Repelente',
        'Mayor exposición a insectos',
        RecommendationPriority.high,
        RecommendationCategory.health,
      );
      add(
        'Efectivo',
        'En zonas rurales no siempre hay datáfono',
        RecommendationPriority.medium,
        RecommendationCategory.safety,
      );
    } else if (isAirport) {
      add(
        'Documento de viaje',
        'Salida desde aeropuerto',
        RecommendationPriority.essential,
        RecommendationCategory.document,
      );
      add(
        'Reserva o boarding pass',
        'Tenlo a mano antes de llegar',
        RecommendationPriority.essential,
        RecommendationCategory.document,
      );
      add(
        'Cargador portátil',
        'Útil durante esperas o conexiones',
        RecommendationPriority.medium,
        RecommendationCategory.destination,
      );
    } else if (isWarmValleyOrCity) {
      add(
        'Ropa fresca',
        'Clima urbano cálido en ${destination.name}',
        RecommendationPriority.high,
        RecommendationCategory.destination,
      );
      add(
        'Botella de agua',
        'Hidratación para recorridos por la ciudad',
        RecommendationPriority.high,
        RecommendationCategory.health,
      );
      add(
        'Calzado cómodo',
        'Movilidad urbana en ${destination.name}',
        RecommendationPriority.medium,
        RecommendationCategory.destination,
      );
    } else if (destination.category == DestinationCategory.city ||
        destination.category == DestinationCategory.unknown) {
      add(
        'Calzado cómodo',
        'Recorridos urbanos en ${destination.name}',
        RecommendationPriority.medium,
        RecommendationCategory.destination,
      );
      add(
        'Cargador portátil',
        'Para mapas, transporte y reservas',
        RecommendationPriority.medium,
        RecommendationCategory.destination,
      );
    }

    final altitude = destination.altitude;
    if (altitude != null && altitude > 2000) {
      add(
        'Medicamento para la altitud',
        'Altitud ${altitude.round()} msnm',
        RecommendationPriority.high,
        RecommendationCategory.health,
      );
    }

    final international = isInternationalTrip || destination.isInternational;
    if (international) {
      add(
        'Pasaporte',
        'Viaje internacional',
        RecommendationPriority.essential,
        RecommendationCategory.document,
      );
      add(
        'Seguro de viaje',
        'Viaje internacional',
        RecommendationPriority.high,
        RecommendationCategory.document,
      );
    } else {
      add(
        'Cédula de ciudadanía',
        'Viaje doméstico',
        RecommendationPriority.essential,
        RecommendationCategory.document,
      );
    }

    add(
      'Botiquín básico',
      'Prevención de salud en ruta',
      RecommendationPriority.medium,
      RecommendationCategory.health,
    );

    return items
      ..sort(
        (a, b) => a.category.sortOrder.compareTo(b.category.sortOrder),
      );
  }
}
