import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/lesson.dart';

/// Material 3 hero card showing active learning state, next lesson, progress bar, and CTA.
class ContinueLearningCard extends StatelessWidget {
  final Course course;
  final Lesson lesson;
  final Enrollment enrollment;
  final VoidCallback? onResumeTap;

  const ContinueLearningCard({
    super.key,
    required this.course,
    required this.lesson,
    required this.enrollment,
    this.onResumeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = enrollment.progress.overallProgressPercentage;

    return Card(
      elevation: 2.0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_filled_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 24.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'CONTINUE LEARNING',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    course.subject,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              course.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Next Lesson: ${lesson.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.toStringAsFixed(0)}% Completed',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${lesson.durationMinutes} mins left',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            LinearProgressIndicator(
              value: progress / 100.0,
              backgroundColor:
                  colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              borderRadius: BorderRadius.circular(6.0),
            ),
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onResumeTap,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Resume Lesson'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
