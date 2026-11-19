import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] inside the app's dark theme, on a Scaffold so it can show
/// SnackBars and dialogs.
Future<void> pumpInApp(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: Scaffold(body: child),
    ),
  );
}
