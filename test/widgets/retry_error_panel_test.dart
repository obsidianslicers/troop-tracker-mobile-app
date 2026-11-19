import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/widgets/retry_error_panel.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('shows the error and retries', (tester) async {
    var retries = 0;
    await pumpInApp(tester, RetryErrorPanel(message: 'net::ERR_FAILED', onRetry: () => retries++));

    expect(find.text('Unable to connect'), findsOneWidget);
    expect(find.text('net::ERR_FAILED'), findsOneWidget);
    expect(find.text('Open in Browser'), findsNothing);

    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  testWidgets('explains an error without a message', (tester) async {
    await pumpInApp(tester, RetryErrorPanel(message: '', onRetry: () {}));

    expect(find.text('Check your internet connection and try again.'), findsOneWidget);
  });

  testWidgets('offers the browser when given a way to open it', (tester) async {
    var opened = 0;
    await pumpInApp(
      tester,
      RetryErrorPanel(message: '', onRetry: () {}, onOpenInBrowser: () => opened++),
    );

    await tester.tap(find.text('Open in Browser'));
    expect(opened, 1);
  });
}
