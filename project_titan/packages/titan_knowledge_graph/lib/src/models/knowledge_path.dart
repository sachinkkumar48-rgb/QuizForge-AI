import 'package:meta/meta.dart';

import 'knowledge_edge.dart';
import 'knowledge_node.dart';

/// Immutable domain model representing a directed learning path in the Knowledge Graph.
@immutable
class KnowledgePath {
  final List<KnowledgeNode> nodes;
  final List<KnowledgeEdge> edges;
  final double totalDistance;
  final int stepCount;

  KnowledgePath({
    required List<KnowledgeNode> nodes,
    required List<KnowledgeEdge> edges,
    required this.totalDistance,
  })  : nodes = List<KnowledgeNode>.unmodifiable(nodes),
        edges = List<KnowledgeEdge>.unmodifiable(edges),
        stepCount = nodes.length;

  /// Retrieves the start node of the learning path.
  KnowledgeNode? get startNode => nodes.isNotEmpty ? nodes.first : null;

  /// Retrieves the final target node of the learning path.
  KnowledgeNode? get targetNode => nodes.isNotEmpty ? nodes.last : null;

  KnowledgePath copyWith({
    List<KnowledgeNode>? nodes,
    List<KnowledgeEdge>? edges,
    double? totalDistance,
  }) {
    return KnowledgePath(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgePath &&
          runtimeType == other.runtimeType &&
          totalDistance == other.totalDistance &&
          _listEquals(nodes, other.nodes) &&
          _listEquals(edges, other.edges);

  @override
  int get hashCode => Object.hash(
        totalDistance,
        Object.hashAll(nodes),
        Object.hashAll(edges),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
