import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/bus_model.dart';
import '../../../data/models/route_model.dart';
import '../../../providers/bus_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/report_issue_dialog.dart';

class BusDetailsScreen extends StatelessWidget {
  final BusModel? initialBus;

  const BusDetailsScreen({super.key, this.initialBus});

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);

    // Get bus from route args or initialBus or busProvider selection
    final args = ModalRoute.of(context)?.settings.arguments;
    final bus = (args is BusModel)
        ? args
        : (initialBus ?? busProvider.selectedBus ?? busProvider.mainLiveBus);

    if (bus == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Bus Details')),
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
                    ? 'Synchronizing bus telemetry...'
                    : 'No bus details found',
                style: AppStyles.bodyMedium.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      );
    }

    // Keep live reference if exists in busProvider
    final liveBus = busProvider.buses.firstWhere(
      (b) => b.id == bus.id,
      orElse: () => bus,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(liveBus.name, style: AppStyles.appBarTitle.copyWith(fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sharing ${liveBus.name} live tracking link...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bus Visual Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: AppStyles.radiusLarge,
                  border: AppStyles.cardBorder,
                  boxShadow: const [AppColors.softShadow],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 120,
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Image.asset(
                        'assets/images/uet_bus.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.directions_bus_rounded,
                          size: 64,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(liveBus.name, style: AppStyles.heading1.copyWith(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      liveBus.routeName,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: liveBus.isSpecial ? AppColors.goldLight : AppColors.goldLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.goldBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (liveBus.isSpecial) const Text('⚡ ', style: TextStyle(fontSize: 12)),
                          Text(
                            liveBus.isSpecial
                                ? 'SPECIAL CAMPUS BUS • ${liveBus.specialPurpose ?? 'Direct Transit'}'
                                : 'Scheduled Route Bus',
                            style: AppStyles.badgeText.copyWith(
                              color: liveBus.isSpecial ? AppColors.primaryBlue : AppColors.goldDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4 Key Schedule Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'MORNING START',
                      '7:00 am',
                      Icons.departure_board_rounded,
                      AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'CAMPUS ARRIVAL',
                      '8:30 am',
                      Icons.school_rounded,
                      AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'EVENING RETURN',
                      '4:15 pm sharp',
                      Icons.schedule_rounded,
                      AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      'SCHEDULE STATUS',
                      'On Timetable',
                      Icons.check_circle_outline_rounded,
                      AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Driver Information Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppStyles.radiusMedium,
                  border: AppStyles.cardBorder,
                  boxShadow: const [AppColors.cardShadow],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: AppColors.primaryBlue,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(liveBus.driver.name, style: AppStyles.heading3.copyWith(fontSize: 16)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: AppColors.goldAccent),
                              const SizedBox(width: 3),
                              Text(
                                '${liveBus.driver.rating} • Assigned Hino Bus Driver',
                                style: AppStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.phone_rounded, color: AppColors.primaryBlue, size: 20),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Calling Driver ${liveBus.driver.name}...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Real-time Live GPS Map Preview Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppStyles.radiusLarge,
                  border: AppStyles.cardBorder,
                  boxShadow: const [AppColors.softShadow],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.gps_fixed_rounded, color: AppColors.primaryBlue, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Text('LIVE GPS TRACKING', style: AppStyles.heading3.copyWith(fontSize: 14)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: liveBus.status == BusStatusType.onRoute
                                  ? const Color(0xFFDCFCE7)
                                  : AppColors.goldLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: liveBus.status == BusStatusType.onRoute
                                    ? const Color(0xFF86EFAC)
                                    : AppColors.goldBorder.withOpacity(0.6),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (liveBus.status == BusStatusType.onRoute) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${liveBus.speed.toInt()} km/h',
                                    style: const TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'STANDBY',
                                    style: AppStyles.badgeText.copyWith(
                                      color: AppColors.goldDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Interactive Mini FlutterMap with Tap to Expand
                    GestureDetector(
                      onTap: () {
                        busProvider.selectBus(liveBus);
                        Navigator.pushNamed(context, AppRoutes.liveMap, arguments: liveBus);
                      },
                      child: SizedBox(
                        height: 190,
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: liveBus.location,
                                initialZoom: 14.2,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.uniridr.app',
                                  maxZoom: 19,
                                  panBuffer: 1,
                                  keepBuffer: 3,
                                  errorTileCallback: (tile, error, stackTrace) {},
                                  tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 120)),
                                ),
                                // Route line casing & core
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: busProvider.routes
                                          .firstWhere(
                                            (r) => r.id == liveBus.routeId,
                                            orElse: () => busProvider.routes.first,
                                          )
                                          .polylinePoints,
                                      color: AppColors.primaryBlue.withOpacity(0.3),
                                      strokeWidth: 7.0,
                                    ),
                                    Polyline(
                                      points: busProvider.routes
                                          .firstWhere(
                                            (r) => r.id == liveBus.routeId,
                                            orElse: () => busProvider.routes.first,
                                          )
                                          .polylinePoints,
                                      color: AppColors.primaryBlue,
                                      strokeWidth: 4.0,
                                    ),
                                  ],
                                ),
                                // Live bus position marker
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: liveBus.location,
                                      width: 44,
                                      height: 44,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.goldAccent, width: 2.2),
                                          boxShadow: const [AppColors.cardShadow],
                                        ),
                                        child: const Icon(
                                          Icons.directions_bus_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Floating Tap Hint Overlay
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.touch_app_rounded, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tap to explore full map',
                                      style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Fullscreen Track Action
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.map_rounded, size: 20),
                          label: const Text(
                            'VIEW LIVE ON MAP',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                          ),
                          onPressed: () {
                            busProvider.selectBus(liveBus);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.liveMap,
                              arguments: liveBus,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Route Stop Progress Timeline
              Text('ROUTE TIMELINE & STOPS', style: AppStyles.sectionTitle),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppStyles.radiusMedium,
                  border: AppStyles.cardBorder,
                  boxShadow: const [AppColors.cardShadow],
                ),
                child: Builder(
                  builder: (context) {
                    final route = busProvider.routes.firstWhere(
                      (r) => r.id == liveBus.routeId,
                      orElse: () => busProvider.routes.isNotEmpty
                          ? busProvider.routes.first
                          : const RouteModel(
                              id: 'r1',
                              code: 'Route 1',
                              title: 'Campus Transit',
                              stops: [],
                              polylinePoints: [],
                              estimatedDurationMinutes: 45,
                              activeBusCount: 1,
                            ),
                    );
                    final stops = route.stops;
                    if (stops.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Stops will be available once route starts.',
                          style: AppStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                        ),
                      );
                    }
                    final bool isLive = liveBus.status == BusStatusType.onRoute;
                    return Column(
                      children: List.generate(stops.length, (i) {
                        final stop = stops[i];
                        final isNext = isLive &&
                            (liveBus.nextStop.toLowerCase().trim() == stop.name.toLowerCase().trim() ||
                             liveBus.nextStop.toLowerCase().contains(stop.name.toLowerCase()));
                        final isPassed = isLive && i < liveBus.currentStopIndex;
                        final isLast = i == stops.length - 1;
                        return _buildTimelineStop(stop.name, isPassed, isNext, isLast);
                      }),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'VIEW ALL STOPS',
                      icon: Icons.list_alt_rounded,
                      onPressed: () {
                        final route = busProvider.routes.firstWhere(
                          (r) => r.id == liveBus.routeId,
                          orElse: () => busProvider.routes.first,
                        );
                        busProvider.selectRoute(route);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.routeDetails,
                          arguments: route,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'REPORT ISSUE',
                      isOutlined: true,
                      textColor: AppColors.primaryBlue,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => ReportIssueDialog(
                            busId: liveBus.id,
                            busName: liveBus.name,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.radiusMedium,
        border: AppStyles.cardBorder,
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.secondaryBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppStyles.bodySmall.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppStyles.buttonText.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStop(String stopName, bool isPassed, bool isCurrent, bool isLast) {
    Widget dotWidget = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.mutedText, width: 2),
      ),
    );

    if (isPassed) {
      dotWidget = Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(
          color: AppColors.primaryBlue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 12, color: Colors.white),
      );
    } else if (isCurrent) {
      dotWidget = Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.lightBlue, width: 3),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            child: Center(child: dotWidget),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      stopName,
                      style: AppStyles.bodyMedium.copyWith(
                        color: isCurrent
                            ? AppColors.primaryBlue
                            : (isPassed ? AppColors.primaryText : AppColors.mutedText),
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'CURRENT',
                        style: AppStyles.badgeText.copyWith(
                          fontSize: 10,
                          color: AppColors.primaryBlue,
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
    );
  }
}
