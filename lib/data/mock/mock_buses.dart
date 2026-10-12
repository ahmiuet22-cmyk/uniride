import 'package:latlong2/latlong.dart';
import '../../shared/widgets/status_badge.dart';
import '../models/bus_model.dart';
import '../models/driver_model.dart';

class MockBuses {
  static final List<BusModel> allBuses = [
    // Route No. 1 Bus - Hino Bus GAU-2555 (Standby at Terminal)
    BusModel(
      id: 'bus_gau_2555',
      name: 'GAU-2555',
      routeName: 'Route No. 1 - Chanda Qila/Wapda Town',
      routeId: 'route_1',
      driver: const DriverModel(
        id: 'drv_01',
        name: 'Muhammad Ali',
        phone: '+92 300 1234567',
        rating: 4.9,
      ),
      status: BusStatusType.stopped,
      speed: 0.0,
      etaMinutes: 0,
      nextStop: 'Standby at Chanda Qila',
      distanceKm: 0.0,
      location: const LatLng(32.0950, 74.1985), // Chanda Qila Terminal Start
      heading: 0.0,
      currentStopIndex: 0,
      totalStops: 9,
      occupancy: 'Standby',
      lastUpdated: DateTime.now(),
    ),

    // Route No. 2 Bus - Hino Bus LEJ-6832
    BusModel(
      id: 'bus_lej_6832',
      name: 'LEJ-6832',
      routeName: 'Route No. 2 - Sheikhupura Mor via Sialkot Road',
      routeId: 'route_2',
      driver: const DriverModel(
        id: 'drv_02',
        name: 'Tariq Mehmood',
        phone: '+92 301 9876543',
        rating: 4.8,
      ),
      status: BusStatusType.stopped,
      speed: 0.0,
      etaMinutes: 0,
      nextStop: 'Sheikhupura Mor',
      distanceKm: 0.0,
      location: const LatLng(32.1494, 74.1895), // Sheikhupura Mor Start
      heading: 0.0,
      currentStopIndex: 0,
      totalStops: 15,
      occupancy: 'Standby',
      lastUpdated: DateTime.now(),
    ),

    // Route No. 3 Bus - Hino Bus GAX-4555
    BusModel(
      id: 'bus_gax_4555',
      name: 'GAX-4555',
      routeName: 'Route No. 3 - Sheikhupura Mor via Lari Adda',
      routeId: 'route_3',
      driver: const DriverModel(
        id: 'drv_03',
        name: 'Zubair Khan',
        phone: '+92 333 4567890',
        rating: 4.7,
      ),
      status: BusStatusType.stopped,
      speed: 0.0,
      etaMinutes: 0,
      nextStop: 'Sheikhupura Mor',
      distanceKm: 0.0,
      location: const LatLng(32.1494, 74.1895), // Sheikhupura Mor Start
      heading: 0.0,
      currentStopIndex: 0,
      totalStops: 12,
      occupancy: 'Standby',
      lastUpdated: DateTime.now(),
    ),

    // Route No. 4 Bus - Hino Bus LWN-3033
    BusModel(
      id: 'bus_lwn_3033',
      name: 'LWN-3033',
      routeName: 'Route No. 4 - Pindi Bypass',
      routeId: 'route_4',
      driver: const DriverModel(
        id: 'drv_04',
        name: 'Imran Hashmi',
        phone: '+92 345 5678901',
        rating: 4.9,
      ),
      status: BusStatusType.stopped,
      speed: 0.0,
      etaMinutes: 0,
      nextStop: 'Pindi Bypass',
      distanceKm: 0.0,
      location: const LatLng(32.2030, 74.1750), // Pindi Bypass Start
      heading: 0.0,
      currentStopIndex: 0,
      totalStops: 7,
      occupancy: 'Standby',
      lastUpdated: DateTime.now(),
    ),

    // Route No. 5 Bus - Hino Mini-Bus LEA-6834
    BusModel(
      id: 'bus_lea_6834',
      name: 'LEA-6834',
      routeName: 'Route No. 5 - Gujranwala Cantt',
      routeId: 'route_5',
      driver: const DriverModel(
        id: 'drv_05',
        name: 'Asif Butt',
        phone: '+92 321 7654321',
        rating: 4.8,
      ),
      status: BusStatusType.stopped,
      speed: 0.0,
      etaMinutes: 0,
      nextStop: 'Cantt Check Post',
      distanceKm: 0.0,
      location: const LatLng(32.2451, 74.1637), // Check Post Start
      heading: 0.0,
      currentStopIndex: 0,
      totalStops: 7,
      occupancy: 'Standby',
      lastUpdated: DateTime.now(),
    ),
  ];
}
