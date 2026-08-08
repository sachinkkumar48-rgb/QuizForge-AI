library;

import 'package:meta/meta.dart';
import 'international_enums.dart';

/// Immutable explicit edge in the GARUDA International Knowledge Graph.
@immutable
class InternationalRelationship {
  final String sourceId;
  final String targetId;
  final InternationalRelationshipType relationshipType;
  final String description;

  const InternationalRelationship({
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

  factory InternationalRelationship.fromJson(Map<String, dynamic> json) =>
      InternationalRelationship(
        sourceId: json['sourceId'] as String? ?? '',
        targetId: json['targetId'] as String? ?? '',
        relationshipType: InternationalRelationshipType.values.firstWhere(
          (t) => t.name == json['relationshipType'],
          orElse: () => InternationalRelationshipType.relatedTo,
        ),
        description: json['description'] as String? ?? '',
      );
}
