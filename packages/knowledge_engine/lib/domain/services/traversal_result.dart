import 'package:meta/meta.dart';

import '../entities/knowledge_relationship.dart';

/// Immutable domain value object capturing the outcome and execution metrics of a
/// graph traversal operation in the TITAN Knowledge Intelligence Engine.
@immutable
class TraversalResult {
  /// Ordered list of unique node IDs visited during graph traversal.
  final List<String> visitedNodes;

  /// Ordered list of relationship edges traversed during graph traversal.
  final List<KnowledgeRelationship> traversedEdges;

  /// Maximum depth level reached during traversal.
  final int traversalDepth;

  /// Extensible statistics and metrics payload (e.g. execution duration, cycle detection count).
  final Map<String, dynamic> statistics;

  /// Constructs an immutable [TraversalResult].
  TraversalResult({
    required List<String> visitedNodes,
    required List<KnowledgeRelationship> traversedEdges,
    required this.traversalDepth,
    Map<String, dynamic> statistics = const {},
  })  : visitedNodes = List<String>.unmodifiable(visitedNodes),
        traversedEdges =
            List<KnowledgeRelationship>.unmodifiable(traversedEdges),
        statistics = Map<String, dynamic>.unmodifiable(statistics);

  /// Converts this [TraversalResult] into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'visitedNodes': visitedNodes,
      'traversedEdges': traversedEdges.map((e) => e.toMap()).toList(),
      'traversalDepth': traversalDepth,
      'statistics': statistics,
    };
  }

  /// Deserializes a [TraversalResult] from a Map.
  factory TraversalResult.fromMap(Map<String, dynamic> map) {
    return TraversalResult(
      visitedNodes: List<String>.from(map['visitedNodes'] as List? ?? const []),
      traversedEdges: (map['traversedEdges'] as List? ?? const [])
          .map((e) => KnowledgeRelationship.fromMap(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      traversalDepth: (map['traversalDepth'] as num?)?.toInt() ?? 0,
      statistics:
          Map<String, dynamic>.from(map['statistics'] as Map? ?? const {}),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TraversalResult &&
        _listEquals(other.visitedNodes, visitedNodes) &&
        _listEquals(other.traversedEdges, traversedEdges) &&
        other.traversalDepth == traversalDepth &&
        _mapEquals(other.statistics, statistics);
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(visitedNodes),
      Object.hashAll(traversedEdges),
      traversalDepth,
      Object.hashAll(statistics.keys),
      Object.hashAll(statistics.values),
    );
  }

  @override
  String toString() {
    return 'TraversalResult(visitedNodes: ${visitedNodes.length}, traversedEdges: ${traversedEdges.length}, depth: $traversalDepth)';
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
