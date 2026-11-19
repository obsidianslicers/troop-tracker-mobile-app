import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/widgets/app_bottom_nav.dart';

import '../support/pump_app.dart';

void main() {
  Future<List<int>> pumpNav(WidgetTester tester, {int currentIndex = 0, int unread = 0}) async {
    final taps = <int>[];
    await pumpInApp(
      tester,
      AppBottomNav(currentIndex: currentIndex, unreadNotificationCount: unread, onTap: taps.add),
    );
    return taps;
  }

  testWidgets('shows the three tabs', (tester) async {
    await pumpNav(tester);

    expect(find.text('Tracker'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('reports the tapped tab', (tester) async {
    final taps = await pumpNav(tester);

    await tester.tap(find.text('Settings'));
    await tester.tap(find.text('Notifications'));

    expect(taps, [2, 1]);
  });

  testWidgets('hides the badge with no unread notifications', (tester) async {
    await pumpNav(tester);

    final badges = tester.widgetList<Badge>(find.byType(Badge));
    expect(badges.every((badge) => !badge.isLabelVisible), isTrue);
  });

  testWidgets('shows the unread count on the badge', (tester) async {
    await pumpNav(tester, unread: 5);

    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('caps the badge at 99+', (tester) async {
    await pumpNav(tester, currentIndex: 1, unread: 150);

    expect(find.text('99+'), findsOneWidget);
  });
}
