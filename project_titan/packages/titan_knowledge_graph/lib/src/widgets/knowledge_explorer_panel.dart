import 'package:flutter/material.dart';

import '../models/knowledge_graph.dart';
import '../models/knowledge_node.dart';
import '../models/knowledge_path.dart';
import 'graph_node_chip.dart';
import 'learning_path_card.dart';
import 'related_topics_card.dart';

/// Comprehensive Material 3 interactive explorer panel for Knowledge Graph entities,
/// BFS traversals, related topics, and shortest learning paths.
class KnowledgeExplorerPanel extends StatefulWidget {
  final KnowledgeGraph graph;
  final KnowledgeNode? initialSelectedNode;
  final List<KnowledgeNode> relatedTopics;
  final KnowledgePath? activePath;
  final ValueChanged<KnowledgeNode>? onNodeSelected;

  const KnowledgeExplorerPanel({
    super.key,
    required this.graph,
    this.initialSelectedNode,
    this.relatedTopics = const [],
    this.activePath,
    this.onNodeSelected,
  });

  @override
  State<KnowledgeExplorerPanel> createState() => _KnowledgeExplorerPanelState();
}

class _KnowledgeExplorerPanelState extends State<KnowledgeExplorerPanel> {
  late KnowledgeNode? _selectedNode;
  String _searchQuery = '';
  KnowledgeNodeType? _filterType;

  @override
  void initState() {
    super.initState();
    _selectedNode = widget.initialSelectedNode ??
        (widget.graph.nodes.isNotEmpty
            ? widget.graph.nodes.values.first
            : null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredNodes = widget.graph.nodes.values.where((n) {
      final matchesSearch = _searchQuery.isEmpty ||
          n.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _filterType == null || n.type == _filterType;
      return matchesSearch && matchesType;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Filter Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search knowledge nodes...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
        const SizedBox(height: 12.0),

        // Node Type Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                selected: _filterType == null,
                label: const Text('All Types'),
                onSelected: (_) => setState(() => _filterType = null),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8.0),
              ...KnowledgeNodeType.values.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    selected: _filterType == type,
                    label: Text(type.name),
                    onSelected: (_) => setState(() => _filterType = type),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // Node Grid / List
        Text(
          'Knowledge Nodes (${filteredNodes.length})',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: filteredNodes.map((node) {
            final isSel = node.id == _selectedNode?.id;
            return GraphNodeChip(
              node: node,
              isSelected: isSel,
              onTap: () {
                setState(() => _selectedNode = node);
                widget.onNodeSelected?.call(node);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20.0),

        // Related Topics for selected node
        if (_selectedNode != null) ...[
          RelatedTopicsCard(
            rootTitle: _selectedNode!.title,
            relatedTopics: widget.relatedTopics,
            onTopicSelected: (node) {
              setState(() => _selectedNode = node);
              widget.onNodeSelected?.call(node);
            },
          ),
          const SizedBox(height: 16.0),
        ],

        // Active Learning Path if available
        if (widget.activePath != null) ...[
          LearningPathCard(path: widget.activePath!),
        ],
      ],
    );
  }
}
