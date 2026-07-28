import 'package:flutter/material.dart';

/// Material 3 card highlighting active concepts from the Knowledge Graph.
class KnowledgeInsightCard extends StatelessWidget {
  final List<String> weakSubjects;
  final List<String> strongSubjects;

  const KnowledgeInsightCard({
    super.key,
    required this.weakSubjects,
    required this.strongSubjects,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.hub_outlined, color: colorScheme.primary),
                const SizedBox(width: 8.0),
                Text(
                  'Knowledge Graph Insights',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            if (weakSubjects.isNotEmpty) ...[
              Text('Focus Areas (Weak):', style: theme.textTheme.labelSmall),
              const SizedBox(height: 4.0),
              Wrap(
                spacing: 6.0,
                children: weakSubjects
                    .map((s) => Chip(
                          label: Text(s),
                          backgroundColor: colorScheme.errorContainer,
                          labelStyle:
                              TextStyle(color: colorScheme.onErrorContainer),
                        ))
                    .toList(),
              ),
            ],
            if (strongSubjects.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              Text('Mastered Areas (Strong):',
                  style: theme.textTheme.labelSmall),
              const SizedBox(height: 4.0),
              Wrap(
                spacing: 6.0,
                children: strongSubjects
                    .map((s) => Chip(
                          label: Text(s),
                          backgroundColor: colorScheme.secondaryContainer,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
