import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../navigation/app_routes.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme Mode'),
            subtitle: Text(themeMode.name.toUpperCase()),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notification Preferences'),
            subtitle:
                const Text('Manage alerts for Planner, Live, & Assessment'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Offline Storage & Downloads'),
            subtitle: const Text('Manage downloaded videos and PDFs'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy & Security'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Feedback'),
            onTap: () => context.push(AppRoutes.helpPath),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Project TITAN'),
            onTap: () => context.push(AppRoutes.aboutPath),
          ),
        ],
      ),
    );
  }
}
