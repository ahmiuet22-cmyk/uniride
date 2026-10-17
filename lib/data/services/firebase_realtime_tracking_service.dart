import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../shared/widgets/status_badge.dart';
import '../models/bus_model.dart';
import '../models/notification_model.dart';
import '../models/route_model.dart';
import '../models/special_shuttle_model.dart';
import 'route_geometry_service.dart';

class FirebaseRealtimeTrackingService {
  static final FirebaseRealtimeTrackingService _instance = FirebaseRealtimeTrackingService._internal();
  factory FirebaseRealtimeTrackingService() => _instance;
  FirebaseRealtimeTrackingService._internal();

  // Configurable Firebase Realtime Database URL
  static String databaseUrl = 'https://uniride-app-79177-default-rtdb.firebaseio.com';

  static String get resolvedUrl {
    if (databaseUrl.contains('database/')) {
      final parts = databaseUrl.split('database/');
      if (parts.length > 1) {
        final dbName = parts[1].split('/').first;
        return 'https://$dbName.firebaseio.com';
      }
    }
    return databaseUrl.endsWith('/') ? databaseUrl.substring(0, databaseUrl.length - 1) : databaseUrl;
  }

  static final http.Client _client = http.Client();
  Timer? _pollingTimer;

  final _liveUpdatesController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get liveUpdatesStream => _liveUpdatesController.stream;

  final _routesUpdatesController = StreamController<List<RouteModel>>.broadcast();
  Stream<List<RouteModel>> get routesUpdatesStream => _routesUpdatesController.stream;

  final _alertsUpdatesController = StreamController<List<NotificationModel>>.broadcast();
  Stream<List<NotificationModel>> get alertsUpdatesStream => _alertsUpdatesController.stream;

  final _specialShuttlesController = StreamController<List<SpecialShuttleModel>>.broadcast();
  Stream<List<SpecialShuttleModel>> get specialShuttlesStream => _specialShuttlesController.stream;

  bool _isListening = false;
  String? _lastRoutesJsonHash;
  List<RouteModel>? _cachedRoutesList;

  /// Update the Firebase Realtime Database endpoint at runtime if needed
  static void setDatabaseUrl(String newUrl) {
    databaseUrl = newUrl.trim();
  }

  /// Driver broadcasts live GPS location & telemetry to Firebase Realtime Database
  Future<bool> publishDriverLocation({
    required String busId,
    required LatLng location,
    required double speed,
    required String nextStop,
    required String occupancy,
    required bool isLive,
    int? etaMinutes,
  }) async {
    try {
      final endpoint = Uri.parse('$resolvedUrl/live_buses/$busId.json');
      final payload = {
        'bus_id': busId,
        'is_live': isLive,
        'status': isLive ? 'onRoute' : 'stopped',
        'latitude': location.latitude,
        'longitude': location.longitude,
        'speed': speed,
        'next_stop': nextStop,
        'occupancy': occupancy,
        'distance_km': double.parse((const Distance()(location, const LatLng(32.362339, 74.208769)) / 1000.0).toStringAsFixed(1)),
        'eta_minutes': etaMinutes ?? (isLive ? 10 : 0),
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      };

      final response = await _client
          .patch(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print('Firebase RTDB published: $busId -> ${location.latitude}, ${location.longitude}');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase RTDB non-blocking notice: $e');
      }
      return false;
    }
  }

