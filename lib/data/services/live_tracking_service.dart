import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../../shared/widgets/status_badge.dart';
import '../mock/mock_buses.dart';
import '../mock/mock_routes.dart';
import '../models/bus_model.dart';
import '../models/driver_model.dart';
import '../models/route_model.dart';

import 'firebase_realtime_tracking_service.dart';

class LiveTrackingService {
  final _busStreamController = StreamController<List<BusModel>>.broadcast();
  Stream<List<BusModel>> get busStream => _busStreamController.stream;

  final FirebaseRealtimeTrackingService _firebaseService = FirebaseRealtimeTrackingService();
  FirebaseRealtimeTrackingService get firebaseService => _firebaseService;
  StreamSubscription<Map<String, dynamic>>? _firebaseSubscription;

  List<BusModel> _currentBuses = [];
  Timer? _movementTimer;
  final Map<String, int> _busPolylineIndices = {};
  final Map<String, int> _busStopDwellTicks = {};
  final Map<String, int> _busStopIndices = {};

  LiveTrackingService() {
    _currentBuses = List.from(MockBuses.allBuses);
    for (final bus in _currentBuses) {
      _busPolylineIndices[bus.id] = 0;
      _busStopIndices[bus.id] = bus.currentStopIndex;
    }
  }

  void startSimulation() {
    _busStreamController.add(List.unmodifiable(_currentBuses));

    // 1. Listen for live updates broadcast from Firebase Realtime Database
    _firebaseService.startListening();
    _firebaseSubscription?.cancel();
    _firebaseSubscription = _firebaseService.liveUpdatesStream.listen((firebaseFleet) {
      _applyFirebaseUpdates(firebaseFleet);
    });

    // Automatic fake movement disabled: Real telemetry strictly comes from Driver GPS or Firebase Realtime Database
    _movementTimer?.cancel();
  }

  void _simulateMovementTick() {
    bool changed = false;
    const distanceCalc = Distance();
    const campusLoc = LatLng(32.362339, 74.208769);

    for (int i = 0; i < _currentBuses.length; i++) {
      final bus = _currentBuses[i];
      // Skip if bus is not live, physically controlled by a real driver phone,
      // OR if it is a Special Bus (Special buses only move when their assigned driver broadcasts live GPS!)
      if (bus.status != BusStatusType.onRoute || _driverControlledBusIds.contains(bus.id) || bus.isSpecial) {
        continue;
      }

      // Match bus to route
      RouteModel? route;
      for (final r in MockRoutes.allRoutes) {
        if (r.id == bus.routeId ||
            r.code.toLowerCase() == bus.routeId.toLowerCase() ||
            bus.routeName.toLowerCase().contains(r.code.toLowerCase()) ||
            bus.routeId.contains(r.id)) {
          route = r;
          break;
        }
      }
      if (route == null || route.polylinePoints.isEmpty) continue;

      final points = route.polylinePoints;
      final stops = route.stops;
      int polyIdx = _busPolylineIndices[bus.id] ?? 0;
      int dwell = _busStopDwellTicks[bus.id] ?? 0;
      int stopIdx = _busStopIndices[bus.id] ?? bus.currentStopIndex;

      // Handle pause at stop for passenger boarding simulation
      if (dwell > 0) {
        _busStopDwellTicks[bus.id] = dwell - 1;
        if (bus.speed != 0.0) {
          _currentBuses[i] = bus.copyWith(
            speed: 0.0,
            lastUpdated: DateTime.now(),
          );
          changed = true;
        }
        continue;
      }

      // Advance along road polyline points (~36-44 km/h)
      polyIdx += 2;
      if (polyIdx >= points.length) {
        // Reached campus destination! Dwell for 8 ticks, then restart from origin
        polyIdx = 0;
        stopIdx = 0;
        _busPolylineIndices[bus.id] = 0;
        _busStopIndices[bus.id] = 0;
        _busStopDwellTicks[bus.id] = 6;
      } else {
        _busPolylineIndices[bus.id] = polyIdx;
      }

      final newLocation = points[polyIdx];

      // Check proximity to stops along the route
      String nextStopName = bus.nextStop;
      double speed = 36.0 + (polyIdx % 7);

      if (stops.isNotEmpty) {
        final targetStop = stops[stopIdx.clamp(0, stops.length - 1)];
        final distToTarget = distanceCalc(newLocation, targetStop.location);

        if (distToTarget < 120) {
          // Bus arrived at stop! Boarding passengers
          _busStopDwellTicks[bus.id] = 3; // pause for 3 ticks (~4.8s)
          speed = 0.0;
          nextStopName = targetStop.name;
          if (stopIdx + 1 < stops.length) {
            _busStopIndices[bus.id] = stopIdx + 1;
          }
        } else {
          nextStopName = targetStop.name;
        }
      }

      final distToCampus = distanceCalc(newLocation, campusLoc) / 1000.0;
      final eta = (distToCampus / 35.0 * 60).round().clamp(1, 90);

      _currentBuses[i] = bus.copyWith(
        location: newLocation,
        speed: speed,
        nextStop: nextStopName,
        currentStopIndex: stopIdx,
        distanceKm: double.parse(distToCampus.toStringAsFixed(1)),
        etaMinutes: eta,
        lastUpdated: DateTime.now(),
      );
      changed = true;
    }

    if (changed) {
      _busStreamController.add(List.unmodifiable(_currentBuses));
    }
  }

