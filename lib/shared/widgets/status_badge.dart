import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

enum BusStatusType { onRoute, approaching, stopped, delayed }

class StatusBadge extends StatelessWidget {
  final BusStatusType status;
  final bool showDot;

  const StatusBadge({
    super.key,
    required this.status,
    this.showDot = true,
  });

  factory StatusBadge.fromString(String statusStr) {
    final lower = statusStr.toLowerCase();
    if (lower.contains('approach')) {
      return const StatusBadge(status: BusStatusType.approaching);
    } else if (lower.contains('delay')) {
      return const StatusBadge(status: BusStatusType.delayed);
    } else if (lower.contains('stop')) {
      return const StatusBadge(status: BusStatusType.stopped);
    }
    return const StatusBadge(status: BusStatusType.onRoute);
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case BusStatusType.onRoute:
        bg = AppColors.lightBlue;
        fg = AppColors.primaryBlue;
        label = 'ACTIVE';
        break;
      case BusStatusType.approaching:
        bg = AppColors.lightBlue;
        fg = AppColors.primaryBlue;
        label = 'ON SCHEDULE';
        break;
      case BusStatusType.stopped:
        bg = const Color(0xFFF1F5F9);
        fg = AppColors.secondaryText;
        label = 'STANDBY';
        break;
      case BusStatusType.delayed:
        bg = AppColors.lightBlue;
        fg = AppColors.primaryBlue;
        label = 'SCHEDULED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppStyles.badgeText.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
