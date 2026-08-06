import 'package:meta/meta.dart';
import '../enums/relationship_type.dart';
import '../value_objects/knowledge_object_id.dart';

/// Immutable entity representing a directional relationship between two Knowledge Objects.
@immutable
class KnowledgeRelationship {
  final String id;
  final KnowledgeObjectId sourceId;
  final KnowledgeObjectId targetId;
  final RelationshipType type;
  final String? description;
  final double weight;
  final Map<String, dynamic> metadata;

  const KnowledgeRelationship({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.type,
    this.description,
    this.weight = 1.0,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId.toJson(),
        'targetId': targetId.toJson(),
        'type': type.toJson(),
        'description': description,
        'weight': weight,
        'metadata': metadata,
      };

  factory KnowledgeRelationship.fromJson(Map<String, dynamic> json) {
    return KnowledgeRelationship(
      id: json['id'] as String? ?? '',
      sourceId: KnowledgeObjectId.fromJson(json['sourceId'] as String),
      targetId: KnowledgeObjectId.fromJson(json['targetId'] as String),
      type: RelationshipType.fromJson(json['type'] as String),
      description: json['description'] as String?,
      weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeRelationship &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
