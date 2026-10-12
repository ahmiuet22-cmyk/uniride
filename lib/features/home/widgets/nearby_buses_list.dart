import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/bus_model.dart';
import '../../../shared/widgets/status_badge.dart';

class NearbyBusesList extends StatelessWidget {
  final List<BusModel> buses;
  final Function(BusModel) onBusTap;

  const NearbyBusesList({
    super.key,
    required this.buses,
    required this.onBusTap,
  });

  @override
  Widget build(BuildContext context) {
    if (buses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: AppStyles.radiusMedium,
          border: AppStyles.cardBorder,
        ),
        child: Center(
          child: Text('No campus buses available', style: AppStyles.bodyMedium),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: buses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bus = buses[index];
        return _NearbyBusTile(
          bus: bus,
          onTap: () => onBusTap(bus),
        );
      },
    );
  }
}

class _NearbyBusTile extends StatefulWidget {
  final BusModel bus;
  final VoidCallback onTap;

  const _NearbyBusTile({required this.bus, required this.onTap});

  @override
  State<_NearbyBusTile> createState() => _NearbyBusTileState();
}

class _NearbyBusTileState extends State<_NearbyBusTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isLive = widget.bus.status == BusStatusType.onRoute;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 90),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          HapticFeedback.lightImpact();
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppStyles.radiusMedium,
            border: Border.all(
              color: isLive ? const Color(0xFF86EFAC) : AppColors.border,
              width: isLive ? 1.4 : 1.0,
            ),
            boxShadow: [
              if (isLive)
                BoxShadow(
                  color: const Color(0xFF22C55E).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              else
                AppColors.cardShadow,
            ],
          ),
          child: Row(
            children: [
              // Bus Icon Box with Live Status Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isLive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isLive ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: isLive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                      size: 24,
                    ),
                  ),
                  if (isLive)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // Bus Name & Dynamic Route Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.bus.name,
                            style: AppStyles.heading3.copyWith(
                              fontSize: 14.5,
                              color: isLive ? AppColors.primaryBlue : AppColors.primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Live GPS vs Standby Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isLive ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLive) ...[
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF16A34A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 3),
                              ],
                              Text(
                                isLive ? 'LIVE' : 'STANDBY',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: isLive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLive
                          ? '${widget.bus.routeName} • Next: ${widget.bus.nextStop}'
                          : '${widget.bus.routeName} • Standby',
                      style: AppStyles.bodySmall.copyWith(
                        fontSize: 12,
                        color: isLive ? AppColors.primaryText : AppColors.secondaryText,
                        fontWeight: isLive ? FontWeight.w500 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Trailing Action / Distance info
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isLive) ...[
                    Text(
                      '${widget.bus.etaMinutes}m ETA',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.bus.distanceKm} km',
                      style: AppStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.mutedText),
                    ),
                  ] else ...[
                    Text(
                      'Standby',
                      style: AppStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 2),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText, size: 18),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