  void _applyFirebaseUpdates(Map<String, dynamic> fleetData) {
    bool changed = false;
    final Set<String> firebaseBusIds = fleetData.keys.toSet();

    // 1. Remove buses deleted from Firebase (if fleetData is active)
    if (fleetData.isNotEmpty) {
      final removed = _currentBuses.where((b) => !firebaseBusIds.contains(b.id)).toList();
      if (removed.isNotEmpty) {
        _currentBuses.removeWhere((b) => !firebaseBusIds.contains(b.id));
        changed = true;
      }
    }

    // 2. Update or insert buses from Firebase
    for (final entry in fleetData.entries) {
      final busId = entry.key;
      final rawBusData = entry.value;
      if (rawBusData is Map) {
        final busData = Map<String, dynamic>.from(rawBusData);
        final index = _currentBuses.indexWhere((b) => b.id == busId);
        if (index != -1) {
          _currentBuses[index] = FirebaseRealtimeTrackingService.mergeFirebaseData(
            _currentBuses[index],
            busData,
          );
          changed = true;
        } else {
          // New bus created dynamically via Web Admin Portal
          try {
            final lat = (busData['latitude'] as num?)?.toDouble() ?? 32.1950;
            final lng = (busData['longitude'] as num?)?.toDouble() ?? 74.1960;
            final isLive = busData['is_live'] as bool? ?? (busData['status'] == 'onRoute');
            final routeId = (busData['route_id'] as String?) ?? (busData['routeId'] as String?) ?? 'route_1';
            final routeName = (busData['route_name'] as String?) ?? (busData['routeName'] as String?) ?? 'Campus Transit';
            final name = (busData['name'] as String?) ??
                (busData['bus_id'] as String? ?? busId).replaceAll('bus_', '').toUpperCase();
            final driverName = (busData['driver_name'] as String?) ?? (busData['driverName'] as String?) ?? 'Campus Driver';
            final driverPhone = (busData['driver_phone'] as String?) ?? (busData['driverPhone'] as String?) ?? '+92 300 1234567';

            final dynamicBus = BusModel(
              id: busId,
              name: name,
              routeName: routeName,
              routeId: routeId,
              driver: DriverModel(
                id: (busData['driver_id'] as String?) ?? (busData['driverId'] as String?) ?? 'drv_$busId',
                name: driverName,
                phone: driverPhone,
                rating: 4.9,
              ),
              status: isLive ? BusStatusType.onRoute : BusStatusType.stopped,
              speed: (busData['speed'] as num?)?.toDouble() ?? 0.0,
              etaMinutes: (busData['eta_minutes'] as num?)?.toInt() ?? (busData['etaMinutes'] as num?)?.toInt() ?? 0,
              nextStop: (busData['next_stop'] as String?) ?? (busData['nextStop'] as String?) ?? 'University Terminal',
              distanceKm: (busData['distance_km'] as num?)?.toDouble() ?? 0.0,
              location: LatLng(lat, lng),
              lastUpdated: DateTime.now(),
            );
            _currentBuses.add(dynamicBus);
            changed = true;
          } catch (_) {}
        }
      }
    }
    if (changed) {
      _busStreamController.add(List.unmodifiable(_currentBuses));
    }
  }

  final Set<String> _driverControlledBusIds = {};

