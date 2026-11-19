import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/services/url_launcher_service.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../support/fake_url_launcher.dart';

void main() {
  late FakeUrlLauncher launcher;

  setUp(() => UrlLauncherPlatform.instance = launcher = FakeUrlLauncher());

  test('opens the URL in an external app', () async {
    final result = await UrlLauncherService.openExternal('https://www.google.com/maps');

    expect(result, isTrue);
    expect(launcher.launched, ['https://www.google.com/maps']);
    expect(launcher.modes, [PreferredLaunchMode.externalApplication]);
  });

  test('does nothing when no app can open the URL', () async {
    launcher.canLaunchResult = false;

    final result = await UrlLauncherService.openExternal('weird://thing');

    expect(result, isFalse);
    expect(launcher.launched, isEmpty);
  });

  test('does nothing for a URL that does not parse', () async {
    final result = await UrlLauncherService.openExternal('http://[::1');

    expect(result, isFalse);
    expect(launcher.launched, isEmpty);
  });
}
