/// Resumable Learning Session Status Domain Entity (TITAN-KO-040.0 P40).
///
/// Encapsulates the deterministic lifecycle states and legal state transitions
/// for interrupted and resumable adaptive learning sessions.
library;

/// Lifecycle states of a resumable adaptive learning session.
enum ResumableSessionStatus {
  /// Session created and configured, not yet started.
  created,

  /// Session actively executing, presenting questions and accepting attempts.
  active,

  /// Session temporarily paused by learner or system.
  paused,

  /// Session unexpectedly interrupted (e.g. app crash, killed process, network loss).
  interrupted,

  /// Interrupted session verified as safely recoverable from a checkpoint.
  recoverable,

  /// Session successfully recovered from checkpoint and actively resumed.
  resumed,

  /// Session finished all scheduled questions and finalized reconciliation.
  completed,

  /// Session explicitly abandoned before completion.
  abandoned,

  /// Session encountered an unrecoverable structural or data corruption error.
  failed;

  /// Whether this session is in a terminal state from which no further transitions occur.
  bool get isTerminal =>
      this == ResumableSessionStatus.completed ||
      this == ResumableSessionStatus.abandoned ||
      this == ResumableSessionStatus.failed;

  /// Whether the session is currently active and can accept learner actions.
  bool get canAcceptInput =>
      this == ResumableSessionStatus.active ||
      this == ResumableSessionStatus.resumed;

  /// Whether the session can be safely recovered across application restarts.
  bool get isRecoverable =>
      this == ResumableSessionStatus.interrupted ||
      this == ResumableSessionStatus.recoverable ||
      this == ResumableSessionStatus.paused;

  /// Validates whether a state transition from this state to [target] is permitted.
  bool canTransitionTo(ResumableSessionStatus target) => switch (this) {
        ResumableSessionStatus.created =>
          target == ResumableSessionStatus.active ||
              target == ResumableSessionStatus.abandoned ||
              target == ResumableSessionStatus.failed,
        ResumableSessionStatus.active =>
          target == ResumableSessionStatus.paused ||
              target == ResumableSessionStatus.interrupted ||
              target == ResumableSessionStatus.completed ||
              target == ResumableSessionStatus.abandoned ||
              target == ResumableSessionStatus.failed,
        ResumableSessionStatus.paused =>
          target == ResumableSessionStatus.active ||
              target == ResumableSessionStatus.resumed ||
              target == ResumableSessionStatus.interrupted ||
              target == ResumableSessionStatus.abandoned ||
              target == ResumableSessionStatus.failed,
        ResumableSessionStatus.interrupted =>
          target == ResumableSessionStatus.recoverable ||
              target == ResumableSessionStatus.resumed ||
              target == ResumableSessionStatus.abandoned ||
              target == ResumableSessionStatus.failed,
        ResumableSessionStatus.recoverable =>
          target == ResumableSessionStatus.resumed ||
              target == ResumableSessionStatus.abandoned ||
              target == ResumableSessionStatus.failed,
        ResumableSessionStatus.resumed =>
          target == ResumableSessionStatus.active ||
              target == ResumableSessionStatus.paused ||
              target == ResumableSessionStatus.interrupted ||
              target == ResumableSessionStatus.completed ||
              target == ResumableSessionStatus.abandoned ||
              target == ResumableSessionStatus.failed,
        ResumableSessionStatus.completed => false,
        ResumableSessionStatus.abandoned => false,
        ResumableSessionStatus.failed => false,
      };
}
