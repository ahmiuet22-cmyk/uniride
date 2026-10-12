import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/bus_model.dart';
import '../../../shared/widgets/status_badge.dart';

class BusMarkerWidget extends StatelessWidget {
  final BusModel bus;
  final bool isSelected;
  final VoidCallback onTap;

  const BusMarkerWidget({
    super.key,
    required this.bus,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color themeColor = AppColors.primaryBlue;
    if (bus.status == BusStatusType.approaching) {
      themeColor = AppColors.warning;
    } else if (bus.status == BusStatusType.delayed) {
      themeColor = AppColors.danger;
    }

    final isLive = bus.status == BusStatusType.onRoute;

    // User requirement: "jo bus standby pr ha usko route k starting point pr rkho sirf bus icon aye"
    // When bus is on standby, render ONLY a clean bus icon (no radar ripples, no telemetry pill)
    if (!isLive) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: isSelected ? 40 : 36,
            height: isSelected ? 40 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bus.isSpecial
                  ? const Color(0xFF6B21A8)
                  : (isSelected ? AppColors.primaryBlue : const Color(0xFF334155)),
              border: Border.all(
                color: bus.isSpecial
                    ? const Color(0xFFFED136)
                    : (isSelected ? AppColors.goldAccent : Colors.white),
                width: (isSelected || bus.isSpecial) ? 2.5 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: bus.isSpecial
                      ? const Color(0xFF6B21A8).withOpacity(0.40)
                      : (isSelected
                          ? AppColors.primaryBlue.withOpacity(0.40)
                          : Colors.black.withOpacity(0.25)),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                bus.isSpecial ? Icons.bolt_rounded : Icons.directions_bus_rounded,
                color: bus.isSpecial
                    ? const Color(0xFFFED136)
                    : (isSelected ? AppColors.goldAccent : Colors.white),
                size: isSelected ? 21 : 18,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Radar ripple wave (Glow effect for Live tracking)
          if (isLive || isSelected) ...[
            Container(
              width: isSelected ? 68 : 52,
              height: isSelected ? 68 : 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (bus.isSpecial
                        ? AppColors.goldAccent
                        : (isSelected ? AppColors.goldAccent : themeColor))
                    .withOpacity(0.18),
              ),
            ),
            Container(
              width: isSelected ? 52 : 42,
              height: isSelected ? 52 : 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (bus.isSpecial
                        ? AppColors.goldAccent
                        : (isSelected ? AppColors.goldAccent : themeColor))
                    .withOpacity(0.28),
              ),
            ),
          ],

          // 2. Main 3D Transit Bus Pin
          Container(
            width: isSelected ? 40 : 34,
            height: isSelected ? 40 : 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bus.isSpecial
                    ? [const Color(0xFF1E3E62), AppColors.primaryBlue]
                    : (isSelected
                        ? [const Color(0xFF1E3A8A), AppColors.primaryBlue]
                        : [themeColor, themeColor.withOpacity(0.9)]),
              ),
              border: Border.all(
                color: bus.isSpecial
                    ? AppColors.goldAccent
                    : (isSelected ? AppColors.goldAccent : Colors.white),
                width: (isSelected || bus.isSpecial) ? 2.5 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: bus.isSpecial
                      ? AppColors.primaryBlue.withOpacity(0.45)
                      : (isSelected
                          ? AppColors.primaryBlue.withOpacity(0.45)
                          : Colors.black.withOpacity(0.25)),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                bus.isSpecial ? Icons.bolt_rounded : Icons.directions_bus_rounded,
                color: bus.isSpecial
                    ? AppColors.goldAccent
                    : (isSelected ? AppColors.goldAccent : Colors.white),
                size: isSelected ? 20 : 17,
              ),
            ),
          ),

          // 3. Floating live telemetry pill callout above pin
          Positioned(
            bottom: isSelected ? 44 : 38,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: bus.isSpecial
                          ? AppColors.goldBorder
                          : (isSelected ? AppColors.goldDark : const Color(0xFFE2E8F0)),
                      width: (isSelected || bus.isSpecial) ? 1.6 : 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x240F172A),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsing green live dot
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isLive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          boxShadow: isLive
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.6),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 5),
                      if (bus.isSpecial) ...[
                        const Text(
                          'SPECIAL • ',
                          style: TextStyle(
                            color: AppColors.goldDark,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                      Text(
                        bus.name,
                        style: TextStyle(
                          color: bus.isSpecial
                              ? AppColors.primaryBlue
                              : (isSelected ? AppColors.primaryBlue : AppColors.primaryText),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '•',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLive
                            ? (bus.speed > 0 ? '${bus.speed.toInt()} km/h' : '0 km/h')
                            : '${bus.etaMinutes}m',
                        style: TextStyle(
                          color: isLive ? const Color(0xFF16A34A) : AppColors.secondaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                // Small downward pointer triangle
                CustomPaint(
                  size: const Size(8, 4),
                  painter: _TrianglePainter(
                    color: isSelected ? AppColors.goldDark : const Color(0xFFCBD5E1),
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

class _TrianglePainter extends CustomPainter {
  final Color color;

  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}
