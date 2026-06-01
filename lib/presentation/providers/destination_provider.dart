import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/destination_repository_impl.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/destination_recommendation.dart';
import '../../domain/entities/weather.dart';
import '../../domain/usecases/get_destination_details_usecase.dart';
import '../../domain/usecases/get_destination_recommendations_usecase.dart';
import '../../domain/usecases/search_destinations_usecase.dart';

class DestinationProvider extends ChangeNotifier {
  final SearchDestinationsUseCase _search;
  final GetDestinationDetailsUseCase _details;
  final GetDestinationRecommendationsUseCase _recommendations;

  List<Destination> _searchResults = [];
  Destination? _selectedDestination;
  List<DestinationRecommendation> _recommendationsList = [];
  bool _isSearching = false;
  String? _error;
  int _searchId = 0;

  Timer? _debounce;

  DestinationProvider({DestinationRepositoryImpl? repository})
      : _search = SearchDestinationsUseCase(
          repository ?? DestinationRepositoryImpl(),
        ),
        _details = GetDestinationDetailsUseCase(
          repository ?? DestinationRepositoryImpl(),
        ),
        _recommendations = GetDestinationRecommendationsUseCase(
          repository ?? DestinationRepositoryImpl(),
        );

  List<Destination> get searchResults => _searchResults;
  Destination? get selectedDestination => _selectedDestination;
  List<DestinationRecommendation> get recommendations => _recommendationsList;
  bool get isSearching => _isSearching;
  String? get error => _error;

  void search(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _searchId++;
      _searchResults = [];
      notifyListeners();
      return;
    }
    final searchId = ++_searchId;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(query.trim(), searchId);
    });
  }

  Future<void> _runSearch(String query, int searchId) async {
    _isSearching = true;
    notifyListeners();
    final result = await _search(query);
    if (searchId != _searchId) return;
    result.fold(
      (f) {
        _error = f.message;
        _searchResults = [];
      },
      (list) {
        _error = null;
        _searchResults = list.take(5).toList();
      },
    );
    _isSearching = false;
    notifyListeners();
  }

  Future<void> selectDestination(
    Destination preview, {
    Weather? weather,
    bool isInternationalTrip = false,
  }) async {
    _isSearching = true;
    notifyListeners();

    Destination resolved = preview;
    if (preview.latitude == 0 &&
        preview.longitude == 0 &&
        preview.placeId.isNotEmpty) {
      final details = await _details(preview.placeId);
      details.fold((f) => _error = f.message, (d) => resolved = d);
    }

    _selectedDestination = resolved;
    _searchResults = [];
    await _loadRecommendations(
      resolved,
      weather: weather,
      isInternationalTrip: isInternationalTrip || resolved.isInternational,
    );
    _isSearching = false;
    notifyListeners();
  }

  Future<void> refreshRecommendations({
    Weather? weather,
    bool isInternationalTrip = false,
  }) async {
    final dest = _selectedDestination;
    if (dest == null) return;
    await _loadRecommendations(
      dest,
      weather: weather,
      isInternationalTrip: isInternationalTrip || dest.isInternational,
    );
    notifyListeners();
  }

  Future<void> _loadRecommendations(
    Destination destination, {
    Weather? weather,
    required bool isInternationalTrip,
  }) async {
    final result = await _recommendations(
      destination: destination,
      weather: weather,
      isInternationalTrip: isInternationalTrip,
    );
    result.fold(
      (f) => _error = f.message,
      (list) {
        _error = null;
        _recommendationsList = list;
      },
    );
  }

  void clearSelection() {
    _selectedDestination = null;
    _recommendationsList = [];
    notifyListeners();
  }

  void clearSearch() {
    _debounce?.cancel();
    _searchResults = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
