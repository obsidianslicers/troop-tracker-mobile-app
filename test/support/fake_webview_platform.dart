import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// A WebView that records what the app asks of it and lets a test play the
/// page's side: [FakeWebViewController.finishPage], [FakeWebViewController.fail], ...
///
/// Install with `WebViewPlatform.instance = FakeWebViewPlatform()`.
class FakeWebViewPlatform extends WebViewPlatform {
  final List<FakeWebViewController> controllers = [];

  /// The most recently created WebView.
  FakeWebViewController get controller => controllers.last;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final controller = FakeWebViewController(params);
    controllers.add(controller);
    return controller;
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) =>
      FakeNavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(PlatformWebViewWidgetCreationParams params) =>
      FakeWebViewWidget(params);
}

class FakeWebViewController extends PlatformWebViewController {
  FakeWebViewController(super.params) : super.implementation();

  final List<String> loadedUrls = [];
  final List<String> scripts = [];
  JavaScriptMode? javaScriptMode;
  Color? backgroundColor;
  String? userAgent;
  FakeNavigationDelegate? delegate;
  void Function(JavaScriptConsoleMessage)? onConsoleMessage;

  /// What `window.__authState` evaluates to, as the platform returns it.
  Object authStateResult = '"false"';
  Object? runJavaScriptError;
  Object? runJavaScriptReturningResultError;
  bool hasHistory = false;
  int goBackCount = 0;
  int reloadCount = 0;
  int clearCacheCount = 0;

  /// When set, clearCache() waits for it, so a test can look mid-clear.
  Completer<void>? clearCacheGate;
  int clearLocalStorageCount = 0;

  /// Plays a page load: started, finished, and lets the async auth check run.
  Future<void> finishPage(String url) async {
    delegate!.onPageStarted!(url);
    delegate!.onPageFinished!(url);
    // Microtasks only, no timers, so this also works inside testWidgets.
    for (var i = 0; i < 10; i++) {
      await Future<void>.value();
    }
  }

  void fail({String description = 'net::ERR_FAILED', bool? isForMainFrame = true}) {
    delegate!.onWebResourceError!(
      WebResourceError(errorCode: -2, description: description, isForMainFrame: isForMainFrame),
    );
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loadedUrls.add(params.uri.toString());
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {
    this.javaScriptMode = javaScriptMode;
  }

  @override
  Future<void> setBackgroundColor(Color color) async => backgroundColor = color;

  @override
  Future<void> setUserAgent(String? userAgent) async => this.userAgent = userAgent;

  @override
  Future<void> setOnConsoleMessage(
    void Function(JavaScriptConsoleMessage consoleMessage) onConsoleMessage,
  ) async {
    this.onConsoleMessage = onConsoleMessage;
  }

  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {
    delegate = handler as FakeNavigationDelegate;
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    scripts.add(javaScript);
    final error = runJavaScriptError;
    if (error != null) throw error;
  }

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async {
    scripts.add(javaScript);
    final error = runJavaScriptReturningResultError;
    if (error != null) throw error;
    return authStateResult;
  }

  @override
  Future<bool> canGoBack() async => hasHistory;

  @override
  Future<void> goBack() async => goBackCount++;

  @override
  Future<void> reload() async => reloadCount++;

  @override
  Future<void> clearCache() async {
    clearCacheCount++;
    await clearCacheGate?.future;
  }

  @override
  Future<void> clearLocalStorage() async => clearLocalStorageCount++;
}

class FakeNavigationDelegate extends PlatformNavigationDelegate {
  FakeNavigationDelegate(super.params) : super.implementation();

  PageEventCallback? onPageStarted;
  PageEventCallback? onPageFinished;
  ProgressCallback? onProgress;
  WebResourceErrorCallback? onWebResourceError;
  NavigationRequestCallback? onNavigationRequest;

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async =>
      this.onPageStarted = onPageStarted;

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async =>
      this.onPageFinished = onPageFinished;

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async => this.onProgress = onProgress;

  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback onWebResourceError) async =>
      this.onWebResourceError = onWebResourceError;

  @override
  Future<void> setOnNavigationRequest(NavigationRequestCallback onNavigationRequest) async =>
      this.onNavigationRequest = onNavigationRequest;

  // The app doesn't use these; accept them so NavigationDelegate can be built.
  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}

  @override
  Future<void> setOnHttpAuthRequest(HttpAuthRequestCallback onHttpAuthRequest) async {}

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {}

  @override
  Future<void> setOnSSlAuthError(SslAuthErrorCallback onSslAuthError) async {}
}

class FakeWebViewWidget extends PlatformWebViewWidget {
  FakeWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand(key: Key('fake-webview'));
}
