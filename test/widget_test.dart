import 'package:flutter_test/flutter_test.dart';
import 'package:uniride/core/constants/app_strings.dart';
import 'package:uniride/data/mock/mock_buses.dart';
import 'package:uniride/data/mock/mock_routes.dart';
import 'package:uniride/data/mock/mock_stops.dart';
import 'package:uniride/data/repositories/bus_repository.dart';
import 'package:uniride/data/services/live_tracking_service.dart';
import 'package:uniride/providers/bus_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UET Gujranwala RCET Routes & Architecture Tests', () {
    test('Mock data is properly populated with official RCET routes and buses', () {
      expect(MockBuses.allBuses.length, equals(5));
      expect(MockRoutes.allRoutes.length, equals(5));
      expect(MockStops.allStops.length, greaterThanOrEqualTo(25));

      final mainBus = MockBuses.allBuses.firstWhere((b) => b.id == 'bus_gau_2555');
      expect(mainBus.name, 'GAU-2555');
      expect(mainBus.routeName, contains('Route 1'));
      expect(mainBus.driver.name, 'Muhammad Ali');

      // Check Route 5 Cantt
      final route5 = MockRoutes.allRoutes.firstWhere((r) => r.id == 'route_5');
      expect(route5.code, 'Route 5');
      expect(route5.title, contains('Cantt'));
    });

    test('LiveTrackingService initializes and emits snapshots for GAU-2555', () async {
      final service = LiveTrackingService();
      final initialSnapshot = service.getCurrentBusesSnapshot();

      expect(initialSnapshot.isNotEmpty, true);
      expect(initialSnapshot.first.name, 'GAU-2555');

      service.dispose();
    });

    test('BusRepository and BusProvider initialize correctly with RCET fleet', () async {
      final service = LiveTrackingService();
      final repository = BusRepository(liveTrackingService: service);
      final provider = BusProvider(repository: repository);

      expect(provider.isLoading, true);
      await Future.delayed(const Duration(milliseconds: 500));

      expect(provider.buses.isNotEmpty, true);
      expect(provider.mainLiveBus?.name, 'GAU-2555');
      expect(provider.routes.length, equals(5));

      provider.dispose();
    });

    test('App strings constants adhere to UniRide branding', () {
      expect(AppStrings.appName, 'UniRide');
      expect(AppStrings.appTagline, 'Your campus. Your route. Your time.');
    });
  });
}
