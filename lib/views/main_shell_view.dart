import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';
import '../controllers/notifications_controller.dart';
import '../controllers/webview_controller.dart';
import '../services/url_launcher_service.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/loading_overlay.dart';
import 'notifications_view.dart';
import 'settings_view.dart';
import 'tracker_view.dart';

/// Root shell that owns the WebviewController and hosts the three main tabs.
///
/// The controller is created here so it can be shared between TrackerView
/// (which renders it) and SettingsView (which can clear its cache).
/// IndexedStack keeps the WebView alive when the user switches tabs.
class MainShellView extends StatefulWidget {
  /// The controllers and the foreground message stream default to the real
  /// ones; tests pass their own. The shell disposes the controllers either way.
  const MainShellView({
    super.key,
    this.webviewController,
    this.notificationsController,
    this.foregroundMessages,
  });

  final WebviewController? webviewController;
  final NotificationsController? notificationsController;
  final Stream<RemoteMessage>? foregroundMessages;

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  int _currentIndex = 0;
  late final WebviewController _webviewController;
  late final NotificationsController _notificationsController;
  late final StreamSubscription<RemoteMessage> _foregroundMessages;
  bool? _lastKnownLoggedIn;

  static const _tabTitles = ['Troop Tracker', 'Notifications', 'Settings'];

  @override
  void initState() {
    super.initState();

    _webviewController = widget.webviewController ?? WebviewController();
    _webviewController.addListener(_onWebviewChanged);
    _webviewController.initialize();

    _notificationsController = widget.notificationsController ?? NotificationsController();

    // A push that arrives while the app is open adds to the inbox.
    _foregroundMessages = (widget.foregroundMessages ?? FirebaseMessaging.onMessage).listen(
      (_) => _refreshNotificationsIfSignedIn(),
    );
  }

  @override
  void dispose() {
    unawaited(_foregroundMessages.cancel());
    _webviewController.removeListener(_onWebviewChanged);
    _webviewController.dispose();
    _notificationsController.dispose();
    super.dispose();
  }

  void _onWebviewChanged() {
    final isLoggedIn = _webviewController.isLoggedIn;
    if (_lastKnownLoggedIn == true && isLoggedIn == false) {
      unawaited(_notificationsController.clearForLogout());
    }
    _lastKnownLoggedIn = isLoggedIn;
    if (mounted) setState(() {});
  }

  void _refreshNotificationsIfSignedIn() {
    if (_webviewController.isLoggedIn != false) unawaited(_notificationsController.refresh());
  }

  AppBar _buildAppBar() {
    final isTrackerTab = _currentIndex == 0;

    return AppBar(
      title: Text(
        _tabTitles[_currentIndex].toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFFFE81F),
          letterSpacing: 3.5,
          fontWeight: FontWeight.w700,
          fontSize: 17,
          shadows: [
            Shadow(color: Color(0xFFFFAA00), blurRadius: 12),
            Shadow(
              color: Color(0xFF000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      actions: [
        if (isTrackerTab) ...[
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Home',
            onPressed: () => unawaited(_webviewController.load(AppConfig.trackerUrl)),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            tooltip: 'Open in Browser',
            onPressed: () => unawaited(UrlLauncherService.openExternal(AppConfig.trackerUrl)),
          ),
        ],
      ],
    );
  }

  void _switchToTracker() => setState(() => _currentIndex = 0);

  // Back goes to the Tracker tab, then through WebView history, then closes
  // the app. Popping this route instead would leave an empty navigator and a
  // black screen, because MainShellView replaced the splash as the only route.
  Future<void> _handleBack(bool didPop, Object? _) async {
    if (didPop) return;
    if (_currentIndex != 0) {
      _switchToTracker();
      return;
    }
    if (!_webviewController.hasError && await _webviewController.canGoBack()) {
      await _webviewController.goBack();
      return;
    }
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final showLoader = _currentIndex == 0 && _webviewController.isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handleBack,
      child: _buildScaffold(showLoader),
    );
  }

  Scaffold _buildScaffold(bool showLoader) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                TrackerView(controller: _webviewController),
                NotificationsView(
                  controller: _notificationsController,
                  webviewController: _webviewController,
                  onNavigateToTracker: _switchToTracker,
                ),
                SettingsView(webviewController: _webviewController),
              ],
            ),
          ),
          LoadingOverlay(
            progress: _webviewController.loadingProgress,
            isVisible: showLoader,
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _notificationsController,
        builder: (context, _) => AppBottomNav(
          currentIndex: _currentIndex,
          unreadNotificationCount:
              _webviewController.isLoggedIn == false ? 0 : _notificationsController.unreadCount,
          onTap: (index) {
            setState(() => _currentIndex = index);
            if (index == 1) _refreshNotificationsIfSignedIn();
          },
        ),
      ),
    );
  }
}
