/// Authoritative Recovery Result Domain Entity (TITAN-KO-039.0 P39).
///
/// Encapsulates the deterministic outcome of loading, validating, and recovering
/// authoritative learner state from persistence.
library;

import 'package:meta/meta.dart';

import 'authoritative_learner_state.dart';
import 'authoritative_persistence_error.dart';
import 'persisted_authoritative_learner_state.dart';

/// Discrete outcome decisions for authoritative state recovery.
enum AuthoritativeRecoveryDecision {
  /// Existing valid state successfully restored without migration.
  restored,

  /// No prior persisted state existed; an initial clean state was created.
  initialized,

  /// An older supported schema was detected, migrated, and persisted.
  migrated,

  /// Persisted state was corrupted or structurally invalid.
  corrupted,

  /// Persisted state carries an unsupported or incompatible schema version.
  incompatibleSchema,

  /// Unhandled repository or IO error.
  failed;

  String get serialName => name;

  bool get isSuccess =>
      this == AuthoritativeRecoveryDecision.restored ||
      this == AuthoritativeRecoveryDecision.initialized ||
      this == AuthoritativeRecoveryDecision.migrated;
}

/// Immutable result of a recovery operation.
@immutable
class AuthoritativeRecoveryResult {
  final AuthoritativeRecoveryDecision decision;
  final String learnerId;
  final String examId;
  final AuthoritativeLearnerState? state;
  final PersistedAuthoritativeLearnerState? persistedState;
  final int? revision;
  final int? schemaVersion;
  final AuthoritativePersistenceException? error;
  final DateTime recoveredAt;

  const AuthoritativeRecoveryResult({
    required this.decision,
    required this.learnerId,
    required this.examId,
    this.state,
    this.persistedState,
    this.revision,
    this.schemaVersion,
    this.error,
    required this.recoveredAt,
  });

  /// Factory for restored state (Case B).
  factory AuthoritativeRecoveryResult.restored({
    required PersistedAuthoritativeLearnerState persistedState,
    required DateTime recoveredAt,
  }) {
    return AuthoritativeRecoveryResult(
      decision: AuthoritativeRecoveryDecision.restored,
      learnerId: persistedState.learnerId,
      examId: persistedState.examId,
      state: persistedState.toAuthoritativeState(),
      persistedState: persistedState,
      revision: persistedState.revision,
      schemaVersion: persistedState.schemaVersion,
      recoveredAt: recoveredAt.toUtc(),
    );
  }

  /// Factory for clean initial state on first launch (Case A).
  factory AuthoritativeRecoveryResult.initialized({
    required AuthoritativeLearnerState state,
    required DateTime recoveredAt,
  }) {
    return AuthoritativeRecoveryResult(
      decision: AuthoritativeRecoveryDecision.initialized,
      learnerId: state.learnerId,
      examId: state.examId,
      state: state,
      revision: state.revision,
      schemaVersion: PersistedAuthoritativeLearnerState.currentSchemaVersion,
      recoveredAt: recoveredAt.toUtc(),
    );
  }

  /// Factory for migrated state (Case E).
  factory AuthoritativeRecoveryResult.migrated({
    required PersistedAuthoritativeLearnerState migratedState,
    required DateTime recoveredAt,
  }) {
    return AuthoritativeRecoveryResult(
      decision: AuthoritativeRecoveryDecision.migrated,
      learnerId: migratedState.learnerId,
      examId: migratedState.examId,
      state: migratedState.toAuthoritativeState(),
      persistedState: migratedState,
      revision: migratedState.revision,
      schemaVersion: migratedState.schemaVersion,
      recoveredAt: recoveredAt.toUtc(),
    );
  }

  /// Factory for corruption detection (Case C).
  factory AuthoritativeRecoveryResult.corrupted({
    required String learnerId,
    required String examId,
    required AuthoritativePersistenceException error,
    required DateTime recoveredAt,
    int? revision,
    int? schemaVersion,
  }) {
    return AuthoritativeRecoveryResult(
      decision: AuthoritativeRecoveryDecision.corrupted,
      learnerId: learnerId,
      examId: examId,
      error: error,
      revision: revision,
      schemaVersion: schemaVersion,
      recoveredAt: recoveredAt.toUtc(),
    );
  }

  /// Factory for incompatible schema version (Case D).
  factory AuthoritativeRecoveryResult.incompatibleSchema({
    required String learnerId,
    required String examId,
    required AuthoritativePersistenceException error,
    required DateTime recoveredAt,
    int? schemaVersion,
  }) {
    return AuthoritativeRecoveryResult(
      decision: AuthoritativeRecoveryDecision.incompatibleSchema,
      learnerId: learnerId,
      examId: examId,
      error: error,
      schemaVersion: schemaVersion,
      recoveredAt: recoveredAt.toUtc(),
    );
  }

  /// Factory for unexpected failure.
  factory AuthoritativeRecoveryResult.failed({
    required String learnerId,
    required String examId,
    required AuthoritativePersistenceException error,
    required DateTime recoveredAt,
  }) {
    return AuthoritativeRecoveryResult(
      decision: AuthoritativeRecoveryDecision.failed,
      learnerId: learnerId,
      examId: examId,
      error: error,
      recoveredAt: recoveredAt.toUtc(),
    );
  }

  bool get isSuccess => decision.isSuccess;

  bool get isFresh => decision == AuthoritativeRecoveryDecision.initialized;

  AuthoritativeLearnerState get stateOrThrow {
    if (state != null) return state!;
    throw StateError(
        'AuthoritativeRecoveryResult did not produce state: ${decision.serialName} (${error?.message})');
  }

  @override
  String toString() =>
      'AuthoritativeRecoveryResult(decision: ${decision.serialName}, learner: $learnerId, exam: $examId, rev: $revision, v$schemaVersion, error: ${error?.code.serialName})';
}
