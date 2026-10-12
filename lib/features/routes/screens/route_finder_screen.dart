import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/stop_model.dart';
import '../../../data/services/route_finder_service.dart';
import '../../../providers/bus_provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/status_badge.dart';

class RouteFinderScreen extends StatefulWidget {
  const RouteFinderScreen({super.key});

  @override
  State<RouteFinderScreen> createState() => _RouteFinderScreenState();
}

class _RouteFinderScreenState extends State<RouteFinderScreen> {
  String? _selectedPickupId;
  String? _selectedDestinationId;
  final Set<String> _expandedRoutes = {};

  @override
  void initState() {
    super.initState();
    // Default pickup: Chanda Qila, default destination: RCET Campus
    _selectedPickupId = 'stop_chanda_qila';
    _selectedDestinationId = 'stop_rcet_campus';
  }

  void _swapStops() {
    setState(() {
      final temp = _selectedPickupId;
      _selectedPickupId = _selectedDestinationId;
      _selectedDestinationId = temp;
    });
  }

  void _showStopPicker({
    required BuildContext context,
    required String title,
    required List<BusStopModel> stops,
    required String? currentSelectedId,
    required Function(String stopId) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final filtered = stops.where((s) {
              if (query.isEmpty) return true;
              return s.name.toLowerCase().contains(query.toLowerCase()) ||
                  s.code.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          Text(title, style: AppStyles.heading2.copyWith(fontSize: 18)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: TextField(
                        autofocus: false,
                        onChanged: (val) => setModalState(() => query = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search bus stop...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.secondaryBlue),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: AppStyles.radiusMedium,
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                        itemBuilder: (context, index) {
                          final stop = filtered[index];
                          final isSelected = stop.id == currentSelectedId;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryBlue : AppColors.lightBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 20,
                                color: isSelected ? Colors.white : AppColors.primaryBlue,
                              ),
                            ),
                            title: Text(
                              stop.name,
                              style: AppStyles.bodyLarge.copyWith(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primaryBlue : AppColors.primaryText,
                              ),
                            ),
                            subtitle: Text(
                              'Stop Code: ${stop.code}${stop.morningTiming.isNotEmpty ? ' • Morning: ${stop.morningTiming}' : ''}',
                              style: AppStyles.bodySmall,
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryBlue)
                                : null,
                            onTap: () {
                              onSelected(stop.id);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);

    // Extract all unique stops from all routes
    final allStopsMap = <String, BusStopModel>{};
    for (final route in busProvider.routes) {
      for (final stop in route.stops) {
        allStopsMap[stop.id] = stop;
      }
    }
    final allStops = allStopsMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final pickupStop = allStopsMap[_selectedPickupId];
    final destinationStop = allStopsMap[_selectedDestinationId];

    // Find trip results
    List<TripSearchResult> tripResults = [];
    if (_selectedPickupId != null &&
        _selectedDestinationId != null &&
        _selectedPickupId != _selectedDestinationId) {
      tripResults = RouteFinderService.findTrips(
        pickupStopId: _selectedPickupId!,
        destinationStopId: _selectedDestinationId!,
        routes: busProvider.routes,
        buses: busProvider.buses,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Route Finder', style: AppStyles.appBarTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: busProvider.isLoading && busProvider.routes.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    const SkeletonLoader(width: double.infinity, height: 200),
                    const SizedBox(height: 16),
                    const SkeletonLoader(width: double.infinity, height: 120),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Planner Input Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppStyles.radiusLarge,
                  border: AppStyles.cardBorder,
                  boxShadow: const [AppColors.cardShadow],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLAN YOUR CAMPUS JOURNEY',
                      style: AppStyles.sectionTitle.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 14),

                    // Pickup Stop Selector
                    _buildStopSelector(
                      context: context,
                      label: 'PICKUP STOP',
                      stopName: pickupStop?.name ?? 'Select pickup stop',
                      stopCode: pickupStop?.code ?? '',
                      iconColor: AppColors.success,
                      iconData: Icons.trip_origin_rounded,
                      onTap: () {
                        _showStopPicker(
                          context: context,
                          title: 'Select Pickup Stop',
                          stops: allStops,
                          currentSelectedId: _selectedPickupId,
                          onSelected: (id) => setState(() => _selectedPickupId = id),
                        );
                      },
                    ),

                    // Intermediate divider & swap button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 2,
                            height: 24,
                            margin: const EdgeInsets.only(left: 11),
                            color: AppColors.border,
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _swapStops,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.lightBlue,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                              ),
                              child: const Icon(
                                Icons.swap_vert_rounded,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),

                    // Destination Stop Selector
                    _buildStopSelector(
                      context: context,
                      label: 'DESTINATION STOP',
                      stopName: destinationStop?.name ?? 'Select destination stop',
                      stopCode: destinationStop?.code ?? '',
                      iconColor: AppColors.danger,
                      iconData: Icons.location_on_rounded,
                      onTap: () {
                        _showStopPicker(
                          context: context,
                          title: 'Select Destination',
                          stops: allStops,
                          currentSelectedId: _selectedDestinationId,
                          onSelected: (id) => setState(() => _selectedDestinationId = id),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Quick Chips for Frequent Stops
                    Text(
                      'Quick Select:',
                      style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickChip(
                          label: 'RCET Campus',
                          stopId: 'stop_rcet_campus',
                          onTap: () => setState(() => _selectedDestinationId = 'stop_rcet_campus'),
                          isActive: _selectedDestinationId == 'stop_rcet_campus',
                        ),
                        _buildQuickChip(
                          label: 'Chanda Qila',
                          stopId: 'stop_chanda_qila',
                          onTap: () => setState(() => _selectedPickupId = 'stop_chanda_qila'),
                          isActive: _selectedPickupId == 'stop_chanda_qila',
                        ),
                        _buildQuickChip(
                          label: 'Sheikhupura Mor',
                          stopId: 'stop_sheikhupura_mor',
                          onTap: () => setState(() => _selectedPickupId = 'stop_sheikhupura_mor'),
                          isActive: _selectedPickupId == 'stop_sheikhupura_mor',
                        ),
                        _buildQuickChip(
                          label: 'Pindi Bypass',
                          stopId: 'stop_pindi_bypass',
                          onTap: () => setState(() => _selectedPickupId = 'stop_pindi_bypass'),
                          isActive: _selectedPickupId == 'stop_pindi_bypass',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Results Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AVAILABLE OPTIONS',
                    style: AppStyles.sectionTitle,
                  ),
                  if (tripResults.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tripResults.length} Direct Route${tripResults.length > 1 ? 's' : ''}',
                        style: AppStyles.badgeText.copyWith(color: AppColors.primaryBlue),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Trip Results List
              if (busProvider.isLoading)
                Column(
                  children: List.generate(
                    2,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: SkeletonLoader(
                        width: double.infinity,
                        height: 180,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                  ),
                )
              else if (_selectedPickupId == _selectedDestinationId)
                _buildSameStopView()
              else if (tripResults.isEmpty)
                _buildNoRouteView(pickupStop?.name ?? 'Pickup', destinationStop?.name ?? 'Destination')
              else
                ...tripResults.map((result) => _buildTripCard(context, result, busProvider)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopSelector({
    required BuildContext context,
    required String label,
    required String stopName,
    required String stopCode,
    required Color iconColor,
    required IconData iconData,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppStyles.radiusMedium,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppStyles.radiusMedium,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(iconData, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppStyles.bodySmall.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stopName,
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (stopCode.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  stopCode,
                  style: AppStyles.badgeText.copyWith(fontSize: 10, color: AppColors.secondaryText),
                ),
              ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required String stopId,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primaryBlue : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.primaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(
    BuildContext context,
    TripSearchResult trip,
    BusProvider busProvider,
  ) {
    final isExpanded = _expandedRoutes.contains(trip.route.id);
    final activeBus = trip.activeBus;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.radiusLarge,
        border: AppStyles.cardBorder,
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trip.route.code,
                    style: AppStyles.badgeText.copyWith(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.route.title,
                        style: AppStyles.heading3.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activeBus != null
                            ? '${activeBus.name} • ${activeBus.occupancy}'
                            : 'Assigned Campus Bus',
                        style: AppStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
                if (activeBus != null)
                  StatusBadge(status: activeBus.status)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Scheduled',
                      style: AppStyles.badgeText.copyWith(color: AppColors.primaryBlue),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Journey Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.timer_outlined,
                  value: '~${trip.estimatedMinutes} mins',
                  label: 'Travel Time',
                ),
                Container(width: 1, height: 28, color: AppColors.divider),
                _buildStatItem(
                  icon: Icons.pin_drop_outlined,
                  value: '${trip.stopsCount} stops',
                  label: 'Journey Stops',
                ),
                Container(width: 1, height: 28, color: AppColors.divider),
                _buildStatItem(
                  icon: Icons.schedule_rounded,
                  value: trip.pickupStop.morningTiming.isNotEmpty
                      ? trip.pickupStop.morningTiming
                      : '7:00 am',
                  label: 'Pickup Time',
                ),
              ],
            ),
          ),

          // Intermediate Stops Expandable Section
          if (trip.intermediateStops.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.divider),
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedRoutes.remove(trip.route.id);
                  } else {
                    _expandedRoutes.add(trip.route.id);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isExpanded
                          ? 'Hide intermediate stops'
                          : 'View ${trip.intermediateStops.length} stops along the route',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded)
              Container(
                color: AppColors.background.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimelineStop(trip.pickupStop.name, isFirst: true),
                    ...trip.intermediateStops.map((s) => _buildTimelineStop(s.name)),
                    _buildTimelineStop(trip.destinationStop.name, isLast: true),
                  ],
                ),
              ),
          ],

          const Divider(height: 1, color: AppColors.divider),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      busProvider.selectRoute(trip.route);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.routeDetails,
                        arguments: trip.route,
                      );
                    },
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text('View Full Route'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: AppStyles.buttonText.copyWith(fontSize: 13),
                    ),
                  ),
                ),
                if (activeBus != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        busProvider.selectBus(activeBus);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.busDetails,
                          arguments: activeBus,
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text('Track Bus Live'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: AppStyles.buttonText.copyWith(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primaryBlue),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.mutedText),
        ),
      ],
    );
  }

  Widget _buildTimelineStop(String name, {bool isFirst = false, bool isLast = false}) {
    Color dotColor = AppColors.secondaryText;
    if (isFirst) dotColor = AppColors.success;
    if (isLast) dotColor = AppColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: AppStyles.bodySmall.copyWith(
              fontWeight: (isFirst || isLast) ? FontWeight.w700 : FontWeight.w400,
              color: (isFirst || isLast) ? AppColors.primaryText : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSameStopView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.radiusLarge,
        border: AppStyles.cardBorder,
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded, size: 40, color: AppColors.goldAccent),
          const SizedBox(height: 12),
          Text(
            'Same Pickup & Destination',
            style: AppStyles.heading3,
          ),
          const SizedBox(height: 6),
          Text(
            'Please select a different pickup and destination stop to find matching bus routes.',
            textAlign: TextAlign.center,
            style: AppStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNoRouteView(String pickupName, String destName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.radiusLarge,
        border: AppStyles.cardBorder,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alt_route_rounded, size: 36, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            'No Direct Bus Found',
            style: AppStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            'There is currently no direct campus bus running directly from "$pickupName" to "$destName".',
            textAlign: TextAlign.center,
            style: AppStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppStyles.radiusMedium,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Try traveling via transfer hubs like Sheikhupura Mor or Pindi Bypass, which connect to all major campus routes.',
                    style: AppStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
