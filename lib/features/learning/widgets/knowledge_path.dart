import 'package:flutter/material.dart';

/// Visual connector widget representing the progression path between two Knowledge Nodes.
class KnowledgePath extends StatelessWidget {
  final bool isCompleted;

  const KnowledgePath({
    super.key,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCompleted
        ? Colors.green.shade600
        : theme.colorScheme.outlineVariant;

    return Container(
      height: 28,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Vertical connecting line
          Container(
            width: 2.5,
            height: 28,
            color: color,
          ),
          // Directional indicator badge (down arrow ↓)
          Container(
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
