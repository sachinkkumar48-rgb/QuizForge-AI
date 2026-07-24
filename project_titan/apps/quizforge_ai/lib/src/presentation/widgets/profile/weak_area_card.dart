import 'package:flutter/material.dart';

/// Material 3 card highlighting weak topics requiring revision and focus.
class WeakAreaCard extends StatelessWidget {
  final List<String> weakTopics;

  const WeakAreaCard({
    super.key,
    required this.weakTopics,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Identified Focus & Weak Areas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (weakTopics.isEmpty)
              Text(
                'No weak areas identified! All topics maintain high proficiency.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: weakTopics
                    .map((topic) => Chip(
                          avatar: Icon(
                            Icons.priority_high,
                            size: 14,
                            color: colorScheme.error,
                          ),
                          label: Text(topic),
                          labelStyle: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: colorScheme.errorContainer,
                          side: BorderSide(
                              color: colorScheme.error.withValues(alpha: 0.3)),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
