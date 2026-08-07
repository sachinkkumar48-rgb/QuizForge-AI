import 'package:flutter/material.dart';

class LessonHeader extends StatelessWidget {
  final String title;
  final String estimatedTime;
  final String? subject;

  const LessonHeader({
    super.key,
    required this.title,
    required this.estimatedTime,
    this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subject != null && subject!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                subject!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
          ],
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6.0),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16.0,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 4.0),
              Text(
                'Est. Time: $estimatedTime',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
