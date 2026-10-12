import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/notification_model.dart';
import '../data/services/firebase_realtime_tracking_service.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _storageKey = 'uniride_dynamic_notifications_v1';
  static const String _deletedIdsKey = 'uniride_deleted_notification_ids_v1';
  final FirebaseRealtimeTrackingService _firebaseService = FirebaseRealtimeTrackingService();
  StreamSubscription<List<NotificationModel>>? _alertsSubscription;

  List<NotificationModel> _notifications = [];
  Set<String> _deletedNotificationIds = {};
  bool _isLoaded = false;
  List<NotificationModel>? _pendingFirebaseAlerts;

  NotificationProvider() {
    _init();
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoaded => _isLoaded;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  Future<void> _init() async {
    await _loadFromStorage();
    _initFirebaseAlertsSync();
  }

  String _getAlertSignature(NotificationModel alert) {
    return '${alert.title.trim().toLowerCase()}__${alert.description.trim().toLowerCase()}';
  }

  bool _isDeleted(NotificationModel alert) {
    if (_deletedNotificationIds.contains(alert.id)) return true;
    if (_deletedNotificationIds.contains(_getAlertSignature(alert))) return true;
    return false;
  }

  void _initFirebaseAlertsSync() {
    _firebaseService.startListening();
    _alertsSubscription = _firebaseService.alertsUpdatesStream.listen((liveAlerts) {
      if (liveAlerts.isNotEmpty) {
        _mergeFirebaseAlerts(liveAlerts);
      }
    });

    // Also fetch snapshot immediately on startup
    _firebaseService.fetchAlertsFromFirebase().then((liveAlerts) {
      if (liveAlerts != null && liveAlerts.isNotEmpty) {
        _mergeFirebaseAlerts(liveAlerts);
      }
    });
  }

  Future<void> refreshAlerts() async {
    final liveAlerts = await _firebaseService.fetchAlertsFromFirebase();
    if (liveAlerts != null && liveAlerts.isNotEmpty) {
      _mergeFirebaseAlerts(liveAlerts);
    }
  }

  void _mergeFirebaseAlerts(List<NotificationModel> liveAlerts) {
    // If local storage has not loaded deleted IDs yet, defer merge
    if (!_isLoaded) {
      _pendingFirebaseAlerts = liveAlerts;
      return;
    }

    // Filter out any notification that was deleted by the user (by ID or content signature)
    final nonDeletedAlerts = liveAlerts.where((a) => !_isDeleted(a)).toList();
    if (nonDeletedAlerts.isEmpty && liveAlerts.isNotEmpty) return;

    final Set<String> existingIds = _notifications.map((n) => n.id).toSet();
    final Map<String, bool> readStates = {for (var n in _notifications) n.id: n.isRead};

    bool hasChanged = false;
    for (final alert in nonDeletedAlerts) {
      final wasRead = readStates[alert.id] ?? false;
      if (existingIds.contains(alert.id)) {
        final idx = _notifications.indexWhere((n) => n.id == alert.id);
        if (idx != -1) {
          if (_notifications[idx].isRead != wasRead ||
              _notifications[idx].title != alert.title ||
              _notifications[idx].description != alert.description) {
            _notifications[idx] = alert.copyWith(isRead: wasRead);
            hasChanged = true;
          }
        }
      } else {
        _notifications.insert(0, alert.copyWith(isRead: wasRead));
        hasChanged = true;
      }
    }

    // Also remove any in-memory alerts that match newly deleted signatures
    final previousCount = _notifications.length;
    _notifications.removeWhere((n) => _isDeleted(n));
    if (_notifications.length != previousCount) {
      hasChanged = true;
    }

    if (hasChanged) {
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (_notifications.length > 50) {
        _notifications = _notifications.sublist(0, 50);
      }
      notifyListeners();
      _saveToStorage();
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedList = prefs.getStringList(_deletedIdsKey);
      if (deletedList != null) {
        _deletedNotificationIds = deletedList.toSet();
      }

      final rawList = prefs.getStringList(_storageKey);
      if (rawList != null && rawList.isNotEmpty) {
        _notifications = rawList
            .map((str) {
              try {
                final map = jsonDecode(str) as Map<String, dynamic>;
                return NotificationModel.fromJson(map);
              } catch (_) {
                return null;
              }
            })
            .whereType<NotificationModel>()
            .where((n) => !_isDeleted(n))
            .toList();
      } else {
        _notifications = [];
      }
    } catch (_) {
      _notifications = [];
    }

    _isLoaded = true;
    notifyListeners();

    // If any Firebase alerts arrived while storage was loading, merge them now safely
    if (_pendingFirebaseAlerts != null && _pendingFirebaseAlerts!.isNotEmpty) {
      _mergeFirebaseAlerts(_pendingFirebaseAlerts!);
      _pendingFirebaseAlerts = null;
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = _notifications.map((n) => jsonEncode(n.toJson())).toList();
      await prefs.setStringList(_storageKey, rawList);
    } catch (_) {}
  }

  Future<void> _saveDeletedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_deletedIdsKey, _deletedNotificationIds.toList());
    } catch (_) {}
  }

  void markAsRead(String id) {
    _notifications = _notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    notifyListeners();
    _saveToStorage();
  }

  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    _saveToStorage();
  }

  void addNotification(NotificationModel notification) {
    if (_isDeleted(notification)) {
      return; // Do not re-add previously deleted notification
    }
    // Avoid duplicate IDs
    _notifications.removeWhere((n) => n.id == notification.id);
    _notifications.insert(0, notification);
    if (_notifications.length > 50) {
      _notifications = _notifications.sublist(0, 50);
    }
    notifyListeners();
    _saveToStorage();
  }

  void deleteNotification(String id) {
    NotificationModel? targetAlert;
    for (final n in _notifications) {
      if (n.id == id) {
        targetAlert = n;
        break;
      }
    }

    _deletedNotificationIds.add(id);
    if (targetAlert != null) {
      _deletedNotificationIds.add(_getAlertSignature(targetAlert));
    }

    _notifications.removeWhere((n) => n.id == id || (targetAlert != null && _getAlertSignature(n) == _getAlertSignature(targetAlert)));
    notifyListeners();
    _saveToStorage();
    _saveDeletedIds();
  }

  void clearAll() {
    for (final n in _notifications) {
      _deletedNotificationIds.add(n.id);
      _deletedNotificationIds.add(_getAlertSignature(n));
    }
    _notifications.clear();
    notifyListeners();
    _saveToStorage();
    _saveDeletedIds();
  }

  @override
  void dispose() {
    _alertsSubscription?.cancel();
    super.dispose();
  }
}
