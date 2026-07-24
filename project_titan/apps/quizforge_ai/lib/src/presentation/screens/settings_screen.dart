import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/app_localization.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_spacing.dart';
import '../widgets/responsive_layout.dart';

/// Screen managing presentation theme and accessibility preferences.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLocalization.navSettings),
      ),
      body: ResponsiveLayout(
        mobile: _buildList(context, theme, themeMode, settings, ref),
        desktop: Center(
          child: SizedBox(
            width: 700,
            child: _buildList(context, theme, themeMode, settings, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    ThemeData theme,
    ThemeMode themeMode,
    AppSettingsState settings,
    WidgetRef ref,
  ) {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Appearance', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.settings_suggest),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode),
            ),
          ],
          selected: {themeMode},
          onSelectionChanged: (Set<ThemeMode> selection) {
            ref.read(themeProvider.notifier).setThemeMode(selection.first);
          },
        ),
        const Divider(height: AppSpacing.xl),
        Text('Accessibility', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        SwitchListTile(
          title: const Text('High Contrast Mode'),
          subtitle: const Text('Increase visual contrast across UI elements'),
          value: settings.highContrast,
          onChanged: (enabled) {
            ref.read(settingsProvider.notifier).setHighContrast(enabled);
          },
        ),
      ],
    );
  }
}
