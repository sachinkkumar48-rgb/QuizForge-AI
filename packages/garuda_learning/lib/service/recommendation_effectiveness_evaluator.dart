/// Recommendation Effectiveness Evaluator (TITAN-KO-022.0 P22).
///
/// Deterministic, stateless evaluation engine that compares issuance-time
/// baseline evidence snapshots against post-recommendation execution outcomes.
///
/// Educational Safety Principles:
/// - Evaluates strictly observed performance differences, never causal mastery claims.
/// - Returns `insufficientEvidence: true` when baseline is missing, outcome is absent,
///   or attempt counts are zero.
/// - Never fabricates numerical accuracy or delta values from missing data.
/// - Pure evaluation without database access, network calls, or `DateTime.now()`.
library;

import '../domain/entities/recommendation_effectiveness.dart';
import '../domain/entities/recommendation_evidence_snapshot.dart';
import '../domain/entities/recommendation_instance.dart';
import '../domain/entities/recommendation_outcome.dart';

/// Stateless evaluator for computing observed recommendation effectiveness.
class RecommendationEffectivenessEvaluator {
  const RecommendationEffectivenessEvaluator();

  /// Evaluates the observed effectiveness of a [RecommendationInstance].
  ///
  /// Parameters:
  /// - [instance]: The target recommendation instance.
  /// - [outcome]: The observed execution outcome of the linked practice session, or null if unexecuted.
  /// - [evidenceSnapshot]: The issuance-time audit snapshot containing baseline accuracy, or null.
  /// - [asOf]: Explicit UTC evaluation timestamp for strict determinism.
  /// - [measurementWindow]: Duration window for evaluation (defaults to 7 days).
  /// - [metadata]: Optional extra diagnostic metadata to merge.
  RecommendationEffectiveness evaluate({
    required RecommendationInstance instance,
    RecommendationOutcome? outcome,
    RecommendationEvidenceSnapshot? evidenceSnapshot,
    required DateTime asOf,
    Duration measurementWindow = const Duration(days: 7),
    Map<String, dynamic>? metadata,
  }) {
    // 1. Extract baseline evidence
    final double? baselineAccuracy = evidenceSnapshot?.baselineAccuracy;
    final int baselineAttemptsCount =
        evidenceSnapshot?.baselineAttemptsCount ?? 0;

    // 2. Extract follow-up outcome evidence
    final double? followUpAccuracy = outcome?.sessionAccuracy;
    final int followUpAttemptsCount = outcome?.totalQuestionsAttempted ?? 0;

    // 3. Determine evidence sufficiency
    // Evidence is insufficient if:
    // - Outcome is missing
    // - Baseline accuracy is unavailable / null
    // - Follow-up accuracy is unavailable / null
    // - Baseline attempt count is 0
    // - Follow-up attempt count is 0
    final bool insufficientEvidence = outcome == null ||
        baselineAccuracy == null ||
        followUpAccuracy == null ||
        baselineAttemptsCount == 0 ||
        followUpAttemptsCount == 0 ||
        (outcome.insufficientEvidence);

    // 4. Calculate observed performance delta (only when evidence is sufficient)
    final double? observedDelta =
        !insufficientEvidence ? (followUpAccuracy - baselineAccuracy) : null;

    final mergedMetadata = <String, dynamic>{
      'recommendationType': instance.recommendationType.name,
      'instanceState': instance.state.name,
      if (outcome != null) 'outcomeCompleted': outcome.isCompleted,
      if (outcome != null) 'completionRate': outcome.completionRate,
      ...?metadata,
    };

    return RecommendationEffectiveness(
      instanceId: instance.instanceId,
      objectiveId: instance.objectiveId,
      learnerId: instance.learnerId,
      baselineAccuracy: baselineAccuracy,
      baselineAttemptsCount: baselineAttemptsCount,
      followUpAccuracy: followUpAccuracy,
      followUpAttemptsCount: followUpAttemptsCount,
      observedPerformanceDelta: observedDelta,
      insufficientEvidence: insufficientEvidence,
      measurementWindow: measurementWindow,
      evaluatedAt: asOf.toUtc(),
      metadata: mergedMetadata,
    );
  }
}
