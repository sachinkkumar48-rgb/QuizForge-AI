/// Authoritative Learning State Repository Interface (TITAN-KO-039.0 P39).
///
/// Abstract repository contract for durable, atomic persistence of authoritative
/// learner state with revision and schema protection.
library;

import '../domain/entities/persisted_authoritative_learner_state.dart';

/// Clean Architecture abstract repository contract for authoritative learning state persistence.
abstract interface class AuthoritativeLearningStateRepository {
  /// Loads the persisted state for a specific learner and exam context.
  ///
  /// Returns `null` if no state has been persisted yet.
  /// Throws [AuthoritativePersistenceException] if the persisted state is corrupted,
  /// carries an unsupported schema, or encounters an IO failure.
  Future<PersistedAuthoritativeLearnerState?> load({
    required String learnerId,
    required String examId,
  });

  /// Atomically persists [state] with monotonic revision protection.
  ///
  /// Semantics:
  /// - `existing.revision < incoming.revision`: Accepts and atomically writes incoming state.
  /// - `existing.revision == incoming.revision`: Idempotent no-op if identical payload.
  /// - `existing.revision > incoming.revision`: Rejects stale write by throwing
  ///   [AuthoritativePersistenceException] with [AuthoritativePersistenceErrorCode.staleWrite].
  ///
  /// Atomic guarantee:
  /// If serialization or storage fails, the previous persisted state is left completely intact.
  Future<void> save(PersistedAuthoritativeLearnerState state);

  /// Deletes persisted state for a specific learner and exam context.
  Future<void> delete({
    required String learnerId,
    required String examId,
  });

  /// Checks if persisted state exists for a given learner and exam context.
  Future<bool> exists({
    required String learnerId,
    required String examId,
  });

  /// Clears all persisted states across all learners (used for test isolation).
  Future<void> clear();
}
