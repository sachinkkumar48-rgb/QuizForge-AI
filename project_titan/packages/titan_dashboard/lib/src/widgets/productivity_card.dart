import 'package:flutter/material.dart';

import '../models/study_statistics.dart';

/// Material 3 productivity metrics summary card.
class ProductivityCard extends StatelessWidget {
  final StudyStatistics statistics;

  const ProductivityCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0.0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              icon: Icons.local_fire_department,
              color: Colors.deepOrange,
              title: '${statistics.currentStreakDays} Days',
              subtitle: 'Current Streak',
            ),
            Container(
                width: 1.0, height: 40.0, color: colorScheme.outlineVariant),
            _buildStatItem(
              context,
              icon: Icons.quiz_outlined,
              color: colorScheme.primary,
              title: '${statistics.totalQuestionsAttempted}',
              subtitle: 'Questions',
            ),
            Container(
                width: 1.0, height: 40.0, color: colorScheme.outlineVariant),
            _buildStatItem(
              context,
              icon: Icons.check_circle,
              color: Colors.green,
              title: '${statistics.completedTasksCount}',
              subtitle: 'Tasks Completed',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22.0),
        const SizedBox(height: 4.0),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11.0,
          ),
        ),
      ],
    );
  }
}
