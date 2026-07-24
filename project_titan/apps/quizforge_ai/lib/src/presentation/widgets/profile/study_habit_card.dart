import 'package:flutter/material.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';

/// Material 3 card displaying study habit metrics (peak study hours, preferred subject, avg session duration).
class StudyHabitCard extends StatelessWidget {
  final StudyHabit habit;

  const StudyHabitCard({
    super.key,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final peakHourFormatted =
        '${habit.peakStudyHour % 12 == 0 ? 12 : habit.peakStudyHour % 12} ${habit.peakStudyHour >= 12 ? "PM" : "AM"}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Study Habits & Patterns',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHabitRow(
              context,
              Icons.access_time,
              'Peak Focus Time',
              peakHourFormatted,
            ),
            const SizedBox(height: 10),
            _buildHabitRow(
              context,
              Icons.book,
              'Preferred Subject',
              habit.preferredSubject,
            ),
            const SizedBox(height: 10),
            _buildHabitRow(
              context,
              Icons.timelapse,
              'Avg Session Length',
              '${habit.avgSessionDurationMinutes} min/session',
            ),
            const SizedBox(height: 10),
            _buildHabitRow(
              context,
              Icons.check_circle_outline,
              'Total Sessions Completed',
              '${habit.totalSessionsCompleted} sessions',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitRow(
      BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
