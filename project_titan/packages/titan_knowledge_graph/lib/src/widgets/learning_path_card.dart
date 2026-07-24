import 'package:flutter/material.dart';

import '../models/knowledge_path.dart';

/// Material 3 Card rendering a step-by-step ordered learning path between nodes.
class LearningPathCard extends StatelessWidget {
  final KnowledgePath path;
  final VoidCallback? onStartPathPressed;

  const LearningPathCard({
    super.key,
    required this.path,
    this.onStartPathPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final startTitle = path.startNode?.title ?? 'Start';
    final targetTitle = path.targetNode?.title ?? 'Target';

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.route_outlined,
                      color: colorScheme.tertiary,
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'Shortest Learning Path',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    '${path.stepCount} Steps',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(
              'From "$startTitle" to "$targetTitle"',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24.0),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: path.nodes.length,
              separatorBuilder: (context, index) {
                final edge =
                    index < path.edges.length ? path.edges[index] : null;
                final relationText =
                    edge != null ? edge.relationType.name : 'leads to';
                return Padding(
                  padding:
                      const EdgeInsets.only(left: 20.0, top: 4.0, bottom: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 14.0,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        '($relationText)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              },
              itemBuilder: (context, index) {
                final stepNode = path.nodes[index];
                final isLast = index == path.nodes.length - 1;

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isLast
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHigh,
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isLast
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        stepNode.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              isLast ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (onStartPathPressed != null) ...[
              const SizedBox(height: 16.0),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onStartPathPressed,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18.0),
                  label: const Text('Begin Learning Sequence'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
