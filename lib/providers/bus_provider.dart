import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/bus_model.dart';
import '../data/models/route_model.dart';
import '../data/models/special_shuttle_model.dart';
import '../data/repositories/bus_repository.dart';
import '../shared/widgets/status_badge.dart';

enum BusFilterOption { all, active, approaching, delayed }

class BusProvider extends ChangeNotifier {
  final BusRepository repository;
  StreamSubscription<List<BusModel>>? _subscription;
  StreamSubscription<List<RouteModel>>? _routesSubscription;
  StreamSubscription<List<SpecialShuttleModel>>? _specialShuttlesSubscription;

  List<BusModel> _buses = [];
  List<RouteModel> _routes = [];
  List<SpecialShuttleModel> _specialShuttles = [];
  bool _isLoading = true;
  String? _errorMessage;

  BusModel? _selectedBus;
  RouteModel? _selectedRoute;
  BusFilterOption _selectedFilter = BusFilterOption.all;
  String _searchQuery = '';

  BusProvider({required this.repository}) {
    _init();
  }

  List<BusModel> get buses => _buses;
  List<RouteModel> get routes => _routes;
  List<SpecialShuttleModel> get specialShuttles => _specialShuttles;
  List<SpecialShuttleModel> get activeSpecialShuttles {
    if (_specialShuttles.isEmpty) return [];
    return _specialShuttles.where((s) {
      if (s.isExpired) return false;
      final st = s.status.toLowerCase();
      return st == 'active' || st == 'scheduled' || st.isEmpty;
    }).toList();
  }
  bool get hasActiveSpecialShuttle => activeSpecialShuttles.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BusModel? get selectedBus => _selectedBus;
  RouteModel? get selectedRoute => _selectedRoute;
  BusFilterOption get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  // Actively live buses only
  List<BusModel> get activeLiveBuses =>
      _buses.where((b) => b.status == BusStatusType.onRoute).toList();
  int get activeBusCount => activeLiveBuses.length;

  // Main featured bus on Home screen
  BusModel? get mainLiveBus {
    if (_buses.isEmpty) return null;
    // 1. Prioritize live onRoute bus
    try {
      return _buses.firstWhere((b) => b.status == BusStatusType.onRoute);
    } catch (_) {}
    // 2. Fallback to GAU-2555 or first bus
    try {
      return _buses.firstWhere((b) => b.id == 'bus_gau_2555');
    } catch (_) {
      return _buses.first;
    }
  }

