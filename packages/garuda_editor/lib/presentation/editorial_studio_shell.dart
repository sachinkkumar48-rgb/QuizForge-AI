import 'package:flutter/material.dart';
import '../application/editorial_studio_controller.dart';
import 'dashboard_screen.dart';
import 'evidence_inbox_screen.dart';
import 'knowledge_object_manager_screen.dart';
import 'link_review_screen.dart';
import 'publishing_queue_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'version_history_screen.dart';

/// Main Desktop-First Material 3 Shell for GARUDA Editorial Studio.
class EditorialStudioShell extends AnimatedWidget {
  final EditorialStudioController controller;

  const EditorialStudioShell({
    super.key,
    required this.controller,
  }) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GARUDA Editorial Studio',
      debugShowCheckedModeBanner: false,
      themeMode: controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        body: Row(
          children: [
            // Left NavigationRail
            NavigationRail(
              selectedIndex: controller.currentTabIndex,
              onDestinationSelected: controller.selectTab,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    const Icon(Icons.security, size: 36, color: Colors.indigoAccent),
                    const SizedBox(height: 4),
                    Text(
                      'GARUDA',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'STUDIO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.indigoAccent),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.inbox_outlined), selectedIcon: Icon(Icons.inbox), label: Text('Inbox')),
                NavigationRailDestination(icon: Icon(Icons.folder_outlined), selectedIcon: Icon(Icons.folder), label: Text('Manager')),
                NavigationRailDestination(icon: Icon(Icons.alt_route_outlined), selectedIcon: Icon(Icons.alt_route), label: Text('Link Review')),
                NavigationRailDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: Text('Versions')),
                NavigationRailDestination(icon: Icon(Icons.publish_outlined), selectedIcon: Icon(Icons.publish), label: Text('Publishing')),
                NavigationRailDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: Text('Search')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
              ],
            ),

            const VerticalDivider(thickness: 1, width: 1),

            // Right Main Content Region
            Expanded(
              child: Column(
                children: [
                  // Top Header Bar
                  Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            _getTabTitle(controller.currentTabIndex),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        Row(
                          children: [
                            IconButton(
                              icon: Icon(controller.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                              tooltip: 'Toggle Theme',
                              onPressed: controller.toggleDarkMode,
                            ),
                            const SizedBox(width: 12),
                            Chip(
                              avatar: const Icon(Icons.person, size: 16),
                              label: Text(controller.currentRole.label),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Active Screen Body
                  Expanded(
                    child: _buildActiveScreen(controller.currentTabIndex),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard & Metrics';
      case 1:
        return 'Evidence Ingestion Inbox';
      case 2:
        return 'Knowledge Object Manager';
      case 3:
        return 'Knowledge Link Review';
      case 4:
        return 'Version History & Diffs';
      case 5:
        return 'Publishing Queue & Pipeline';
      case 6:
        return 'Universal Knowledge Search';
      case 7:
        return 'Studio Settings & Permissions';
      default:
        return 'GARUDA Editorial Studio';
    }
  }

  Widget _buildActiveScreen(int index) {
    switch (index) {
      case 0:
        return DashboardScreen(controller: controller);
      case 1:
        return EvidenceInboxScreen(controller: controller);
      case 2:
        return KnowledgeObjectManagerScreen(controller: controller);
      case 3:
        return LinkReviewScreen(controller: controller);
      case 4:
        return VersionHistoryScreen(controller: controller);
      case 5:
        return PublishingQueueScreen(controller: controller);
      case 6:
        return SearchScreen(controller: controller);
      case 7:
        return SettingsScreen(controller: controller);
      default:
        return DashboardScreen(controller: controller);
    }
  }
}
