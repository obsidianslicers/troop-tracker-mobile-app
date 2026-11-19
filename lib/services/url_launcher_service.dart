import 'package:url_launcher/url_launcher.dart';

/// Opens URLs in the system browser or appropriate external app.
abstract final class UrlLauncherService {
  /// Opens [url] outside the app using the system browser.
  /// Returns true if the URL was successfully launched.
  static Future<bool> openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
