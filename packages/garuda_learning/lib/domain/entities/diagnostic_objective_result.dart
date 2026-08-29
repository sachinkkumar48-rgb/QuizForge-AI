/// Diagnostic Objective Result Entity (TITAN-KO-026.0 P26).
///
/// Records the evaluated diagnostic evidence and placement status for a single
/// learning objective.
///
/// Educational Safety Invariants:
/// - Evidence-based metric bounds: observedAccuracy in [0.0, 1.0], never NaN or Infinity.
/// - When attemptsCount == 0, observedAccuracy is strictly null.
/// - Never makes claims about intelligence, capability, or inherent learning rate.
library;

import 'package:meta/meta.dart';

import 'diagnostic_evidence_state.dart';
import 'diagnostic_placement_status.dart';

@immutable
class DiagnosticObjectiveResult {
  final String objectiveId;
  final DiagnosticEvidenceState evidenceState;
  final DiagnosticPlacementStatus placementStatus;
  final int attemptsCount;
  final int correctCount;
  final double? observedAccuracy;
  final DateTime evaluatedAt;
  final String notes;

  DiagnosticObjectiveResult({
    required this.objectiveId,
    required this.evidenceState,
    required this.placementStatus,
    required this.attemptsCount,
    required this.correctCount,
    required this.observedAccuracy,
    required this.evaluatedAt,
    required this.notes,
  })  : assert(objectiveId.trim().isNotEmpty, 'objectiveId cannot be empty'),
        assert(attemptsCount >= 0, 'attemptsCount cannot be negative'),
        assert(correctCount >= 0, 'correctCount cannot be negative'),
        assert(correctCount <= attemptsCount,
            'correctCount cannot exceed attemptsCount'),
        assert(
            attemptsCount == 0
                ? observedAccuracy == null
                : observedAccuracy != null,
            'observedAccuracy must be null if and only if attemptsCount is 0'),
        assert(
            observedAccuracy == null ||
                (!observedAccuracy.isNaN &&
                    !observedAccuracy.isInfinite &&
                    observedAccuracy >= 0.0 &&
                    observedAccuracy <= 1.0),
            'observedAccuracy must be a valid probability in [0.0, 1.0]');

  Map<String, dynamic> toJson() => {
        'objectiveId': objectiveId,
        'evidenceState': evidenceState.toJson(),
        'placementStatus': placementStatus.toJson(),
        'attemptsCount': attemptsCount,
        'correctCount': correctCount,
        'observedAccuracy': observedAccuracy,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'notes': notes,
      };

  factory DiagnosticObjectiveResult.fromJson(Map<String, dynamic> json) =>
      DiagnosticObjectiveResult(
        objectiveId: json['objectiveId'] as String,
        evidenceState:
            DiagnosticEvidenceState.fromJson(json['evidenceState'] as String),
        placementStatus: DiagnosticPlacementStatus.fromJson(
            json['placementStatus'] as String),
        attemptsCount: (json['attemptsCount'] as num).toInt(),
        correctCount: (json['correctCount'] as num).toInt(),
        observedAccuracy: (json['observedAccuracy'] as num?)?.toDouble(),
        evaluatedAt: DateTime.parse(json['evaluatedAt'] as String),
        notes: json['notes'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticObjectiveResult &&
          runtimeType == other.runtimeType &&
          objectiveId == other.objectiveId &&
          evidenceState == other.evidenceState &&
          placementStatus == other.placementStatus &&
          attemptsCount == other.attemptsCount &&
          correctCount == other.correctCount &&
          observedAccuracy == other.observedAccuracy &&
          evaluatedAt.isAtSameMomentAs(other.evaluatedAt);

  @override
  int get hashCode => Object.hash(
        objectiveId,
        evidenceState,
        placementStatus,
        attemptsCount,
        correctCount,
        observedAccuracy,
        evaluatedAt,
      );
}
