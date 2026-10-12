import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mock/mock_stops.dart';
import '../data/models/stop_model.dart';

class FavoritesProvider extends ChangeNotifier {
  static const String _prefKey = 'uniride_favorite_stop_ids';
  Set<String> _favoriteStopIds = {};
  bool _isLoaded = false;

  FavoritesProvider() {
    _loadFavorites();
  }

  bool get isLoaded => _isLoaded;

  List<BusStopModel> get allStops {
    return MockStops.allStops.map((stop) {
      return stop.copyWith(isFavorite: _favoriteStopIds.contains(stop.id));
    }).toList();
  }

  List<BusStopModel> get favoriteStops {
    return allStops.where((stop) => _favoriteStopIds.contains(stop.id)).toList();
  }

  bool isFavorite(String stopId) => _favoriteStopIds.contains(stopId);

  static const String _pickupKey = 'uniride_selected_pickup_stop_id';
  String? _selectedPickupStopId;

  String get selectedPickupStopId => _selectedPickupStopId ?? 'stop_pindi_bypass';

  BusStopModel get selectedPickupStop {
    try {
      return allStops.firstWhere((s) => s.id == selectedPickupStopId);
    } catch (_) {
      return allStops.first;
    }
  }

  Future<void> setPickupStop(String stopId) async {
    _selectedPickupStopId = stopId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pickupKey, stopId);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefKey);
    _selectedPickupStopId = prefs.getString(_pickupKey) ?? 'stop_pindi_bypass';
    if (saved != null) {
      _favoriteStopIds = saved.toSet();
    } else {
      // Default initial favorite stops from UET Gujranwala RCET schedule
      _favoriteStopIds = {
        'stop_sheikhupura_mor',
        'stop_pindi_bypass',
        'stop_rahwali',
        'stop_ghakhar',
      };
      await prefs.setStringList(_prefKey, _favoriteStopIds.toList());
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggleFavorite(String stopId) async {
    if (_favoriteStopIds.contains(stopId)) {
      _favoriteStopIds.remove(stopId);
    } else {
      _favoriteStopIds.add(stopId);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _favoriteStopIds.toList());
  }
}
