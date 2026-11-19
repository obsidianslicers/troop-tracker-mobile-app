import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/webview_controller.dart';
import 'package:tt_mobile_app/views/error_view.dart';
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
    WebViewPlatform.instance = platform = FakeWebViewPlatform();
    UrlLauncherPlatform.instance = launcher = FakeUrlLauncher();
    controller = WebviewController()..initialize();
    platform.controller.fail(description: 'net::ERR_NAME_NOT_RESOLVED');
  });

  tearDown(() => controller.dispose());

  testWidgets('shows the WebView error', (tester) async {
    await pumpInApp(tester, ErrorView(controller: controller));

    expect(find.text('net::ERR_NAME_NOT_RESOLVED'), findsOneWidget);
  });

  testWidgets('Retry reloads the tracker', (tester) async {
    await pumpInApp(tester, ErrorView(controller: controller));

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(platform.controller.reloadCount, 1);
    expect(controller.hasError, isFalse);
  });

  testWidgets('Open in Browser opens the tracker outside the app', (tester) async {
    await pumpInApp(tester, ErrorView(controller: controller));

    await tester.tap(find.text('Open in Browser'));
    await tester.pump();

    expect(launcher.launched, [testTrackerUrl]);
  });
}
