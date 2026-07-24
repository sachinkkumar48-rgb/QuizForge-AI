import 'package:meta/meta.dart';

/// Relationship type connecting two nodes in the Knowledge Graph.
enum KnowledgeRelationType {
  prerequisite,
  contains,
  relatedTo,
  assesses,
  derivedFrom,
}

/// Immutable directed edge connecting source node to target node.
@immutable
class KnowledgeEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final KnowledgeRelationType relationType;
  final double weight; // Strength of relationship (0.0 to 1.0)
  final Map<String, dynamic> metadata;

  KnowledgeEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.relationType,
    this.weight = 1.0,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {});

  KnowledgeEdge copyWith({
    String? id,
    String? sourceId,
    String? targetId,
    KnowledgeRelationType? relationType,
    double? weight,
    Map<String, dynamic>? metadata,
  }) {
    return KnowledgeEdge(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      relationType: relationType ?? this.relationType,
      weight: weight ?? this.weight,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeEdge &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sourceId == other.sourceId &&
          targetId == other.targetId &&
          relationType == other.relationType &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(
        id,
        sourceId,
        targetId,
        relationType,
        weight,
      );
}
