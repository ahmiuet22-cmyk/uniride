import '../models/bus_model.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';

class TripSearchResult {
  final RouteModel route;
  final BusStopModel pickupStop;
  final BusStopModel destinationStop;
  final List<BusStopModel> intermediateStops;
  final int stopsCount;
  final int estimatedMinutes;
  final BusModel? activeBus;
  final bool isDirect;
  final String? transferAt;

  const TripSearchResult({
    required this.route,
    required this.pickupStop,
    required this.destinationStop,
    required this.intermediateStops,
    required this.stopsCount,
    required this.estimatedMinutes,
    this.activeBus,
    this.isDirect = true,
    this.transferAt,
  });
}

class RouteFinderService {
  /// Finds all available bus trips from pickupStop to destinationStop
  static List<TripSearchResult> findTrips({
    required String pickupStopId,
    required String destinationStopId,
    required List<RouteModel> routes,
    required List<BusModel> buses,
  }) {
    final List<TripSearchResult> results = [];

    if (pickupStopId == destinationStopId) {
      return results;
    }

    // 1. Check for direct routes where pickup comes before destination
    for (final route in routes) {
      final pickupIndex = route.stops.indexWhere((s) => s.id == pickupStopId);
      final destIndex = route.stops.indexWhere((s) => s.id == destinationStopId);

      if (pickupIndex != -1 && destIndex != -1 && pickupIndex < destIndex) {
        final pickupStop = route.stops[pickupIndex];
        final destStop = route.stops[destIndex];
        final intermediate = route.stops.sublist(pickupIndex + 1, destIndex);

        // Calculate proportional travel time based on total stops in route
        final int totalStops = route.stops.length;
        final int journeyStops = destIndex - pickupIndex;
        final int estMinutes = ((journeyStops / (totalStops > 0 ? totalStops : 1)) *
                route.estimatedDurationMinutes)
            .round()
            .clamp(5, 120);

        // Find assigned active bus on this route
        BusModel? assignedBus;
        try {
          assignedBus = buses.firstWhere(
            (b) => b.routeId == route.id || b.name.toLowerCase().contains(route.code.toLowerCase()),
          );
        } catch (_) {
          assignedBus = null;
        }

        results.add(
          TripSearchResult(
            route: route,
            pickupStop: pickupStop,
            destinationStop: destStop,
            intermediateStops: intermediate,
            stopsCount: journeyStops,
            estimatedMinutes: estMinutes,
            activeBus: assignedBus,
            isDirect: true,
          ),
        );
      }
    }

    // Sort direct routes: active buses first, then least stops
    results.sort((a, b) {
      if (a.activeBus != null && b.activeBus == null) return -1;
      if (a.activeBus == null && b.activeBus != null) return 1;
      return a.stopsCount.compareTo(b.stopsCount);
    });

    return results;
  }
}
