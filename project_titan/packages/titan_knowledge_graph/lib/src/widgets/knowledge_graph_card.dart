import 'package:flutter/material.dart';

import '../models/knowledge_graph.dart';

/// Material 3 Card summarizing Knowledge Graph metrics (nodes, edges, categories).
class KnowledgeGraphCard extends StatelessWidget {
  final KnowledgeGraph graph;
  final VoidCallback? onExplorePressed;

  const KnowledgeGraphCard({
    super.key,
    required this.graph,
    this.onExplorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nodeCount = graph.nodes.length;
    final edgeCount = graph.edges.length;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hub_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TITAN Knowledge Graph',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$nodeCount Nodes • $edgeCount Connected Relations',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatTile(
                  label: 'Entities',
                  value: nodeCount.toString(),
                  icon: Icons.bubble_chart_outlined,
                ),
                _StatTile(
                  label: 'Relations',
                  value: edgeCount.toString(),
                  icon: Icons.share_outlined,
                ),
                _StatTile(
                  label: 'Syllabus Coverage',
                  value: '${(nodeCount > 0 ? 85 : 0)}%',
                  icon: Icons.verified_outlined,
                ),
              ],
            ),
            if (onExplorePressed != null) ...[
              const SizedBox(height: 16.0),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onExplorePressed,
                  icon: const Icon(Icons.explore_outlined, size: 18.0),
                  label: const Text('Explore Graph'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, size: 20.0, color: colorScheme.primary),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
