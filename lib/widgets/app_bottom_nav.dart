import 'package:flutter/material.dart';

/// Bottom navigation bar with three tabs: Tracker, Notifications, Settings.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final int unreadNotificationCount;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.unreadNotificationCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.track_changes_outlined),
          selectedIcon: Icon(Icons.track_changes),
          label: 'Tracker',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: unreadNotificationCount > 0,
            label: Text(unreadNotificationCount > 99 ? '99+' : '$unreadNotificationCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: unreadNotificationCount > 0,
            label: Text(unreadNotificationCount > 99 ? '99+' : '$unreadNotificationCount'),
            child: const Icon(Icons.notifications),
          ),
          label: 'Notifications',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
