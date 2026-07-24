import 'package:flutter/material.dart';

import '../models/knowledge_node.dart';
import 'graph_node_chip.dart';

/// Material 3 Card rendering ranked related topics for a concept/subtopic.
class RelatedTopicsCard extends StatelessWidget {
  final String rootTitle;
  final List<KnowledgeNode> relatedTopics;
  final ValueChanged<KnowledgeNode>? onTopicSelected;

  const RelatedTopicsCard({
    super.key,
    required this.rootTitle,
    required this.relatedTopics,
    this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.scatter_plot_outlined,
                  size: 20.0,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Related Topics for "$rootTitle"',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            if (relatedTopics.isEmpty)
              Text(
                'No related topics found in graph.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: relatedTopics.map((node) {
                  return GraphNodeChip(
                    node: node,
                    onTap: () => onTopicSelected?.call(node),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
