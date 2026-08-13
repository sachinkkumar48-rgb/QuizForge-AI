/// Explicit prerequisite relationship model (TITAN-KO-017.0 P17).
///
/// Every prerequisite relationship must be EXPLICITLY declared with a target
/// learning objective ID and explicit source provenance.
///
/// Prerequisites are NEVER inferred from chronology, graph connectivity, legal
/// similarity, doctrine membership, or topic ordering alone.
library;

import 'package:meta/meta.dart';

@immutable
class PrerequisiteRelationship {
  /// Canonical ID of the target prerequisite learning objective.
  final String prerequisiteObjectiveId;

  /// Source justification or evidence for declaring this prerequisite
  /// (e.g. 'syllabus_prerequisite_rule', 'doctrinal_dependency').
  final String provenance;

  /// Whether this prerequisite is mandatory for the learning sequence.
  final bool isMandatory;

  /// Description of why this prerequisite is required.
  final String rationale;

  PrerequisiteRelationship({
    required this.prerequisiteObjectiveId,
    required this.provenance,
    this.isMandatory = true,
    this.rationale = '',
  })  : assert(prerequisiteObjectiveId.trim().isNotEmpty,
            'prerequisiteObjectiveId cannot be empty'),
        assert(provenance.trim().isNotEmpty,
            'prerequisite relationship must carry explicit provenance');

  Map<String, dynamic> toJson() => {
        'prerequisiteObjectiveId': prerequisiteObjectiveId,
        'provenance': provenance,
        'isMandatory': isMandatory,
        if (rationale.isNotEmpty) 'rationale': rationale,
      };

  factory PrerequisiteRelationship.fromJson(Map<String, dynamic> json) =>
      PrerequisiteRelationship(
        prerequisiteObjectiveId:
            json['prerequisiteObjectiveId'] as String? ?? '',
        provenance: json['provenance'] as String? ?? '',
        isMandatory: json['isMandatory'] as bool? ?? true,
        rationale: json['rationale'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrerequisiteRelationship &&
          prerequisiteObjectiveId == other.prerequisiteObjectiveId &&
          provenance == other.provenance &&
          isMandatory == other.isMandatory &&
          rationale == other.rationale;

  @override
  int get hashCode => Object.hash(
        prerequisiteObjectiveId,
        provenance,
        isMandatory,
        rationale,
      );

  @override
  String toString() =>
      'PrerequisiteRelationship($prerequisiteObjectiveId, provenance: $provenance, mandatory: $isMandatory)';
}
