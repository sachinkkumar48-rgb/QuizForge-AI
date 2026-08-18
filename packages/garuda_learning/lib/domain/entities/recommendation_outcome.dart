/// Recommendation Outcome Entity (TITAN-KO-022.0 P22).
///
/// Immutable domain model capturing the observed execution outcome of a
/// recommendation-linked practice session.
///
/// Educational Safety Principles:
/// - Represents strictly observed execution metrics (questions attempted, completion rate, accuracy).
/// - Does NOT make causal claims of mastery or learning improvement.
/// - Safely handles zero-attempt and unattempted scenarios with explicit `insufficientEvidence` representation.
library;

import 'package:meta/meta.dart';

@immutable
class RecommendationOutcome {
  /// Unique identifier for this outcome evaluation record.
  final String outcomeId;

  /// Target [RecommendationInstance.instanceId] evaluated.
  final String instanceId;

  /// Target P19 [LearningSession.sessionId] evaluated.
  final String sessionId;

  /// Total number of questions scheduled in the practice session.
  final int totalQuestionsScheduled;

  /// Total number of questions actually attempted by the learner.
  final int totalQuestionsAttempted;

  /// Fraction of scheduled questions attempted ([0.0, 1.0]).
  final double completionRate;

  /// Observed session accuracy across attempted questions ([0.0, 1.0]), or null if zero attempts.
  final double? sessionAccuracy;

  /// Whether the linked practice session reached completed state.
  final bool isCompleted;

  /// Whether the sample size / attempts are insufficient to evaluate accuracy reliably.
  final bool insufficientEvidence;

  /// UTC timestamp when this outcome was evaluated.
  final DateTime evaluatedAt;

  /// Immutable diagnostic metadata.
  final Map<String, dynamic> metadata;

  RecommendationOutcome({
    required this.outcomeId,
    required this.instanceId,
    required this.sessionId,
    required this.totalQuestionsScheduled,
    required this.totalQuestionsAttempted,
    double? completionRate,
    double? sessionAccuracy,
    required this.isCompleted,
    bool? insufficientEvidence,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  })  : completionRate = completionRate != null
            ? completionRate.clamp(0.0, 1.0)
            : (totalQuestionsScheduled > 0
                ? (totalQuestionsAttempted / totalQuestionsScheduled)
                    .clamp(0.0, 1.0)
                : 0.0),
        sessionAccuracy = sessionAccuracy?.clamp(0.0, 1.0),
        insufficientEvidence =
            insufficientEvidence ?? (totalQuestionsAttempted == 0),
        evaluatedAt = evaluatedAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (outcomeId.trim().isEmpty) {
      throw ArgumentError('outcomeId cannot be empty');
    }
    if (instanceId.trim().isEmpty) {
      throw ArgumentError('instanceId cannot be empty');
    }
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('sessionId cannot be empty');
    }
    if (totalQuestionsScheduled < 0) {
      throw ArgumentError('totalQuestionsScheduled cannot be negative');
    }
    if (totalQuestionsAttempted < 0) {
      throw ArgumentError('totalQuestionsAttempted cannot be negative');
    }
  }

  Map<String, dynamic> toJson() => {
        'outcomeId': outcomeId,
        'instanceId': instanceId,
        'sessionId': sessionId,
        'totalQuestionsScheduled': totalQuestionsScheduled,
        'totalQuestionsAttempted': totalQuestionsAttempted,
        'completionRate': completionRate,
        if (sessionAccuracy != null) 'sessionAccuracy': sessionAccuracy,
        'isCompleted': isCompleted,
        'insufficientEvidence': insufficientEvidence,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory RecommendationOutcome.fromJson(Map<String, dynamic> json) =>
      RecommendationOutcome(
        outcomeId: json['outcomeId'] as String? ?? '',
        instanceId: json['instanceId'] as String? ?? '',
        sessionId: json['sessionId'] as String? ?? '',
        totalQuestionsScheduled:
            (json['totalQuestionsScheduled'] as num?)?.toInt() ?? 0,
        totalQuestionsAttempted:
            (json['totalQuestionsAttempted'] as num?)?.toInt() ?? 0,
        completionRate: (json['completionRate'] as num?)?.toDouble(),
        sessionAccuracy: (json['sessionAccuracy'] as num?)?.toDouble(),
        isCompleted: json['isCompleted'] as bool? ?? false,
        insufficientEvidence: json['insufficientEvidence'] as bool?,
        evaluatedAt: DateTime.parse(json['evaluatedAt'] as String).toUtc(),
        metadata:
            Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationOutcome &&
          outcomeId == other.outcomeId &&
          instanceId == other.instanceId &&
          sessionId == other.sessionId &&
          totalQuestionsScheduled == other.totalQuestionsScheduled &&
          totalQuestionsAttempted == other.totalQuestionsAttempted &&
          (completionRate - other.completionRate).abs() < 0.0001 &&
          ((sessionAccuracy == null && other.sessionAccuracy == null) ||
              (sessionAccuracy != null &&
                  other.sessionAccuracy != null &&
                  (sessionAccuracy! - other.sessionAccuracy!).abs() <
                      0.0001)) &&
          isCompleted == other.isCompleted &&
          insufficientEvidence == other.insufficientEvidence &&
          evaluatedAt == other.evaluatedAt;

  @override
  int get hashCode => Object.hash(
        outcomeId,
        instanceId,
        sessionId,
        totalQuestionsScheduled,
        totalQuestionsAttempted,
        completionRate,
        sessionAccuracy,
        isCompleted,
        insufficientEvidence,
        evaluatedAt,
      );

  @override
  String toString() =>
      'RecommendationOutcome($outcomeId, instance: $instanceId, session: $sessionId, completion: ${(completionRate * 100).toStringAsFixed(1)}%, completed: $isCompleted)';
}
