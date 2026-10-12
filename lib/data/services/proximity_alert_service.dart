import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_styles.dart';
import '../../data/models/bus_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/stop_model.dart';
import '../../providers/notification_provider.dart';
import '../../shared/widgets/status_badge.dart';

class ProximityAlertService {
  static final ProximityAlertService _instance = ProximityAlertService._internal();
  factory ProximityAlertService() => _instance;
  ProximityAlertService._internal();

  // 5 Kilometers distance threshold in meters
  static const double proximityThresholdMeters = 5000.0;

  // Track alerts sent for bus-stop pairs to avoid spamming
  final Map<String, DateTime> _alertedBuses = {};

  void checkProximity({
    required List<BusModel> buses,
    required BusStopModel studentStop,
    required NotificationProvider notifProvider,
    BuildContext? context,
    Function(BusModel bus)? onTrackBus,
  }) {
    final now = DateTime.now();

    for (final bus in buses) {
      if (bus.status != BusStatusType.onRoute) continue;

      final distanceMeters = Geolocator.distanceBetween(
        bus.location.latitude,
        bus.location.longitude,
        studentStop.location.latitude,
        studentStop.location.longitude,
      );

      final alertKey = '${bus.id}_${studentStop.id}';
      final lastAlertTime = _alertedBuses[alertKey];

      // If bus moves far away (> 8 km), reset alert flag so it can alert again on return trip
      if (distanceMeters > 8000.0 && lastAlertTime != null) {
        _alertedBuses.remove(alertKey);
        continue;
      }

      // Check if bus is within 5.0 km and not alerted in the last 15 minutes
      final shouldAlert = distanceMeters <= proximityThresholdMeters &&
          (lastAlertTime == null || now.difference(lastAlertTime).inMinutes >= 15);

      if (shouldAlert) {
        _alertedBuses[alertKey] = now;
        final distanceKm = (distanceMeters / 1000.0).toStringAsFixed(1);
        final calculatedEta = bus.etaMinutes > 0
            ? bus.etaMinutes
            : ((distanceMeters / 1000.0) / 35.0 * 60).round().clamp(1, 60);

        // 1. Add alert to NotificationProvider (Inbox / Alerts Tab)
        final notification = NotificationModel(
          id: 'prox_${bus.id}_${now.millisecondsSinceEpoch}',
          title: '🚍 Bus Approaching ($distanceKm km away)',
          description:
              '${bus.name} is now $distanceKm km from your stop (${studentStop.name}). Estimated arrival in ~$calculatedEta mins. Please get ready!',
          category: NotificationCategory.warning,
          timestamp: now,
          relatedBusId: bus.id,
          relatedRouteId: bus.routeId,
        );
        notifProvider.addNotification(notification);

        // 2. Trigger Haptic Vibration Feedback
        HapticFeedback.heavyImpact();

        // 3. Display interactive In-App Proximity SnackBar Banner if UI context is active
        if (context != null && context.mounted) {
          _showInAppProximityBanner(
            context: context,
            bus: bus,
            studentStop: studentStop,
            distanceKm: distanceKm,
            etaMinutes: calculatedEta,
            onTrack: () {
              if (onTrackBus != null) {
                onTrackBus(bus);
              }
            },
          );
        }
      }
    }
  }

  void _showInAppProximityBanner({
    required BuildContext context,
    required BusModel bus,
    required BusStopModel studentStop,
    required String distanceKm,
    required int etaMinutes,
    required VoidCallback onTrack,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0A2240),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFED136), width: 1.5),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFED136).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFED136)),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: Color(0xFFFED136),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'BUS APPROACHING',
                        style: AppStyles.badgeText.copyWith(
                          color: const Color(0xFFFED136),
                          letterSpacing: 1.0,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• $distanceKm KM AWAY',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bus.name} ➔ ${studentStop.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ETA: ~$etaMinutes mins. Please head to your stop.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onTrack();
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFED136),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'TRACK',
                style: TextStyle(
                  color: Color(0xFF0A2240),
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
