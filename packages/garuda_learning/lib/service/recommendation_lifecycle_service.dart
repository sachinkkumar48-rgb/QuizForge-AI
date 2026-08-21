/// Recommendation Lifecycle Service (TITAN-KO-022.0 P22).
///
/// Application service managing the end-to-end lifecycle of [RecommendationInstance]s:
/// - Ingestion and persistence of P21 recommendations.
/// - Learner interaction telemetry recording.
/// - Decoupled P19 [LearningSession] link management.
/// - Post-session execution outcome recording.
/// - Deterministic effectiveness evaluation.
///
/// Architecture Rules:
/// - Depends on [RecommendationLifecycleRepository] abstraction (no direct database coupling).
/// - Stateless evaluation delegated to [RecommendationEffectivenessEvaluator].
/// - Strict time determinism via caller-supplied [DateTime] parameters.
/// - Zero network, database, or LLM dependencies.
library;

import '../domain/entities/dismissal_reason.dart';
import '../domain/entities/learning_recommendation.dart';
import '../domain/entities/recommendation_effectiveness.dart';
import '../domain/entities/recommendation_evidence_snapshot.dart';
import '../domain/entities/recommendation_instance.dart';
import '../domain/entities/recommendation_interaction.dart';
import '../domain/entities/recommendation_lifecycle_state.dart';
import '../domain/entities/recommendation_outcome.dart';
import '../domain/entities/recommendation_session_link.dart';
import '../repository/recommendation_lifecycle_repository.dart';
import 'recommendation_effectiveness_evaluator.dart';

/// Service orchestrating P22 recommendation lifecycle persistence and evaluation.
class RecommendationLifecycleService {
  final RecommendationLifecycleRepository _repository;
  final RecommendationEffectivenessEvaluator _evaluator;

  const RecommendationLifecycleService({
    required RecommendationLifecycleRepository repository,
    RecommendationEffectivenessEvaluator evaluator =
        const RecommendationEffectivenessEvaluator(),
  })  : _repository = repository,
        _evaluator = evaluator;

  // ---------------------------------------------------------------------------
  // Recommendation Issuance
  // ---------------------------------------------------------------------------

  /// Persists a new [RecommendationInstance] originating from a P21 [LearningRecommendation].
  Future<RecommendationInstance> issueRecommendation(
    LearningRecommendation recommendation, {
    required String instanceId,
    required DateTime issuedAt,
    Duration validityDuration = RecommendationInstance.defaultValidityDuration,
    RecommendationEvidenceSnapshot? evidenceSnapshot,
    Map<String, dynamic>? metadata,
  }) async {
    final mergedMetadata = <String, dynamic>{
      if (evidenceSnapshot != null)
        'evidenceSnapshot': evidenceSnapshot.toJson(),
      ...?metadata,
    };

    final instance = RecommendationInstance.fromRecommendation(
      recommendation,
      instanceId: instanceId,
      issuedAt: issuedAt,
      validityDuration: validityDuration,
      metadata: mergedMetadata,
    );

    await _repository.saveInstance(instance);
    return instance;
  }

  // ---------------------------------------------------------------------------
  // Learner Interaction Logging
  // ---------------------------------------------------------------------------

