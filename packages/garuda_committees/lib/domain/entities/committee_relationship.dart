library;

import 'package:meta/meta.dart';

/// Relationship link type between Committees and other GARUDA entities.
enum RelationshipType {
  succeededBy,
  precededBy,
  recommendedAct,
  amendedConstitution,
  citedInCase,
  endorsedByNiti,
  linkedToPyq,
  linkedToCurrentAffairs,
}

/// Immutable model representing explicit relationships in the Committee Graph.
@immutable
class CommitteeRelationship {
  final String sourceId;
  final String targetId;
  final RelationshipType relationshipType;
  final String description;

  const CommitteeRelationship({
    required this.sourceId,
    required this.targetId,
    required this.relationshipType,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'targetId': targetId,
        'relationshipType': relationshipType.name,
        'description': description,
      };

  factory CommitteeRelationship.fromJson(Map<String, dynamic> json) => CommitteeRelationship(
        sourceId: json['sourceId'] as String? ?? '',
        targetId: json['targetId'] as String? ?? '',
        relationshipType: RelationshipType.values.firstWhere(
          (t) => t.name == json['relationshipType'],
          orElse: () => RelationshipType.recommendedAct,
        ),
        description: json['description'] as String? ?? '',
      );
}
