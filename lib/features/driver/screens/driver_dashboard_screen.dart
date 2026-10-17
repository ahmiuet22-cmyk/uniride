import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/bus_model.dart';
import '../../../data/models/driver_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/route_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bus_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/widgets/status_badge.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLocationOn = false;
  Timer? _tripTimer;
  StreamSubscription<Position>? _positionSubscription;
  int _tripSeconds = 0;
  String _currentNextStop = 'Initial Stop';
  int _currentStopIndex = 0;
  LatLng? _deviceGpsLocation;
  double _currentSpeed = 0.0;
  double _smoothedSpeed = 0.0;
  int _stationaryTickCount = 0;
  bool _isGpsConnecting = false;
  DateTime? _lastGpsTime;
  Position? _lastGpsPosition;
  bool _isAtCurrentStop = false;
  double _distToTargetStopMeters = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDriverState();
    });
  }

  void _initDriverState() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final busProvider = Provider.of<BusProvider>(context, listen: false);
    final busId = auth.driverAssignedBusId ?? 'bus_gau_2555';
    final bus = busProvider.getBusById(busId) ?? busProvider.mainLiveBus;

    if (bus != null) {
      final route = busProvider.getRouteForBus(bus);
      final initialStop = (route != null && route.stops.isNotEmpty)
          ? route.stops.first.name
          : (bus.nextStop.isNotEmpty ? bus.nextStop : 'Starting Stop');

      setState(() {
        _isLocationOn = bus.status == BusStatusType.onRoute;
        _currentNextStop = (bus.nextStop.isNotEmpty && bus.nextStop != 'Terminal Standby')
            ? bus.nextStop
            : initialStop;
        _currentStopIndex = bus.currentStopIndex;
        _deviceGpsLocation = bus.location;
        if (_isLocationOn) {
          _startLiveTracking(bus);
        }
      });
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _tripTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startLiveTracking(BusModel bus) async {
    // 1. Immediate broadcast upon turning ON (defaults to 0.0 until driver physically moves)
    final busProvider = Provider.of<BusProvider>(context, listen: false);
    busProvider.updateDriverBusStatus(
      busId: bus.id,
      isLive: true,
      location: _deviceGpsLocation ?? bus.location,
      speed: _currentSpeed,
      nextStop: _currentNextStop,
    );

    // 2. Periodic background synchronization to Firebase (every 3 seconds)
    _tripTimer?.cancel();
    _tripTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isLocationOn) {
        setState(() {
          _tripSeconds++;
        });

        // Sync live telemetry to Firebase every 3 seconds
        if (_tripSeconds % 3 == 0) {
          final bp = Provider.of<BusProvider>(context, listen: false);
          bp.updateDriverBusStatus(
            busId: bus.id,
            isLive: true,
            location: _deviceGpsLocation ?? bus.location,
            speed: _currentSpeed,
            nextStop: _currentNextStop,
          );
        }
      }
    });

    // 3. Request actual device GPS permissions and listen to real movement
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (serviceEnabled &&
          (permission == LocationPermission.whileInUse || permission == LocationPermission.always)) {
        // Initial current position
        try {
          final initialPos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation,
            timeLimit: const Duration(seconds: 4),
          );
          if (mounted) {
            setState(() {
              _deviceGpsLocation = LatLng(initialPos.latitude, initialPos.longitude);
              _lastGpsPosition = initialPos;
              _lastGpsTime = DateTime.now();
              _smoothedSpeed = initialPos.speed > 0.9 ? (initialPos.speed * 3.6).clamp(0.0, 85.0) : 0.0;
              _currentSpeed = double.parse(_smoothedSpeed.toStringAsFixed(1));
            });
          }
        } catch (_) {}

        // Platform-specific high-frequency GPS stream for vehicle navigation
        final LocationSettings locationSettings;
        if (defaultTargetPlatform == TargetPlatform.android) {
          locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 2, // 2-meter filter rejects idle phone drift while capturing real motion
            intervalDuration: const Duration(milliseconds: 1000), // 1 second update
            forceLocationManager: false,
          );
        } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
          locationSettings = AppleSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 2,
            pauseLocationUpdatesAutomatically: false,
            activityType: ActivityType.automotiveNavigation,
          );
        } else {
          locationSettings = const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 2,
          );
        }

        // Continuous device movement stream
        _positionSubscription?.cancel();
        _positionSubscription = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position pos) {
          if (mounted && _isLocationOn) {
            final now = DateTime.now();
            final double elapsedSec = _lastGpsTime != null
                ? (now.difference(_lastGpsTime!).inMilliseconds / 1000.0).clamp(0.2, 5.0)
                : 1.0;

            double rawCandidateSpeed = 0.0;
            bool hasMotion = false;

            // Compute distance from last fix
            double distMeters = 0.0;
            if (_lastGpsPosition != null) {
              distMeters = Geolocator.distanceBetween(
                _lastGpsPosition!.latitude,
                _lastGpsPosition!.longitude,
                pos.latitude,
                pos.longitude,
              );
            }

            // 1. Accuracy Check (Ignore degraded fixes with accuracy > 25m)
            final bool isAccurate = pos.accuracy <= 25.0;

            // 2. Hardware Doppler Speed directly from phone GPS chip (with Vehicle Deadband)
            // Mobile GPS sensors exhibit 0.2 - 0.7 m/s drift while parked.
            // Minimum authentic vehicle rolling speed is >= 0.9 m/s (~3.2 km/h).
            if (isAccurate && pos.speed >= 0.9) {
              rawCandidateSpeed = pos.speed * 3.6; // convert m/s to km/h
              hasMotion = true;
            } 
            // 3. Delta distance fallback ONLY if hardware speed sensor is uncalibrated/unsupported (pos.speed <= 0.2)
            // and authentic vehicle translation is verified (> 3.5m in >= 0.9s)
            else if (isAccurate && pos.speed <= 0.2 && distMeters >= 3.5 && elapsedSec >= 0.9) {
              final deltaSpeed = (distMeters / elapsedSec) * 3.6;
              if (deltaSpeed >= 3.5) {
                rawCandidateSpeed = deltaSpeed;
                hasMotion = true;
              }
            }

            // 4. Standstill / Stop Detection (Rejects stationary GPS jitter at stops and red lights)
            if (!hasMotion || rawCandidateSpeed < 3.0 || (distMeters < 2.2 && pos.speed < 0.9)) {
              rawCandidateSpeed = 0.0;
              _stationaryTickCount++;
            } else {
              _stationaryTickCount = 0;
            }

            // Clamp GPS anomaly spikes (university bus won't exceed 85 km/h)
            rawCandidateSpeed = rawCandidateSpeed.clamp(0.0, 85.0);

            // 5. Asymmetric Physical Rate Limiting & Inertia
            // City bus normal acceleration ~ 8 km/h/s, braking ~ 18 km/h/s
            final maxAccel = 8.0 * elapsedSec;
            final maxDecel = 18.0 * elapsedSec;

            double targetSpeed = rawCandidateSpeed;
            if (targetSpeed > _smoothedSpeed + maxAccel) {
              targetSpeed = _smoothedSpeed + maxAccel;
            } else if (targetSpeed < _smoothedSpeed - maxDecel && _stationaryTickCount == 0) {
              targetSpeed = _smoothedSpeed - maxDecel;
            }

            // 6. Asymmetric EMA Smoothing (Fast Brake Response + Silky Acceleration + Instant Stop)
            if (_stationaryTickCount >= 1 || (targetSpeed == 0.0 && _smoothedSpeed < 4.0)) {
              // Instant snap to 0.0 when bus stops (eliminates the 5-second crawling deceleration lag)
              _smoothedSpeed = 0.0;
            } else {
              // When braking: use fast alpha (0.70) so speedometer tracks the brake pedal
              // When accelerating: use smooth alpha (0.35) for a silky rising gauge
              final double alpha = (targetSpeed < _smoothedSpeed) ? 0.70 : 0.35;
              _smoothedSpeed = (_smoothedSpeed * (1.0 - alpha)) + (targetSpeed * alpha);
            }

            // Clean deadband below walking crawl
            if (_smoothedSpeed < 2.0) {
              _smoothedSpeed = 0.0;
            }

            final freshLocation = LatLng(pos.latitude, pos.longitude);
            _lastGpsPosition = pos;
            _lastGpsTime = now;
            final formattedSpeed = double.parse(_smoothedSpeed.toStringAsFixed(1));

            final busProvider = Provider.of<BusProvider>(context, listen: false);
            final route = busProvider.getRouteForBus(bus);
            if (route != null && route.stops.isNotEmpty) {
              int bestStopIndex = _currentStopIndex.clamp(0, route.stops.length - 1);
              double minDistance = double.infinity;

              // Check forward stops along the route
              for (int i = _currentStopIndex; i < route.stops.length; i++) {
                final s = route.stops[i];
                final d = Geolocator.distanceBetween(
                  pos.latitude,
                  pos.longitude,
                  s.location.latitude,
                  s.location.longitude,
                );
                if (d < minDistance) {
                  minDistance = d;
                  bestStopIndex = i;
                }
              }

              _distToTargetStopMeters = minDistance;

              // Auto-detect arrival at stop (< 140m)
              if (minDistance < 140) {
                _currentStopIndex = bestStopIndex;
                _currentNextStop = route.stops[bestStopIndex].name;
                _isAtCurrentStop = true;
              } else {
                // If bus was at this stop and now departed (> 140m away), advance to next stop
                if (_isAtCurrentStop && bestStopIndex + 1 < route.stops.length) {
                  _currentStopIndex = bestStopIndex + 1;
                  _currentNextStop = route.stops[_currentStopIndex].name;
                  _isAtCurrentStop = false;
                } else {
                  _currentStopIndex = bestStopIndex;
                  _currentNextStop = route.stops[bestStopIndex].name;
                }
              }
            }

            setState(() {
              _deviceGpsLocation = freshLocation;
              _currentSpeed = formattedSpeed;
            });

            busProvider.updateDriverBusStatus(
              busId: bus.id,
              isLive: true,
              location: freshLocation,
              speed: formattedSpeed,
              nextStop: _currentNextStop,
            );
          }
        });
      }
    } catch (_) {
      // Fallback seamlessly if desktop/emulator has no hardware GPS sensor
    }
  }

  void _stopLiveTracking(BusModel bus) {
    _positionSubscription?.cancel();
    _tripTimer?.cancel();
    setState(() {
      _tripSeconds = 0;
      _isLocationOn = false;
      _currentSpeed = 0.0;
      _smoothedSpeed = 0.0;
      _stationaryTickCount = 0;
    });

    final busProvider = Provider.of<BusProvider>(context, listen: false);
    busProvider.updateDriverBusStatus(
      busId: bus.id,
      isLive: false,
      speed: 0.0,
    );
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final hours = totalSeconds ~/ 3600;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _toggleLocation(BusModel bus) async {
    if (!_isLocationOn) {
      // Turn ON Location with loading feedback
      setState(() {
        _isGpsConnecting = true;
      });
      await _startLiveTracking(bus);
      if (mounted) {
        setState(() {
          _isGpsConnecting = false;
          _isLocationOn = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Live location sharing started for ${bus.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      // Turn OFF Location
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Turn Off Location?'),
          content: const Text(
            'Live GPS broadcast will stop and your bus will appear Off Duty to students.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _stopLiveTracking(bus);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Location turned off. Duty ended.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Turn Off'),
            ),
          ],
        ),
      );
    }
  }

  void _advanceNextStop(RouteModel route, BusModel bus) {
    if (route.stops.isEmpty) return;

    final nextIndex = (_currentStopIndex + 1) % route.stops.length;
    final nextStopName = route.stops[nextIndex].name;

    setState(() {
      _currentStopIndex = nextIndex;
      _currentNextStop = nextStopName;
    });

    if (_isLocationOn) {
      final busProvider = Provider.of<BusProvider>(context, listen: false);
      busProvider.updateDriverBusStatus(
        busId: bus.id,
        isLive: true,
        location: _deviceGpsLocation ?? bus.location,
        nextStop: nextStopName,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Next stop updated to: $nextStopName'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQuickDelayAlert(BusModel bus) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Broadcast Quick Delay Alert'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          SimpleDialogOption(
            onPressed: () => _sendAlert(ctx, 'Heavy Traffic on GT Road (10 min delay)', bus),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('🚗 Heavy Traffic (10 min delay)', style: TextStyle(fontSize: 15)),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => _sendAlert(ctx, 'Mechanical Issue / Tyre Puncture - Backup coming', bus),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('🔧 Tyre Puncture / Breakdown', style: TextStyle(fontSize: 15)),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => _sendAlert(ctx, 'Arrived at Campus - Final Stop', bus),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('🎓 Campus Reached (Trip Complete)', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  void _sendAlert(BuildContext ctx, String msg, BusModel bus) {
    Navigator.pop(ctx);
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    final notifCategory = (msg.contains('Puncture') || msg.contains('Breakdown'))
        ? NotificationCategory.emergency
        : (msg.contains('Traffic') || msg.contains('delay'))
            ? NotificationCategory.warning
            : NotificationCategory.info;

    notifProvider.addNotification(
      NotificationModel(
        id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Driver Alert • ${bus.name}',
        description: msg,
        category: notifCategory,
        timestamp: DateTime.now(),
        relatedBusId: bus.id,
        relatedRouteId: bus.routeId,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert broadcasted to students: "$msg"'),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final busProvider = Provider.of<BusProvider>(context);

    final assignedBusId = auth.driverAssignedBusId ?? 'bus_gau_2555';
    final bus = busProvider.getBusById(assignedBusId) ?? busProvider.mainLiveBus;
    final driver = auth.driver ?? bus?.driver;

    final route = busProvider.routes.firstWhere(
      (r) => r.id == bus?.routeId,
      orElse: () => busProvider.routes.isNotEmpty
          ? busProvider.routes.first
          : const RouteModel(
              id: 'route_1',
              code: 'Route 1',
              title: 'Chanda Qila / Wapda Town',
              stops: [],
              polylinePoints: [],
              estimatedDurationMinutes: 45,
              activeBusCount: 1,
            ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Clean, daylight cockpit
      drawer: _buildDriverDrawer(context, auth, driver, bus, route),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
            tooltip: 'Open Driver Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UET DRIVER CONSOLE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              driver != null ? '${driver.name} (Driver Duty)' : 'Active Driver',
              style: TextStyle(
                color: AppColors.goldAccent.withOpacity(0.95),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => _confirmLogout(context, auth, bus),
          ),
        ],
      ),
      body: bus == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Bus Identity Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [AppColors.cardShadow],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_bus_filled_rounded,
                            color: AppColors.primaryBlue,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    bus.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                  if (bus.isSpecial || bus.routeName.contains('➔') || (bus.specialPurpose != null && bus.specialPurpose!.isNotEmpty)) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.goldAccent,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '⚡ SPECIAL',
                                        style: TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                bus.routeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2. THE MAIN LOCATION ON/OFF HERO CARD
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _isLocationOn ? const Color(0xFF0F2D1F) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isLocationOn ? const Color(0xFF22C55E) : AppColors.border,
                          width: _isLocationOn ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          if (_isLocationOn)
                            BoxShadow(
                              color: const Color(0xFF22C55E).withOpacity(0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          else
                            const BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Pulsing Radar Beacon
                          ScaleTransition(
                            scale: _isLocationOn ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isLocationOn
                                    ? const Color(0xFF16A34A).withOpacity(0.2)
                                    : const Color(0xFFF1F5F9),
                                border: Border.all(
                                  color: _isLocationOn ? const Color(0xFF22C55E) : Colors.black12,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  _isLocationOn ? Icons.sensors_rounded : Icons.location_off_rounded,
                                  size: 50,
                                  color: _isLocationOn ? const Color(0xFF22C55E) : Colors.grey,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            _isLocationOn ? 'LOCATION IS ON' : 'LOCATION IS OFF',
                            style: TextStyle(
                              color: _isLocationOn ? const Color(0xFF4ADE80) : AppColors.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            _isLocationOn
                                ? 'Sharing live location (${_formatDuration(_tripSeconds)})'
                                : 'Tap below to share live location with students',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isLocationOn ? Colors.white70 : AppColors.secondaryText,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),

                          // Clean GPS Connected Tag
                          if (_isLocationOn && _deviceGpsLocation != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.gps_fixed_rounded, color: Color(0xFF4ADE80), size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'GPS Connected',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Real-Time Speedometer Cockpit HUD
                          if (_isLocationOn) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5), width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.satellite_alt_rounded, color: Color(0xFF4ADE80), size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    _currentSpeed.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'KM/H',
                                    style: TextStyle(
                                      color: Color(0xFF4ADE80),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _currentSpeed > 0 ? const Color(0xFF16A34A) : Colors.orange.shade800,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _currentSpeed > 0 ? 'LIVE GPS SPEED' : 'STATIONARY',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          // BIG TOGGLE BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isGpsConnecting
                                    ? const Color(0xFF0284C7)
                                    : (_isLocationOn ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isGpsConnecting ? null : () => _toggleLocation(bus),
                              child: _isGpsConnecting
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'LOCKING ON GPS SATELLITES...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isLocationOn ? Icons.power_settings_new_rounded : Icons.gps_fixed_rounded,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _isLocationOn ? 'TURN OFF LOCATION' : 'TURN ON LOCATION',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. ONLY 2 IMPORTANT DRIVING CONTROLS:
                  // Control A: Auto-detected Next Stop
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _isLocationOn ? const Color(0xFF86EFAC) : AppColors.border,
                        width: _isLocationOn ? 1.5 : 1.0,
                      ),
                      boxShadow: const [AppColors.cardShadow],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isLocationOn ? const Color(0xFFDCFCE7) : AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isAtCurrentStop ? Icons.where_to_vote_rounded : Icons.pin_drop_rounded,
                            color: _isLocationOn ? const Color(0xFF16A34A) : AppColors.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (_isLocationOn) ...[
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF16A34A),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'AUTO-TRACKING (GPS)',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF15803D),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ] else ...[
                                    const Text(
                                      'NEXT STOP',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.secondaryText,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _currentNextStop,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              if (_isLocationOn) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _isAtCurrentStop
                                      ? '● At stop (Boarding passengers)'
                                      : (_distToTargetStopMeters > 0 && _distToTargetStopMeters < 5000
                                          ? '● Approaching (${_distToTargetStopMeters.toStringAsFixed(0)}m away)'
                                          : '● Auto-advancing along route'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _isAtCurrentStop ? const Color(0xFF16A34A) : AppColors.secondaryText,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          onPressed: () => _advanceNextStop(route, bus),
                          child: const Text('Skip ➔', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Control B: Report Delay / Alert
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB45309),
                        side: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
                        backgroundColor: const Color(0xFFFFFBEB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.campaign_rounded, size: 22),
                      label: const Text(
                        'Report Traffic / 10 Min Delay',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      onPressed: () => _showQuickDelayAlert(bus),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth, BusModel? bus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text('Log Out Driver?'),
          ],
        ),
        content: Text(
          _isLocationOn
              ? 'Your active live tracking will be turned OFF and bus stationed in Standby.'
              : 'Are you sure you want to end your driver shift and log out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (_isLocationOn && bus != null) {
                _stopLiveTracking(bus);
              }
              final nav = Navigator.of(context);
              await auth.logout();
              nav.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            },
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverDrawer(
    BuildContext context,
    AuthProvider auth,
    DriverModel? driver,
    BusModel? bus,
    RouteModel route,
  ) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 16,
      child: Column(
        children: [
          // Drawer Header with Transport Wing branding & Driver info
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, Color(0xFF00224D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.goldBorder, width: 1.5),
                        boxShadow: const [AppColors.cardShadow],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/images/uet_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.directions_bus_rounded,
                          color: AppColors.primaryBlue,
                          size: 26,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF4ADE80), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'STAFF ON DUTY',
                            style: TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  driver?.name ?? 'Muhammad Ali',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  driver?.phone ?? '+92 300 1234567',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Assigned Bus: ${bus?.name ?? 'GAU-2555'} (${route.code})',
                    style: const TextStyle(
                      color: AppColors.goldAccent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Drawer Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Cockpit Dashboard',
                  onTap: () => Navigator.pop(context),
                  isSelected: true,
                ),
                _buildDrawerItem(
                  icon: Icons.campaign_rounded,
                  title: 'Broadcast Delay Notice',
                  onTap: () {
                    Navigator.pop(context);
                    if (bus != null) _showQuickDelayAlert(bus);
                  },
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(color: AppColors.divider, height: 1),
                ),

                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Log Out Driver Account',
                  iconColor: const Color(0xFFDC2626),
                  textColor: const Color(0xFFDC2626),
                  onTap: () async {
                    Navigator.pop(context);
                    _confirmLogout(context, auth, bus);
                  },
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'UniRide Driver Fleet v2.0',
                  style: TextStyle(fontSize: 11, color: AppColors.secondaryText, fontWeight: FontWeight.w600),
                ),
                Text(
                  'UET RCET',
                  style: TextStyle(fontSize: 11, color: AppColors.primaryBlue.withOpacity(0.8), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryBlue.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: iconColor ?? (isSelected ? AppColors.primaryBlue : AppColors.secondaryText),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? (isSelected ? AppColors.primaryBlue : AppColors.primaryText),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
