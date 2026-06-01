import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/destination.dart';
import '../../domain/entities/destination_recommendation.dart';
import '../providers/destination_provider.dart';
import '../providers/weather_provider.dart';

class DestinationSearchWidget extends StatefulWidget {
  final bool isInternationalTrip;
  final VoidCallback? onAddAllToChecklist;

  const DestinationSearchWidget({
    super.key,
    this.isInternationalTrip = false,
    this.onAddAllToChecklist,
  });

  @override
  State<DestinationSearchWidget> createState() =>
      _DestinationSearchWidgetState();
}

class _DestinationSearchWidgetState extends State<DestinationSearchWidget> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destProv = context.watch<DestinationProvider>();
    final weatherProv = context.watch<WeatherProvider>();
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Buscar destino...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      destProv.clearSearch();
                      setState(() {});
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onChanged: (v) {
            setState(() {});
            destProv.search(v);
          },
        ),
        if (destProv.searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: destProv.searchResults.asMap().entries.map((entry) {
                final d = entry.value;
                return ListTile(
                  leading: Text(d.category.emoji),
                  title: Text(d.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    d.fullAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    _searchCtrl.text = d.name;
                    await destProv.selectDestination(
                      d,
                      weather: weatherProv.weather,
                      isInternationalTrip: widget.isInternationalTrip,
                    );
                    setState(() {});
                  },
                )
                    .animate()
                    .fadeIn(duration: 200.ms, delay: (entry.key * 40).ms);
              }).toList(),
            ),
          ),
        ],
        if (destProv.selectedDestination != null) ...[
          const SizedBox(height: 16),
          _DestinationMap(
            destination: destProv.selectedDestination!,
          ),
          const SizedBox(height: 12),
          Chip(
            avatar: Text(destProv.selectedDestination!.category.emoji),
            label: Text(destProv.selectedDestination!.name),
            deleteIcon: const Icon(Icons.close, size: 18),
            onDeleted: destProv.clearSelection,
          ),
          const SizedBox(height: 16),
          ..._buildRecommendationSections(destProv.recommendations, colors),
          if (destProv.recommendations.isNotEmpty &&
              widget.onAddAllToChecklist != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onAddAllToChecklist,
                icon: const Icon(Icons.playlist_add_check),
                label: const Text('Agregar todos a la checklist'),
              ),
            ),
          ],
        ],
        if (destProv.isSearching)
          const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  List<Widget> _buildRecommendationSections(
    List<DestinationRecommendation> items,
    ColorScheme colors,
  ) {
    if (items.isEmpty) {
      return [
        Text(
          'Selecciona un destino para ver recomendaciones',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      ];
    }

    final grouped = <RecommendationCategory, List<DestinationRecommendation>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    final order = grouped.keys.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return order.map((cat) {
      final list = grouped[cat]!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              cat.label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: colors.onSurface.withOpacity(0.45),
              ),
            ),
          ),
          ...list.map((rec) => _RecommendationTile(recommendation: rec)),
        ],
      );
    }).toList();
  }
}

class _DestinationMap extends StatelessWidget {
  final Destination destination;

  const _DestinationMap({
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasCoords = destination.latitude != 0 || destination.longitude != 0;

    if (!hasCoords) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 40),
            const SizedBox(height: 8),
            Text(
              destination.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Selecciona un resultado con ubicación para ver el mapa',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final point = LatLng(destination.latitude, destination.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 12,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.checkout.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 44,
                  height: 44,
                  child: Tooltip(
                    message: destination.name,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const Icon(
                        Icons.place_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final DestinationRecommendation recommendation;

  const _RecommendationTile({required this.recommendation});

  IconData _iconForCategory(RecommendationCategory cat) {
    switch (cat) {
      case RecommendationCategory.document:
        return Icons.badge_outlined;
      case RecommendationCategory.weather:
        return Icons.wb_sunny_outlined;
      case RecommendationCategory.destination:
        return Icons.place_outlined;
      case RecommendationCategory.health:
        return Icons.medical_services_outlined;
      case RecommendationCategory.safety:
        return Icons.shield_outlined;
    }
  }

  Color _badgeColor(RecommendationPriority p, ColorScheme colors) {
    switch (p) {
      case RecommendationPriority.essential:
        return colors.error;
      case RecommendationPriority.high:
        return colors.primary;
      case RecommendationPriority.medium:
        return colors.secondary;
      case RecommendationPriority.low:
        return colors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rec = recommendation;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_iconForCategory(rec.category), color: colors.primary),
        title: Text(rec.itemName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(rec.reason),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _badgeColor(rec.priority, colors).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            rec.priority.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _badgeColor(rec.priority, colors),
            ),
          ),
        ),
      ),
    );
  }
}
