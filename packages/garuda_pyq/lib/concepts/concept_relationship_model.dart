import 'package:meta/meta.dart';

enum ConceptRelationshipType {
  prerequisite,
  componentOf,
  overlapsWith,
  triggers,
  generalizes,
}

@immutable
class ConceptRelationship {
  final String id;
  final String sourceConceptId;
  final String targetConceptId;
  final ConceptRelationshipType relationshipType;
  final double strength;

  const ConceptRelationship({
    required this.id,
    required this.sourceConceptId,
    required this.targetConceptId,
    required this.relationshipType,
    this.strength = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceConceptId': sourceConceptId,
        'targetConceptId': targetConceptId,
        'relationshipType': relationshipType.name,
        'strength': strength,
      };

  factory ConceptRelationship.fromJson(Map<String, dynamic> json) =>
      ConceptRelationship(
        id: json['id'] as String,
        sourceConceptId: json['sourceConceptId'] as String,
        targetConceptId: json['targetConceptId'] as String,
        relationshipType: ConceptRelationshipType.values.firstWhere(
          (e) => e.name == json['relationshipType'],
          orElse: () => ConceptRelationshipType.prerequisite,
        ),
        strength: (json['strength'] as num?)?.toDouble() ?? 1.0,
      );
}
