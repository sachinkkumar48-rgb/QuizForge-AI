library;

import 'package:meta/meta.dart';
import 'body_enums.dart';

/// Immutable explicit edge in the GARUDA Government Bodies Knowledge Graph.
@immutable
class BodyRelationship {
  final String sourceId;
  final String targetId;
  final BodyRelationshipType relationshipType;
  final String description;

  const BodyRelationship({
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

  factory BodyRelationship.fromJson(Map<String, dynamic> json) =>
      BodyRelationship(
        sourceId: json['sourceId'] as String? ?? '',
        targetId: json['targetId'] as String? ?? '',
        relationshipType: BodyRelationshipType.values.firstWhere(
          (t) => t.name == json['relationshipType'],
          orElse: () => BodyRelationshipType.relatedTo,
        ),
        description: json['description'] as String? ?? '',
      );
}
