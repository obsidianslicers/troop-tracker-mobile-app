import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/notifications_controller.dart';
import 'package:tt_mobile_app/controllers/webview_controller.dart';
import 'package:tt_mobile_app/models/push_notification.dart';
import 'package:tt_mobile_app/views/main_shell_view.dart';
import 'package:tt_mobile_app/views/notifications_view.dart';
import 'package:tt_mobile_app/views/settings_view.dart';
import 'package:tt_mobile_app/widgets/loading_overlay.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../support/fake_notification_api.dart';
import '../support/fake_url_launcher.dart';
import '../support/fake_webview_platform.dart';
import '../support/test_env.dart';

void main() {
  late FakeWebViewPlatform platform;
  late FakeUrlLauncher launcher;
  late FakeNotificationApi api;
  late StreamController<RemoteMessage> foregroundMessages;
  late List<String> platformCalls;

  setUp(() {
    loadTestEnv();
    WebViewPlatform.instance = platform = FakeWebViewPlatform();
    UrlLauncherPlatform.instance = launcher = FakeUrlLauncher();
    api = FakeNotificationApi([
      PushNotification(
        id: '1',
        title: 'Troop posted',
        body: 'Sign up now',
        url: '/events/1',
        readAt: null,
        createdAt: DateTime.now(),
      ),
    ]);
    foregroundMessages = StreamController<RemoteMessage>.broadcast();
  });

  tearDown(() => foregroundMessages.close());

  FakeWebViewController webView() => platform.controller;

  Future<void> pumpShell(WidgetTester tester) async {
    platformCalls = [];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      platformCalls.add(call.method);
      return null;
    });
    await tester.pumpWidget(
      MaterialApp(
        home: MainShellView(
          webviewController: WebviewController(),
          notificationsController: NotificationsController(api: api, updateBadge: (_) async {}),
          foregroundMessages: foregroundMessages.stream,
        ),
      ),
    );
  }

  Future<void> finishPage(WidgetTester tester, {required bool signedIn}) async {
    webView().authStateResult = '$signedIn';
    await webView().finishPage(testTrackerUrl);
    await tester.pump();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
    await tester.pump();
  }

  testWidgets('starts on the tracker with the loading bar', (tester) async {
    await pumpShell(tester);

    expect(find.text('TROOP TRACKER'), findsOneWidget);
    expect(webView().loadedUrls, [testTrackerUrl]);
    expect(tester.widget<LoadingOverlay>(find.byType(LoadingOverlay)).isVisible, isTrue);

    await finishPage(tester, signedIn: true);
    expect(tester.widget<LoadingOverlay>(find.byType(LoadingOverlay)).isVisible, isFalse);
  });

  testWidgets('Home loads the tracker home page', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.byTooltip('Home'));
    await tester.pump();

    expect(webView().loadedUrls, [testTrackerUrl, testTrackerUrl]);
  });

  testWidgets('Open in Browser opens the tracker outside the app', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.byTooltip('Open in Browser'));
    await tester.pump();

    expect(launcher.launched, [testTrackerUrl]);
  });

  testWidgets('switches tabs and only shows tracker actions on the tracker', (tester) async {
    await pumpShell(tester);
    await finishPage(tester, signedIn: true);

    await openTab(tester, 'Settings');
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.byTooltip('Home'), findsNothing);
    expect(find.byType(SettingsView), findsOneWidget);

    await openTab(tester, 'Notifications');
    expect(find.text('NOTIFICATIONS'), findsOneWidget);
  });

  testWidgets('opening Notifications refreshes the inbox and shows the badge', (tester) async {
    await pumpShell(tester);
    await finishPage(tester, signedIn: true);
    final before = api.fetches;

    await openTab(tester, 'Notifications');

    expect(api.fetches, before + 1);
    expect(find.text('Troop posted'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(NavigationBar), matching: find.text('1')),
      findsWidgets,
    );
  });

  testWidgets('a signed-out trooper sees no badge and no inbox refresh', (tester) async {
    await pumpShell(tester);
    await finishPage(tester, signedIn: false);
    final before = api.fetches;

    await openTab(tester, 'Notifications');
    foregroundMessages.add(const RemoteMessage());
    await tester.pump();

    expect(api.fetches, before);
    expect(find.text('Sign in to view notifications'), findsOneWidget);
  });

  testWidgets('a push while the app is open refreshes the inbox', (tester) async {
    await pumpShell(tester);
    await finishPage(tester, signedIn: true);
    final before = api.fetches;

    foregroundMessages.add(const RemoteMessage());
    await tester.pump();

    expect(api.fetches, before + 1);
  });

  testWidgets('signing out empties the inbox', (tester) async {
    await pumpShell(tester);
    await finishPage(tester, signedIn: true);
    await openTab(tester, 'Notifications');
    expect(find.text('Troop posted'), findsOneWidget);

    await finishPage(tester, signedIn: false);

    final notifications = tester.widget<NotificationsView>(find.byType(NotificationsView));
    expect(notifications.controller.notifications, isEmpty);
  });

  group('back', () {
    testWidgets('returns to the tracker from another tab', (tester) async {
      await pumpShell(tester);
      await openTab(tester, 'Settings');

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.text('TROOP TRACKER'), findsOneWidget);
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    });

    testWidgets('goes back in the WebView when it has history', (tester) async {
      await pumpShell(tester);
      webView().hasHistory = true;

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(webView().goBackCount, 1);
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
    });

    testWidgets('closes the app with no history', (tester) async {
      await pumpShell(tester);

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(platformCalls, contains('SystemNavigator.pop'));
    });

    testWidgets('closes the app from the error screen', (tester) async {
      await pumpShell(tester);
      webView().hasHistory = true;
      webView().fail();
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(webView().goBackCount, 0);
      expect(platformCalls, contains('SystemNavigator.pop'));
    });
  });

  testWidgets('stops listening for pushes once closed', (tester) async {
    await pumpShell(tester);
    await tester.pumpWidget(const SizedBox());

    expect(foregroundMessages.hasListener, isFalse);
  });

  testWidgets('builds its real controllers by default', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShellView()));

    expect(webView().loadedUrls, [testTrackerUrl]);
    await tester.pumpWidget(const SizedBox());
  });
}
