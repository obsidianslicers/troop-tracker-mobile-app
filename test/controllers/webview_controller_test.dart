import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/config/app_config.dart';
import 'package:tt_mobile_app/controllers/webview_controller.dart';
import 'package:tt_mobile_app/services/push_notification_service.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../support/fake_messaging.dart';
import '../support/fake_url_launcher.dart';
import '../support/fake_webview_platform.dart';
import '../support/test_env.dart';

void main() {
  late FakeWebViewPlatform platform;
  late FakeUrlLauncher launcher;
  late WebviewController subject;
  late int notifications;

  FakeWebViewController webView() => platform.controller;

  setUp(() {
    loadTestEnv(internalDomains: 'forum.example.net');
    PushNotificationService.reset();
    WebViewPlatform.instance = platform = FakeWebViewPlatform();
    UrlLauncherPlatform.instance = launcher = FakeUrlLauncher();
    subject = WebviewController();
    notifications = 0;
    subject.addListener(() => notifications++);
  });

  tearDown(() => subject.dispose());

  group('initialize', () {
    test('loads the tracker with JavaScript on and the splash background', () {
      subject.initialize();

      expect(subject.webViewController, isNotNull);
      expect(webView().loadedUrls, [testTrackerUrl]);
      expect(webView().javaScriptMode, JavaScriptMode.unrestricted);
      expect(webView().backgroundColor, AppConfig.splashBackgroundColor);
      expect(subject.isLoading, isTrue);
      expect(subject.isLoggedIn, isNull);
    });

    test('keeps the default user agent on iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        subject.initialize();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }

      expect(webView().userAgent, isNull);
    });

    test('sends a plain mobile Chrome user agent on Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        subject.initialize();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }

      expect(webView().userAgent, contains('Chrome/'));
      expect(webView().userAgent, isNot(contains('; wv)')));
    });

    test('routes a tapped notification into the WebView', () {
      subject.initialize();

      PushNotificationService.handleMessage(tappedNotification('events/42'));

      expect(webView().loadedUrls.last, 'https://tracker.example.org/events/42');
    });

    test('accepts console messages from the page', () {
      subject.initialize();

      webView().onConsoleMessage!(
        const JavaScriptConsoleMessage(level: JavaScriptLogLevel.log, message: 'hello'),
      );
    });
  });

  group('page loads', () {
    setUp(() => subject.initialize());

    test('tracks progress', () {
      webView().delegate!.onProgress!(40);

      expect(subject.loadingProgress, 0.4);
      expect(notifications, 1);
    });

    test('a started page clears an earlier error', () {
      webView().fail(description: 'offline');
      expect(subject.hasError, isTrue);

      webView().delegate!.onPageStarted!(testTrackerUrl);

      expect(subject.hasError, isFalse);
      expect(subject.errorMessage, isEmpty);
      expect(subject.isLoading, isTrue);
    });

    test('a finished page stops loading and overrides window.open', () async {
      await webView().finishPage(testTrackerUrl);

      expect(subject.isLoading, isFalse);
      expect(webView().scripts, contains(startsWith('window.open = function')));
    });

    test('reads the signed-in state from the page', () async {
      webView().authStateResult = '"true"';

      await webView().finishPage(testTrackerUrl);

      expect(subject.isLoggedIn, isTrue);
    });

    test('reads the signed-out state from the page', () async {
      webView().authStateResult = 'false';

      await webView().finishPage(testTrackerUrl);

      expect(subject.isLoggedIn, isFalse);
    });

    test('only notifies when the signed-in state changes', () async {
      webView().authStateResult = 'true';
      await webView().finishPage(testTrackerUrl);
      final afterFirst = notifications;

      await webView().finishPage(testTrackerUrl);

      // started + finished, with no extra notification for an unchanged state.
      expect(notifications - afterFirst, 2);
    });

    test('leaves the signed-in state unknown when the check fails', () async {
      webView().runJavaScriptReturningResultError = Exception('no page');

      await webView().finishPage(testTrackerUrl);

      expect(subject.isLoggedIn, isNull);
    });

    test('carries on when page scripts fail', () async {
      PushNotificationService.currentToken = 'tok';
      webView().runJavaScriptError = Exception('no page');

      await webView().finishPage(testTrackerUrl);

      expect(subject.isLoading, isFalse);
    });
  });

  group('FCM token', () {
    setUp(() => subject.initialize());

    test('is injected into each finished page', () async {
      PushNotificationService.currentToken = 'tok-1';

      await webView().finishPage(testTrackerUrl);

      expect(webView().scripts, contains(contains('window.__fcmToken = "tok-1"')));
    });

    test('is not injected before there is one', () async {
      await webView().finishPage(testTrackerUrl);

      expect(webView().scripts, isNot(contains(contains('__fcmToken'))));
    });

    test('is injected when it arrives after the page finished', () async {
      await webView().finishPage(testTrackerUrl);

      await simulateTokenArrival('tok-late');

      expect(webView().scripts, contains(contains('window.__fcmToken = "tok-late"')));
    });

    test('waits for the page when it arrives during a load', () async {
      await simulateTokenArrival('tok-early');

      expect(webView().scripts, isEmpty);
    });
  });

  group('errors', () {
    setUp(() => subject.initialize());

    test('a main-frame error shows the error', () {
      webView().fail(description: 'net::ERR_INTERNET_DISCONNECTED');

      expect(subject.hasError, isTrue);
      expect(subject.isLoading, isFalse);
      expect(subject.errorMessage, 'net::ERR_INTERNET_DISCONNECTED');
    });

    test('an error of unknown frame counts as main-frame', () {
      webView().fail(isForMainFrame: null);

      expect(subject.hasError, isTrue);
    });

    test('a sub-resource error is ignored', () {
      webView().fail(isForMainFrame: false);

      expect(subject.hasError, isFalse);
    });
  });

  group('navigation', () {
    setUp(() => subject.initialize());

    Future<NavigationDecision> navigate(String url, {bool isMainFrame = true}) async =>
        webView().delegate!.onNavigationRequest!(
          NavigationRequest(url: url, isMainFrame: isMainFrame),
        );

    test('keeps tracker and internal domains in the app', () async {
      expect(await navigate('https://tracker.example.org/events'), NavigationDecision.navigate);
      expect(await navigate('https://forum.example.net/threads/1'), NavigationDecision.navigate);
      expect(launcher.launched, isEmpty);
    });

    test('loads an external iframe in place', () async {
      expect(
        await navigate('https://www.youtube.com/embed/x', isMainFrame: false),
        NavigationDecision.navigate,
      );
      expect(launcher.launched, isEmpty);
    });

    test('opens an external page in the system browser', () async {
      expect(await navigate('https://www.google.com/maps'), NavigationDecision.prevent);
      await pumpEventQueue();

      expect(launcher.launched, ['https://www.google.com/maps']);
    });
  });

  group('actions', () {
    setUp(() => subject.initialize());

    test('reload clears the error and reloads', () async {
      webView().fail();

      await subject.reload();

      expect(subject.hasError, isFalse);
      expect(webView().reloadCount, 1);
    });

    test('goBack goes back when there is history', () async {
      webView().hasHistory = true;

      expect(await subject.canGoBack(), isTrue);
      await subject.goBack();

      expect(webView().goBackCount, 1);
    });

    test('goBack does nothing without history', () async {
      await subject.goBack();

      expect(webView().goBackCount, 0);
    });

    test('clearCache clears the cache and local storage, then reloads', () async {
      await subject.clearCache();

      expect(webView().clearCacheCount, 1);
      expect(webView().clearLocalStorageCount, 1);
      expect(webView().reloadCount, 1);
    });

    test('load opens a URL', () async {
      await subject.load('https://tracker.example.org/faq');

      expect(webView().loadedUrls.last, 'https://tracker.example.org/faq');
    });
  });
}

/// Delivers [token] the way Firebase does when it arrives after startup.
Future<void> simulateTokenArrival(String token) async {
  final messaging = FakeMessaging()..token = null;
  await PushNotificationService.initialize(messaging: messaging, openedApp: const Stream.empty());
  messaging.tokenRefresh.add(token);
  await pumpEventQueue();
}
