import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs before every test file: keeps the app's debug logging out of test output.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugPrint = (String? message, {int? wrapWidth}) {};
  await testMain();
}
