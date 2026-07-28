import 'package:meta/meta.dart';

/// Relationship link between concepts, topics, or lessons.
@immutable
class KnowledgeRelationship {
  final String sourceId;
  final String targetId;
  final String relationType;
  final String description;
  final double weight;

  const KnowledgeRelationship({
    required this.sourceId,
    required this.targetId,
    required this.relationType,
    this.description = '',
    this.weight = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'targetId': targetId,
        'relationType': relationType,
        'description': description,
        'weight': weight,
      };

  factory KnowledgeRelationship.fromJson(Map<String, dynamic> json) =>
      KnowledgeRelationship(
        sourceId: json['sourceId'] as String,
        targetId: json['targetId'] as String,
        relationType: json['relationType'] as String,
        description: json['description'] as String? ?? '',
        weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeRelationship &&
          runtimeType == other.runtimeType &&
          sourceId == other.sourceId &&
          targetId == other.targetId &&
          relationType == other.relationType;

  @override
  int get hashCode => Object.hash(sourceId, targetId, relationType);
}
