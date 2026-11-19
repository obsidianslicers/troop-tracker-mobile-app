import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controllers/webview_controller.dart';
import '../views/error_view.dart';

/// Displays the Tracker WebView with pull-to-refresh.
///
/// Android back navigation is handled by MainShellView.
///
/// The [controller] is owned by MainShellView — this view only adds/removes
/// a listener and does not call initialize() or dispose() on the controller.
class TrackerView extends StatefulWidget {
  final WebviewController controller;

  const TrackerView({super.key, required this.controller});

  @override
  State<TrackerView> createState() => _TrackerViewState();
}

class _TrackerViewState extends State<TrackerView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.hasError) {
      return ErrorView(controller: widget.controller);
    }

    return RefreshIndicator(
      onRefresh: widget.controller.reload,
      child: WebViewWidget(
        controller: widget.controller.webViewController,
      ),
    );
  }
}
