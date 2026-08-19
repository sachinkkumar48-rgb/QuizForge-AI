/// In-Memory Recommendation Lifecycle Repository (TITAN-KO-022.0 P22).
///
/// Deterministic, offline-first in-memory implementation of
/// [RecommendationLifecycleRepository] with:
/// - Deep defensive copying on all reads and writes (repository isolation).
/// - Deterministic sort order (timestamp ascending, ID lexicographic tie-breaking).
/// - Safe missing-record behavior (null returns, no exceptions on absent records).
/// - Zero external database, network, or persistence dependencies.
library;

import '../domain/entities/recommendation_instance.dart';
import '../domain/entities/recommendation_interaction.dart';
import '../domain/entities/recommendation_lifecycle_state.dart';
import '../domain/entities/recommendation_outcome.dart';
import '../domain/entities/recommendation_session_link.dart';
import 'recommendation_lifecycle_repository.dart';

/// Offline in-memory repository for P22 recommendation lifecycle records.
///
/// All stored entities are deep-copied via JSON round-trip serialization to
/// guarantee full isolation between caller-held references and repository state.
class InMemoryRecommendationLifecycleRepository
    implements RecommendationLifecycleRepository {
  /// Internal store: instanceId → RecommendationInstance
  final Map<String, RecommendationInstance> _instances = {};

  /// Internal store: interactionId → RecommendationInteraction
  final Map<String, RecommendationInteraction> _interactions = {};

  /// Internal store: linkId → RecommendationSessionLink
  final Map<String, RecommendationSessionLink> _links = {};

  /// Internal store: instanceId → RecommendationOutcome (one outcome per instance)
  final Map<String, RecommendationOutcome> _outcomes = {};

  // ---------------------------------------------------------------------------
  // Instance Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveInstance(RecommendationInstance instance) async {
    _instances[instance.instanceId] = _copyInstance(instance);
  }

  @override
  Future<RecommendationInstance?> getInstanceById(String instanceId) async {
    final stored = _instances[instanceId];
    return stored != null ? _copyInstance(stored) : null;
  }

  @override
  Future<RecommendationInstance?> getInstanceByRecommendationId(
    String recommendationId,
  ) async {
    for (final instance in _instances.values) {
      if (instance.recommendationId == recommendationId) {
        return _copyInstance(instance);
      }
    }
    return null;
  }

  @override
  Future<List<RecommendationInstance>> getInstancesForLearner(
    String learnerId, {
    RecommendationLifecycleState? state,
    String? objectiveId,
  }) async {
    final results = _instances.values.where((inst) {
      if (inst.learnerId != learnerId) return false;
      if (state != null && inst.state != state) return false;
      if (objectiveId != null && inst.objectiveId != objectiveId) return false;
      return true;
    }).toList();

    // Deterministic ordering: issuedAt ascending, instanceId lexicographic tie-breaking.
    results.sort((a, b) {
      final timeCmp = a.issuedAt.compareTo(b.issuedAt);
      return timeCmp != 0 ? timeCmp : a.instanceId.compareTo(b.instanceId);
    });

    return results.map(_copyInstance).toList();
  }

  // ---------------------------------------------------------------------------
  // Interaction Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> recordInteraction(
    RecommendationInteraction interaction,
  ) async {
    _interactions[interaction.interactionId] = _copyInteraction(interaction);
  }

  @override
  Future<List<RecommendationInteraction>> getInteractionsForInstance(
    String instanceId,
  ) async {
    final results = _interactions.values
        .where((inter) => inter.instanceId == instanceId)
        .toList();

    // Deterministic ordering: timestamp ascending, interactionId tie-breaking.
    results.sort((a, b) {
      final timeCmp = a.timestamp.compareTo(b.timestamp);
      return timeCmp != 0
          ? timeCmp
          : a.interactionId.compareTo(b.interactionId);
    });

    return results.map(_copyInteraction).toList();
  }

  // ---------------------------------------------------------------------------
  // Session Link Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveSessionLink(RecommendationSessionLink link) async {
    _links[link.linkId] = _copyLink(link);
  }

  @override
  Future<RecommendationSessionLink?> getLinkForSession(
    String sessionId,
  ) async {
    for (final link in _links.values) {
      if (link.sessionId == sessionId) {
        return _copyLink(link);
      }
    }
    return null;
  }

  @override
  Future<List<RecommendationSessionLink>> getLinksForInstance(
    String instanceId,
  ) async {
    final results =
        _links.values.where((link) => link.instanceId == instanceId).toList();

    // Deterministic ordering: linkedAt ascending, linkId tie-breaking.
    results.sort((a, b) {
      final timeCmp = a.linkedAt.compareTo(b.linkedAt);
      return timeCmp != 0 ? timeCmp : a.linkId.compareTo(b.linkId);
    });

    return results.map(_copyLink).toList();
  }

  // ---------------------------------------------------------------------------
  // Outcome Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveOutcome(RecommendationOutcome outcome) async {
    _outcomes[outcome.instanceId] = _copyOutcome(outcome);
  }

  @override
  Future<RecommendationOutcome?> getOutcomeForInstance(
    String instanceId,
  ) async {
    final stored = _outcomes[instanceId];
    return stored != null ? _copyOutcome(stored) : null;
  }

  // ---------------------------------------------------------------------------
  // Clear
  // ---------------------------------------------------------------------------

  @override
  Future<void> clear() async {
    _instances.clear();
    _interactions.clear();
    _links.clear();
    _outcomes.clear();
  }

  // ---------------------------------------------------------------------------
  // Defensive Copy Helpers (JSON round-trip for complete isolation)
  // ---------------------------------------------------------------------------

  /// Deep-copies a [RecommendationInstance] via JSON round-trip.
  static RecommendationInstance _copyInstance(RecommendationInstance inst) =>
      RecommendationInstance.fromJson(inst.toJson());

  /// Deep-copies a [RecommendationInteraction] via JSON round-trip.
  static RecommendationInteraction _copyInteraction(
    RecommendationInteraction inter,
  ) =>
      RecommendationInteraction.fromJson(inter.toJson());

  /// Deep-copies a [RecommendationSessionLink] via JSON round-trip.
  static RecommendationSessionLink _copyLink(
    RecommendationSessionLink link,
  ) =>
      RecommendationSessionLink.fromJson(link.toJson());

  /// Deep-copies a [RecommendationOutcome] via JSON round-trip.
  static RecommendationOutcome _copyOutcome(RecommendationOutcome outcome) =>
      RecommendationOutcome.fromJson(outcome.toJson());
}
