import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tt_mobile_app/controllers/settings_controller.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../support/fake_url_launcher.dart';
import '../support/test_env.dart';

void main() {
  late SettingsController subject;

  setUp(() {
    loadTestEnv();
    PackageInfo.setMockInitialValues(
      appName: 'Troop Tracker',
      packageName: 'com.drennansoftware.troop_tracker',
      version: '2.0.2',
      buildNumber: '13',
      buildSignature: '',
    );
    subject = SettingsController();
  });

  test('getVersionString shows the version and build number', () async {
    expect(await subject.getVersionString(), '2.0.2 (13)');
  });

  test('getPackageInfo is fetched once and cached', () async {
    final first = await subject.getPackageInfo();

    expect(await subject.getPackageInfo(), same(first));
  });

  test('openInBrowser opens the tracker in the system browser', () async {
    final launcher = FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;

    await subject.openInBrowser();

    expect(launcher.launched, [testTrackerUrl]);
  });
}
