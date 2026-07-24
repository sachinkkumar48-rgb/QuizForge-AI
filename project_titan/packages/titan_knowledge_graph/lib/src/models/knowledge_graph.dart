import 'package:meta/meta.dart';

import 'knowledge_edge.dart';
import 'knowledge_node.dart';

/// Immutable domain container representing an entire Knowledge Graph.
@immutable
class KnowledgeGraph {
  final Map<String, KnowledgeNode> nodes;
  final List<KnowledgeEdge> edges;
  final Map<String, List<KnowledgeEdge>> _adjacencyOut;
  final Map<String, List<KnowledgeEdge>> _adjacencyIn;

  KnowledgeGraph({
    required Map<String, KnowledgeNode> nodes,
    required List<KnowledgeEdge> edges,
  })  : nodes = Map<String, KnowledgeNode>.unmodifiable(nodes),
        edges = List<KnowledgeEdge>.unmodifiable(edges),
        _adjacencyOut = _buildOutAdjacency(edges),
        _adjacencyIn = _buildInAdjacency(edges);

  /// Retrieves outgoing edges from a given source node.
  List<KnowledgeEdge> getOutgoingEdges(String nodeId) {
    return _adjacencyOut[nodeId] ?? const [];
  }

  /// Retrieves incoming edges to a given target node.
  List<KnowledgeEdge> getIncomingEdges(String nodeId) {
    return _adjacencyIn[nodeId] ?? const [];
  }

  /// Retrieves a node by its unique ID.
  KnowledgeNode? getNode(String nodeId) {
    return nodes[nodeId];
  }

  /// Finds nodes matching a specific node type.
  List<KnowledgeNode> getNodesByType(KnowledgeNodeType type) {
    return nodes.values.where((n) => n.type == type).toList();
  }

  KnowledgeGraph copyWith({
    Map<String, KnowledgeNode>? nodes,
    List<KnowledgeEdge>? edges,
  }) {
    return KnowledgeGraph(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }

  static Map<String, List<KnowledgeEdge>> _buildOutAdjacency(
    List<KnowledgeEdge> edges,
  ) {
    final map = <String, List<KnowledgeEdge>>{};
    for (final edge in edges) {
      map.putIfAbsent(edge.sourceId, () => []).add(edge);
    }
    return Map.unmodifiable(
      map.map((k, v) => MapEntry(k, List<KnowledgeEdge>.unmodifiable(v))),
    );
  }

  static Map<String, List<KnowledgeEdge>> _buildInAdjacency(
    List<KnowledgeEdge> edges,
  ) {
    final map = <String, List<KnowledgeEdge>>{};
    for (final edge in edges) {
      map.putIfAbsent(edge.targetId, () => []).add(edge);
    }
    return Map.unmodifiable(
      map.map((k, v) => MapEntry(k, List<KnowledgeEdge>.unmodifiable(v))),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeGraph &&
          runtimeType == other.runtimeType &&
          nodes.length == other.nodes.length &&
          edges.length == other.edges.length;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(nodes.keys),
        Object.hashAll(edges),
      );
}
