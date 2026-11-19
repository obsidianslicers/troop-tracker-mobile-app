import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/webview_controller.dart';
import 'package:tt_mobile_app/views/error_view.dart';
import 'package:tt_mobile_app/views/tracker_view.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../support/fake_webview_platform.dart';
import '../support/pump_app.dart';
import '../support/test_env.dart';

void main() {
  late FakeWebViewPlatform platform;
  late WebviewController controller;

  setUp(() {
    loadTestEnv();
    WebViewPlatform.instance = platform = FakeWebViewPlatform();
    controller = WebviewController()..initialize();
  });

  tearDown(() => controller.dispose());

  testWidgets('shows the WebView', (tester) async {
    await pumpInApp(tester, TrackerView(controller: controller));

    expect(find.byKey(const Key('fake-webview')), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('switches to the error view when the page fails, and back', (tester) async {
    await pumpInApp(tester, TrackerView(controller: controller));

    platform.controller.fail();
    await tester.pump();
    expect(find.byType(ErrorView), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byKey(const Key('fake-webview')), findsOneWidget);
  });

  testWidgets('pull to refresh reloads the page', (tester) async {
    await pumpInApp(tester, TrackerView(controller: controller));

    final indicator = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
    await indicator.onRefresh();

    expect(platform.controller.reloadCount, 1);
  });

  testWidgets('stops listening once removed', (tester) async {
    await pumpInApp(tester, TrackerView(controller: controller));
    await pumpInApp(tester, const SizedBox());

    platform.controller.fail();
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
