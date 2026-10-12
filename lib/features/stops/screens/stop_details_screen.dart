import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/mock/mock_stops.dart';
import '../../../data/models/stop_model.dart';
import '../../../providers/favorites_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../schedule/screens/schedule_screen.dart';

class StopDetailsScreen extends StatelessWidget {
  final BusStopModel? initialStop;

  const StopDetailsScreen({super.key, this.initialStop});

  @override
  Widget build(BuildContext context) {
    final favProvider = Provider.of<FavoritesProvider>(context);
    final args = ModalRoute.of(context)?.settings.arguments;
    final stop = (args is BusStopModel)
        ? args
        : (initialStop ?? MockStops.allStops.first);

    final isFav = favProvider.isFavorite(stop.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(stop.name, style: AppStyles.appBarTitle.copyWith(fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              color: isFav ? AppColors.goldAccent : Colors.white,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              favProvider.toggleFavorite(stop.id);
            },
          ),
          const SizedBox(width: 8),
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
                    // Stop Header Card
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
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.place_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(stop.name, style: AppStyles.heading2.copyWith(fontSize: 20)),
                                    Text(
                                      'Stop Code: ${stop.code} • UET Gujranwala (RCET)',
                                      style: AppStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: AppStyles.radiusMedium,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primaryBlue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    stop.morningTiming.isNotEmpty
                                        ? 'Scheduled Morning Pickup: ${stop.morningTiming}'
                                        : 'Official Campus Route Stop',
                                    style: AppStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () {
                              favProvider.setPickupStop(stop.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.radar_rounded, color: AppColors.goldAccent),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '${stop.name} set as primary stop! You will receive alerts when buses are within 5 km.',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppColors.primaryBlue,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                            borderRadius: AppStyles.radiusMedium,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: favProvider.selectedPickupStopId == stop.id
                                    ? const Color(0xFFDCFCE7)
                                    : AppColors.goldLight,
                                borderRadius: AppStyles.radiusMedium,
                                border: Border.all(
                                  color: favProvider.selectedPickupStopId == stop.id
                                      ? const Color(0xFF86EFAC)
                                      : AppColors.goldBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    favProvider.selectedPickupStopId == stop.id
                                        ? Icons.check_circle_rounded
                                        : Icons.radar_rounded,
                                    size: 18,
                                    color: favProvider.selectedPickupStopId == stop.id
                                        ? const Color(0xFF16A34A)
                                        : AppColors.goldDark,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      favProvider.selectedPickupStopId == stop.id
                                          ? 'Active Pickup Stop (5 km Proximity Alert ON)'
                                          : 'Set as My Pickup Stop for 5 km Bus Alerts',
                                      style: AppStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: favProvider.selectedPickupStopId == stop.id
                                            ? const Color(0xFF16A34A)
                                            : AppColors.goldDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Schedule Info Section
                    Text('OFFICIAL TIMETABLE SCHEDULE', style: AppStyles.sectionTitle),
                    const SizedBox(height: 14),

                    _buildArrivalCard(
                      'Morning Pickup',
                      stop.morningTiming.isNotEmpty ? stop.morningTiming : '7:20 AM',
                      'RCET Route Stop',
                      'Estimated morning bus arrival',
                      Icons.wb_sunny_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildArrivalCard(
                      'Campus Arrival',
                      '8:30 AM',
                      'RCET Campus Gujranwala',
                      'Official drop-off at main academic block',
                      Icons.school_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildArrivalCard(
                      'Evening Return',
                      '4:15 PM',
                      'Return to City / Terminal',
                      'All buses depart simultaneously from campus',
                      Icons.nightlight_round,
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom View Timetable Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: CustomButton(
                text: 'VIEW FULL TIMETABLE',
                icon: Icons.calendar_month_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScheduleScreen(),
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

  Widget _buildArrivalCard(
    String busName,
    String eta,
    String routeName,
    String note, [
    IconData icon = Icons.directions_bus_rounded,
  ]) {
    return Container(
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(busName, style: AppStyles.heading3.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  '$routeName • $note',
                  style: AppStyles.bodySmall.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              eta,
              style: AppStyles.etaMedium.copyWith(fontSize: 14, color: AppColors.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}
