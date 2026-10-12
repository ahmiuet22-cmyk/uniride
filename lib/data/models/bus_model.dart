import 'package:latlong2/latlong.dart';
import '../../shared/widgets/status_badge.dart';
import 'driver_model.dart';

class BusModel {
  final String id;
  final String name;
  final String routeName;
  final String routeId;
  final DriverModel driver;
  final BusStatusType status;
  final double speed; // km/h
  final int etaMinutes;
  final String nextStop;
  final double distanceKm;
  final LatLng location;
  final double heading; // 0 to 360 degrees
  final int currentStopIndex;
  final int totalStops;
  final String occupancy;
  final DateTime lastUpdated;
  final bool isSpecial;
  final String? specialPurpose;
  final String? specialOrigin;
  final String? specialDestination;
  final double? specialOriginLat;
  final double? specialOriginLng;
  final double? specialDestinationLat;
  final double? specialDestinationLng;
  final String? specialEndTime;

  const BusModel({
    required this.id,
    required this.name,
    required this.routeName,
    required this.routeId,
    required this.driver,
    required this.status,
    required this.speed,
    required this.etaMinutes,
    required this.nextStop,
    required this.distanceKm,
    required this.location,
    this.heading = 0.0,
    this.currentStopIndex = 0,
    this.totalStops = 7,
    this.occupancy = '65% Full',
    required this.lastUpdated,
    this.isSpecial = false,
    this.specialPurpose,
    this.specialOrigin,
    this.specialDestination,
    this.specialOriginLat,
    this.specialOriginLng,
    this.specialDestinationLat,
    this.specialDestinationLng,
    this.specialEndTime,
  });

  BusModel copyWith({
    String? id,
    String? name,
    String? routeName,
    String? routeId,
    DriverModel? driver,
    BusStatusType? status,
    double? speed,
    int? etaMinutes,
    String? nextStop,
    double? distanceKm,
    LatLng? location,
    double? heading,
    int? currentStopIndex,
    int? totalStops,
    String? occupancy,
    DateTime? lastUpdated,
    bool? isSpecial,
    String? specialPurpose,
    String? specialOrigin,
    String? specialDestination,
    double? specialOriginLat,
    double? specialOriginLng,
    double? specialDestinationLat,
    double? specialDestinationLng,
    String? specialEndTime,
  }) {
    return BusModel(
      id: id ?? this.id,
      name: name ?? this.name,
      routeName: routeName ?? this.routeName,
      routeId: routeId ?? this.routeId,
      driver: driver ?? this.driver,
      status: status ?? this.status,
      speed: speed ?? this.speed,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      nextStop: nextStop ?? this.nextStop,
      distanceKm: distanceKm ?? this.distanceKm,
      location: location ?? this.location,
      heading: heading ?? this.heading,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      totalStops: totalStops ?? this.totalStops,
      occupancy: occupancy ?? this.occupancy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSpecial: isSpecial ?? this.isSpecial,
      specialPurpose: specialPurpose ?? this.specialPurpose,
      specialOrigin: specialOrigin ?? this.specialOrigin,
      specialDestination: specialDestination ?? this.specialDestination,
      specialOriginLat: specialOriginLat ?? this.specialOriginLat,
      specialOriginLng: specialOriginLng ?? this.specialOriginLng,
      specialDestinationLat: specialDestinationLat ?? this.specialDestinationLat,
      specialDestinationLng: specialDestinationLng ?? this.specialDestinationLng,
      specialEndTime: specialEndTime ?? this.specialEndTime,
    );
  }
}
