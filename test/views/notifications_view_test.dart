import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/notifications_controller.dart';
import 'package:tt_mobile_app/controllers/webview_controller.dart';
import 'package:tt_mobile_app/models/push_notification.dart';
import 'package:tt_mobile_app/views/notifications_view.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../support/fake_notification_api.dart';
import '../support/fake_webview_platform.dart';
import '../support/pump_app.dart';
import '../support/test_env.dart';

void main() {
  late FakeWebViewPlatform platform;
  late WebviewController webview;
  late FakeNotificationApi api;
  late NotificationsController controller;
  late int trackerVisits;

  setUp(() {
    loadTestEnv();
    WebViewPlatform.instance = platform = FakeWebViewPlatform();
    webview = WebviewController()..initialize();
    api = FakeNotificationApi();
    controller = NotificationsController(api: api, updateBadge: (_) async {});
    trackerVisits = 0;
  });

  tearDown(() {
    webview.dispose();
    controller.dispose();
  });

  Future<void> pumpView(WidgetTester tester) async {
    await pumpInApp(
      tester,
      NotificationsView(
        controller: controller,
        webviewController: webview,
        onNavigateToTracker: () => trackerVisits++,
      ),
    );
    await tester.pump();
  }

  Future<void> signIn(bool signedIn) async {
    platform.controller.authStateResult = '$signedIn';
    await platform.controller.finishPage(testTrackerUrl);
  }

  testWidgets('asks a signed-out trooper to sign in, without loading', (tester) async {
    await signIn(false);
    await pumpView(tester);

    expect(find.text('Sign in to view notifications'), findsOneWidget);
    expect(api.fetches, 0);

    await tester.tap(find.text('Go to Sign In'));
    expect(trackerVisits, 1);
  });

  testWidgets('loads the inbox when opened', (tester) async {
    api.inbox = [notification('1', title: 'Troop posted')];

    await pumpView(tester);

    expect(api.fetches, 1);
    expect(find.text('Troop posted'), findsOneWidget);
  });

  testWidgets('shows a spinner while the first load runs', (tester) async {
    final gate = api.fetchGate = Completer<void>();
    await pumpView(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows an empty inbox with a refresh button', (tester) async {
    await pumpView(tester);

    expect(find.text('No notifications yet'), findsOneWidget);

    api.inbox = [notification('1', title: 'New troop')];
    await tester.tap(find.text('Refresh'));
    await tester.pump();

    expect(find.text('New troop'), findsOneWidget);
  });

  testWidgets('shows unread notifications in bold with their age', (tester) async {
    final now = DateTime.now();
    api.inbox = [
      notification('1', title: 'Just now', createdAt: now),
      notification('2', title: 'Minutes', createdAt: now.subtract(const Duration(minutes: 5))),
      notification('3', title: 'Hours', createdAt: now.subtract(const Duration(hours: 3))),
      notification(
        '4',
        title: 'Days',
        createdAt: now.subtract(const Duration(days: 2)),
        readAt: now,
      ),
    ];

    await pumpView(tester);

    expect(find.text('just now'), findsOneWidget);
    expect(find.text('5m ago'), findsOneWidget);
    expect(find.text('3h ago'), findsOneWidget);
    expect(find.text('2d ago'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Just now')).style!.fontWeight, FontWeight.bold);
    expect(tester.widget<Text>(find.text('Days')).style!.fontWeight, FontWeight.normal);
    expect(find.byIcon(Icons.notifications_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });

  testWidgets('tapping a notification marks it read and opens its page', (tester) async {
    api.inbox = [notification('7', title: 'Troop update', url: 'events/7')];
    await pumpView(tester);

    await tester.tap(find.text('Troop update'));
    await tester.pump();

    expect(api.markedRead, ['7']);
    expect(platform.controller.loadedUrls.last, 'https://tracker.example.org/events/7');
    expect(trackerVisits, 1);
  });

  testWidgets('Clear all asks first, and Cancel keeps the inbox', (tester) async {
    api.inbox = [notification('1', title: 'Keep me')];
    await pumpView(tester);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all notifications?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(api.cleared, 0);
    expect(find.text('Keep me'), findsOneWidget);
  });

  testWidgets('Clear all empties the inbox once confirmed', (tester) async {
    api.inbox = [notification('1', title: 'Delete me')];
    await pumpView(tester);

    await tester.tap(find.text('Clear all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(api.cleared, 1);
    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('pull to refresh reloads the inbox', (tester) async {
    api.inbox = [notification('1')];
    await pumpView(tester);

    await tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();

    expect(api.fetches, 2);
  });
}

PushNotification notification(
  String id, {
  String? title,
  String? url,
  DateTime? createdAt,
  DateTime? readAt,
}) =>
    PushNotification(
      id: id,
      title: title ?? 'Title $id',
      body: 'Body $id',
      url: url ?? '/events/$id',
      readAt: readAt,
      createdAt: createdAt ?? DateTime.now(),
    );
