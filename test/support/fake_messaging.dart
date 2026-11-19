import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for FirebaseMessaging.instance.
class FakeMessaging extends Fake implements FirebaseMessaging {
  String? token = 'token-1';
  Object? getTokenError;
  RemoteMessage? initialMessage;
  final StreamController<String> tokenRefresh = StreamController<String>.broadcast();
  final List<String> calls = [];

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    calls.add('requestPermission');
    return const NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.notSupported,
      authorizationStatus: AuthorizationStatus.authorized,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.notSupported,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.notSupported,
      criticalAlert: AppleNotificationSetting.notSupported,
      sound: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.notSupported,
    );
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) async {
    calls.add('setForegroundNotificationPresentationOptions');
  }

  @override
  Future<String?> getToken({String? vapidKey}) async {
    final error = getTokenError;
    if (error != null) throw error;
    return token;
  }

  @override
  Stream<String> get onTokenRefresh => tokenRefresh.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;
}

/// A tapped notification that links to [url].
RemoteMessage tappedNotification(String? url) => RemoteMessage(data: {if (url != null) 'url': url});