  /// Read snapshot of all live buses from Firebase
  Future<Map<String, dynamic>?> fetchAllLiveBusesFromFirebase() async {
    try {
      final endpoint = Uri.parse('$resolvedUrl/live_buses.json');
      final response = await _client.get(endpoint).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body != 'null') {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Read snapshot of all routes from Firebase (with road snapped polylines and smart memory caching)
  Future<List<RouteModel>?> fetchRoutesFromFirebase({bool forceRefresh = false}) async {
    try {
      final endpoint = Uri.parse('$resolvedUrl/routes.json');
      final response = await _client.get(endpoint).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body != 'null') {
        // Bandwidth & CPU Optimizer: Return cached routes if server payload hasn't changed
        if (!forceRefresh && _cachedRoutesList != null && _lastRoutesJsonHash == response.body) {
          return _cachedRoutesList;
        }

        final decoded = jsonDecode(response.body);
        final List<RouteModel> parsedRoutes = [];

        if (decoded is Map) {
          for (final entry in decoded.entries) {
            if (entry.value is Map) {
              final rMap = Map<String, dynamic>.from(entry.value as Map);
              if (!rMap.containsKey('id') || rMap['id'] == null) {
                rMap['id'] = entry.key;
              }
              final route = RouteModel.fromJson(rMap);
              parsedRoutes.add(route);
            }
          }
        } else if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              parsedRoutes.add(RouteModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }

        if (parsedRoutes.isNotEmpty) {
          // Verify and fill polylines for routes if needed
          final List<RouteModel> completeRoutes = [];
          for (final r in parsedRoutes) {
            if (r.polylinePoints.isEmpty && r.stops.length >= 2) {
              final roadPoints = await RouteGeometryService.fetchRoadPolyline(
                routeId: r.id,
                waypoints: r.stops.map((s) => s.location).toList(),
              );
              completeRoutes.add(r.copyWith(polylinePoints: roadPoints));
            } else {
              completeRoutes.add(r);
            }
          }
          _lastRoutesJsonHash = response.body;
          _cachedRoutesList = completeRoutes;
          return completeRoutes;
        }
      }
      return _cachedRoutesList;
    } catch (_) {
      return _cachedRoutesList;
    }
  }

  /// Read snapshot of all broadcast alerts from Firebase
  Future<List<NotificationModel>?> fetchAlertsFromFirebase() async {
    try {
      final endpoint = Uri.parse('$resolvedUrl/alerts.json');
      final response = await _client.get(endpoint).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 && response.body != 'null') {
        final decoded = jsonDecode(response.body);
        final List<NotificationModel> parsedAlerts = [];

        if (decoded is Map) {
          for (final entry in decoded.entries) {
            if (entry.value is Map) {
              final aMap = Map<String, dynamic>.from(entry.value as Map);
              if (!aMap.containsKey('id') || aMap['id'] == null) {
                aMap['id'] = entry.key;
              }
              parsedAlerts.add(NotificationModel.fromJson(aMap));
            }
          }
        } else if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              parsedAlerts.add(NotificationModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }

        // Sort latest alerts first
        parsedAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return parsedAlerts;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Read snapshot of all special shuttles from Firebase
  Future<List<SpecialShuttleModel>?> fetchSpecialShuttlesFromFirebase() async {
    try {
      final endpoint = Uri.parse('$resolvedUrl/special_shuttles.json');
      final response = await _client.get(endpoint).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 && response.body != 'null') {
        final decoded = jsonDecode(response.body);
        final parsedShuttles = _parseSpecialShuttlesList(decoded);
        debugPrint('[SpecialShuttles] Synced ${parsedShuttles.length} shuttles from Firebase');
        return parsedShuttles;
      }

      // If /special_shuttles gets 401 (rules not published yet), fallback to /alerts node (which is active in rules)
      if (response.statusCode == 401 || response.statusCode == 403 || response.body == 'null') {
        final backupEndpoint = Uri.parse('$resolvedUrl/alerts.json');
        final backupResponse = await _client.get(backupEndpoint).timeout(const Duration(seconds: 8));

        if (backupResponse.statusCode == 200 && backupResponse.body != 'null') {
          final decoded = jsonDecode(backupResponse.body);
          final List<SpecialShuttleModel> fallbackList = [];
          if (decoded is Map) {
            for (final entry in decoded.entries) {
              if (entry.value is Map) {
                final map = Map<String, dynamic>.from(entry.value as Map);
                final bool isSpec = map['is_special_shuttle'] == true ||
                    map['isSpecial'] == true ||
                    map['type'] == 'special_shuttle' ||
                    map['id']?.toString().startsWith('spec_') == true ||
                    entry.key.toString().startsWith('spec_');
                if (isSpec) {
                  if (!map.containsKey('id') || map['id'] == null) {
                    map['id'] = entry.key;
                  }
                  fallbackList.add(SpecialShuttleModel.fromJson(map));
                }
              }
            }
          }
          if (fallbackList.isNotEmpty) {
            debugPrint('[SpecialShuttles] Synced ${fallbackList.length} shuttles from alerts fallback');
            return fallbackList;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('[SpecialShuttles] Network exception: $e');
      return null;
    }
  }

  List<SpecialShuttleModel> _parseSpecialShuttlesList(dynamic decoded) {
    final List<SpecialShuttleModel> list = [];
    if (decoded is Map) {
      for (final entry in decoded.entries) {
        if (entry.value is Map) {
          final sMap = Map<String, dynamic>.from(entry.value as Map);
          if (!sMap.containsKey('id') || sMap['id'] == null) {
            sMap['id'] = entry.key;
          }
          list.add(SpecialShuttleModel.fromJson(sMap));
        }
      }
    } else if (decoded is List) {
      for (final item in decoded) {
        if (item is Map) {
          list.add(SpecialShuttleModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return list;
  }

  /// Start periodic background polling stream for real-time synchronization
  void startListening({Duration interval = const Duration(seconds: 4)}) {
    if (_isListening) return;
    _isListening = true;

    // Immediate initial sync upon startup (routes, buses, alerts, shuttles)
    _syncOnce();

    _pollingTimer?.cancel();
    int tickCounter = 0;
    _pollingTimer = Timer.periodic(interval, (_) async {
      tickCounter++;

      // 1. Live buses polled every 4s (ensures real-time speed & smooth position updates)
      final liveData = await fetchAllLiveBusesFromFirebase();
      if (liveData != null && !_liveUpdatesController.isClosed) {
        _liveUpdatesController.add(liveData);
      }

      // 2. Broadcast Alerts & Special Shuttles polled every 20s (every 5th tick)
      // Highly responsive for campus announcements without burning quota
      if (tickCounter % 5 == 0) {
        final alertsData = await fetchAlertsFromFirebase();
        if (alertsData != null && !_alertsUpdatesController.isClosed) {
          _alertsUpdatesController.add(alertsData);
        }

        final specialData = await fetchSpecialShuttlesFromFirebase();
        if (specialData != null && !_specialShuttlesController.isClosed) {
          _specialShuttlesController.add(specialData);
        }
      }

      // 3. Heavy Route Polylines polled every 2 minutes (every 30th tick)
      // Routes are static geometry; initial fetch is already completed at startup.
      // This saves 95% of bandwidth for hundreds of concurrent students!
      if (tickCounter % 30 == 0) {
        final routesData = await fetchRoutesFromFirebase();
        if (routesData != null && !_routesUpdatesController.isClosed) {
          _routesUpdatesController.add(routesData);
        }
      }
    });
  }

  void _syncOnce() {
    fetchAllLiveBusesFromFirebase().then((liveData) {
      if (liveData != null && !_liveUpdatesController.isClosed) {
        _liveUpdatesController.add(liveData);
      }
    });

    fetchRoutesFromFirebase().then((routesData) {
      if (routesData != null && !_routesUpdatesController.isClosed) {
        _routesUpdatesController.add(routesData);
      }
    });

    fetchAlertsFromFirebase().then((alertsData) {
      if (alertsData != null && !_alertsUpdatesController.isClosed) {
        _alertsUpdatesController.add(alertsData);
      }
    });

    fetchSpecialShuttlesFromFirebase().then((specialData) {
      if (specialData != null && !_specialShuttlesController.isClosed) {
        _specialShuttlesController.add(specialData);
      }
    });
  }

  void stopListening() {
    _isListening = false;
    _pollingTimer?.cancel();
  }

  void dispose() {
    stopListening();
    _liveUpdatesController.close();
    _routesUpdatesController.close();
    _alertsUpdatesController.close();
  }

  /// Merge Firebase live telemetry snapshot into an existing BusModel
  static BusModel mergeFirebaseData(BusModel bus, Map<String, dynamic> data) {
    try {
      final isLive = (data['is_live'] == true) || (data['status'] == 'onRoute');
      final lat = (data['latitude'] as num?)?.toDouble() ?? (data['lat'] as num?)?.toDouble() ?? bus.location.latitude;
      final lng = (data['longitude'] as num?)?.toDouble() ?? (data['lng'] as num?)?.toDouble() ?? bus.location.longitude;
      final speed = (data['speed'] as num?)?.toDouble() ?? (isLive ? bus.speed : 0.0);
      final nextStop = data['next_stop'] as String? ?? (data['nextStop'] as String?) ?? bus.nextStop;
      final occupancy = data['occupancy'] as String? ?? bus.occupancy;
      final distanceKm = (data['distance_km'] as num?)?.toDouble() ??
          double.parse((const Distance()(LatLng(lat, lng), const LatLng(32.362339, 74.208769)) / 1000.0).toStringAsFixed(1));
      
      int rawEta = (data['eta_minutes'] as num?)?.toInt() ?? (data['etaMinutes'] as num?)?.toInt() ?? (isLive ? bus.etaMinutes : 0);
      if (isLive && rawEta <= 0) {
        rawEta = (distanceKm / 35.0 * 60).round().clamp(2, 90);
      }

      // Synchronize Route Assignment & Bus Identity from Firebase (ignoring special ephemeral route titles)
      final rawRouteName = (data['route_name'] as String?) ?? (data['routeName'] as String?) ?? bus.routeName;
      final routeName = rawRouteName.contains('➔') ? bus.routeName : rawRouteName;
      final routeId = (data['route_id'] as String?) ?? (data['routeId'] as String?) ?? bus.routeId;
      final name = (data['name'] as String?) ?? bus.name;
      final driverName = (data['driver_name'] as String?) ?? (data['driverName'] as String?) ?? bus.driver.name;
      final driverPhone = (data['driver_phone'] as String?) ?? (data['driverPhone'] as String?) ?? bus.driver.phone;

      return bus.copyWith(
        name: name,
        routeId: routeId,
        routeName: routeName,
        driver: bus.driver.copyWith(name: driverName, phone: driverPhone),
        status: isLive ? BusStatusType.onRoute : BusStatusType.stopped,
        location: LatLng(lat, lng),
        speed: speed,
        nextStop: nextStop.contains('➔') ? bus.nextStop : nextStop,
        occupancy: occupancy,
        distanceKm: distanceKm,
        etaMinutes: rawEta,
        isSpecial: false,
        lastUpdated: DateTime.now(),
      );
    } catch (_) {
      return bus;
    }
  }
}
