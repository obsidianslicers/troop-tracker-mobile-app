import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static String? currentToken;
  static void Function(String url)? _onDeepLink;
  static String? _pendingUrl;
  static void Function(String token)? _onTokenReady;

  static void setDeepLinkHandler(void Function(String url) handler) {
    _onDeepLink = handler;
    if (_pendingUrl != null) {
      handler(_pendingUrl!);
      _pendingUrl = null;
    }
  }

  static void setTokenReadyHandler(void Function(String token) handler) {
    _onTokenReady = handler;
    if (currentToken != null) {
      handler(currentToken!);
    }
  }

  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    try {
      currentToken = await messaging.getToken();
      debugPrint('[FCM] Token: $currentToken');
      if (currentToken != null) _onTokenReady?.call(currentToken!);
    } catch (e) {
      // On iOS the APNS token may not be registered yet at cold start
      // (common on simulators / first launch). Don't block app startup —
      // onTokenRefresh will pick it up once APNs registration completes.
      debugPrint('[FCM] getToken failed, will retry via onTokenRefresh: $e');
    }

    messaging.onTokenRefresh.listen((token) {
      debugPrint('[FCM] Token refreshed: $token');
      currentToken = token;
      _onTokenReady?.call(token);
    });

    // App opened by tapping a notification while in background.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // App launched from a terminated state by tapping a notification.
    // _onDeepLink is not set yet here — _handleMessage stores url in _pendingUrl
    // and setDeepLinkHandler() flushes it once the WebView is ready.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);
  }

  static void _handleMessage(RemoteMessage message) {
    final url = message.data['url'] as String?;
    debugPrint('[FCM] notification tapped, url: $url');
    if (url == null) return;
    if (_onDeepLink != null) {
      _onDeepLink!(url);
    } else {
      _pendingUrl = url;
    }
  }
}
