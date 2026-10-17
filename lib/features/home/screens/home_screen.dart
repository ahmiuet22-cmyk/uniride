import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/bus_model.dart';
import '../../../data/models/special_shuttle_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bus_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/live_bus_card.dart';
import '../widgets/nearby_buses_list.dart';
import '../widgets/special_shuttle_banner_card.dart';

class HomeScreen extends StatelessWidget {
  final Function(int tabIndex)? onSwitchTab;
  final VoidCallback? onOpenDrawer;

  const HomeScreen({super.key, this.onSwitchTab, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final busProvider = Provider.of<BusProvider>(context);
    final notifProvider = Provider.of<NotificationProvider>(context);

    final mainBus = busProvider.mainLiveBus;
    // Show entire campus fleet with live database bus prioritized at the top
    final allFleetBuses = List<BusModel>.from(busProvider.buses);
    allFleetBuses.sort((a, b) {
      if (a.status == BusStatusType.onRoute && b.status != BusStatusType.onRoute) return -1;
      if (b.status == BusStatusType.onRoute && a.status != BusStatusType.onRoute) return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          onRefresh: () async {
            await busProvider.refreshBuses();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    if (onOpenDrawer != null) ...[
                      InkWell(
                        onTap: onOpenDrawer,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: AppStyles.cardBorder,
                            boxShadow: const [AppColors.cardShadow],
                          ),
                          child: const Icon(
                            Icons.menu_rounded,
                            color: AppColors.primaryText,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning, ${auth.student.name.split(' ').first} 👋',
                            style: AppStyles.heading2.copyWith(fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'UET Gujranwala • RCET Campus',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    GestureDetector(
                      onTap: () {
                        if (onSwitchTab != null) {
                          onSwitchTab!(4); // Alerts tab
                        }
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: AppStyles.cardBorder,
                              boxShadow: const [AppColors.cardShadow],
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.primaryText,
                              size: 22,
                            ),
                          ),
                          if (notifProvider.hasUnread)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.goldAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (busProvider.activeSpecialShuttles.isNotEmpty) ...[
                  _buildSpecialBusesBanner(context, busProvider.activeSpecialShuttles),
                  const SizedBox(height: 18),
                ],

                
                if (busProvider.isLoading) ...[
                  const SkeletonLoader(width: double.infinity, height: 150 ),
                ] else if (mainBus != null) ...[
                  LiveBusCard(
                    bus: mainBus,
                    onTrackLive: () {
                      busProvider.selectBus(mainBus);
                      if (onSwitchTab != null) {
                        onSwitchTab!(1); // Live Map tab!
                      }
                    },
                    onViewRoute: () {
                      final route = busProvider.getRouteForBus(mainBus);
                      if (route != null) {
                        busProvider.selectRoute(route);
                        Navigator.pushNamed(
                          context,
                          AppRoutes.routeDetails,
                          arguments: route,
                        );
                      }
                    },
                  ),
                ],

                const SizedBox(height: 18),

                // Quick Route Finder Banner Card
                InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.routeFinder),
                  borderRadius: AppStyles.radiusLarge,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppStyles.radiusLarge,
                      border: AppStyles.cardBorder,
                      boxShadow: const [AppColors.cardShadow],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Campus Route Finder',
                                style: AppStyles.heading3.copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select pickup stop to find direct buses & ETA',
                                style: AppStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Find',
                                style: AppStyles.badgeText.copyWith(color: AppColors.primaryBlue),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryBlue, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

              
                

                // Section: Nearby Buses
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CAMPUS BUS FLEET',
                      style: AppStyles.sectionTitle,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: busProvider.activeBusCount > 0 ? const Color(0xFFDCFCE7) : AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: busProvider.activeBusCount > 0 ? Border.all(color: const Color(0xFF86EFAC)) : null,
                      ),
                      child: Text(
                        busProvider.activeBusCount > 0
                            ? '${busProvider.activeBusCount} Live on Route'
                            : 'All Off Duty',
                        style: AppStyles.badgeText.copyWith(
                          color: busProvider.activeBusCount > 0 ? const Color(0xFF16A34A) : AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (busProvider.isLoading || (allFleetBuses.isEmpty && busProvider.routes.isEmpty)) ...[
                  const SkeletonLoader(width: double.infinity, height: 74),
                  const SizedBox(height: 10),
                  const SkeletonLoader(width: double.infinity, height: 74),
                ] else ...[
                  NearbyBusesList(
                    buses: allFleetBuses,
                    onBusTap: (BusModel bus) {
                      busProvider.selectBus(bus);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.busDetails,
                        arguments: bus,
                      );
                    },
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialBusesBanner(
    BuildContext context,
    List<SpecialShuttleModel> shuttles,
  ) {
    final firstShuttle = shuttles.first;
    final String subtitle = shuttles.length == 1
        ? '${firstShuttle.busName} • Departs ${firstShuttle.formattedDepartureTime}'
        : '${shuttles.length} special campus shuttles scheduled';

    return InkWell(
      onTap: () => _showSpecialBusesModal(context, shuttles),
      borderRadius: AppStyles.radiusLarge,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A2240), Color(0xFF15325B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppStyles.radiusLarge,
          border: Border.all(color: AppColors.goldAccent, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x220A2240),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Golden Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.goldAccent, Color(0xFFE5B81C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33FED136),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus_filled_rounded,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Special Buses',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          shuttles.length > 1 ? '${shuttles.length} Active' : 'Active',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFE2E8F0),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // View Details Button / Arrow
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      color: AppColors.goldAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.goldAccent,
                    size: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpecialBusesModal(
    BuildContext context,
    List<SpecialShuttleModel> shuttles,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Special Buses',
                              style: AppStyles.heading2.copyWith(fontSize: 18),
                            ),
                            Text(
                              '${shuttles.length} active scheduled run${shuttles.length > 1 ? 's' : ''}',
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.secondaryText),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content List
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: shuttles.length,
                  itemBuilder: (context, index) {
                    final shuttle = shuttles[index];
                    return SpecialShuttleBannerCard(
                      shuttle: shuttle,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
