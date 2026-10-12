import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../mock/route_road_polylines.dart';

class RouteGeometryService {
  static final http.Client _client = http.Client();
  static final Map<String, List<LatLng>> _cache = {};

  /// Preloaded road polylines mapped by route id
  static List<LatLng>? getPreloadedPolyline(String routeId) {
    switch (routeId.toLowerCase().trim()) {
      case 'route_1':
      case 'route 1':
      case '1':
        return RouteRoadPolylines.route1Points;
      case 'route_2':
      case 'route 2':
      case '2':
        return RouteRoadPolylines.route2Points;
      case 'route_3':
      case 'route 3':
      case '3':
        return RouteRoadPolylines.route3Points;
      case 'route_4':
      case 'route 4':
      case '4':
        return RouteRoadPolylines.route4Points;
      case 'route_5':
      case 'route 5':
      case '5':
        return RouteRoadPolylines.route5Points;
      default:
        return null;
    }
  }

  static List<LatLng> getFallbackPolyline(String routeId, [List<LatLng>? waypoints]) {
    final preloaded = getPreloadedPolyline(routeId);
    if (preloaded != null && preloaded.isNotEmpty) {
      return preloaded;
    }
    if (waypoints != null && waypoints.isNotEmpty) {
      return waypoints;
    }
    return RouteRoadPolylines.route1Points;
  }

  /// Fetches real road turn-by-turn polyline points from OpenStreetMap OSRM routing engine.
  /// Falls back instantly to high-precision pre-calculated road polylines or route waypoints.
  static Future<List<LatLng>> fetchRoadPolyline({
    required String routeId,
    required List<LatLng> waypoints,
  }) async {
    if (_cache.containsKey(routeId)) {
      return _cache[routeId]!;
    }

    // 1. Instant match for default university routes (no external HTTP latency)
    final preloaded = getPreloadedPolyline(routeId);
    if (preloaded != null && preloaded.isNotEmpty) {
      _cache[routeId] = preloaded;
      return preloaded;
    }

    if (waypoints.length < 2) {
      final fallback = getFallbackPolyline(routeId, waypoints);
      _cache[routeId] = fallback;
      return fallback;
    }

    // 2. Dynamic turn-by-turn routing for newly added custom routes
    try {
      final coordsParam = waypoints
          .map((p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}')
          .join(';');

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordsParam?overview=full&geometries=geojson',
      );

      final response = await _client.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {
          final coordinates =
              data['routes'][0]['geometry']['coordinates'] as List;

          final roadPoints = coordinates.map((c) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();

          if (roadPoints.isNotEmpty) {
            _cache[routeId] = roadPoints;
            return roadPoints;
          }
        }
      }
    } catch (_) {
      // Non-blocking smooth fallback to waypoints
    }

    // Fallback directly to route waypoints
    final fallback = getFallbackPolyline(routeId, waypoints);
    _cache[routeId] = fallback;
    return fallback;
  }
}
