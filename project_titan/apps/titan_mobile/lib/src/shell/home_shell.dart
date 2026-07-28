import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_routes.dart';
import '../providers/notification_provider.dart';
import '../widgets/offline_banner.dart';
import 'adaptive_navigation.dart';
import 'app_drawer.dart';

class HomeShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({
    super.key,
    required this.navigationShell,
  });

  static const List<NavigationDestinationItem> _destinations = [
    NavigationDestinationItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    NavigationDestinationItem(
      label: 'Academy',
      icon: Icons.school_outlined,
      selectedIcon: Icons.school,
    ),
    NavigationDestinationItem(
      label: 'Learning',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
    ),
    NavigationDestinationItem(
      label: 'Assessments',
      icon: Icons.quiz_outlined,
      selectedIcon: Icons.quiz,
    ),
    NavigationDestinationItem(
      label: 'AI Tutor',
      icon: Icons.psychology_outlined,
      selectedIcon: Icons.psychology,
    ),
    NavigationDestinationItem(
      label: 'Journey',
      icon: Icons.map_outlined,
      selectedIcon: Icons.map,
    ),
    NavigationDestinationItem(
      label: 'Planner',
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
    ),
    NavigationDestinationItem(
      label: 'Search',
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
    ),
    NavigationDestinationItem(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TITAN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.searchPath),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(AppRoutes.notificationsPath),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const OfflineBanner(isOffline: false),
          Expanded(
            child: AdaptiveNavigationLayout(
              currentIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: _destinations,
              body: navigationShell,
            ),
          ),
        ],
      ),
    );
  }
}
