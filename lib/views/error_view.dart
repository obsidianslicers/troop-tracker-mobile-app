import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../controllers/webview_controller.dart';
import '../services/url_launcher_service.dart';
import '../widgets/retry_error_panel.dart';

/// Full-screen error view shown when the WebView cannot load the tracker site.
/// Offers a retry button and a fallback to open the site in the system browser.
class ErrorView extends StatelessWidget {
  final WebviewController controller;

  const ErrorView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RetryErrorPanel(
        message: controller.errorMessage,
        onRetry: controller.reload,
        onOpenInBrowser: () => UrlLauncherService.openExternal(AppConfig.trackerUrl),
      ),
    );
  }
}
