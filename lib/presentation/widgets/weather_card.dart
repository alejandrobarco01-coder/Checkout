import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/weather_provider.dart';

/// Tarjeta del clima mejorada con animaciones y efectos visuales.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primaryContainer.withOpacity(0.3),
              colors.primaryContainer.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: switch (weatherProvider.status) {
            // Estado cargando con shimmer
            WeatherStatus.loading => Shimmer.fromColors(
                baseColor: colors.surface.withOpacity(0.5),
                highlightColor: colors.surface,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: 100,
                            color: colors.surface,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: 200,
                            color: colors.surface,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Estado error con ícono animado
            WeatherStatus.error => Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.cloud_off, color: Colors.red, size: 24)
                        .animate(onPlay: (controller) => controller.repeat())
                        .shake(duration: 2000.ms),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error al obtener clima',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          weatherProvider.errorMessage ?? 'Intenta de nuevo',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: 'Reintentar',
                  ).animate().fadeIn(),
                ],
              ).animate().fadeIn(),

            // Estado exitoso con animaciones
            WeatherStatus.success => Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary.withOpacity(0.3),
                          colors.secondary.withOpacity(0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _weatherEmoji(
                        weatherProvider.weather?.esLluvia ?? false,
                        weatherProvider.weather?.descripcion ?? '',
                      ),
                      style: const TextStyle(fontSize: 28),
                    ),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weatherProvider.weather?.ciudad ?? 'Desconocida',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.2),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${weatherProvider.weather?.temperatura.toStringAsFixed(1)}°C',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.primary,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                weatherProvider.weather?.descripcion ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 100.ms)
                            .slideX(begin: -0.2),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: onRefresh,
                    tooltip: 'Actualizar clima',
                    splashRadius: 24,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms),
                ],
              ).animate().fadeIn(),

            // Estado inicial
            _ => Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_outlined,
                      color: colors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información del clima',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Toca el botón para cargar datos',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                  ),
                ],
              ),
          },
        ),
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