  void updateBusByDriver({
    required String busId,
    required bool isLive,
    double? speed,
    String? nextStop,
    String? occupancy,
    LatLng? location,
    int? etaMinutes,
  }) {
    if (isLive) {
      _driverControlledBusIds.add(busId);
    } else {
      _driverControlledBusIds.remove(busId);
    }
    final index = _currentBuses.indexWhere((b) => b.id == busId);
    if (index != -1) {
      final existing = _currentBuses[index];
      final effectiveLocation = location ?? existing.location;
      final effectiveSpeed = isLive ? (speed ?? existing.speed) : 0.0;

      // Distance to campus and dynamic ETA
      const distanceCalc = Distance();
      const campusLoc = LatLng(32.362339, 74.208769);
      final double distanceMeters = distanceCalc(effectiveLocation, campusLoc);
      final double distKm = distanceMeters / 1000.0;
      final int computedEta = isLive ? (distKm / (effectiveSpeed > 10 ? effectiveSpeed : 35.0) * 60).round().clamp(1, 90) : 0;

      final updated = existing.copyWith(
        status: isLive ? BusStatusType.onRoute : BusStatusType.stopped,
        speed: effectiveSpeed,
        nextStop: nextStop ?? existing.nextStop,
        occupancy: occupancy ?? existing.occupancy,
        location: effectiveLocation,
        distanceKm: double.parse(distKm.toStringAsFixed(1)),
        etaMinutes: etaMinutes ?? (isLive ? computedEta : 0),
        lastUpdated: DateTime.now(),
      );
      _currentBuses[index] = updated;
      _busStreamController.add(List.unmodifiable(_currentBuses));

      // Asynchronously publish to Firebase Realtime Database
      _firebaseService.publishDriverLocation(
        busId: busId,
        location: updated.location,
        speed: updated.speed,
        nextStop: updated.nextStop,
        occupancy: updated.occupancy,
        isLive: isLive,
        etaMinutes: updated.etaMinutes,
      );
    }
  }

  /// Start or stop live trip simulation for a bus
  void toggleBusLiveSimulation(String busId, {bool? forceLive}) {
    final index = _currentBuses.indexWhere((b) => b.id == busId);
    if (index == -1) return;

    final bus = _currentBuses[index];
    final bool willBeLive = forceLive ?? (bus.status != BusStatusType.onRoute);

    // Find route for bus
    RouteModel? route;
    for (final r in MockRoutes.allRoutes) {
      if (r.id == bus.routeId ||
          r.code.toLowerCase() == bus.routeId.toLowerCase() ||
          bus.routeName.toLowerCase().contains(r.code.toLowerCase()) ||
          bus.routeId.contains(r.id)) {
        route = r;
        break;
      }
    }
    route ??= MockRoutes.allRoutes.first;

    if (willBeLive) {
      _busPolylineIndices[busId] = 0;
      _busStopIndices[busId] = 0;
      _busStopDwellTicks[busId] = 0;
      final startLoc = route.polylinePoints.isNotEmpty ? route.polylinePoints.first : bus.location;
      final firstStopName = route.stops.isNotEmpty ? route.stops.first.name : 'University Terminal';

      const distanceCalc = Distance();
      const campusLoc = LatLng(32.362339, 74.208769);
      final distKm = distanceCalc(startLoc, campusLoc) / 1000.0;
      final eta = (distKm / 35.0 * 60).round().clamp(1, 90);

      _currentBuses[index] = bus.copyWith(
        status: BusStatusType.onRoute,
        location: startLoc,
        speed: 36.0,
        nextStop: firstStopName,
        currentStopIndex: 0,
        distanceKm: double.parse(distKm.toStringAsFixed(1)),
        etaMinutes: eta,
        occupancy: 'Seats Available',
        lastUpdated: DateTime.now(),
      );
    } else {
      _busPolylineIndices[busId] = 0;
      _busStopIndices[busId] = 0;
      _busStopDwellTicks[busId] = 0;
      final startLoc = route.polylinePoints.isNotEmpty ? route.polylinePoints.first : bus.location;
      final firstStopName = route.stops.isNotEmpty ? route.stops.first.name : 'Standby';

      _currentBuses[index] = bus.copyWith(
        status: BusStatusType.stopped,
        location: startLoc,
        speed: 0.0,
        nextStop: firstStopName,
        currentStopIndex: 0,
        distanceKm: 0.0,
        etaMinutes: 0,
        occupancy: 'Standby',
        lastUpdated: DateTime.now(),
      );
    }

    _busStreamController.add(List.unmodifiable(_currentBuses));
  }

  void stopSimulation() {
    _movementTimer?.cancel();
    _firebaseService.stopListening();
  }

  void dispose() {
    _movementTimer?.cancel();
    _firebaseSubscription?.cancel();
    _firebaseService.dispose();
    _busStreamController.close();
  }

  List<BusModel> getCurrentBusesSnapshot() => List.unmodifiable(_currentBuses);
}
