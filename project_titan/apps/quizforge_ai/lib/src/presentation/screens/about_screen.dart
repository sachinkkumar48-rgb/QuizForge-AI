import 'package:flutter/material.dart';
import '../localization/app_localization.dart';
import '../theme/app_spacing.dart';
import '../widgets/responsive_layout.dart';

/// Screen presenting application information and architecture version.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLocalization.navAbout),
      ),
      body: ResponsiveLayout(
        mobile: _buildContent(context, theme),
        desktop: Center(
          child: SizedBox(
            width: 600,
            child: _buildContent(context, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalization.appTitle,
            style: theme.textTheme.displaySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Version 1.0.0 (Project TITAN SPRINT 2.1)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'QuizForge AI is a modular, AI-driven UPSC quiz generation engine powered by Project TITAN clean architecture.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
