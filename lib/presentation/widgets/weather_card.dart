import 'package:flutter/material.dart';
import '../providers/weather_provider.dart';

/// Tarjeta del clima con estados: loading, success, error.
class WeatherCard extends StatelessWidget {
  final WeatherProvider weatherProvider;
  final VoidCallback onRefresh;

  const WeatherCard({
    super.key,
    required this.weatherProvider,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (weatherProvider.status) {
          // Estado cargando
          WeatherStatus.loading => const Row(
              children: [
                SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('Obteniendo clima...'),
              ],
            ),

          // Estado error
          WeatherStatus.error => Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    weatherProvider.errorMessage ?? 'Error al obtener clima',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                  tooltip: 'Reintentar',
                ),
              ],
            ),

          // Estado exitoso
          WeatherStatus.success => Row(
              children: [
                // Ícono del clima
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _weatherEmoji(weatherProvider.weather?.esLluvia ?? false,
                        weatherProvider.weather?.descripcion ?? ''),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weatherProvider.weather?.ciudad ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${weatherProvider.weather?.temperatura.toStringAsFixed(1)}°C · '
                        '${weatherProvider.weather?.descripcion}',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: onRefresh,
                  tooltip: 'Actualizar clima',
                ),
              ],
            ),

          // Estado inicial
          _ => Row(
              children: [
                const Icon(Icons.cloud_outlined, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('Cargando clima...'),
                IconButton(
                    icon: const Icon(Icons.refresh), onPressed: onRefresh),
              ],
            ),
        },
      ),
    );
  }

  String _weatherEmoji(bool isRaining, String description) {
    if (description.contains('tormenta')) return '⛈️';
    if (isRaining) return '🌧️';
    if (description.contains('nube')) return '☁️';
    if (description.contains('nieve')) return '❄️';
    return '☀️';
  }
}
