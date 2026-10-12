import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../data/models/bus_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/status_badge.dart';

class BusDetailBottomSheet extends StatefulWidget {
  final BusModel bus;
  final VoidCallback onTrackRoute;
  final VoidCallback onBusDetails;
  final VoidCallback? onClose;

  const BusDetailBottomSheet({
    super.key,
    required this.bus,
    required this.onTrackRoute,
    required this.onBusDetails,
    this.onClose,
  });

  @override
  State<BusDetailBottomSheet> createState() => _BusDetailBottomSheetState();
}

class _BusDetailBottomSheetState extends State<BusDetailBottomSheet> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x200F172A),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar & Quick toggle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isCollapsed = !_isCollapsed;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Bus Header & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: widget.bus.isSpecial ? AppColors.goldLight : AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(12),
                            border: widget.bus.isSpecial ? Border.all(color: AppColors.goldBorder) : null,
                          ),
                          child: Icon(
                            widget.bus.isSpecial ? Icons.bolt_rounded : Icons.directions_bus_rounded,
                            color: widget.bus.isSpecial ? AppColors.primaryBlue : AppColors.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.bus.name,
                                    style: AppStyles.heading2.copyWith(fontSize: 17),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (widget.bus.isSpecial) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.goldLight,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.goldBorder),
                                      ),
                                      child: const Text(
                                        '⚡ SPECIAL',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primaryBlue,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                widget.bus.isSpecial
                                    ? '${widget.bus.specialPurpose ?? 'Special Transit'} • ${widget.bus.routeName}'
                                    : widget.bus.routeName,
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: widget.bus.status),
                  const SizedBox(width: 6),
                  // Collapse / Close icons
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      _isCollapsed ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.secondaryText,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCollapsed = !_isCollapsed;
                      });
                    },
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.mutedText,
                        size: 20,
                      ),
                      onPressed: widget.onClose,
                    ),
                ],
              ),

              // If collapsed, only show single slim summary line
              if (_isCollapsed) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next: ${widget.bus.nextStop} • Speed: ${widget.bus.speed.toInt()} km/h',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Campus ETA ${widget.bus.etaMinutes} min',
                      style: AppStyles.badgeText.copyWith(color: AppColors.primaryText),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 14),

                // Metrics Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Campus ETA', '${widget.bus.etaMinutes} min', AppColors.primaryBlue),
                      Container(height: 26, width: 1, color: const Color(0xFFE2E8F0)),
                      _buildStatItem('Next Stop', widget.bus.nextStop, AppColors.primaryText),
                      Container(height: 26, width: 1, color: const Color(0xFFE2E8F0)),
                      _buildStatItem('Speed', '${widget.bus.speed.toStringAsFixed(0)} km/h', AppColors.primaryText),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.bus.status == BusStatusType.onRoute
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.bus.status == BusStatusType.onRoute
                              ? (widget.bus.speed < 2 ? 'At Stop / Boarding' : 'Live on route')
                              : 'Standby / Off-Duty',
                          style: AppStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: widget.bus.status == BusStatusType.onRoute
                                ? const Color(0xFF16A34A)
                                : AppColors.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Driver: ${widget.bus.driver.name}',
                      style: AppStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'ROUTE STOPS',
                        icon: Icons.alt_route_rounded,
                        height: 44,
                        onPressed: widget.onTrackRoute,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        text: 'BUS DETAILS',
                        isOutlined: true,
                        height: 44,
                        onPressed: widget.onBusDetails,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: AppStyles.bodySmall.copyWith(fontSize: 10.5, color: AppColors.secondaryText),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppStyles.buttonText.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
