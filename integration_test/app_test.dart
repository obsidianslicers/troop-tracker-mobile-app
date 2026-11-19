// End-to-end tests: the real app on a device or emulator, with a real WebView,
// against the mock tracker in tool/mock_tracker.dart. See docs/TESTING.md.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:tt_mobile_app/app.dart';
import 'package:tt_mobile_app/config/app_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initializeServices);

  setUp(() => _tracker('POST', '/__test/reset'));

  testWidgets('opens on the splash screen, then loads the tracker', (tester) async {
    await tester.pumpWidget(const TroopTrackerApp());
    expect(find.text('Troop Tracker'), findsOneWidget);

    await _waitFor(tester, find.text('TROOP TRACKER'));
    await _waitForRequest(tester, 'GET /');
  });

  testWidgets('asks a signed-out trooper to sign in for notifications', (tester) async {
    await _openApp(tester);

    await _openTab(tester, 'Notifications');
    await _waitFor(tester, find.text('Sign in to view notifications'));

    await tester.tap(find.text('Go to Sign In'));
    await _waitFor(tester, find.text('TROOP TRACKER'));
  });

  testWidgets('a signed-in trooper opens a notification on its page', (tester) async {
    await _openApp(tester);
    await _signIn(tester);

    await _openTab(tester, 'Notifications');
    await _waitFor(tester, find.text('Troop posted'));
    expect(find.text('Costume approved'), findsOneWidget);

    await tester.tap(find.text('Troop posted'));
    await _waitForRequest(tester, 'POST /api/push-notifications/1/read');
    await _waitForRequest(tester, 'GET /events/42');
    await _waitFor(tester, find.text('TROOP TRACKER'));
  });

  testWidgets('a signed-in trooper clears the inbox', (tester) async {
    await _openApp(tester);
    await _signIn(tester);
    await _openTab(tester, 'Notifications');
    await _waitFor(tester, find.text('Troop posted'));

    await tester.tap(find.text('Clear all'));
    await _waitFor(tester, find.text('Delete all notifications?'));
    await tester.tap(find.text('Clear'));

    await _waitForRequest(tester, 'DELETE /api/push-notifications');
    await _waitFor(tester, find.text('No notifications yet'));
  });

  testWidgets('Settings shows the version and clears the cache', (tester) async {
    await _openApp(tester);

    await _openTab(tester, 'Settings');
    await _waitFor(tester, find.textContaining(RegExp(r'^\d+\.\d+\.\d+ \(\d+\)$')));

    await _tracker('POST', '/__test/reset-requests');
    await tester.tap(find.text('Clear Cache'));
    await _waitFor(tester, find.text('Cache cleared.'));
    await _waitForRequest(tester, 'GET /');
  });

  testWidgets('back returns from another tab to the tracker', (tester) async {
    await _openApp(tester);
    await _openTab(tester, 'Settings');
    await _waitFor(tester, find.text('SETTINGS'));

    await tester.binding.handlePopRoute();

    await _waitFor(tester, find.text('TROOP TRACKER'));
  });
}

/// Launches the app and waits until the tracker's first page has loaded.
Future<void> _openApp(WidgetTester tester) async {
  await tester.pumpWidget(const TroopTrackerApp());
  await _waitFor(tester, find.text('TROOP TRACKER'));
  await _waitForRequest(tester, 'GET /');
  await _settle(tester);
}

/// Signs in on the tracker, then reloads the page with the Home button so the
/// app sees the new sign-in state, as it would after the trooper's login form.
Future<void> _signIn(WidgetTester tester) async {
  await _tracker('POST', '/__test/sign-in');
  await _tracker('POST', '/__test/reset-requests');
  await tester.tap(find.byTooltip('Home'));
  await _waitForRequest(tester, 'GET /');
  // The app reads the sign-in state once the page finishes loading.
  await Future<void>.delayed(const Duration(seconds: 1));
  await _settle(tester);
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await _settle(tester);
}

Future<http.Response> _tracker(String method, String path) {
  final uri = Uri.parse(AppConfig.urlFor(path));
  return switch (method) {
    'POST' => http.post(uri),
    _ => http.get(uri),
  };
}

Future<void> _waitForRequest(WidgetTester tester, String request) async {
  await _waitUntil(tester, 'the app to request $request', () async {
    final response = await _tracker('GET', '/__test/requests');
    return (jsonDecode(response.body) as List<dynamic>).contains(request);
  });
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  await _waitUntil(tester, finder.describeMatch(Plurality.one), () async {
    return finder.evaluate().isNotEmpty;
  });
}

Future<void> _waitUntil(
  WidgetTester tester,
  String what,
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out waiting for $what');
    await _settle(tester);
  }
}

/// Lets real time pass (network, WebView) and draws the frames it causes.
Future<void> _settle(WidgetTester tester) async {
  await Future<void>.delayed(const Duration(milliseconds: 250));
  await tester.pump();
}
