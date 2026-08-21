/// Recommendation Lifecycle Repository Interface (TITAN-KO-022.0 P22).
///
/// Clean Architecture abstract repository contract for persisting and querying
/// P22 recommendation lifecycle records: instances, interactions, session links,
/// and outcomes.
///
/// This interface is independent of any concrete persistence mechanism
/// (in-memory, Hive, SQLite, network). Implementations must provide:
/// - Defensive copying (callers must not mutate repository state)
/// - Deterministic ordering (timestamp ascending, ID lexicographic tie-breaking)
/// - Safe missing-record semantics (null returns for absent records)
library;

import '../domain/entities/recommendation_effectiveness.dart';
import '../domain/entities/recommendation_instance.dart';
import '../domain/entities/recommendation_interaction.dart';
import '../domain/entities/recommendation_lifecycle_state.dart';
import '../domain/entities/recommendation_outcome.dart';
import '../domain/entities/recommendation_session_link.dart';

/// Abstract repository contract for P22 recommendation lifecycle persistence.
abstract interface class RecommendationLifecycleRepository {
  /// Persists a [RecommendationInstance], creating or updating by [instanceId].
  Future<void> saveInstance(RecommendationInstance instance);

  /// Retrieves a [RecommendationInstance] by its unique [instanceId],
  /// or null if no record exists.
  Future<RecommendationInstance?> getInstanceById(String instanceId);

  /// Retrieves a [RecommendationInstance] by its P21 [recommendationId],
  /// or null if no record exists.
  Future<RecommendationInstance?> getInstanceByRecommendationId(
    String recommendationId,
  );

  /// Retrieves all [RecommendationInstance]s for a given [learnerId],
  /// optionally filtered by lifecycle [state] and/or [objectiveId].
  ///
  /// Results are ordered deterministically: [issuedAt] ascending,
  /// [instanceId] lexicographic tie-breaking.
  Future<List<RecommendationInstance>> getInstancesForLearner(
    String learnerId, {
    RecommendationLifecycleState? state,
    String? objectiveId,
  });

  /// Records a [RecommendationInteraction] event.
  Future<void> recordInteraction(RecommendationInteraction interaction);

  /// Retrieves all [RecommendationInteraction]s for a given [instanceId],
  /// ordered by [timestamp] ascending.
  Future<List<RecommendationInteraction>> getInteractionsForInstance(
    String instanceId,
  );

  /// Persists a [RecommendationSessionLink] between an instance and a P19 session.
  Future<void> saveSessionLink(RecommendationSessionLink link);

  /// Retrieves the [RecommendationSessionLink] for a given P19 [sessionId],
  /// or null if no link exists.
  Future<RecommendationSessionLink?> getLinkForSession(String sessionId);

  /// Retrieves all [RecommendationSessionLink]s for a given [instanceId],
  /// ordered by [linkedAt] ascending.
  Future<List<RecommendationSessionLink>> getLinksForInstance(
    String instanceId,
  );

  /// Persists a [RecommendationOutcome] evaluation record.
  Future<void> saveOutcome(RecommendationOutcome outcome);

  /// Retrieves the [RecommendationOutcome] for a given [instanceId],
  /// or null if no outcome has been recorded.
  Future<RecommendationOutcome?> getOutcomeForInstance(String instanceId);

  /// Persists a [RecommendationEffectiveness] evaluation record.
  Future<void> saveEffectiveness(RecommendationEffectiveness effectiveness);

  /// Retrieves the [RecommendationEffectiveness] for a given [instanceId],
  /// or null if no evaluation has been recorded.
  Future<RecommendationEffectiveness?> getEffectivenessForInstance(
    String instanceId,
  );

  /// Retrieves all [RecommendationEffectiveness] records for a given [learnerId],
  /// ordered deterministically by [evaluatedAt] ascending, [instanceId] tie-breaking.
  Future<List<RecommendationEffectiveness>> getEffectivenessForLearner(
    String learnerId,
  );

  /// Clears all persisted lifecycle records (instances, interactions, links, outcomes, effectiveness).
  Future<void> clear();
}
