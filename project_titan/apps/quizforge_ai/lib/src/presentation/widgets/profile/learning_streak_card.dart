import 'package:flutter/material.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';

/// Material 3 card displaying current streak days, longest streak, and active flame badge.
class LearningStreakCard extends StatelessWidget {
  final LearningStreak streak;

  const LearningStreakCard({
    super.key,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.deepOrange,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${streak.currentStreakDays} Day Streak!',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Longest Streak: ${streak.longestStreakDays} days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(streak.isStreakActive ? 'Active' : 'Paused'),
              backgroundColor: streak.isStreakActive
                  ? Colors.green.withValues(alpha: 0.15)
                  : colorScheme.error.withValues(alpha: 0.15),
              labelStyle: theme.textTheme.labelSmall?.copyWith(
                color: streak.isStreakActive ? Colors.green : colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
