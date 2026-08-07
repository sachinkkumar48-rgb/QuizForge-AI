library;

import '../domain/entities/enums.dart';
import 'knowledge_ontology_node.dart';

/// Hierarchical Knowledge Ontology Tree supporting Subject -> Module -> Topic -> Subtopic -> Concept -> Knowledge Object -> Evidence.
class KnowledgeOntology {
  final Map<String, KnowledgeOntologyNode> _nodes = {};

  /// Add or update a node in the ontology tree.
  void addNode(KnowledgeOntologyNode node) {
    _nodes[node.id] = node;

    // Attach to parent if parent node exists
    if (node.parentId != null && _nodes.containsKey(node.parentId)) {
      final parent = _nodes[node.parentId!]!;
      if (!parent.childrenIds.contains(node.id)) {
        _nodes[node.parentId!] = parent.copyWith(
          childrenIds: [...parent.childrenIds, node.id],
        );
      }
    }
  }

  /// Get node by ID.
  KnowledgeOntologyNode? getNode(String id) => _nodes[id];

  /// Get ancestors up to root.
  List<KnowledgeOntologyNode> getAncestors(String nodeId) {
    final ancestors = <KnowledgeOntologyNode>[];
    var current = _nodes[nodeId];

    while (current != null && current.parentId != null) {
      final parent = _nodes[current.parentId!];
      if (parent == null || ancestors.contains(parent)) break; // cycle protection
      ancestors.add(parent);
      current = parent;
    }
    return ancestors;
  }

  /// Get descendants of a node.
  List<KnowledgeOntologyNode> getDescendants(String nodeId) {
    final descendants = <KnowledgeOntologyNode>[];
    final queue = <String>[nodeId];
    final visited = <String>{nodeId};

    while (queue.isNotEmpty) {
      final currId = queue.removeAt(0);
      final currNode = _nodes[currId];
      if (currNode == null) continue;

      for (final childId in currNode.childrenIds) {
        if (!visited.contains(childId)) {
          visited.add(childId);
          queue.add(childId);
          if (_nodes.containsKey(childId)) {
            descendants.add(_nodes[childId]!);
          }
        }
      }
    }
    return descendants;
  }

  /// Check if two nodes belong to the same hierarchy path or topic branch.
  bool isSameBranch(String nodeIdA, String nodeIdB) {
    if (nodeIdA == nodeIdB) return true;
    final ancestorsA = getAncestors(nodeIdA).map((n) => n.id).toSet();
    final ancestorsB = getAncestors(nodeIdB).map((n) => n.id).toSet();

    return ancestorsA.contains(nodeIdB) ||
        ancestorsB.contains(nodeIdA) ||
        ancestorsA.intersection(ancestorsB).isNotEmpty;
  }

  /// Find nodes by type.
  List<KnowledgeOntologyNode> findByType(NodeType type) {
    return _nodes.values.where((n) => n.type == type).toList();
  }
}
