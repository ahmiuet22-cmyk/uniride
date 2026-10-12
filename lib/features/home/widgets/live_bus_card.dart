import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/bus_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/status_badge.dart';

class LiveBusCard extends StatelessWidget {
  final BusModel bus;
  final VoidCallback onTrackLive;
  final VoidCallback onViewRoute;

  const LiveBusCard({
    super.key,
    required this.bus,
    required this.onTrackLive,
    required this.onViewRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppStyles.radiusLarge,
        border: AppStyles.cardBorder,
        boxShadow: const [AppColors.softShadow],
      ),
      child: Stack(
        children: [
          // Background subtle light blue top corner glow
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lightBlue.withOpacity(0.5),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Bus identity & Official Schedule Tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.goldBorder.withOpacity(0.6),
                        ),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: AppColors.goldDark,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus.name,
                            style: AppStyles.heading2.copyWith(fontSize: 17),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            bus.routeName,
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
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
                        color: (bus.status == BusStatusType.onRoute ? const Color(0xFFDCFCE7) : AppColors.goldLight),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (bus.status == BusStatusType.onRoute
                              ? const Color(0xFF86EFAC)
                              : AppColors.goldBorder.withOpacity(0.6)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (bus.status == BusStatusType.onRoute) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'LIVE ON ROUTE',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
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

                const SizedBox(height: 16),

                // Schedule Time Highlight Box (Switches to Live ETA when driver is active)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppStyles.radiusMedium,
                    border: Border.all(color: AppColors.border.withOpacity(0.6)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus.status == BusStatusType.onRoute ? 'ESTIMATED ETA' : 'MORNING PICKUP',
                            style: AppStyles.sectionTitle.copyWith(fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                bus.status == BusStatusType.onRoute
                                    ? (bus.etaMinutes > 0
                                        ? '${bus.etaMinutes}'
                                        : '${(bus.distanceKm / 35.0 * 60).round().clamp(3, 45)}')
                                    : '7:00',
                                style: AppStyles.etaLarge.copyWith(fontSize: 26),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                bus.status == BusStatusType.onRoute ? 'min' : 'am',
                                style: AppStyles.heading3.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        height: 42,
                        width: 1,
                        color: AppColors.border,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bus.status == BusStatusType.onRoute ? 'LIVE SPEED' : 'CAMPUS ARRIVAL',
                                style: AppStyles.sectionTitle.copyWith(fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (bus.status == BusStatusType.onRoute) ...[
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: bus.speed > 0 ? const Color(0xFF16A34A) : const Color(0xFFEAB308),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                  Text(
                                    bus.status == BusStatusType.onRoute
                                        ? (bus.speed > 0 ? '${bus.speed.toInt()} km/h' : '0 km/h (Stopped)')
                                        : '8:30 am',
                                    style: AppStyles.heading3.copyWith(
                                      fontSize: 16,
                                      color: AppColors.primaryText,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                bus.status == BusStatusType.onRoute
                                    ? 'Next: ${bus.nextStop}'
                                    : 'Return: 4:15 pm sharp',
                                style: AppStyles.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Key Route Details Chips
                Row(
                  children: [
                    _buildMetricChip(
                      icon: Icons.place_outlined,
                      label: 'Key Stop',
                      value: 'Sheikhupura Mor (7:15 am)',
                    ),
                    const SizedBox(width: 10),
                    _buildMetricChip(
                      icon: Icons.person_outline_rounded,
                      label: 'Driver',
                      value: bus.driver.name,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: bus.status == BusStatusType.onRoute ? 'TRACK LIVE' : 'VIEW ROUTE',
                        icon: bus.status == BusStatusType.onRoute
                            ? Icons.gps_fixed_rounded
                            : Icons.alt_route_rounded,
                        height: 44,
                        onPressed: bus.status == BusStatusType.onRoute ? onTrackLive : onViewRoute,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        text: 'TIMETABLE',
                        isOutlined: true,
                        icon: Icons.schedule_rounded,
                        height: 44,
                        onPressed: onTrackLive,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.blueAccentSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.goldDark),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: AppStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.secondaryText),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: AppStyles.buttonText.copyWith(
                fontSize: 12,
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
