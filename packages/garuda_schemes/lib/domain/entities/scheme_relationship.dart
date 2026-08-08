library;

import 'package:meta/meta.dart';
import 'scheme_enums.dart';

/// Immutable explicit edge in the GARUDA Government Schemes Knowledge Graph.
@immutable
class SchemeRelationship {
  final String sourceId;
  final String targetId;
  final SchemeRelationshipType relationshipType;
  final String description;

  const SchemeRelationship({
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

  factory SchemeRelationship.fromJson(Map<String, dynamic> json) =>
      SchemeRelationship(
        sourceId: json['sourceId'] as String? ?? '',
        targetId: json['targetId'] as String? ?? '',
        relationshipType: SchemeRelationshipType.values.firstWhere(
          (t) => t.name == json['relationshipType'],
          orElse: () => SchemeRelationshipType.fundedBy,
        ),
        description: json['description'] as String? ?? '',
      );
}
