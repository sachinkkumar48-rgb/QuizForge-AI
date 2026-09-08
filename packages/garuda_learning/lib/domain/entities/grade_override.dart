/// Grade Override Domain Entities (TITAN-KO-050.0 P50).
///
/// Production models preserving immutable historical evaluation records,
/// override delta logging, mandatory faculty justification, and dispute linkage.
library;

import 'package:meta/meta.dart';

/// Immutable audit record of a faculty grade override.
@immutable
class GradeOverrideRecord {
  /// Unique canonical override identifier.
  final String overrideId;

  /// Associated gradebook entry identifier.
  final String entryId;

  /// Associated assessment identifier.
  final String assessmentId;

  /// Target learner identifier.
  final String learnerId;

  /// Previous evaluated score before override.
  final double previousScore;

  /// Previous evaluated percentage before override.
  final double previousPercentage;

  /// Previous letter grade before override.
  final String previousGrade;

  /// New overridden official score.
  final double newScore;

  /// New overridden official percentage.
  final double newPercentage;

  /// New overridden letter grade.
  final String newGrade;

  /// Mandatory faculty rationale / explanation.
  final String reason;

  /// Identifier of the faculty member executing the override.
  final String facultyId;

  /// Linked dispute identifier (if override resolved a dispute).
  final String? disputeId;

  /// UTC timestamp of override execution.
  final DateTime overriddenAt;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  GradeOverrideRecord({
    required this.overrideId,
    required this.entryId,
    required this.assessmentId,
    required this.learnerId,
    required this.previousScore,
    required this.previousPercentage,
    required this.previousGrade,
    required this.newScore,
    required this.newPercentage,
    required this.newGrade,
    required this.reason,
    required this.facultyId,
    this.disputeId,
    DateTime? overriddenAt,
    Map<String, dynamic>? metadata,
  })  : overriddenAt = (overriddenAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (overrideId.trim().isEmpty) {
      throw ArgumentError('overrideId cannot be empty');
    }
    if (entryId.trim().isEmpty) {
      throw ArgumentError('entryId cannot be empty');
    }
    if (assessmentId.trim().isEmpty) {
      throw ArgumentError('assessmentId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError('Override reason cannot be empty');
    }
    if (facultyId.trim().isEmpty) {
      throw ArgumentError('facultyId cannot be empty');
    }
  }

  Map<String, dynamic> toJson() => {
        'overrideId': overrideId,
        'entryId': entryId,
        'assessmentId': assessmentId,
        'learnerId': learnerId,
        'previousScore': previousScore,
        'previousPercentage': previousPercentage,
        'previousGrade': previousGrade,
        'newScore': newScore,
        'newPercentage': newPercentage,
        'newGrade': newGrade,
        'reason': reason,
        'facultyId': facultyId,
        if (disputeId != null) 'disputeId': disputeId,
        'overriddenAt': overriddenAt.toIso8601String(),
        'metadata': metadata,
      };

  factory GradeOverrideRecord.fromJson(Map<String, dynamic> json) =>
      GradeOverrideRecord(
        overrideId: json['overrideId'] as String? ?? '',
        entryId: json['entryId'] as String? ?? '',
        assessmentId: json['assessmentId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        previousScore: (json['previousScore'] as num?)?.toDouble() ?? 0.0,
        previousPercentage:
            (json['previousPercentage'] as num?)?.toDouble() ?? 0.0,
        previousGrade: json['previousGrade'] as String? ?? '',
        newScore: (json['newScore'] as num?)?.toDouble() ?? 0.0,
        newPercentage: (json['newPercentage'] as num?)?.toDouble() ?? 0.0,
        newGrade: json['newGrade'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        facultyId: json['facultyId'] as String? ?? '',
        disputeId: json['disputeId'] as String?,
        overriddenAt: json['overriddenAt'] != null
            ? DateTime.parse(json['overriddenAt'] as String).toUtc()
            : null,
        metadata: Map<String, dynamic>.from(
            json['metadata'] as Map? ?? const <String, dynamic>{}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeOverrideRecord &&
          overrideId == other.overrideId &&
          entryId == other.entryId &&
          learnerId == other.learnerId &&
          newScore == other.newScore &&
          facultyId == other.facultyId &&
          overriddenAt == other.overriddenAt;

  @override
  int get hashCode => Object.hash(
        overrideId,
        entryId,
        learnerId,
        newScore,
        facultyId,
        overriddenAt,
      );

  @override
  String toString() =>
      'GradeOverrideRecord(id: $overrideId, learner: $learnerId, $previousGrade ($previousScore) -> $newGrade ($newScore), by: $facultyId)';
}
