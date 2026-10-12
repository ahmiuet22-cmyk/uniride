import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/routes/app_routes.dart';
import '../../../providers/bus_provider.dart';

import '../../../shared/widgets/skeleton_loader.dart';

class ScheduleScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const ScheduleScreen({super.key, this.onOpenDrawer});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedRouteIndex = 0; // 0 to 4 for Route 1 to 5
  bool _hasInitializedRoute = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedRoute) {
      final busProvider = Provider.of<BusProvider>(context, listen: false);
      if (busProvider.selectedRoute != null) {
        final idx = busProvider.routes.indexWhere((r) => r.id == busProvider.selectedRoute!.id);
        if (idx != -1) {
          _selectedRouteIndex = idx;
        }
      }
      _hasInitializedRoute = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = Provider.of<BusProvider>(context);
    final routes = busProvider.routes;

    if (busProvider.isLoading || routes.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Bus Timetable', style: AppStyles.appBarTitle),
          centerTitle: false,
          leading: widget.onOpenDrawer != null
              ? IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: widget.onOpenDrawer,
                )
              : null,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                const SkeletonLoader(
                  width: double.infinity,
                  height: 42,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                const SizedBox(height: 12),
                const SkeletonLoader(
                  width: double.infinity,
                  height: 130,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, __) => const SkeletonLoader(
                      width: double.infinity,
                      height: 60,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentRoute = routes[_selectedRouteIndex.clamp(0, routes.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Bus Timetable', style: AppStyles.appBarTitle),
        centerTitle: false,
        leading: widget.onOpenDrawer != null
            ? IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: widget.onOpenDrawer,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Route Selector Horizontal Pills
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(routes.length, (index) {
                    final r = routes[index];
                    final isSel = _selectedRouteIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRouteIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.goldLight : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSel ? AppColors.goldBorder : AppColors.border,
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          r.code,
                          style: AppStyles.buttonText.copyWith(
                            fontSize: 13,
                            color: isSel ? AppColors.goldDark : AppColors.primaryText,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Route Header Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                width: double.infinity,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(currentRoute.title, style: AppStyles.heading3.copyWith(fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.goldBorder.withOpacity(0.6)),
                          ),
                          child: Text(
                            'Active Fleet',
                            style: AppStyles.badgeText.copyWith(color: AppColors.goldDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentRoute.description,
                      style: AppStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildTimeChip('Morning Departure', currentRoute.stops.first.morningTiming),
                        const SizedBox(width: 8),
                        _buildTimeChip('Campus Arrival', currentRoute.stops.last.morningTiming),
                        const SizedBox(width: 8),
                        _buildTimeChip('Return Time', '4:15 PM'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Stops and Timings List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('STOPS & SCHEDULED TIMINGS', style: AppStyles.sectionTitle),
                  Text('${currentRoute.stops.length} Stops', style: AppStyles.bodySmall),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: currentRoute.stops.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final stop = currentRoute.stops[index];
                  final isFirst = index == 0;
                  final isLast = index == currentRoute.stops.length - 1;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.stopDetails,
                        arguments: stop,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppStyles.radiusMedium,
                        border: Border.all(
                          color: isFirst || isLast
                              ? AppColors.primaryBlue.withOpacity(0.4)
                              : AppColors.border.withOpacity(0.6),
                          width: isFirst || isLast ? 1.5 : 1,
                        ),
                        boxShadow: const [AppColors.cardShadow],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isLast
                                  ? AppColors.goldLight
                                  : (isFirst ? AppColors.lightBlue : AppColors.background),
                              borderRadius: BorderRadius.circular(10),
                              border: isLast
                                  ? Border.all(color: AppColors.goldBorder.withOpacity(0.8))
                                  : null,
                            ),
                            child: Icon(
                              isLast
                                  ? Icons.school_rounded
                                  : (isFirst ? Icons.departure_board_rounded : Icons.place_rounded),
                              color: isLast
                                  ? AppColors.goldDark
                                  : (isFirst ? AppColors.primaryBlue : AppColors.secondaryText),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stop.name,
                                  style: AppStyles.bodyLarge.copyWith(
                                    fontWeight: isFirst || isLast ? FontWeight.w700 : FontWeight.w500,
                                    color: isLast ? AppColors.goldDark : AppColors.primaryText,
                                  ),
                                ),
                                Text(
                                  'Stop Code: ${stop.code}',
                                  style: AppStyles.bodySmall.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isLast ? AppColors.goldLight : AppColors.lightBlue,
                              borderRadius: BorderRadius.circular(8),
                              border: isLast
                                  ? Border.all(color: AppColors.goldBorder.withOpacity(0.8))
                                  : null,
                            ),
                            child: Text(
                              stop.morningTiming,
                              style: AppStyles.buttonText.copyWith(
                                fontSize: 13,
                                color: isLast ? AppColors.goldDark : AppColors.primaryBlue,
                                fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildTimeChip(String label, String time) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppStyles.bodySmall.copyWith(fontSize: 9.5), maxLines: 1),
            const SizedBox(height: 2),
            Text(
              time,
              style: AppStyles.badgeText.copyWith(fontSize: 11.5, color: AppColors.primaryBlue),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
