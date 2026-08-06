library;

import 'package:meta/meta.dart';
import 'act_enums.dart';

/// Inter-domain Knowledge Graph Relationship link.
@immutable
class ActRelationship {
  final String relationshipId;
  final String sourceId;
  final String sourceType; // e.g. 'Act', 'Section'
  final String targetId;
  final String targetType; // e.g. 'ConstitutionArticle', 'CaseLaw', 'Doctrine', 'PYQ', 'CurrentAffairs'
  final RelationshipType type;
  final String description;
  final double confidenceScore;

  const ActRelationship({
    required this.relationshipId,
    required this.sourceId,
    required this.sourceType,
    required this.targetId,
    required this.targetType,
    required this.type,
    required this.description,
    this.confidenceScore = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'relationshipId': relationshipId,
      'sourceId': sourceId,
      'sourceType': sourceType,
      'targetId': targetId,
      'targetType': targetType,
      'type': type.name,
      'description': description,
      'confidenceScore': confidenceScore,
    };
  }

  factory ActRelationship.fromJson(Map<String, dynamic> json) {
    return ActRelationship(
      relationshipId: json['relationshipId'] as String,
      sourceId: json['sourceId'] as String,
      sourceType: json['sourceType'] as String,
      targetId: json['targetId'] as String,
      targetType: json['targetType'] as String,
      type: RelationshipType.values.byName(json['type'] as String),
      description: json['description'] as String,
      confidenceScore: (json['confidenceScore'] as num? ?? 1.0).toDouble(),
    );
  }
}
