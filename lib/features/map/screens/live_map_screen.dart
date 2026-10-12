import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/bus_model.dart';
import '../../../data/models/route_model.dart';
import '../../../providers/bus_provider.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/bus_detail_bottom_sheet.dart';
import '../widgets/bus_marker_widget.dart';

enum AppMapType {
  streets,
  satellite,
  hybrid,
}

class LiveMapScreen extends StatefulWidget {
  final BusModel? focusBus;
  final VoidCallback? onOpenDrawer;

  const LiveMapScreen({super.key, this.focusBus, this.onOpenDrawer});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  // University Campus Main Gate
  final LatLng _campusLocation = const LatLng(32.362339, 74.208769);
  final double _currentZoom = 14.5;
  bool _hasInitialCentered = false;
  bool _showBottomSheet = true;
  AppMapType _currentMapType = AppMapType.streets;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyInitialFocus();
    });
  }

  void _applyInitialFocus() {
    if (_hasInitialCentered) return;
    _hasInitialCentered = true;

    final busProvider = Provider.of<BusProvider>(context, listen: false);

    // Support ModalRoute arguments if navigated via Navigator.pushNamed(..., arguments: bus)
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    BusModel? targetBus;
    if (routeArgs is BusModel) {
      targetBus = routeArgs;
    } else {
      targetBus = widget.focusBus ?? busProvider.selectedBus ?? busProvider.mainLiveBus;
    }

    if (targetBus != null) {
      _focusOnBus(targetBus);
    }
  }

  void _locateCampus() {
    _mapController.move(_campusLocation, 15.5);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Centered on UET RCET Campus Main Gate'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }



  void _focusOnBus(BusModel bus) {
    final busProvider = Provider.of<BusProvider>(context, listen: false);
    busProvider.selectBus(bus);

    final route = busProvider.getRouteForBus(bus) ?? (busProvider.routes.isNotEmpty ? busProvider.routes.first : null);
    if (route != null) {
      busProvider.selectRoute(route);
    }

    final isLive = bus.status == BusStatusType.onRoute;
    final busPoint = (!isLive && route != null && route.polylinePoints.isNotEmpty)
        ? route.polylinePoints.first
        : bus.location;

    setState(() {
      _showBottomSheet = true;
    });

    _mapController.move(busPoint, 15.8);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isLive ? Icons.gps_fixed_rounded : Icons.location_on_rounded,
              color: AppColors.goldAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isLive
                    ? '📍 Live: ${bus.name} (${bus.speed.toInt()} km/h) • Next: ${bus.nextStop}'
                    : '🅿️ Stationed: ${bus.name} (Standby at ${bus.nextStop})',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _fitEntireRoute() {
    final busProvider = Provider.of<BusProvider>(context, listen: false);
    final selectedBus = busProvider.selectedBus ?? busProvider.mainLiveBus;
    final route = busProvider.getRouteForBus(selectedBus) ?? (busProvider.routes.isNotEmpty ? busProvider.routes.first : null);

    if (route != null && route.polylinePoints.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: route.polylinePoints,
          padding: const EdgeInsets.all(36),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Showing entire ${route.title} to Campus'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Map View Style', style: AppStyles.heading2.copyWith(fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildMapTypeOption(
                type: AppMapType.streets,
                title: 'Standard Streets',
                subtitle: 'Clear road and street map',
                icon: Icons.map_rounded,
                iconColor: AppColors.primaryBlue,
              ),
              const SizedBox(height: 10),
              _buildMapTypeOption(
                type: AppMapType.satellite,
                title: 'Satellite View',
                subtitle: 'High-resolution aerial imagery',
                icon: Icons.satellite_alt_rounded,
                iconColor: Colors.teal,
              ),
              const SizedBox(height: 10),
              _buildMapTypeOption(
                type: AppMapType.hybrid,
                title: 'Hybrid View',
                subtitle: 'Satellite with street labels and stops',
                icon: Icons.layers_rounded,
                iconColor: AppColors.goldDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapTypeOption({
    required AppMapType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _currentMapType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _currentMapType = type;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to $title'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primaryBlue : AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);
    final displayedBuses = busProvider.filteredBuses;
    final liveBuses = displayedBuses.where((b) => b.status == BusStatusType.onRoute).toList();
    final selectedBus = busProvider.selectedBus ?? (liveBuses.isNotEmpty ? liveBuses.first : busProvider.mainLiveBus);

    final RouteModel? activeRoute = busProvider.selectedRoute ??
        busProvider.getRouteForBus(selectedBus) ??
        (busProvider.routes.isNotEmpty ? busProvider.routes.first : null);

    final isSatelliteMode = _currentMapType != AppMapType.streets;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. High-Performance Multi-Layer Map (Streets / Satellite / Hybrid)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: selectedBus?.location ?? const LatLng(32.2030, 74.1750),
              initialZoom: _currentZoom,
              minZoom: 9.0,
              maxZoom: 18.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Dynamic Base Map Tile Layer
              if (_currentMapType == AppMapType.streets) ...[
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.uniridr.app',
                  maxZoom: 19,
                  panBuffer: 1,
                  keepBuffer: 4,
                  errorTileCallback: (tile, error, stackTrace) {},
                  tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 120)),
                ),
              ] else if (_currentMapType == AppMapType.satellite) ...[
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.uniridr.app',
                  maxZoom: 19,
                  panBuffer: 1,
                  keepBuffer: 3,
                  errorTileCallback: (tile, error, stackTrace) {},
                  tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 120)),
                ),
              ] else if (_currentMapType == AppMapType.hybrid) ...[
                // Satellite base imagery
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.uniridr.app',
                  maxZoom: 19,
                  panBuffer: 1,
                  keepBuffer: 3,
                  errorTileCallback: (tile, error, stackTrace) {},
                  tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 120)),
                ),
                // Road networks & boundaries reference overlay
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.uniridr.app',
                  maxZoom: 19,
                  panBuffer: 1,
                  keepBuffer: 3,
                  errorTileCallback: (tile, error, stackTrace) {},
                  tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 120)),
                ),
              ],

              // Route Polylines Layer - Prominently renders the selected bus's GT Road route
              PolylineLayer(
                polylines: [
                  // Active Route - Outer Road Casing / Glow
                  if (activeRoute != null && activeRoute.polylinePoints.isNotEmpty)
                    Polyline(
                      points: activeRoute.polylinePoints,
                      color: isSatelliteMode
                          ? AppColors.goldAccent.withOpacity(0.70)
                          : const Color(0xFF1E40AF).withOpacity(0.35),
                      strokeWidth: 9.5,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),

                  // Active Route - Crisp, Vibrant Royal Blue Road Line
                  if (activeRoute != null && activeRoute.polylinePoints.isNotEmpty)
                    Polyline(
                      points: activeRoute.polylinePoints,
                      color: isSatelliteMode ? Colors.white : const Color(0xFF2563EB),
                      strokeWidth: 5.2,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                ],
              ),


              // Stop Markers Layer (Filtered to the active route's official stops)
              MarkerLayer(
                markers: (activeRoute?.stops ?? []).map((stop) {
                  final isCampus = stop.id == 'stop_rcet_campus';
                  final isStart = activeRoute!.stops.isNotEmpty && activeRoute.stops.first.id == stop.id;
                  final isNext = selectedBus != null &&
                      selectedBus.nextStop.toLowerCase().contains(stop.name.toLowerCase());

                  if (isCampus || isStart) {
                    // Campus and Start points have dedicated prominent markers
                    return Marker(
                      point: stop.location,
                      width: 0,
                      height: 0,
                      child: const SizedBox.shrink(),
                    );
                  }

                  return Marker(
                    point: stop.location,
                    width: isNext ? 34 : 24,
                    height: isNext ? 34 : 24,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.stopDetails,
                          arguments: stop,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isNext ? AppColors.primaryBlue : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isNext ? AppColors.goldAccent : const Color(0xFF2563EB),
                            width: isNext ? 2.5 : 1.8,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isNext ? Icons.near_me_rounded : Icons.radio_button_checked_rounded,
                            size: isNext ? 16 : 12,
                            color: isNext ? Colors.white : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Prominent UET RCET Campus Destination Marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: _campusLocation,
                    width: 140,
                    height: 72,
                    child: GestureDetector(
                      onTap: _locateCampus,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.goldAccent, width: 1.2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x35000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.school_rounded, color: AppColors.goldAccent, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'RCET Campus Gate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.goldAccent,
                              border: Border.all(color: AppColors.primaryBlue, width: 2.5),
                              boxShadow: const [AppColors.cardShadow],
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 18,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Fleet Markers Layer (Shows buses and highlights the selected one)
              MarkerLayer(
                markers: busProvider.buses.map((bus) {
                  final isSelected = selectedBus?.id == bus.id;
                  final isLive = bus.status == BusStatusType.onRoute;

                  // If bus is on standby, position it strictly at route starting point
                  LatLng busPoint = bus.location;
                  if (!isLive) {
                    final busRoute = busProvider.getRouteForBus(bus) ?? activeRoute;
                    if (busRoute != null && busRoute.polylinePoints.isNotEmpty) {
                      busPoint = busRoute.polylinePoints.first;
                    } else if (busRoute != null && busRoute.stops.isNotEmpty) {
                      busPoint = busRoute.stops.first.location;
                    }
                  }

                  return Marker(
                    point: busPoint,
                    width: isSelected ? (isLive ? 90 : 50) : (isLive ? 72 : 40),
                    height: isSelected ? (isLive ? 90 : 50) : (isLive ? 72 : 40),
                    child: BusMarkerWidget(
                      bus: bus,
                      isSelected: isSelected,
                      onTap: () {
                        _focusOnBus(bus);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. Top Header & Interactive Bus Selector Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Status Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: AppStyles.cardBorder,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x180F172A),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (widget.onOpenDrawer != null) ...[
                          GestureDetector(
                            onTap: widget.onOpenDrawer,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.menu_rounded,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ] else if (Navigator.canPop(context)) ...[
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.lightBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.directions_bus_rounded,
                              color: AppColors.primaryBlue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                selectedBus != null
                                    ? '${selectedBus.name} • ${selectedBus.status == BusStatusType.onRoute ? 'Active' : 'Off Duty'}'
                                    : 'UET Transit Live Map',
                                style: AppStyles.heading3.copyWith(fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                selectedBus != null && selectedBus.status == BusStatusType.onRoute
                                    ? '${selectedBus.speed.toInt()} km/h • Next: ${selectedBus.nextStop}'
                                    : (liveBuses.isNotEmpty
                                        ? '${liveBuses.length} bus${liveBuses.length > 1 ? 'es' : ''} transmitting live GPS'
                                        : 'No buses on live duty right now'),
                                style: AppStyles.bodySmall.copyWith(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: busProvider.isLoading
                                ? AppColors.lightBlue
                                : (liveBuses.isNotEmpty ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: busProvider.isLoading
                                  ? AppColors.primaryBlue.withOpacity(0.3)
                                  : (liveBuses.isNotEmpty ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1)),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (busProvider.isLoading) ...[
                                const SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primaryBlue),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'SYNCING',
                                  style: AppStyles.badgeText.copyWith(fontSize: 10, color: AppColors.primaryBlue),
                                ),
                              ] else ...[
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: liveBuses.isNotEmpty ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  liveBuses.isNotEmpty ? 'LIVE GPS' : 'OFF DUTY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: liveBuses.isNotEmpty ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Horizontal Quick Bus Switcher
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: busProvider.buses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, index) {
                        final b = busProvider.buses[index];
                        final isSelected = selectedBus?.id == b.id;
                        final isLive = b.status == BusStatusType.onRoute;

                        return GestureDetector(
                          onTap: () {
                            _focusOnBus(b);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryBlue : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryBlue : AppColors.border,
                              ),
                              boxShadow: const [AppColors.cardShadow],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_bus_rounded,
                                  size: 14,
                                  color: isSelected
                                      ? AppColors.goldAccent
                                      : (isLive ? const Color(0xFF16A34A) : AppColors.secondaryText),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  b.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : AppColors.primaryText,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isLive ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isLive ? 'LIVE' : 'OFF',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isLive ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),


                ],
              ),
            ),
          ),

          // Live Telemetry Syncing Pill
          if (busProvider.isLoading)
            Positioned(
              top: 140,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [AppColors.cardShadow],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Updating bus locations...',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Floating Action Controls (Right side)
          Positioned(
            right: 16,
            bottom: (_showBottomSheet && selectedBus != null) ? 220 : 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Switch Map Type (Streets / Satellite / Hybrid)
                FloatingActionButton.small(
                  heroTag: 'map_type_btn',
                  backgroundColor: isSatelliteMode ? AppColors.goldAccent : Colors.white,
                  foregroundColor: isSatelliteMode ? AppColors.primaryBlue : AppColors.primaryBlue,
                  tooltip: 'Map View (Streets/Satellite/Hybrid)',
                  onPressed: _showMapTypeSelector,
                  child: const Icon(Icons.layers_rounded),
                ),
                const SizedBox(height: 8),

                // Fit Route on Screen Button
                FloatingActionButton.small(
                  heroTag: 'fit_route_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryBlue,
                  tooltip: 'Fit Route in View',
                  onPressed: _fitEntireRoute,
                  child: const Icon(Icons.route_rounded),
                ),
                const SizedBox(height: 8),

                // Center on Bus FAB (Target Button)
                FloatingActionButton.small(
                  heroTag: 'focus_bus_btn',
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.goldAccent,
                  tooltip: 'Locate & Track Bus',
                  onPressed: () {
                    final busToFocus = selectedBus ??
                        busProvider.selectedBus ??
                        busProvider.mainLiveBus ??
                        (busProvider.buses.isNotEmpty ? busProvider.buses.first : null);
                    if (busToFocus != null) {
                      _focusOnBus(busToFocus);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No bus currently selected.'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 8),

                // Center on Campus FAB
                FloatingActionButton.small(
                  heroTag: 'campus_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryBlue,
                  tooltip: 'RCET Campus Gate',
                  onPressed: _locateCampus,
                  child: const Icon(Icons.school_rounded),
                ),
              ],
            ),
          ),

          // 4. Bottom Telemetry Sheet for Selected Bus (Dismissible / Collapsible)
          if (_showBottomSheet && selectedBus != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BusDetailBottomSheet(
                bus: selectedBus,
                onClose: () {
                  setState(() {
                    _showBottomSheet = false;
                  });
                },
                onTrackRoute: () {
                  final route = busProvider.getRouteForBus(selectedBus);
                  if (route != null) {
                    busProvider.selectRoute(route);
                    Navigator.pushNamed(
                      context,
                      AppRoutes.routeDetails,
                      arguments: route,
                    );
                  }
                },
                onBusDetails: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.busDetails,
                    arguments: selectedBus,
                  );
                },
              ),
            ),

          // If bottom sheet was closed, show small re-open pill
          if (!_showBottomSheet && selectedBus != null)
            Positioned(
              left: 20,
              bottom: 30,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showBottomSheet = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [AppColors.cardShadow],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_bus_rounded, color: AppColors.goldAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'View ${selectedBus.name} Telemetry',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
