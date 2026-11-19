import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/widgets/loading_overlay.dart';

import '../support/pump_app.dart';

void main() {
  Finder beam() => find.descendant(
        of: find.byType(LoadingOverlay),
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.decoration is BoxDecoration,
        ),
      );

  testWidgets('draws nothing when hidden', (tester) async {
    await pumpInApp(tester, const LoadingOverlay(progress: 0.5, isVisible: false));

    expect(find.byType(LayoutBuilder), findsNothing);
  });

  testWidgets('fills the bar to the progress', (tester) async {
    await pumpInApp(tester, const LoadingOverlay(progress: 0.5, isVisible: true));
    await tester.pump(const Duration(milliseconds: 450));

    final width = tester.getSize(beam().first).width;
    expect(width, closeTo(tester.getSize(find.byType(LoadingOverlay)).width * 0.5, 0.01));
  });

  testWidgets('shows a sliver of the bar at zero progress', (tester) async {
    await pumpInApp(tester, const LoadingOverlay(progress: 0, isVisible: true));
    await tester.pump();

    final width = tester.getSize(beam().first).width;
    expect(width, closeTo(tester.getSize(find.byType(LoadingOverlay)).width * 0.02, 0.01));
  });

  testWidgets('stops its animation when removed', (tester) async {
    await pumpInApp(tester, const LoadingOverlay(progress: 0.3, isVisible: true));
    await pumpInApp(tester, const SizedBox());

    expect(tester.hasRunningAnimations, isFalse);
  });
}
