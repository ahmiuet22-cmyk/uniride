import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/bus_repository.dart';
import 'data/services/live_tracking_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/buses/screens/bus_details_screen.dart';
import 'features/driver/screens/driver_dashboard_screen.dart';
import 'features/map/screens/live_map_screen.dart';
import 'features/navigation/screens/main_navigation_scaffold.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/routes/screens/route_details_screen.dart';
import 'features/routes/screens/route_finder_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/stops/screens/stop_details_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/bus_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('ViewInsets cannot be negative') ||
        details.exceptionAsString().contains('window.dart')) {
      return; // Ignore Flutter Web browser resize physical size assertion
    }
    FlutterError.presentError(details);
  };

  final liveTrackingService = LiveTrackingService();
  final busRepository = BusRepository(liveTrackingService: liveTrackingService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(
          create: (_) => BusProvider(repository: busRepository),
        ),
      ],
      child: const UniRideApp(),
    ),
  );
}

class UniRideApp extends StatelessWidget {
  const UniRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.mainScaffold: (context) => const MainNavigationScaffold(),
        AppRoutes.busDetails: (context) => const BusDetailsScreen(),
        AppRoutes.routeDetails: (context) => const RouteDetailsScreen(),
        AppRoutes.stopDetails: (context) => const StopDetailsScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
        AppRoutes.routeFinder: (context) => const RouteFinderScreen(),
        AppRoutes.driverDashboard: (context) => const DriverDashboardScreen(),
        AppRoutes.liveMap: (context) => const LiveMapScreen(),
      },
    );
  }
}
