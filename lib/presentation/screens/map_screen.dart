import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../data/datasources/local/shared_prefs_helper.dart';
import '../../data/datasources/remote/geocoding_api.dart';
import '../../domain/entities/completed_trip.dart';
import '../providers/trip_history_provider.dart';

/// IDs de tipo que aparecen en el mapa inteligente.
const _mapTypes = ['compras', 'hogar', 'gym', 'medico'];

/// Mapa OpenStreetMap con marcadores de destinos y búsqueda Nominatim / Overpass.
class MapScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? locationName;

  const MapScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.locationName,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _mapController = MapController();
  final _searchCtrl = TextEditingController();
  final _geocoding = GeocodingApi();

  LatLng? _searchResult;
  String? _searchLabel;
  String _selectedType = 'compras';
  String _city = 'Madrid';
  LatLng? _currentLocation;
  bool _searching = false;
  List<CompletedTrip> _tripsWithCoords = [];
  List<GeocodingResult> _nearbyOptions = [];
  int _nearbySearchId = 0;

  /// true cuando "hogar" está seleccionado (muestra sólo ubicación actual)
  bool _showingHome = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _searchResult = LatLng(widget.initialLat!, widget.initialLng!);
      _searchLabel = widget.locationName;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = SharedPrefsHelper.instance;
      _city = await prefs.getCity();
      final useCurrent = await prefs.getUseCurrentLocation();
      final current = await prefs.getCurrentLocation();
      if (useCurrent && current != null) {
        _currentLocation = LatLng(current.lat, current.lng);
        _searchLabel = current.name;
      }
      if (!mounted) return;
      await context.read<TripHistoryProvider>().loadTrips();
      if (mounted) {
        setState(() {
          _tripsWithCoords = context
              .read<TripHistoryProvider>()
              .trips
              .where((t) => t.lat != null && t.lng != null)
              .toList();
        });
        await _searchNearbyForType(_selectedType);
        _fitBounds();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  LatLng get _center {
    if (_showingHome && _currentLocation != null) return _currentLocation!;
    if (_searchResult != null) return _searchResult!;
    if (_currentLocation != null) return _currentLocation!;
    if (_tripsWithCoords.isNotEmpty) {
      return LatLng(_tripsWithCoords.first.lat!, _tripsWithCoords.first.lng!);
    }
    return const LatLng(40.4168, -3.7038); // Madrid por defecto
  }

  void _fitBounds() {
    if (_showingHome) {
      if (_currentLocation != null) {
        _mapController.move(_currentLocation!, 15);
      }
      return;
    }

    final points = <LatLng>[];
    if (_searchResult != null) points.add(_searchResult!);
    if (_currentLocation != null) points.add(_currentLocation!);
    for (final option in _nearbyOptions) {
      points.add(LatLng(option.lat, option.lng));
    }
    if (points.length > 1) {
      final bounds = LatLngBounds.fromPoints(points);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
        );
      });
    } else if (points.length == 1) {
      _mapController.move(points.first, 13);
    }
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() => _searching = true);
    try {
      final results = await _geocoding.search(query);
      if (results.isNotEmpty && mounted) {
        setState(() {
          _searchResult = LatLng(results.first.lat, results.first.lng);
          _searchLabel = results.first.displayName;
          _showingHome = false;
        });
        _mapController.move(_searchResult!, 13);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el destino')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al buscar destino')),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _searchNearbyForType(String type) async {
    final searchId = ++_nearbySearchId;

    // Limpia marcadores anteriores de inmediato para que no se mezclen
    setState(() {
      _selectedType = type;
      _searching = true;
      _showingHome = false;
      _nearbyOptions = [];
      _searchResult = null;
      _searchLabel = null;
    });

    // ── HOGAR: sólo muestra la ubicación actual ──────────────────────────
    if (type == 'hogar') {
      setState(() {
        _showingHome = true;
        _nearbyOptions = [];
        _searching = false;
      });
      if (_currentLocation != null) {
        _mapController.move(_currentLocation!, 15);
        setState(() {
          _searchLabel = 'Tu ubicación actual';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Activa la ubicación actual en Configuración para ver tu hogar.',
              ),
            ),
          );
        }
      }
      return;
    }

    try {
      List<GeocodingResult> results = [];

      if (_currentLocation != null) {
        // ── Búsqueda con Overpass por etiqueta OSM ────────────────────────
        if (type == 'playa') {
          results = await _geocoding.searchBeachesInCountry(
            lat: _currentLocation!.latitude,
            lng: _currentLocation!.longitude,
          );
        } else {
          if (type == 'gym' || type == 'medico' || type == 'compras') {
            final placeType = type == 'gym'
                ? 'gym'
                : type == 'medico'
                    ? 'hospital'
                    : 'supermarket';
            final googleResults = await _geocoding.searchNearbyGoogle(
              placeType: placeType,
              lat: _currentLocation!.latitude,
              lng: _currentLocation!.longitude,
              radiusMeters: _radiusFor(type),
            );
            if (googleResults != null && googleResults.isNotEmpty) {
              results = googleResults;
            }
          }

          if (results.isEmpty) {
            final filter = _overpassFilterFor(type);
            results = await _geocoding.searchByOsmTag(
              overpassFilter: filter,
              lat: _currentLocation!.latitude,
              lng: _currentLocation!.longitude,
              radiusMeters: _radiusFor(type),
            );
          }

          if (type == 'gym' && results.isEmpty) {
            results = await _geocoding.searchNearby(
              query: 'gimnasio',
              lat: _currentLocation!.latitude,
              lng: _currentLocation!.longitude,
            );
          }
        }
      } else {
        // Fallback Nominatim si no hay ubicación
        final query = _nominatimQueryFor(type);
        results = await _geocoding.search('$query en $_city');
      }

      if (!mounted || searchId != _nearbySearchId) return;
      setState(() {
        _nearbyOptions = results;
        _showingHome = false;
        if (results.isNotEmpty) {
          _searchResult = LatLng(results.first.lat, results.first.lng);
          _searchLabel = results.first.displayName;
        } else {
          _searchLabel = 'Sin resultados cercanos';
        }
      });
      if (results.isNotEmpty) {
        _fitBounds();
      }
    } finally {
      if (mounted && searchId == _nearbySearchId) {
        setState(() => _searching = false);
      }
    }
  }

  /// Filtro Overpass por tipo de salida.
  String _overpassFilterFor(String type) {
    switch (type) {
      case 'compras':
        return '["shop"~"supermarket|grocery|convenience"]';
      case 'gym':
        return '["leisure"~"fitness_centre|sports_centre|fitness_station"]';
      case 'medico':
        return '["amenity"~"hospital|clinic|pharmacy|doctors"]';
      default:
        return '["amenity"="place_of_worship"]';
    }
  }

  /// Radio de búsqueda en metros según el tipo.
  double _radiusFor(String type) {
    switch (type) {
      case 'compras':
        return 3000;
      case 'gym':
        return 3000;
      case 'medico':
        return 3000;
      default:
        return 3000;
    }
  }

  /// Query Nominatim de fallback (sin ubicación GPS).
  String _nominatimQueryFor(String type) {
    switch (type) {
      case 'compras':
        return 'supermercado';
      case 'gym':
        return 'gimnasio';
      case 'medico':
        return 'hospital'; // Una sola palabra es 10x más rápido en Nominatim
      case 'playa':
        return 'playa';
      default:
        return 'lugar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Chips del mapa: sólo los 5 tipos relevantes
    final mapChips = AppConstants.exitTypes
        .where((t) => _mapTypes.contains(t['id']))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.locationName ?? 'Mapa inteligente'),
      ),
      body: Column(
        children: [
          // ── Chips de categoría ──────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              scrollDirection: Axis.horizontal,
              itemCount: mapChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type = mapChips[index];
                final id = type['id']!;
                final selected = id == _selectedType;
                return ChoiceChip(
                  selected: selected,
                  avatar: Text(type['emoji'] ?? '📍'),
                  label: Text(type['nombre'] ?? id),
                  onSelected: (_) => _searchNearbyForType(id),
                );
              },
            ),
          ),

          // ── Buscador libre ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar destino o negocio...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _searching ? null : _search,
                  icon: const Icon(Icons.travel_explore),
                  tooltip: 'Buscar',
                ),
              ],
            ),
          ),

          // ── Chip informativo ────────────────────────────────────────────
          if (_showingHome && _currentLocation != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(Icons.my_location_rounded,
                      size: 16, color: colors.primary),
                  label: const Text(
                    'Mostrando tu ubicación actual',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            )
          else if (_searchLabel != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(Icons.place, size: 16, color: colors.primary),
                  label: Text(
                    _searchLabel!.length > 50
                        ? '${_searchLabel!.substring(0, 50)}...'
                        : _searchLabel!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),

          // ── Opciones cercanas (chips horizontales) ──────────────────────
          if (_nearbyOptions.isNotEmpty && !_showingHome)
            SizedBox(
              height: 78,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _nearbyOptions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = _nearbyOptions[index];
                  return ActionChip(
                    avatar: Icon(_iconForType(_selectedType), size: 18),
                    label: SizedBox(
                      width: 210,
                      child: Text(
                        option.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _searchResult = LatLng(option.lat, option.lng);
                        _searchLabel = option.displayName;
                      });
                      _mapController.move(_searchResult!, 15);
                    },
                  );
                },
              ),
            ),

          // ── Mapa ────────────────────────────────────────────────────────
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 12,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.checkout.app',
                ),
                MarkerLayer(
                  markers: [
                    // Marcador de resultado de búsqueda libre
                    if (_searchResult != null && !_showingHome)
                      Marker(
                        point: _searchResult!,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_pin,
                          color: Color(0xFFD63031),
                          size: 40,
                        ),
                      ),
                    // Marcador de ubicación actual
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        width: 46,
                        height: 46,
                        child: Tooltip(
                          message: 'Tu ubicación',
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 5),
                              ],
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    // Marcadores de opciones cercanas
                    ..._nearbyOptions.map(
                      (option) => Marker(
                        point: LatLng(option.lat, option.lng),
                        width: 42,
                        height: 42,
                        child: Tooltip(
                          message: option.displayName,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _colorForType(_selectedType),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Icon(
                              _iconForType(_selectedType),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Marcadores de viajes anteriores
                    ..._tripsWithCoords.map(
                      (trip) => Marker(
                        point: LatLng(trip.lat!, trip.lng!),
                        width: 40,
                        height: 40,
                        child: Tooltip(
                          message: trip.destino.isNotEmpty
                              ? trip.destino
                              : trip.nombre,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: const Icon(Icons.flight,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Leyenda de viajes ───────────────────────────────────────────
          if (_tripsWithCoords.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: colors.surfaceContainerHighest.withOpacity(0.5),
              child: Text(
                '${_tripsWithCoords.length} destino(s) de viajes anteriores',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'compras':
        return Icons.shopping_cart_rounded;
      case 'hogar':
        return Icons.home_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'medico':
        return Icons.local_hospital_rounded;
      case 'playa':
        return Icons.beach_access_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'compras':
        return const Color(0xFF6C5CE7);
      case 'gym':
        return const Color(0xFFE17055);
      case 'medico':
        return const Color(0xFF00B894);
      case 'playa':
        return const Color(0xFF0984E3);
      default:
        return const Color(0xFF2D3436);
    }
  }
}
