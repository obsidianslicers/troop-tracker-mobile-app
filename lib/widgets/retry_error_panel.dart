import 'package:flutter/material.dart';

/// Displayed when the WebView fails to load the tracker site.
/// Provides a retry button and an optional "Open in Browser" fallback.
class RetryErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onOpenInBrowser;

  const RetryErrorPanel({
    super.key,
    required this.message,
    required this.onRetry,
    this.onOpenInBrowser,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 72, color: Colors.white38),
            const SizedBox(height: 20),
            const Text(
              'Unable to connect',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              message.isNotEmpty ? message : 'Check your internet connection and try again.',
              style: const TextStyle(color: Colors.white54, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
            if (onOpenInBrowser != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onOpenInBrowser,
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text('Open in Browser'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
