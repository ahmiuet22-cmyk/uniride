import '../models/notification_model.dart';

class MockNotifications {
  static final List<NotificationModel> initialNotifications = [
    NotificationModel(
      id: 'notif_01',
      title: 'GAU-2555 Approaching Pindi Bypass',
      description: 'Route 1 bus (GAU-2555) is approaching Pindi Bypass. Estimated arrival in 7 minutes.',
      category: NotificationCategory.info,
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      isRead: false,
      relatedBusId: 'bus_gau_2555',
      relatedRouteId: 'route_1',
    ),
    NotificationModel(
      id: 'notif_02',
      title: 'Route 2 Traffic Advisory',
      description: 'Hino Bus LEJ-6832 experiencing 5-minute delay near Sialkot bypass due to morning school rush.',
      category: NotificationCategory.warning,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      relatedBusId: 'bus_lej_6832',
      relatedRouteId: 'route_2',
    ),
    NotificationModel(
      id: 'notif_03',
      title: 'Evening Return Schedule Notice',
      description: 'All buses departure from RCET Campus is scheduled at 4:15 PM sharp today.',
      category: NotificationCategory.success,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
    ),
    NotificationModel(
      id: 'notif_04',
      title: 'Transport Control Notice',
      description: 'For any route assistance or timing queries, contact Mr. Waqas Butt (Transport Assistant) at 0302-6669662.',
      category: NotificationCategory.info,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
    ),
  ];
}
