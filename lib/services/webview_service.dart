import '../config/app_config.dart';

/// Routing logic that determines whether a URL should stay inside
/// the WebView or be opened externally.
abstract final class WebViewService {
  /// Returns true if [url] belongs to the tracker domain and should
  /// be handled by the WebView. Returns false for all external URLs.
  static bool isInternalUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    // The domain itself or a subdomain of it; a plain endsWith would also let
    // a lookalike such as "evilfl501st.com" stay in the WebView (and get the FCM token).
    return AppConfig.internalDomains.any((domain) => host == domain || host.endsWith('.$domain'));
  }
}
