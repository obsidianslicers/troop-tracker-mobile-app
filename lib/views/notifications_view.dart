import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../controllers/notifications_controller.dart';
import '../controllers/webview_controller.dart';
import '../models/push_notification.dart';

class NotificationsView extends StatefulWidget {
  final NotificationsController controller;
  final WebviewController webviewController;
  final VoidCallback onNavigateToTracker;

  const NotificationsView({
    super.key,
    required this.controller,
    required this.webviewController,
    required this.onNavigateToTracker,
  });

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    if (widget.webviewController.isLoggedIn != false) unawaited(widget.controller.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.webviewController]),
      builder: (context, _) {
        if (widget.webviewController.isLoggedIn == false) {
          return _SignInPrompt(onSignIn: widget.onNavigateToTracker);
        }

        final ctrl = widget.controller;

        if (ctrl.isLoading && ctrl.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.notifications.isEmpty) {
          return _EmptyState(onRefresh: ctrl.refresh);
        }

        return RefreshIndicator(
          onRefresh: ctrl.refresh,
          child: Column(
            children: [
              _Toolbar(onClear: ctrl.clearAll),
              Expanded(
                child: ListView.separated(
                  itemCount: ctrl.notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final notification = ctrl.notifications[index];
                    return _NotificationTile(
                      notification: notification,
                      onTap: () async {
                        await ctrl.markRead(notification);
                        unawaited(
                          widget.webviewController.load(AppConfig.urlFor(notification.url)),
                        );
                        widget.onNavigateToTracker();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  final Future<void> Function() onClear;
  const _Toolbar({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            label: const Text('Clear all'),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Clear notifications'),
                  content: const Text('Delete all notifications?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirm == true) await onClear();
            },
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final PushNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        notification.isUnread ? Icons.notifications_rounded : Icons.notifications_none_rounded,
        color: notification.isUnread ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(notification.body),
      trailing: Text(
        _timeAgo(notification.createdAt),
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      onTap: onTap,
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _SignInPrompt extends StatelessWidget {
  final VoidCallback onSignIn;
  const _SignInPrompt({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 72, color: Colors.white24),
          const SizedBox(height: 20),
          const Text(
            'Sign in to view notifications',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'You are not currently signed in.',
            style: TextStyle(color: Colors.white38),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onSignIn,
            child: const Text('Go to Sign In'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none_rounded, size: 72, color: Colors.white24),
          const SizedBox(height: 20),
          const Text(
            'No notifications yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Notifications will appear here.',
            style: TextStyle(color: Colors.white38),
          ),
          const SizedBox(height: 24),
          TextButton(onPressed: onRefresh, child: const Text('Refresh')),
        ],
      ),
    );
  }
}
