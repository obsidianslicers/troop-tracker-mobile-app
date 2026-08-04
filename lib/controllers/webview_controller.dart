import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/app_config.dart';
import '../services/push_notification_service.dart';
import '../services/url_launcher_service.dart';
import '../services/webview_service.dart';

/// Manages WebView state and exposes it to the UI via ChangeNotifier.
///
/// Ownership: Created and disposed by MainShellView. Passed as a
/// constructor parameter to TrackerView and SettingsView.
class WebviewController extends ChangeNotifier {
  late final WebViewController _webViewController;

  bool _isLoading = true;
  double _loadingProgress = 0.0;
  bool _hasError = false;
  String _errorMessage = '';
  bool? _isLoggedIn;

  bool get isLoading => _isLoading;
  double get loadingProgress => _loadingProgress;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  // null = unknown (page not yet loaded), true/false = auth state from web app
  bool? get isLoggedIn => _isLoggedIn;

  /// The underlying webview_flutter controller used by WebViewWidget.
  WebViewController get webViewController => _webViewController;

  /// Sets up the WebViewController and loads the tracker URL.
  /// Must be called once by MainShellView.initState().
  void initialize() {
    PushNotificationService.setDeepLinkHandler((path) {
      final base = AppConfig.trackerUrl.replaceAll(RegExp(r'/$'), '');
      final relative = path.startsWith('/') ? path : '/$path';
      load('$base$relative');
    });

    // On iOS the FCM token often arrives after the webview's first page load
    // (APNs round trip). Re-inject once the token is available so the web
    // app's fcm-register.js still gets a chance to register it.
    PushNotificationService.setTokenReadyHandler((token) {
      if (!_isLoading) _injectFcmToken();
    });

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppConfig.splashBackgroundColor)
      ..setUserAgent(_buildUserAgent())
      ..setOnConsoleMessage(
        (message) => debugPrint('[WebView] ${message.level.name}: ${message.message}'),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: _onPageStarted,
          onPageFinished: _onPageFinished,
          onProgress: _onProgress,
          onWebResourceError: _onWebResourceError,
          onNavigationRequest: _onNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse(AppConfig.trackerUrl));
  }

  void _onPageStarted(String url) {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  void _onPageFinished(String url) {
    debugPrint('[WebView] page finished: $url');
    _isLoading = false;
    _overrideWindowOpen();
    _injectFcmToken();
    _checkAuthState();
    notifyListeners();
  }

  Future<void> _checkAuthState() async {
    try {
      final result = await _webViewController.runJavaScriptReturningResult(
        'window.__authState === true ? "true" : "false"',
      );
      final loggedIn = result.toString().replaceAll('"', '') == 'true';
      if (_isLoggedIn != loggedIn) {
        _isLoggedIn = loggedIn;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Auth] state check error: $e');
    }
  }

  void _injectFcmToken() {
    final token = PushNotificationService.currentToken;
    debugPrint('[FCM] _injectFcmToken called, token: $token');
    if (token == null) return;
    _webViewController.runJavaScript(
      'window.__fcmToken = "$token";'
      'if (typeof window.__onFcmTokenReady === "function") window.__onFcmTokenReady("$token");',
    ).catchError((e) => debugPrint('[FCM] JS injection error: $e'));
  }

  // Redirects window.open() into the same WebView so OAuth callbacks don't
  // escape to the system browser and lose the session cookie.
  void _overrideWindowOpen() {
    _webViewController.runJavaScript(
      'window.open = function(url) { if (url) window.location.href = url; return window; };',
    );
  }

  void _onProgress(int progress) {
    _loadingProgress = progress / 100.0;
    notifyListeners();
  }

  void _onWebResourceError(WebResourceError error) {
    // Only treat main-frame errors as fatal — sub-resource failures
    // (ads, tracking pixels) should not interrupt the user experience.
    if (error.isForMainFrame ?? true) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = error.description;
      notifyListeners();
    }
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (WebViewService.isInternalUrl(request.url)) {
      return NavigationDecision.navigate;
    }
    // Subframe requests (e.g. embedded YouTube iframes) should load in
    // place; only top-level navigation to an external URL should be
    // kicked out to the system browser. Blocking subframe loads causes
    // embeds to repeatedly retry and appear to loop.
    if (!request.isMainFrame) {
      return NavigationDecision.navigate;
    }
    // External URL: open in system browser and block in-app navigation.
    UrlLauncherService.openExternal(request.url);
    return NavigationDecision.prevent;
  }

  /// Reloads the tracker URL. Clears any visible error state first.
  Future<void> reload() async {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
    await _webViewController.reload();
  }

  /// Navigates back in the WebView history if possible.
  Future<void> goBack() async {
    if (await _webViewController.canGoBack()) {
      await _webViewController.goBack();
    }
  }

  /// Returns true if the WebView has history to go back to.
  Future<bool> canGoBack() => _webViewController.canGoBack();

  /// Clears the WebView cache and local storage, then reloads.
  Future<void> clearCache() async {
    await _webViewController.clearCache();
    await _webViewController.clearLocalStorage();
    await reload();
  }

  /// Loads a specific URL. Used for deep link support.
  Future<void> load(String url) async {
    await _webViewController.loadRequest(Uri.parse(url));
  }

  // On Android the default WebView UA contains "; wv)" which marks the request
  // as an embedded WebView. XenForo (and other OAuth providers) detect this and
  // block authorization forms as a phishing countermeasure. Return a clean
  // mobile Chrome UA on Android; return null on iOS to keep the default Safari UA.
  String? _buildUserAgent() {
    if (!Platform.isAndroid) return null;
    return 'Mozilla/5.0 (Linux; Android 10; K) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/124.0.0.0 Mobile Safari/537.36';
  }
}
