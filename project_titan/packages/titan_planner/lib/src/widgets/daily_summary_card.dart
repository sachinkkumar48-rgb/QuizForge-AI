import 'package:flutter/material.dart';

import '../models/planner_models.dart';

/// Material 3 overview banner displaying daily study plan summary metrics,
/// category duration breakdown chips, and top focus area.
class DailySummaryCard extends StatelessWidget {
  final StudySummary summary;
  final int targetStudyTimeMinutes;

  const DailySummaryCard({
    super.key,
    required this.summary,
    required this.targetStudyTimeMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final targetFormatted = _formatTime(targetStudyTimeMinutes);

    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: colorScheme.secondary.withAlpha(64)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title + Target Time Badge
            Row(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  color: colorScheme.onSecondaryContainer,
                  size: 26.0,
                ),
                const SizedBox(width: 10.0),
                Text(
                  'Daily Study Plan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    'Budget: $targetFormatted',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            // Top Focus Topic Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withAlpha(180),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.center_focus_strong_rounded,
                    size: 18.0,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Top Focus: ${summary.topFocusTopic}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16.0),

            // Category Time Breakdown Wrap
            Wrap(
              spacing: 8.0,
              runSpacing: 6.0,
              children: [
                _CategoryChip(
                  label: 'Revision',
                  durationMinutes: summary.revisionMinutes,
                  icon: Icons.replay_rounded,
                  color: colorScheme.primary,
                ),
                _CategoryChip(
                  label: 'Learning',
                  durationMinutes: summary.learningMinutes,
                  icon: Icons.menu_book_rounded,
                  color: colorScheme.secondary,
                ),
                _CategoryChip(
                  label: 'Practice',
                  durationMinutes: summary.practiceMinutes,
                  icon: Icons.assignment_turned_in_rounded,
                  color: colorScheme.tertiary,
                ),
                _CategoryChip(
                  label: 'CA',
                  durationMinutes: summary.currentAffairsMinutes,
                  icon: Icons.newspaper_rounded,
                  color: colorScheme.outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int minutes) {
    if (minutes <= 0) return '0m';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (hours == 0) return '${rem}m';
    if (rem == 0) return '${hours}h';
    return '${hours}h ${rem}m';
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int durationMinutes;
  final IconData icon;
  final Color color;

  const _CategoryChip({
    required this.label,
    required this.durationMinutes,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: color.withAlpha(80), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.0, color: color),
          const SizedBox(width: 4.0),
          Text(
            '$label: ${durationMinutes}m',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
