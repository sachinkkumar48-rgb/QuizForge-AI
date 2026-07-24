import 'package:flutter/material.dart';

import '../models/knowledge_node.dart';

/// Material 3 Chip widget rendering a Knowledge Graph Node with type icon and mastery indicator.
class GraphNodeChip extends StatelessWidget {
  final KnowledgeNode node;
  final VoidCallback? onTap;
  final bool isSelected;

  const GraphNodeChip({
    super.key,
    required this.node,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = _getNodeIcon(node.type);

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onTap?.call(),
      avatar: Icon(
        iconData,
        size: 16.0,
        color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
      ),
      label: Text(node.title),
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color:
            isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
      ),
      backgroundColor: colorScheme.surfaceContainerHigh,
      selectedColor: colorScheme.primary,
      elevation: isSelected ? 2.0 : 0.0,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
    );
  }

  IconData _getNodeIcon(KnowledgeNodeType type) {
    switch (type) {
      case KnowledgeNodeType.subject:
        return Icons.account_tree_outlined;
      case KnowledgeNodeType.topic:
        return Icons.folder_special_outlined;
      case KnowledgeNodeType.subtopic:
        return Icons.alt_route_outlined;
      case KnowledgeNodeType.concept:
        return Icons.lightbulb_outline;
      case KnowledgeNodeType.pdf:
        return Icons.picture_as_pdf_outlined;
      case KnowledgeNodeType.pyq:
        return Icons.quiz_outlined;
      case KnowledgeNodeType.currentAffairs:
        return Icons.newspaper_outlined;
      case KnowledgeNodeType.notes:
        return Icons.description_outlined;
      case KnowledgeNodeType.revisionItem:
        return Icons.history_toggle_off;
    }
  }
}
