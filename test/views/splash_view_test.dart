import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/views/main_shell_view.dart';
import 'package:tt_mobile_app/views/splash_view.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../support/fake_webview_platform.dart';
import '../support/test_env.dart';

void main() {
  setUp(() {
    loadTestEnv();
    WebViewPlatform.instance = FakeWebViewPlatform();
  });

  Widget next(BuildContext context) => const Text('Next screen');

  testWidgets('shows the logo and app name', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SplashView(next: next)));

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Troop Tracker'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('moves on after the minimum splash time', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SplashView(next: next)));

    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('Next screen'), findsNothing);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('Next screen'), findsOneWidget);
    expect(find.byType(SplashView), findsNothing);
  });

  testWidgets('does not move on once removed', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SplashView(next: next)));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Next screen'), findsNothing);
  });

  testWidgets('moves on to the main shell by default', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashView()));

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(MainShellView), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
