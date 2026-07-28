import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../navigation/app_routes.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              authState.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(authState.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.colorScheme.onPrimary,
              child: Text(
                authState.displayName.isNotEmpty
                    ? authState.displayName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.go(AppRoutes.profilePath);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification Center'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.notificationsPath);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.settingsPath);
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Feedback'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.helpPath);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.aboutPath);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
              context.go(AppRoutes.authPath);
            },
          ),
        ],
      ),
    );
  }
}
