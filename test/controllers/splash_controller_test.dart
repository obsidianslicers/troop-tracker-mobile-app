import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/controllers/splash_controller.dart';

void main() {
  test('waitForReady resolves after the minimum splash time', () {
    fakeAsync((async) {
      var ready = false;
      SplashController().waitForReady().then((_) => ready = true);

      async.elapse(const Duration(milliseconds: 1799));
      expect(ready, isFalse);

      async.elapse(const Duration(milliseconds: 1));
      expect(ready, isTrue);
    });
  });
}
