import 'package:flutter/material.dart';
import 'package:titan_quiz/titan_quiz.dart';
import '../../theme/app_spacing.dart';

/// Card widget allowing one-tap launching of targeted adaptive practice sessions for weak areas.
class PracticeWeakAreasCard extends StatelessWidget {
  final List<String> weakTopics;
  final QuizDifficulty recommendedDifficulty;
  final VoidCallback? onStartPractice;

  const PracticeWeakAreasCard({
    super.key,
    required this.weakTopics,
    this.recommendedDifficulty = QuizDifficulty.medium,
    this.onStartPractice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (weakTopics.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Critical Weak Areas Detected',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All tested topics are currently meeting mastery benchmarks.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: Colors.deepOrange.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes,
                    color: Colors.deepOrange.shade700, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Practice Weak Areas',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Level: ${recommendedDifficulty.name.toUpperCase()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.deepOrange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Focused practice targeting ${weakTopics.length} weak topics to improve overall profile score:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: weakTopics
                  .map(
                    (topic) => Chip(
                      label: Text(topic),
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      side: BorderSide(color: Colors.red.shade200),
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            if (onStartPractice != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onStartPractice,
                  icon: const Icon(Icons.bolt, size: 18),
                  label: const Text('Start Adaptive Weak Area Practice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
