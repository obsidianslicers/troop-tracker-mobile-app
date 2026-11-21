import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/services/push_notification_service.dart';

import '../support/fake_messaging.dart';

void main() {
  late FakeMessaging messaging;
  late StreamController<RemoteMessage> openedApp;

  setUp(() {
    PushNotificationService.reset();
    messaging = FakeMessaging();
    openedApp = StreamController<RemoteMessage>.broadcast();
  });

  tearDown(() => openedApp.close());

  Future<void> initialize() =>
      PushNotificationService.initialize(messaging: messaging, openedApp: openedApp.stream);

  group('initialize', () {
    test('asks for permission and shows notifications in the foreground', () async {
      await initialize();

      expect(messaging.calls, [
        'requestPermission',
        'setForegroundNotificationPresentationOptions',
      ]);
    });

    test('stores the token and hands it to the token handler', () async {
      final tokens = <String>[];
      PushNotificationService.setTokenReadyHandler(tokens.add);

      await initialize();

      expect(PushNotificationService.currentToken, 'token-1');
      expect(tokens, ['token-1']);
    });

    test('carries on when there is no token yet', () async {
      messaging.token = null;
      final tokens = <String>[];
      PushNotificationService.setTokenReadyHandler(tokens.add);

      await initialize();

      expect(PushNotificationService.currentToken, isNull);
      expect(tokens, isEmpty);
    });

    test('carries on when getting the token fails, and takes a refreshed one', () async {
      messaging.getTokenError = Exception('APNS token not set');
      final tokens = <String>[];
      PushNotificationService.setTokenReadyHandler(tokens.add);

      await initialize();
      expect(PushNotificationService.currentToken, isNull);

      messaging.tokenRefresh.add('token-2');
      await pumpEventQueue();

      expect(PushNotificationService.currentToken, 'token-2');
      expect(tokens, ['token-2']);
    });

    test('routes a notification tapped while the app was in the background', () async {
      final urls = <String>[];
      PushNotificationService.setDeepLinkHandler(urls.add);

      await initialize();
      openedApp.add(tappedNotification('/events/7'));
      await pumpEventQueue();

      expect(urls, ['/events/7']);
    });

    test('keeps the notification that launched the app until the WebView is ready', () async {
      messaging.initialMessage = tappedNotification('/events/9');

      await initialize();
      final urls = <String>[];
      PushNotificationService.setDeepLinkHandler(urls.add);

      expect(urls, ['/events/9']);
    });
  });

  group('handleMessage', () {
    test('ignores a notification without a url', () {
      final urls = <String>[];
      PushNotificationService.setDeepLinkHandler(urls.add);

      PushNotificationService.handleMessage(tappedNotification(null));

      expect(urls, isEmpty);
    });

    test('delivers a pending link only once', () {
      PushNotificationService.handleMessage(tappedNotification('/events/1'));
      final first = <String>[];
      final second = <String>[];

      PushNotificationService.setDeepLinkHandler(first.add);
      PushNotificationService.setDeepLinkHandler(second.add);

      expect(first, ['/events/1']);
      expect(second, isEmpty);
    });

    test('takePendingUrl hands over a pending link only once', () {
      PushNotificationService.handleMessage(tappedNotification('/events/1'));
      final urls = <String>[];

      expect(PushNotificationService.takePendingUrl(), '/events/1');
      expect(PushNotificationService.takePendingUrl(), isNull);

      PushNotificationService.setDeepLinkHandler(urls.add);
      expect(urls, isEmpty);
    });
  });

  test('setTokenReadyHandler gets a token that is already known', () {
    PushNotificationService.currentToken = 'known';
    final tokens = <String>[];

    PushNotificationService.setTokenReadyHandler(tokens.add);

    expect(tokens, ['known']);
  });
}
