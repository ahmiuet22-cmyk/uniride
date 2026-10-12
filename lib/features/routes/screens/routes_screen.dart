import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/route_model.dart';
import '../../../providers/bus_provider.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/status_badge.dart';

class RoutesScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const RoutesScreen({super.key, this.onOpenDrawer});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);
    final allRoutes = busProvider.routes;

    final filteredRoutes = allRoutes.where((route) {
      if (_filter.isEmpty) return true;
      final query = _filter.toLowerCase();
      final titleMatch = route.title.toLowerCase().contains(query);
      final codeMatch = route.code.toLowerCase().contains(query);
      final stopMatch = route.stops.any((s) => s.name.toLowerCase().contains(query));
      return titleMatch || codeMatch || stopMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Bus Routes', style: AppStyles.appBarTitle),
        centerTitle: false,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: widget.onOpenDrawer,
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Route Finder',
            icon: const Icon(Icons.explore_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.routeFinder),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Route Finder Quick Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 4.0),
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.routeFinder),
                borderRadius: AppStyles.radiusMedium,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryBlue, Color(0xFF003D8F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppStyles.radiusMedium,
                    boxShadow: const [AppColors.cardShadow],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route Finder / Trip Planner',
                              style: AppStyles.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Find direct bus from your stop to campus',
                              style: AppStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 13),
                    ],
                  ),
                ),
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _filter = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search routes or stops...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.secondaryBlue),
                  suffixIcon: _filter.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.mutedText),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _filter = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Routes List
            Expanded(
              child: busProvider.isLoading
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: 4,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, __) => const SkeletonLoader(
                        width: double.infinity,
                        height: 90,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    )
                  : filteredRoutes.isEmpty
                      ? EmptyStateView(
                          icon: Icons.alt_route_rounded,
                          title: 'No Routes Found',
                          message: 'No campus shuttle routes match "$_filter".',
                          buttonText: 'Clear Search',
                          onButtonPressed: () {
                            _searchController.clear();
                            setState(() => _filter = '');
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredRoutes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final route = filteredRoutes[index];
                        return _RouteCard(
                          route: route,
                          onTap: () {
                            busProvider.selectRoute(route);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.routeDetails,
                              arguments: route,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatefulWidget {
  final RouteModel route;
  final VoidCallback onTap;

  const _RouteCard({required this.route, required this.onTap});

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 90),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          padding: const EdgeInsets.all(18),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldBorder.withOpacity(0.6)),
                    ),
                    child: Text(
                      widget.route.code,
                      style: AppStyles.badgeText.copyWith(
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StatusBadge(
                    status: widget.route.isActive ? BusStatusType.onRoute : BusStatusType.stopped,
                    showDot: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.route.title,
                style: AppStyles.heading2.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                widget.route.description,
                style: AppStyles.bodySmall.copyWith(fontSize: 12, color: AppColors.secondaryText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: AppColors.divider.withOpacity(0.8)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: AppColors.secondaryBlue),
                      const SizedBox(width: 4),
                      Text('${widget.route.totalStops} stops', style: AppStyles.bodySmall),
                      const SizedBox(width: 14),
                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.secondaryBlue),
                      const SizedBox(width: 4),
                      Text('${widget.route.estimatedDurationMinutes} min', style: AppStyles.bodySmall),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.directions_bus_filled_rounded, size: 16, color: AppColors.goldDark),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.route.activeBusCount} buses',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.goldDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.mutedText),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
