import 'package:flutter/material.dart';

import '../models/learning_session_models.dart';

/// Card rendering comprehensive statistics and achievements earned after completing a study session.
class StudySessionSummary extends StatelessWidget {
  final LearningFlowSummary summary;
  final VoidCallback? onReturnHome;

  const StudySessionSummary({
    super.key,
    required this.summary,
    this.onReturnHome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Study Session Completion Summary Card',
      container: true,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_rounded,
                      color: Colors.amber.shade700, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'SESSION SUMMARY',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      label: 'Duration',
                      value: '${summary.totalDurationMinutes}m',
                      icon: Icons.timer_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      label: 'Accuracy',
                      value: '${(summary.quizAccuracy * 100).toInt()}%',
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      label: 'Notes Created',
                      value: '${summary.notesCreatedCount}',
                      icon: Icons.edit_note_rounded,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      context,
                      label: 'Revisions Set',
                      value: '${summary.revisionScheduledCount}',
                      icon: Icons.published_with_changes_rounded,
                      color: colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              if (summary.achievementsEarned.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Achievements Unlocked:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: summary.achievementsEarned.map((badge) {
                    return Chip(
                      label: Text(badge),
                      backgroundColor:
                          colorScheme.primaryContainer.withValues(alpha: 0.6),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),
              if (onReturnHome != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onReturnHome,
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Return to Dashboard'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
