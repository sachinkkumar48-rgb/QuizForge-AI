import 'package:meta/meta.dart';
import 'enums.dart';

/// Directed relationship linking one evidence object to another.
@immutable
class EvidenceRelationship {
  final String targetEvidenceId;
  final RelationshipType relationshipType;
  final String description;
  final double confidenceScore;

  const EvidenceRelationship({
    required this.targetEvidenceId,
    required this.relationshipType,
    this.description = '',
    this.confidenceScore = 1.0,
  });

  EvidenceRelationship copyWith({
    String? targetEvidenceId,
    RelationshipType? relationshipType,
    String? description,
    double? confidenceScore,
  }) {
    return EvidenceRelationship(
      targetEvidenceId: targetEvidenceId ?? this.targetEvidenceId,
      relationshipType: relationshipType ?? this.relationshipType,
      description: description ?? this.description,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetEvidenceId': targetEvidenceId,
      'relationshipType': relationshipType.name,
      'description': description,
      'confidenceScore': confidenceScore,
    };
  }

  factory EvidenceRelationship.fromJson(Map<String, dynamic> json) {
    return EvidenceRelationship(
      targetEvidenceId: json['targetEvidenceId'] as String? ?? '',
      relationshipType: RelationshipType.values.firstWhere(
        (e) => e.name == json['relationshipType'],
        orElse: () => RelationshipType.references,
      ),
      description: json['description'] as String? ?? '',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceRelationship &&
        other.targetEvidenceId == targetEvidenceId &&
        other.relationshipType == relationshipType &&
        other.description == description &&
        other.confidenceScore == confidenceScore;
  }

  @override
  int get hashCode => Object.hash(
        targetEvidenceId,
        relationshipType,
        description,
        confidenceScore,
      );

  @override
  String toString() =>
      'EvidenceRelationship(target: $targetEvidenceId, type: $relationshipType)';
}
