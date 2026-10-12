enum NotificationCategory { info, warning, emergency, success }

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedBusId;
  final String? relatedRouteId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.relatedBusId,
    this.relatedRouteId,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    String? relatedBusId,
    String? relatedRouteId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedBusId: relatedBusId ?? this.relatedBusId,
      relatedRouteId: relatedRouteId ?? this.relatedRouteId,
    );
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.index,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'relatedBusId': relatedBusId,
        'relatedRouteId': relatedRouteId,
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationCategory cat = NotificationCategory.info;
    final rawCat = json['category'] ?? json['type'];
    if (rawCat is int && rawCat >= 0 && rawCat < NotificationCategory.values.length) {
      cat = NotificationCategory.values[rawCat];
    } else if (rawCat is String) {
      final l = rawCat.toLowerCase();
      if (l.contains('warn')) {
        cat = NotificationCategory.warning;
      } else if (l.contains('emerg') || l.contains('dang') || l.contains('urg')) {
        cat = NotificationCategory.emergency;
      } else if (l.contains('succ')) {
        cat = NotificationCategory.success;
      } else {
        cat = NotificationCategory.info;
      }
    }

    DateTime ts = DateTime.now();
    if (json['timestamp'] is String) {
      ts = DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now();
    } else if (json['timestamp'] is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int);
    }

    return NotificationModel(
      id: (json['id'] as String?) ?? 'alt_${DateTime.now().millisecondsSinceEpoch}',
      title: (json['title'] as String?) ?? 'Campus Announcement',
      description: (json['description'] as String?) ?? (json['message'] as String?) ?? '',
      category: cat,
      timestamp: ts,
      isRead: json['isRead'] as bool? ?? false,
      relatedBusId: json['relatedBusId'] as String?,
      relatedRouteId: (json['relatedRouteId'] as String?) ?? (json['routeId'] as String?),
    );
  }
}