  /// Records a learner interaction telemetry event and updates the instance state.
  Future<RecommendationInstance> recordInteraction({
    required String interactionId,
    required String instanceId,
    required RecommendationLifecycleState targetState,
    DismissalReason? dismissalReason,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) async {
    final instance = await _repository.getInstanceById(instanceId);
    if (instance == null) {
      throw ArgumentError(
        'RecommendationInstance with id $instanceId not found',
      );
    }

    final interaction = RecommendationInteraction(
      interactionId: interactionId,
      instanceId: instanceId,
      targetState: targetState,
      dismissalReason: dismissalReason,
      timestamp: timestamp,
      metadata: metadata,
    );

    await _repository.recordInteraction(interaction);

    final updatedInstance = instance.transitionTo(
      targetState,
      asOf: timestamp,
      dismissalReason: dismissalReason,
      metadata: metadata,
    );

    await _repository.saveInstance(updatedInstance);
    return updatedInstance;
  }

  /// Convenience method to record a `viewed` interaction.
  Future<RecommendationInstance> markViewed({
    required String interactionId,
    required String instanceId,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) =>
      recordInteraction(
        interactionId: interactionId,
        instanceId: instanceId,
        targetState: RecommendationLifecycleState.viewed,
        timestamp: timestamp,
        metadata: metadata,
      );

  /// Convenience method to record an `accepted` interaction.
  Future<RecommendationInstance> acceptRecommendation({
    required String interactionId,
    required String instanceId,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) =>
      recordInteraction(
        interactionId: interactionId,
        instanceId: instanceId,
        targetState: RecommendationLifecycleState.accepted,
        timestamp: timestamp,
        metadata: metadata,
      );

  /// Convenience method to record a `dismissed` interaction.
  Future<RecommendationInstance> dismissRecommendation({
    required String interactionId,
    required String instanceId,
    required DismissalReason reason,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) =>
      recordInteraction(
        interactionId: interactionId,
        instanceId: instanceId,
        targetState: RecommendationLifecycleState.dismissed,
        dismissalReason: reason,
        timestamp: timestamp,
        metadata: metadata,
      );

  /// Convenience method to record a `deferred` interaction.
  Future<RecommendationInstance> deferRecommendation({
    required String interactionId,
    required String instanceId,
    required DateTime timestamp,
    Map<String, dynamic>? metadata,
  }) =>
      recordInteraction(
        interactionId: interactionId,
        instanceId: instanceId,
        targetState: RecommendationLifecycleState.deferred,
        timestamp: timestamp,
        metadata: metadata,
      );

  // ---------------------------------------------------------------------------
  // Session Provenance Linking
  // ---------------------------------------------------------------------------

  /// Links a recommendation instance to an executed P19 [LearningSession].
  ///
  /// Automatically transitions the instance state to `started` if in `accepted` or `issued` state.
  Future<RecommendationSessionLink> linkSession({
    required String linkId,
    required String instanceId,
    required String sessionId,
    required DateTime linkedAt,
    Map<String, dynamic>? metadata,
  }) async {
    final instance = await _repository.getInstanceById(instanceId);
    if (instance == null) {
      throw ArgumentError(
        'RecommendationInstance with id $instanceId not found',
      );
    }

    final link = RecommendationSessionLink(
      linkId: linkId,
      instanceId: instanceId,
      sessionId: sessionId,
      linkedAt: linkedAt,
      metadata: metadata,
    );

    await _repository.saveSessionLink(link);

    if (instance.state.canTransitionTo(RecommendationLifecycleState.started)) {
      final updatedInstance = instance.transitionTo(
        RecommendationLifecycleState.started,
        asOf: linkedAt,
        metadata: metadata,
      );
      await _repository.saveInstance(updatedInstance);
    }

    return link;
  }

  // ---------------------------------------------------------------------------
  // Practice Session Outcome Recording
  // ---------------------------------------------------------------------------

  /// Records an execution outcome for a recommendation-linked session and updates instance state.
  Future<RecommendationOutcome> recordOutcome({
    required String outcomeId,
    required String instanceId,
    required String sessionId,
    required int totalQuestionsScheduled,
    required int totalQuestionsAttempted,
    double? sessionAccuracy,
    required bool isCompleted,
    bool? insufficientEvidence,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) async {
    final instance = await _repository.getInstanceById(instanceId);
    if (instance == null) {
      throw ArgumentError(
        'RecommendationInstance with id $instanceId not found',
      );
    }

    final outcome = RecommendationOutcome(
      outcomeId: outcomeId,
      instanceId: instanceId,
      sessionId: sessionId,
      totalQuestionsScheduled: totalQuestionsScheduled,
      totalQuestionsAttempted: totalQuestionsAttempted,
      sessionAccuracy: sessionAccuracy,
      isCompleted: isCompleted,
      insufficientEvidence: insufficientEvidence,
      evaluatedAt: evaluatedAt,
      metadata: metadata,
    );

    await _repository.saveOutcome(outcome);

    final targetState = isCompleted
        ? RecommendationLifecycleState.completed
        : RecommendationLifecycleState.abandoned;

    if (instance.state.canTransitionTo(targetState)) {
      final updatedInstance = instance.transitionTo(
        targetState,
        asOf: evaluatedAt,
        metadata: metadata,
      );
      await _repository.saveInstance(updatedInstance);
    }

    return outcome;
  }

  // ---------------------------------------------------------------------------
  // Effectiveness Evaluation
  // ---------------------------------------------------------------------------

  /// Evaluates the observed post-recommendation effectiveness for a target instance.
  Future<RecommendationEffectiveness> evaluateEffectiveness(
    String instanceId, {
    required DateTime asOf,
    Duration measurementWindow = const Duration(days: 7),
    RecommendationEvidenceSnapshot? evidenceSnapshot,
    Map<String, dynamic>? metadata,
  }) async {
    final instance = await _repository.getInstanceById(instanceId);
    if (instance == null) {
      throw ArgumentError(
        'RecommendationInstance with id $instanceId not found',
      );
    }

    final outcome = await _repository.getOutcomeForInstance(instanceId);

    RecommendationEvidenceSnapshot? snapshot = evidenceSnapshot;
    if (snapshot == null &&
        instance.metadata.containsKey('evidenceSnapshot') &&
        instance.metadata['evidenceSnapshot'] is Map<String, dynamic>) {
      snapshot = RecommendationEvidenceSnapshot.fromJson(
        instance.metadata['evidenceSnapshot'] as Map<String, dynamic>,
      );
    }

    final evaluation = _evaluator.evaluate(
      instance: instance,
      outcome: outcome,
      evidenceSnapshot: snapshot,
      asOf: asOf,
      measurementWindow: measurementWindow,
      metadata: metadata,
    );

    await _repository.saveEffectiveness(evaluation);
    return evaluation;
  }

  // ---------------------------------------------------------------------------
  // Query Helpers
  // ---------------------------------------------------------------------------

  /// Retrieves a recommendation instance by [instanceId].
  Future<RecommendationInstance?> getInstance(String instanceId) =>
      _repository.getInstanceById(instanceId);

  /// Retrieves all active (non-terminal, non-expired) recommendations for [learnerId].
  Future<List<RecommendationInstance>> getActiveRecommendationsForLearner(
    String learnerId, {
    required DateTime asOf,
    String? objectiveId,
  }) async {
    final instances = await _repository.getInstancesForLearner(
      learnerId,
      objectiveId: objectiveId,
    );

    return instances.where((inst) {
      if (inst.state.isTerminal) return false;
      if (inst.isExpired(asOf: asOf)) return false;
      return true;
    }).toList();
  }

  /// Retrieves all interactions recorded for [instanceId].
  Future<List<RecommendationInteraction>> getInteractions(
    String instanceId,
  ) =>
      _repository.getInteractionsForInstance(instanceId);

  /// Retrieves all session links for [instanceId].
  Future<List<RecommendationSessionLink>> getLinks(String instanceId) =>
      _repository.getLinksForInstance(instanceId);

  /// Retrieves the recorded outcome for [instanceId], or null.
  Future<RecommendationOutcome?> getOutcome(String instanceId) =>
      _repository.getOutcomeForInstance(instanceId);

  /// Retrieves the recorded effectiveness evaluation for [instanceId], or null.
  Future<RecommendationEffectiveness?> getEffectiveness(String instanceId) =>
      _repository.getEffectivenessForInstance(instanceId);

  /// Retrieves all effectiveness evaluations recorded for [learnerId].
  Future<List<RecommendationEffectiveness>> getEffectivenessForLearner(
    String learnerId,
  ) =>
      _repository.getEffectivenessForLearner(learnerId);
}
