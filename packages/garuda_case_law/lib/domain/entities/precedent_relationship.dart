library;

import 'package:meta/meta.dart';
import 'case_enums.dart';

/// Evidence-backed relationship between two cases. A relationship is only
/// recorded where the source judgment (or the ratio it establishes) supports
/// it — never inferred merely to increase graph density.
@immutable
class PrecedentRelationship {
  /// ID of the case that cites / treats the target.
  final String sourceCaseId;

  /// ID of the case that is being cited, followed, overruled, etc.
  final String targetCaseId;

  /// Nature of the relationship.
  final PrecedentRelationshipType type;

  /// Optional justification / where in the judgment this is established.
  final String? note;

  const PrecedentRelationship({
    required this.sourceCaseId,
    required this.targetCaseId,
    required this.type,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'sourceCaseId': sourceCaseId,
        'targetCaseId': targetCaseId,
        'type': type.name,
        if (note != null) 'note': note,
      };

  factory PrecedentRelationship.fromJson(Map<String, dynamic> json) =>
      PrecedentRelationship(
        sourceCaseId: json['sourceCaseId'] as String? ?? '',
        targetCaseId: json['targetCaseId'] as String? ?? '',
        type: PrecedentRelationshipType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => PrecedentRelationshipType.applied,
        ),
        note: json['note'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrecedentRelationship &&
          sourceCaseId == other.sourceCaseId &&
          targetCaseId == other.targetCaseId &&
          type == other.type;

  @override
  int get hashCode => Object.hash(sourceCaseId, targetCaseId, type);
}
