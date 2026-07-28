import 'package:flutter/material.dart';

/// Material 3 Video Progress Card showing video progress & watch statistics.
class VideoProgressCard extends StatelessWidget {
  final String title;
  final int positionSeconds;
  final int durationSeconds;

  const VideoProgressCard({
    super.key,
    required this.title,
    required this.positionSeconds,
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = durationSeconds > 0
        ? (positionSeconds / durationSeconds).clamp(0.0, 1.0)
        : 0.0;
    final percentage = (progress * 100).toInt();

    return Card(
      elevation: 1,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Video Progress', style: theme.textTheme.titleSmall),
                Text('$percentage%',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4)),
            const SizedBox(height: 8),
            Text('$title ($positionSeconds / $durationSeconds sec)',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