  // Filtered buses according to filter chip and search
  List<BusModel> get filteredBuses {
    return _buses.where((bus) {
      // Status filter
      if (_selectedFilter == BusFilterOption.active &&
          bus.status != BusStatusType.onRoute) {
        return false;
      }
      if (_selectedFilter == BusFilterOption.approaching &&
          bus.status != BusStatusType.approaching) {
        return false;
      }
      if (_selectedFilter == BusFilterOption.delayed &&
          bus.status != BusStatusType.delayed) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = bus.name.toLowerCase().contains(query);
        final matchesRoute = bus.routeName.toLowerCase().contains(query);
        final matchesStop = bus.nextStop.toLowerCase().contains(query);
        final matchesSpecial = bus.isSpecial || (bus.specialPurpose?.toLowerCase().contains(query) ?? false);
        return matchesName || matchesRoute || matchesStop || matchesSpecial;
      }

      return true;
    }).toList();
  }

  void _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _buses = await repository.getBuses();
      _routes = await repository.getRoutes();
      if (_buses.isNotEmpty) {
        _selectedBus = _buses.first;
      }
      if (_routes.isNotEmpty) {
        _selectedRoute = _routes.first;
      }

      // Start live GPS movement stream for regular fleet
      repository.liveTrackingService.startSimulation();
      _subscription = repository.liveTrackingService.busStream.listen((updatedList) {
        _buses = updatedList;

        // Keep selected bus reference updated with latest telemetry
        if (_selectedBus != null) {
          try {
            _selectedBus = _buses.firstWhere((b) => b.id == _selectedBus!.id);
          } catch (_) {}
        }
        notifyListeners();
      });

      // Listen for dynamic routes added/updated from Web Admin Portal
      _routesSubscription = repository.liveTrackingService.firebaseService.routesUpdatesStream.listen((liveRoutes) {
        if (liveRoutes.isNotEmpty) {
          _routes = liveRoutes;
          if (_selectedRoute != null) {
            try {
              _selectedRoute = liveRoutes.firstWhere((r) => r.id == _selectedRoute!.id);
            } catch (_) {
              _selectedRoute = liveRoutes.first;
            }
          }
          notifyListeners();
        }
      });

      // Initial fetch of Special Shuttles from Firebase Realtime Database
      try {
        final initialShuttles = await repository.liveTrackingService.firebaseService.fetchSpecialShuttlesFromFirebase();
        if (initialShuttles != null) {
          _specialShuttles = initialShuttles;
          notifyListeners();
        }
      } catch (_) {}

      // Listen for dynamic Special Shuttles uploaded by Web Admin Portal
      _specialShuttlesSubscription = repository.liveTrackingService.firebaseService.specialShuttlesStream.listen((liveShuttles) {
        _specialShuttles = liveShuttles;
        notifyListeners();
      });

      _isLoading = false;
      _errorMessage = null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load bus data. Please try again.';
    }
    notifyListeners();
  }

  RouteModel? getRouteForBus(BusModel? bus) {
    if (bus == null || _routes.isEmpty) return _routes.isNotEmpty ? _routes.first : null;

    // 1. Direct ID match
    try {
      return _routes.firstWhere((r) => r.id == bus.routeId);
    } catch (_) {}

    // 2. Case-insensitive and code / title matching
    final busRouteId = bus.routeId.toLowerCase().trim();
    final busRouteName = bus.routeName.toLowerCase().trim();

    for (final r in _routes) {
      final rId = r.id.toLowerCase().trim();
      final rCode = r.code.toLowerCase().trim();
      final rTitle = r.title.toLowerCase().trim();

      if (rId == busRouteId) return r;
      if (rCode == busRouteId || rCode == busRouteName) return r;
      if (busRouteName.isNotEmpty && (busRouteName.contains(rCode) || busRouteName.contains(rTitle))) return r;
      if (busRouteId.isNotEmpty && (busRouteId.contains(rCode) || rId.contains(busRouteId))) return r;
    }

    // 3. Number-based heuristic match (e.g. Route 1, Route 2, Route 3...)
    for (int i = 1; i <= 20; i++) {
      if (busRouteId.contains('$i') || busRouteName.contains('route $i') || busRouteName.contains('no. $i') || busRouteName.contains('no.$i')) {
        try {
          return _routes.firstWhere((r) => r.id.contains('$i') || r.code.contains('$i'));
        } catch (_) {}
      }
    }

    return _routes.first;
  }

  void selectBus(BusModel bus) {
    _selectedBus = bus;
    final matchedRoute = getRouteForBus(bus);
    if (matchedRoute != null) {
      _selectedRoute = matchedRoute;
    }
    notifyListeners();
  }

  void selectRoute(RouteModel route) {
    _selectedRoute = route;
    notifyListeners();
  }

  void setFilter(BusFilterOption filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<bool> reportBusIssue({
    required String busId,
    required String issueType,
    required String description,
  }) async {
    return await repository.reportIssue(
      busId: busId,
      issueType: issueType,
      description: description,
    );
  }

  Future<void> refreshBuses() async {
    try {
      final buses = await repository.getBuses();
      final routes = await repository.getRoutes();
      _buses = buses;
      _routes = routes;
      notifyListeners();
    } catch (_) {}
  }

  BusModel? getBusById(String busId) {
    try {
      return _buses.firstWhere((b) => b.id == busId);
    } catch (_) {
      return null;
    }
  }

  void updateDriverBusStatus({
    required String busId,
    required bool isLive,
    LatLng? location,
    double? speed,
    String? nextStop,
    String? occupancy,
    int? etaMinutes,
  }) {
    repository.liveTrackingService.updateBusByDriver(
      busId: busId,
      isLive: isLive,
      location: location,
      speed: speed,
      nextStop: nextStop,
      occupancy: occupancy,
      etaMinutes: etaMinutes,
    );
    notifyListeners();
  }

  void toggleBusLiveSimulation(String busId, {bool? forceLive}) {
    repository.liveTrackingService.toggleBusLiveSimulation(busId, forceLive: forceLive);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _routesSubscription?.cancel();
    _specialShuttlesSubscription?.cancel();
    repository.liveTrackingService.dispose();
    super.dispose();
  }
}
