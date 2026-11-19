import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Records the URLs the app opens outside itself.
///
/// Install with `UrlLauncherPlatform.instance = FakeUrlLauncher()`.
class FakeUrlLauncher extends Fake with MockPlatformInterfaceMixin implements UrlLauncherPlatform {
  final List<String> launched = [];
  final List<PreferredLaunchMode> modes = [];
  bool canLaunchResult = true;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    modes.add(options.mode);
    return true;
  }
}
