import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tt_mobile_app/controllers/webview_controller.dart';
import 'package:tt_mobile_app/views/settings_view.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../support/fake_url_launcher.dart';
import '../support/fake_webview_platform.dart';
import '../support/pump_app.dart';
import '../support/test_env.dart';

void main() {
  late FakeWebViewPlatform platform;
  late FakeUrlLauncher launcher;
  late WebviewController controller;

  setUp(() {
    loadTestEnv();
    PackageInfo.setMockInitialValues(
      appName: 'Troop Tracker',
      packageName: 'com.drennansoftware.troop_tracker',
      version: '2.0.2',
      buildNumber: '13',
      buildSignature: '',
    );
    WebViewPlatform.instance = platform = FakeWebViewPlatform();
    UrlLauncherPlatform.instance = launcher = FakeUrlLauncher();
    controller = WebviewController()..initialize();
  });

  tearDown(() => controller.dispose());

  testWidgets('shows the app version and the tracker URL', (tester) async {
    await pumpInApp(tester, SettingsView(webviewController: controller));
    expect(find.text('…'), findsOneWidget);

    await tester.pump();

    expect(find.text('2.0.2 (13)'), findsOneWidget);
    expect(find.text(testTrackerUrl), findsOneWidget);
    expect(find.text('Troop Tracker'), findsOneWidget);
  });

  testWidgets('Clear Cache clears the WebView and says so', (tester) async {
    await pumpInApp(tester, SettingsView(webviewController: controller));

    await tester.tap(find.text('Clear Cache'));
    await tester.pump();
    await tester.pump();

    expect(platform.controller.clearCacheCount, 1);
    expect(platform.controller.clearLocalStorageCount, 1);
    expect(find.text('Cache cleared.'), findsOneWidget);
  });

  testWidgets('Clear Cache shows progress and cannot be tapped twice', (tester) async {
    final gate = platform.controller.clearCacheGate = Completer<void>();
    await pumpInApp(tester, SettingsView(webviewController: controller));

    await tester.tap(find.text('Clear Cache'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Clear Cache'));
    gate.complete();
    await tester.pump();
    await tester.pump();

    expect(platform.controller.clearCacheCount, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('does not show the message after leaving the screen', (tester) async {
    final gate = platform.controller.clearCacheGate = Completer<void>();
    await pumpInApp(tester, SettingsView(webviewController: controller));

    await tester.tap(find.text('Clear Cache'));
    await pumpInApp(tester, const SizedBox());
    gate.complete();
    await tester.pump();

    expect(find.text('Cache cleared.'), findsNothing);
  });

  testWidgets('Open in Browser opens the tracker outside the app', (tester) async {
    await pumpInApp(tester, SettingsView(webviewController: controller));

    await tester.tap(find.text('Open in Browser'));
    await tester.pump();

    expect(launcher.launched, [testTrackerUrl]);
  });
}
