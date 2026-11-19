import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging setup: permission, the device token, and routing a
/// tapped notification to its page in the WebView.
abstract final class PushNotificationService {
  static String? currentToken;
  static void Function(String url)? _onDeepLink;
  static String? _pendingUrl;
  static void Function(String token)? _onTokenReady;

  /// Called with a notification's URL when the user taps it. A tap that
  /// launched the app before the WebView was ready is delivered here at once.
  static void setDeepLinkHandler(void Function(String url) handler) {
    _onDeepLink = handler;
    final pending = _pendingUrl;
    if (pending != null) {
      _pendingUrl = null;
      handler(pending);
    }
  }

  /// Called with the FCM token whenever it becomes available or changes.
  static void setTokenReadyHandler(void Function(String token) handler) {
    _onTokenReady = handler;
    final token = currentToken;
    if (token != null) handler(token);
  }

  /// [messaging] and [openedApp] default to Firebase; tests pass fakes.
  static Future<void> initialize({
    FirebaseMessaging? messaging,
    Stream<RemoteMessage>? openedApp,
  }) async {
    final fcm = messaging ?? FirebaseMessaging.instance;

    final settings = await fcm.requestPermission(alert: true, badge: true, sound: true);
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    await fcm.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);

    try {
      _setToken(await fcm.getToken());
      debugPrint('[FCM] Token: $currentToken');
    } catch (e) {
      // On iOS the APNS token may not be registered yet at cold start
      // (common on simulators / first launch). Don't block app startup —
      // onTokenRefresh will pick it up once APNs registration completes.
      debugPrint('[FCM] getToken failed, will retry via onTokenRefresh: $e');
    }

    fcm.onTokenRefresh.listen((token) {
      debugPrint('[FCM] Token refreshed: $token');
      _setToken(token);
    });

    // App opened by tapping a notification while in background.
    (openedApp ?? FirebaseMessaging.onMessageOpenedApp).listen(handleMessage);

    // App launched from a terminated state by tapping a notification.
    // _onDeepLink is not set yet here — handleMessage stores the url in _pendingUrl
    // and setDeepLinkHandler() flushes it once the WebView is ready.
    final initialMessage = await fcm.getInitialMessage();
    if (initialMessage != null) handleMessage(initialMessage);
  }

  /// Routes a tapped notification's `url` data to the deep link handler.
  @visibleForTesting
  static void handleMessage(RemoteMessage message) {
    final url = message.data['url'] as String?;
    debugPrint('[FCM] notification tapped, url: $url');
    if (url == null) return;
    final onDeepLink = _onDeepLink;
    if (onDeepLink != null) {
      onDeepLink(url);
    } else {
      _pendingUrl = url;
    }
  }

  /// Forgets the token, handlers and any pending deep link.
  @visibleForTesting
  static void reset() {
    currentToken = null;
    _onDeepLink = null;
    _pendingUrl = null;
    _onTokenReady = null;
  }

  static void _setToken(String? token) {
    currentToken = token;
    if (token != null) _onTokenReady?.call(token);
  }
}
