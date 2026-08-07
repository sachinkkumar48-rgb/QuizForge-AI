import 'package:flutter/material.dart';

/// Progress Card displaying module metadata, completed/remaining stats, and completion percentage.
class ModuleProgressCard extends StatelessWidget {
  final String subject;
  final String moduleTitle;
  final int completedLessons;
  final int totalLessons;

  const ModuleProgressCard({
    super.key,
    required this.subject,
    required this.moduleTitle,
    required this.completedLessons,
    required this.totalLessons,
  });

  int get remainingLessons => (totalLessons - completedLessons).clamp(0, totalLessons);

  double get progressRatio => totalLessons > 0 ? (completedLessons / totalLessons) : 0.0;

  int get completionPercentage => (progressRatio * 100).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: theme.colorScheme.primary.withAlpha(80),
        ),
      ),
      color: theme.colorScheme.primaryContainer.withAlpha(40),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Tag & Completion Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    subject.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700.withAlpha(30),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.green.shade700.withAlpha(100)),
                  ),
                  child: Text(
                    '$completionPercentage% COMPLETED',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Module Title Header
            Text(
              moduleTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),

            // Animated Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: LinearProgressIndicator(
                value: progressRatio,
                minHeight: 8.0,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16.0),

            // Stat Metrics Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricTile(
                  context: context,
                  label: 'Completed',
                  value: '$completedLessons',
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.green.shade700,
                ),
                _buildMetricTile(
                  context: context,
                  label: 'Remaining',
                  value: '$remainingLessons',
                  icon: Icons.hourglass_empty_rounded,
                  color: theme.colorScheme.tertiary,
                ),
                _buildMetricTile(
                  context: context,
                  label: 'Total Lessons',
                  value: '$totalLessons',
                  icon: Icons.menu_book_rounded,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.0, color: color),
            const SizedBox(width: 4.0),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2.0),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
