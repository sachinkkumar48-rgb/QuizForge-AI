/// Authoritative Application Decision (TITAN-KO-039.0 P39).
///
/// Enumerates the categorical outcomes of attempting to apply a
/// [ReconciledLearningStateProposal] to P19 authoritative persistence.
library;

enum AuthoritativeApplicationDecision {
  /// The proposal was successfully and atomically written to P19 persistence
  /// and verified through authoritative state reload.
  applied,

  /// The practice session or proposal was already applied to the learner's state;
  /// no durable mutation occurred (idempotent no-op).
  alreadyApplied,

  /// The proposal contained zero net state changes (e.g. unchanged);
  /// no durable writes were required.
  noOp,

  /// The proposal's base state fingerprint does not match current authoritative state;
  /// rejected to prevent overwriting newer state (optimistic concurrency violation).
  stale,

  /// The proposal could not be applied due to conflicting state constraints.
  conflict,

  /// The proposal or state input arguments were malformed or invalid.
  invalid,

  /// The application was rejected due to identity/exam boundary violations.
  rejected,

  /// Atomic persistence or post-write verification failed.
  failed;

  String get serialName => name;

  static AuthoritativeApplicationDecision fromString(String val) {
    for (final decision in values) {
      if (decision.name.toLowerCase() == val.trim().toLowerCase()) {
        return decision;
      }
    }
    throw ArgumentError(
        'Unknown AuthoritativeApplicationDecision: "$val". Valid: ${values.map((v) => v.name).toList()}');
  }
}
