import '../mock/mock_notifications.dart';
import '../mock/mock_routes.dart';
import '../mock/mock_stops.dart';
import '../models/bus_model.dart';
import '../models/notification_model.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../services/live_tracking_service.dart';

class BusRepository {
  final LiveTrackingService liveTrackingService;

  BusRepository({required this.liveTrackingService});

  Future<List<BusModel>> getBuses() async {
    // Simulate brief network latency for realistic feel
    await Future.delayed(const Duration(milliseconds: 300));
    return liveTrackingService.getCurrentBusesSnapshot();
  }

  Future<BusModel?> getBusById(String id) async {
    final buses = liveTrackingService.getCurrentBusesSnapshot();
    try {
      return buses.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  List<RouteModel> _cachedRoutes = MockRoutes.allRoutes;

  Future<List<RouteModel>> getRoutes() async {
    try {
      final firebaseRoutes = await liveTrackingService.firebaseService.fetchRoutesFromFirebase();
      if (firebaseRoutes != null && firebaseRoutes.isNotEmpty) {
        _cachedRoutes = firebaseRoutes;
        return List.unmodifiable(_cachedRoutes);
      }
    } catch (_) {}
    return List.unmodifiable(_cachedRoutes.isNotEmpty ? _cachedRoutes : MockRoutes.allRoutes);
  }

  Future<RouteModel?> getRouteById(String id) async {
    try {
      return _cachedRoutes.firstWhere((r) => r.id == id);
    } catch (_) {
      try {
        return MockRoutes.allRoutes.firstWhere((r) => r.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  Future<List<BusStopModel>> getStops() async {
    // Extract unique stops from active routes dynamically
    final Set<String> seenIds = {};
    final List<BusStopModel> dynamicStops = [];

    for (final r in _cachedRoutes) {
      for (final s in r.stops) {
        if (!seenIds.contains(s.id)) {
          seenIds.add(s.id);
          dynamicStops.add(s);
        }
      }
    }

    if (dynamicStops.isNotEmpty) {
      return List.unmodifiable(dynamicStops);
    }
    return List.unmodifiable(MockStops.allStops);
  }

  Future<BusStopModel?> getStopById(String id) async {
    final stops = await getStops();
    try {
      return stops.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final firebaseAlerts = await liveTrackingService.firebaseService.fetchAlertsFromFirebase();
      if (firebaseAlerts != null && firebaseAlerts.isNotEmpty) {
        return firebaseAlerts;
      }
    } catch (_) {}
    return List.from(MockNotifications.initialNotifications);
  }

  Future<bool> reportIssue({
    required String busId,
    required String issueType,
    required String description,
  }) async {
    // Simulate API POST request
    await Future.delayed(const Duration(milliseconds: 600));
    return true;
  }
}
