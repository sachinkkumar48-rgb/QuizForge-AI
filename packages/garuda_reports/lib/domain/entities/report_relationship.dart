library;

import 'package:meta/meta.dart';

/// Relationship link type between Reports, Indices, Surveys and other GARUDA entities.
enum RelationshipType {
  citesReport,
  supersedesEdition,
  feedsIntoIndex,
  derivedFromSurvey,
  linkedToIndicator,
  linkedToRecommendation,
  linkedToChapter,
  linkedToPyq,
  linkedToCurrentAffairs,
  linkedToCommittee,
}

/// Immutable explicit edge in the GARUDA Reports & Indices Knowledge Graph.
@immutable
class ReportRelationship {
  final String sourceId;
  final String targetId;
  final RelationshipType relationshipType;
  final String description;

  const ReportRelationship({
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

  factory ReportRelationship.fromJson(Map<String, dynamic> json) =>
      ReportRelationship(
        sourceId: json['sourceId'] as String? ?? '',
        targetId: json['targetId'] as String? ?? '',
        relationshipType: RelationshipType.values.firstWhere(
          (t) => t.name == json['relationshipType'],
          orElse: () => RelationshipType.citesReport,
        ),
        description: json['description'] as String? ?? '',
      );
}
