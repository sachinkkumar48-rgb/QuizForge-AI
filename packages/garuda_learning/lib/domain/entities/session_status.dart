/// Adaptive Learning Session Status (TITAN-KO-040.0 P40).
///
/// Discrete lifecycle states and permitted state transitions for adaptive
/// learning sessions.
library;

/// Explicit lifecycle execution states of an adaptive learning session.
enum SessionStatus {
  /// Session created and configured, not yet active.
  created,

  /// Session actively executing, presenting questions, and accepting attempts.
  active,

  /// Session temporarily paused by the learner or application lifecycle.
  paused,

  /// Session in the process of being recovered after interruption or restart.
  recovering,

  /// Session reached terminal completion with all required criteria satisfied.
  completed,

  /// Session explicitly abandoned by learner before completion.
  abandoned,

  /// Session encountered an unrecoverable structural or data corruption failure.
  failed;

  /// Whether this session is in an immutable terminal state.
  bool get isTerminal =>
      this == SessionStatus.completed ||
      this == SessionStatus.abandoned ||
      this == SessionStatus.failed;

  /// Whether the session can accept question attempts and learner interactions.
  bool get canAcceptInput => this == SessionStatus.active;

  /// Whether the session is eligible for crash recovery.
  bool get isRecoverable =>
      this == SessionStatus.active ||
      this == SessionStatus.paused ||
      this == SessionStatus.recovering;

  /// Validates whether transitioning from this state to [target] is permitted.
  bool canTransitionTo(SessionStatus target) => switch (this) {
        SessionStatus.created => target == SessionStatus.active ||
            target == SessionStatus.abandoned ||
            target == SessionStatus.failed,
        SessionStatus.active => target == SessionStatus.paused ||
            target == SessionStatus.recovering ||
            target == SessionStatus.completed ||
            target == SessionStatus.abandoned ||
            target == SessionStatus.failed,
        SessionStatus.paused => target == SessionStatus.active ||
            target == SessionStatus.recovering ||
            target == SessionStatus.abandoned ||
            target == SessionStatus.failed,
        SessionStatus.recovering => target == SessionStatus.active ||
            target == SessionStatus.completed ||
            target == SessionStatus.abandoned ||
            target == SessionStatus.failed,
        SessionStatus.completed => false,
        SessionStatus.abandoned => false,
        SessionStatus.failed => false,
      };
}
