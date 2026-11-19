import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/push_notification.dart';
import '../services/notification_api_service.dart';

/// The notification inbox shown on the Notifications tab. Keeps the app icon
/// badge in step with the unread count.
class NotificationsController extends ChangeNotifier {
  NotificationsController({
    NotificationApiService? api,
    Future<void> Function(int count)? updateBadge,
    DateTime Function()? now,
  })  : _api = api ?? NotificationApiService(),
        _updateBadge = updateBadge ?? AppBadgePlus.updateBadge,
        _now = now ?? DateTime.now;

  final NotificationApiService _api;
  final Future<void> Function(int count) _updateBadge;
  final DateTime Function() _now;

  List<PushNotification> _notifications = [];
  bool _isLoading = false;

  List<PushNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => n.isUnread).length;

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    _notifications = await _api.fetchAll();
    _isLoading = false;
    await _syncBadge();
    notifyListeners();
  }

  Future<void> markRead(PushNotification notification) async {
    if (!notification.isUnread) return;
    await _api.markRead(notification.id);
    final readAt = _now();
    _notifications = _notifications
        .map((n) => n.id == notification.id ? n.copyWith(readAt: readAt) : n)
        .toList();
    await _syncBadge();
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _api.clearAll();
    _notifications = [];
    await _syncBadge();
    notifyListeners();
  }

  Future<void> clearForLogout() async {
    _notifications = [];
    await _syncBadge();
    notifyListeners();
  }

  // A device without badge support must not break the inbox.
  Future<void> _syncBadge() async {
    try {
      await _updateBadge(unreadCount);
    } catch (e) {
      debugPrint('[Badge] update failed: $e');
    }
  }
}
