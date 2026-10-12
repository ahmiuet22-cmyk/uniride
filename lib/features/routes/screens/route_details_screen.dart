import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/bus_model.dart';
import '../../../data/models/route_model.dart';
import '../../../data/models/stop_model.dart';
import '../../../providers/bus_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../schedule/screens/schedule_screen.dart';

class RouteDetailsScreen extends StatefulWidget {
  final RouteModel? initialRoute;

  const RouteDetailsScreen({super.key, this.initialRoute});

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);
    final args = ModalRoute.of(context)?.settings.arguments;
    final RouteModel? route = (args is RouteModel)
        ? args
        : (widget.initialRoute ??
            busProvider.selectedRoute ??
            (busProvider.routes.isNotEmpty ? busProvider.routes.first : null));

    if (route == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Route Details')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                busProvider.isLoading
                    ? 'Loading route details...'
                    : 'No route found',
                style: AppStyles.bodyMedium.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      );
    }

    // Match bus assigned to this route
    BusModel? activeBus;
    for (final b in busProvider.buses) {
      if (b.routeId == route.id ||
          busProvider.getRouteForBus(b)?.id == route.id ||
          b.routeName.toLowerCase().contains(route.code.toLowerCase()) ||
          (route.id.contains('3') && b.id.contains('gax'))) {
        if (activeBus == null || b.status == BusStatusType.onRoute) {
          activeBus = b;
        }
      }
    }

    final bool isLive = activeBus != null && activeBus.status == BusStatusType.onRoute;

    // Dynamically calculate current stop and distance
    int currentStopIndex = -1;
    bool isAtStop = false;
    double distanceToStopKm = 0.0;

    if (isLive && route.stops.isNotEmpty) {
      final active = activeBus;
      // 1. NextStop name matching
      final nextStopClean = active.nextStop.toLowerCase().trim();
      int matchByName = route.stops.indexWhere(
        (s) => s.name.toLowerCase().trim() == nextStopClean ||
               nextStopClean.contains(s.name.toLowerCase().trim()) ||
               s.name.toLowerCase().trim().contains(nextStopClean),
      );

      // 2. Measure physical distance from bus location to all stops
      const distCalc = Distance();
      int closestStopIndex = 0;
      double minDistanceMeters = double.infinity;
      for (int i = 0; i < route.stops.length; i++) {
        final d = distCalc(activeBus.location, route.stops[i].location);
        if (d < minDistanceMeters) {
          minDistanceMeters = d;
          closestStopIndex = i;
        }
      }

      if (matchByName != -1) {
        currentStopIndex = matchByName;
      } else if (activeBus.currentStopIndex >= 0 && activeBus.currentStopIndex < route.stops.length) {
        currentStopIndex = activeBus.currentStopIndex;
      } else {
        currentStopIndex = closestStopIndex;
      }

      currentStopIndex = currentStopIndex.clamp(0, route.stops.length - 1);
      final distToStop = distCalc(activeBus.location, route.stops[currentStopIndex].location);
      distanceToStopKm = distToStop / 1000.0;
      isAtStop = distToStop < 150 || (distToStop < 350 && activeBus.speed < 5.0);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(route.title, style: AppStyles.appBarTitle.copyWith(fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Timetable Schedule',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () {
              busProvider.selectRoute(route);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScheduleScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Banner Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppStyles.radiusLarge,
                        border: AppStyles.cardBorder,
                        boxShadow: const [AppColors.softShadow],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  route.code,
                                  style: AppStyles.badgeText.copyWith(color: AppColors.primaryBlue),
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isLive ? const Color(0xFF16A34A) : const Color(0xFFEAB308),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isLive ? 'Bus Live On Route' : 'Scheduled Route',
                                    style: AppStyles.bodySmall.copyWith(
                                      color: isLive ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(route.title, style: AppStyles.heading1.copyWith(fontSize: 22)),
                          const SizedBox(height: 6),
                          Text(
                            route.description,
                            style: AppStyles.bodyMedium.copyWith(color: AppColors.secondaryText),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _buildInfoChip(
                                Icons.directions_bus_rounded,
                                activeBus != null ? activeBus.name : '${route.activeBusCount} Buses on Route',
                              ),
                              const SizedBox(width: 12),
                              _buildInfoChip(
                                Icons.timer_rounded,
                                '${route.estimatedDurationMinutes} mins travel',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Dynamic Real-time Operational Card
                    _buildOperationalCard(
                      context: context,
                      busProvider: busProvider,
                      route: route,
                      activeBus: activeBus,
                      isLive: isLive,
                      currentStopIndex: currentStopIndex,
                      isAtStop: isAtStop,
                      distKm: distanceToStopKm,
                    ),

                    const SizedBox(height: 22),

                    // Vertical Stop Timeline Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('STOPS ALONG THIS ROUTE', style: AppStyles.sectionTitle),
                        Text(
                          '${route.stops.length} Stops',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Dynamic Vertical Stop Timeline
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppStyles.radiusMedium,
                        border: AppStyles.cardBorder,
                        boxShadow: const [AppColors.cardShadow],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: route.stops.length,
                        itemBuilder: (context, index) {
                          final stop = route.stops[index];
                          final isFirst = index == 0;
                          final isLast = index == route.stops.length - 1;

                          // Only mark stops dynamically if the bus is actively on the route
                          final isCurrent = isLive && index == currentStopIndex;
                          final isPassed = isLive && currentStopIndex >= 0 && index < currentStopIndex;
                          final isTopActive = isLive && !isFirst && index <= currentStopIndex;
                          final isBottomActive = isLive && !isLast && index < currentStopIndex;

                          return _buildTimelineItem(
                            context: context,
                            stop: stop,
                            index: index,
                            totalStops: route.stops.length,
                            isFirst: isFirst,
                            isLast: isLast,
                            isLive: isLive,
                            isCurrent: isCurrent,
                            isPassed: isPassed,
                            isTopActive: isTopActive,
                            isBottomActive: isBottomActive,
                            isAtStop: isAtStop,
                            distKm: distanceToStopKm,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'VIEW FULL TIMETABLE',
                      icon: Icons.calendar_month_rounded,
                      onPressed: () {
                        busProvider.selectRoute(route);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScheduleScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  if (activeBus != null) ...[
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        busProvider.selectBus(activeBus!);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.liveMap,
                          arguments: activeBus,
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.blueAccentSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryBlue),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: AppStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalCard({
    required BuildContext context,
    required BusProvider busProvider,
    required RouteModel route,
    required BusModel? activeBus,
    required bool isLive,
    required int currentStopIndex,
    required bool isAtStop,
    required double distKm,
  }) {
    if (isLive && activeBus != null) {
      final stopName = (currentStopIndex >= 0 && currentStopIndex < route.stops.length)
          ? route.stops[currentStopIndex].name
          : activeBus.nextStop;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF0FDF4), Color(0xFFEFF6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppStyles.radiusMedium,
          border: Border.all(color: const Color(0xFF86EFAC)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'BUS IS LIVE ON ROUTE',
                      style: AppStyles.badgeText.copyWith(
                        color: const Color(0xFF15803D),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Text(
                    '${activeBus.speed.toStringAsFixed(0)} km/h',
                    style: AppStyles.badgeText.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAtStop ? 'Currently at Stop:' : 'Approaching Next Stop:',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stopName,
                      style: AppStyles.heading2.copyWith(
                        fontSize: 17,
                        color: isAtStop ? const Color(0xFF15803D) : AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Campus ETA',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${activeBus.etaMinutes} mins',
                      style: AppStyles.heading2.copyWith(
                        fontSize: 17,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      busProvider.selectBus(activeBus);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.liveMap,
                        arguments: activeBus,
                      );
                    },
                    icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                    label: const Text('Track on Map', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    busProvider.toggleBusLiveSimulation(activeBus.id, forceLive: false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Trip simulation paused for ${activeBus.name}'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.stop_circle_outlined, size: 16),
                  label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Bus is Standby / Scheduled
    final busTargetId = activeBus?.id ?? (route.id == 'route_3' ? 'bus_gax_4555' : 'bus_gau_2555');
    final firstStopName = route.stops.isNotEmpty ? route.stops.first.name : 'Origin Terminal';
    final firstStopTime = route.stops.isNotEmpty ? route.stops.first.morningTiming : '7:00 am';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.radiusMedium,
        border: AppStyles.cardBorder,
        boxShadow: const [AppColors.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 6),
                  Text(
                    'STANDBY • SCHEDULED DEPARTURE',
                    style: AppStyles.badgeText.copyWith(
                      color: const Color(0xFFB45309),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.blueAccentSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  firstStopTime,
                  style: AppStyles.badgeText.copyWith(color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bus is on standby at $firstStopName. Scheduled trip commences at $firstStopTime to RCET Campus.',
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                busProvider.toggleBusLiveSimulation(busTargetId, forceLive: true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Live simulation started! Bus is now moving along ${route.code}.'),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text('START LIVE TRIP SIMULATION', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required BusStopModel stop,
    required int index,
    required int totalStops,
    required bool isFirst,
    required bool isLast,
    required bool isLive,
    required bool isCurrent,
    required bool isPassed,
    required bool isTopActive,
    required bool isBottomActive,
    required bool isAtStop,
    required double distKm,
  }) {
    const Color activeLineColor = AppColors.primaryBlue;
    const Color inactiveLineColor = Color(0xFFCBD5E1);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.stopDetails, arguments: stop);
      },
      borderRadius: BorderRadius.circular(10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline connector line + circle indicator
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  // Upper connecting segment
                  Expanded(
                    child: Container(
                      width: 3.0,
                      color: isFirst
                          ? Colors.transparent
                          : (isTopActive ? activeLineColor : inactiveLineColor),
                    ),
                  ),
                  // Node indicator circle
                  _buildNodeCircle(
                    isCurrent: isCurrent,
                    isPassed: isPassed,
                    isLast: isLast,
                    isFirst: isFirst,
                    isLive: isLive,
                  ),
                  // Lower connecting segment
                  Expanded(
                    child: Container(
                      width: 3.0,
                      color: isLast
                          ? Colors.transparent
                          : (isBottomActive ? activeLineColor : inactiveLineColor),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // Stop name and info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stop.name,
                            style: AppStyles.bodyLarge.copyWith(
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                              color: isCurrent
                                  ? AppColors.primaryBlue
                                  : (isPassed
                                      ? AppColors.primaryText
                                      : (isLive ? AppColors.secondaryText : AppColors.primaryText)),
                              fontSize: isCurrent ? 16 : 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (stop.morningTiming.isNotEmpty) ...[
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: isPassed ? const Color(0xFF16A34A) : AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPassed ? 'Passed • ${stop.morningTiming}' : stop.morningTiming,
                                  style: AppStyles.bodySmall.copyWith(
                                    color: isPassed ? const Color(0xFF15803D) : AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('•', style: AppStyles.bodySmall),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                stop.code,
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Badges on the right
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAtStop ? const Color(0xFFDCFCE7) : AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isAtStop
                                ? const Color(0xFF86EFAC)
                                : AppColors.primaryBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: _pulseAnimation,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isAtStop ? const Color(0xFF16A34A) : AppColors.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isAtStop ? 'AT STOP' : 'CURRENT',
                              style: AppStyles.badgeText.copyWith(
                                color: isAtStop ? const Color(0xFF15803D) : AppColors.primaryBlue,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (isLast) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.goldAccent.withOpacity(0.5)),
                        ),
                        child: Text(
                          'CAMPUS',
                          style: AppStyles.badgeText.copyWith(
                            color: AppColors.goldDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ] else if (isFirst && !isLive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                        ),
                        child: Text(
                          'ORIGIN',
                          style: AppStyles.badgeText.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeCircle({
    required bool isCurrent,
    required bool isPassed,
    required bool isLast,
    required bool isFirst,
    required bool isLive,
  }) {
    if (isCurrent) {
      return ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.lightBlue,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.directions_bus_rounded,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (isPassed) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: AppColors.primaryBlue,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.check,
            size: 11,
            color: Colors.white,
          ),
        ),
      );
    }

    // Pending / Inactive nodes
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isLast
              ? AppColors.goldAccent
              : (isFirst ? AppColors.primaryBlue : const Color(0xFF94A3B8)),
          width: 2.5,
        ),
      ),
      child: isLast
          ? const Center(
              child: Icon(
                Icons.school_rounded,
                size: 8,
                color: AppColors.primaryBlue,
              ),
            )
          : null,
    );
  }
}
