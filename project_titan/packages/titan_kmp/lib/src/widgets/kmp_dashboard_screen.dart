import 'package:flutter/material.dart';
import '../models/kmp_rbac_models.dart';

/// Administrative Knowledge Management Platform (KMP) Dashboard.
class KmpDashboardScreen extends StatelessWidget {
  final KmpUserSession session;

  const KmpDashboardScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TITAN KMP Admin Console'),
            Text(
              '${session.userName} (${session.role.label})',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Security Status',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.cloud_done_outlined),
            tooltip: 'Cloud Sync Status',
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Administrative Header Card
            Card(
              color: colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.auto_stories,
                        size: 36, color: colorScheme.onPrimaryContainer),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Knowledge Management Platform (KMP)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Single Source of Truth for Courses, Question Bank, Media & Publishing.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Content Management Subsystems',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 6 Subsystem Navigation Tiles
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildSubsystemCard(
                  context,
                  title: 'Course Management',
                  subtitle: 'Courses, Modules, Lessons & Paths',
                  icon: Icons.school_outlined,
                  color: Colors.blue,
                  enabled: true,
                ),
                _buildSubsystemCard(
                  context,
                  title: 'Content Authoring',
                  subtitle: 'PDF, DOCX, Markdown & HTML',
                  icon: Icons.edit_note,
                  color: Colors.purple,
                  enabled: session.role.canAuthor,
                ),
                _buildSubsystemCard(
                  context,
                  title: 'Question Bank',
                  subtitle: 'MCQ, PYQ, Mains & 8 Types',
                  icon: Icons.quiz_outlined,
                  color: Colors.orange,
                  enabled: session.role.canAuthor,
                ),
                _buildSubsystemCard(
                  context,
                  title: 'Media Library',
                  subtitle: 'Videos, PDFs, Images & Audio',
                  icon: Icons.perm_media_outlined,
                  color: Colors.teal,
                  enabled: true,
                ),
                _buildSubsystemCard(
                  context,
                  title: 'Publishing Workflow',
                  subtitle: 'Draft → Review → Publish',
                  icon: Icons.published_with_changes,
                  color: Colors.green,
                  enabled: session.role.canReview,
                ),
                _buildSubsystemCard(
                  context,
                  title: 'AI Ingestion Pipeline',
                  subtitle: 'AI Synthesis, Graph & Search',
                  icon: Icons.auto_awesome,
                  color: Colors.indigo,
                  enabled: session.role.canPublish,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubsystemCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: enabled ? 2 : 0,
      color: enabled
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: InkWell(
        onTap: enabled ? () {} : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: enabled ? color : Colors.grey, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: enabled ? theme.colorScheme.onSurface : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: enabled
                      ? theme.colorScheme.onSurfaceVariant
                      : Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
