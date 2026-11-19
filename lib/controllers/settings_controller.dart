import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../services/url_launcher_service.dart';

/// Provides data and actions for the Settings screen.
/// No ChangeNotifier needed — SettingsView uses FutureBuilder for async data
/// and calls methods directly for one-shot actions.
class SettingsController {
  PackageInfo? _packageInfo;

  /// Returns cached package info, fetching it from the platform on first call.
  Future<PackageInfo> getPackageInfo() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!;
  }

  /// Returns a display string like "1.1.6 (7)".
  Future<String> getVersionString() async {
    final info = await getPackageInfo();
    return '${info.version} (${info.buildNumber})';
  }

  /// Opens the tracker URL in the system browser.
  Future<void> openInBrowser() => UrlLauncherService.openExternal(AppConfig.trackerUrl);
}
