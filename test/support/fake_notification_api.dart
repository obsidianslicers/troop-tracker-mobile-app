import 'dart:async';

import 'package:tt_mobile_app/models/push_notification.dart';
import 'package:tt_mobile_app/services/notification_api_service.dart';

/// An inbox held in memory instead of on the tracker.
class FakeNotificationApi implements NotificationApiService {
  FakeNotificationApi([List<PushNotification>? inbox]) : inbox = inbox ?? [];

  List<PushNotification> inbox;
  final List<String> markedRead = [];
  int fetches = 0;
  int cleared = 0;

  /// When set, fetchAll() waits for it, so a test can look mid-load.
  Completer<void>? fetchGate;

  @override
  Future<List<PushNotification>> fetchAll() async {
    fetches++;
    await fetchGate?.future;
    return List.of(inbox);
  }

  @override
  Future<void> markRead(String id) async => markedRead.add(id);

  @override
  Future<void> clearAll() async {
    cleared++;
    inbox = [];
  }
}
