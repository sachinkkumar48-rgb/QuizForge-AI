/// Diagnostic Placement Result Entity (TITAN-KO-026.0 P26).
///
/// Encapsulates the complete, deterministic diagnostic placement evaluation
/// for a learner across curriculum objectives.
///
/// Educational Safety Invariants:
/// - Evidence-based metric bounds: aggregateAccuracy in [0.0, 1.0], never NaN or Infinity.
/// - When totalAttemptsCount == 0, aggregateAccuracy is strictly null.
/// - Never makes claims about intelligence, capability, or inherent learning rate.
library;

import 'package:meta/meta.dart';

import 'diagnostic_objective_result.dart';
import 'diagnostic_placement_frontier.dart';

@immutable
class DiagnosticPlacementResult {
  final String assessmentId;
  final String learnerId;
  final DateTime evaluatedAt;
  final Map<String, DiagnosticObjectiveResult> objectiveResults;
  final DiagnosticPlacementFrontier frontier;
  final int totalAssessedObjectives;
  final int demonstratedObjectivesCount;
  final int totalAttemptsCount;
  final int totalCorrectCount;
  final double? aggregateAccuracy;
  final String provenance;

  DiagnosticPlacementResult({
    required this.assessmentId,
    required this.learnerId,
    required this.evaluatedAt,
    required Map<String, DiagnosticObjectiveResult> objectiveResults,
    required this.frontier,
    required this.totalAssessedObjectives,
    required this.demonstratedObjectivesCount,
    required this.totalAttemptsCount,
    required this.totalCorrectCount,
    required this.aggregateAccuracy,
    required this.provenance,
  })  : assert(assessmentId.trim().isNotEmpty, 'assessmentId cannot be empty'),
        assert(learnerId.trim().isNotEmpty, 'learnerId cannot be empty'),
        assert(totalAssessedObjectives >= 0,
            'totalAssessedObjectives cannot be negative'),
        assert(demonstratedObjectivesCount >= 0,
            'demonstratedObjectivesCount cannot be negative'),
        assert(demonstratedObjectivesCount <= totalAssessedObjectives,
            'demonstratedObjectivesCount cannot exceed totalAssessedObjectives'),
        assert(
            totalAttemptsCount >= 0, 'totalAttemptsCount cannot be negative'),
        assert(totalCorrectCount >= 0, 'totalCorrectCount cannot be negative'),
        assert(totalCorrectCount <= totalAttemptsCount,
            'totalCorrectCount cannot exceed totalAttemptsCount'),
        assert(
            totalAttemptsCount == 0
                ? aggregateAccuracy == null
                : aggregateAccuracy != null,
            'aggregateAccuracy must be null if and only if totalAttemptsCount is 0'),
        assert(
            aggregateAccuracy == null ||
                (!aggregateAccuracy.isNaN &&
                    !aggregateAccuracy.isInfinite &&
                    aggregateAccuracy >= 0.0 &&
                    aggregateAccuracy <= 1.0),
            'aggregateAccuracy must be a valid probability in [0.0, 1.0]'),
        assert(provenance.trim().isNotEmpty, 'provenance cannot be empty'),
        objectiveResults = Map.unmodifiable(objectiveResults);

  Map<String, dynamic> toJson() => {
        'assessmentId': assessmentId,
        'learnerId': learnerId,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'objectiveResults':
            objectiveResults.map((k, v) => MapEntry(k, v.toJson())),
        'frontier': frontier.toJson(),
        'totalAssessedObjectives': totalAssessedObjectives,
        'demonstratedObjectivesCount': demonstratedObjectivesCount,
        'totalAttemptsCount': totalAttemptsCount,
        'totalCorrectCount': totalCorrectCount,
        'aggregateAccuracy': aggregateAccuracy,
        'provenance': provenance,
      };

  factory DiagnosticPlacementResult.fromJson(Map<String, dynamic> json) {
    final rawObjs = json['objectiveResults'] as Map<String, dynamic>? ?? {};
    final mappedObjs = rawObjs.map((k, v) => MapEntry(
        k, DiagnosticObjectiveResult.fromJson(v as Map<String, dynamic>)));

    return DiagnosticPlacementResult(
      assessmentId: json['assessmentId'] as String,
      learnerId: json['learnerId'] as String,
      evaluatedAt: DateTime.parse(json['evaluatedAt'] as String),
      objectiveResults: mappedObjs,
      frontier: DiagnosticPlacementFrontier.fromJson(
          json['frontier'] as Map<String, dynamic>),
      totalAssessedObjectives: (json['totalAssessedObjectives'] as num).toInt(),
      demonstratedObjectivesCount:
          (json['demonstratedObjectivesCount'] as num).toInt(),
      totalAttemptsCount: (json['totalAttemptsCount'] as num).toInt(),
      totalCorrectCount: (json['totalCorrectCount'] as num).toInt(),
      aggregateAccuracy: (json['aggregateAccuracy'] as num?)?.toDouble(),
      provenance: json['provenance'] as String,
    );
  }
}
