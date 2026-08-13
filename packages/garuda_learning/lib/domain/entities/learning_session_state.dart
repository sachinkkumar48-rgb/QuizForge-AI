/// Learning Session Lifecycle State Enum (TITAN-KO-019.0 P19).
///
/// States for lifecycle management of learning orchestration sessions.
library;

enum LearningSessionState {
  /// Session created and configured, but not yet started by learner.
  created,

  /// Session actively in progress, accepting question attempts.
  active,

  /// Session temporarily paused by learner.
  paused,

  /// All questions completed or session explicitly finalized.
  completed,

  /// Session explicitly cancelled or abandoned before completion.
  cancelled;

  /// Human-readable display title for the session state.
  String get displayName => switch (this) {
        LearningSessionState.created => 'Created',
        LearningSessionState.active => 'Active',
        LearningSessionState.paused => 'Paused',
        LearningSessionState.completed => 'Completed',
        LearningSessionState.cancelled => 'Cancelled',
      };

  /// Whether the session is in a final terminal state.
  bool get isTerminal =>
      this == LearningSessionState.completed ||
      this == LearningSessionState.cancelled;

  /// Validates whether a transition from this state to [target] is permitted.
  bool canTransitionTo(LearningSessionState target) => switch (this) {
        LearningSessionState.created => target == LearningSessionState.active ||
            target == LearningSessionState.cancelled,
        LearningSessionState.active => target == LearningSessionState.paused ||
            target == LearningSessionState.completed ||
            target == LearningSessionState.cancelled,
        LearningSessionState.paused => target == LearningSessionState.active ||
            target == LearningSessionState.completed ||
            target == LearningSessionState.cancelled,
        LearningSessionState.completed => false,
        LearningSessionState.cancelled => false,
      };
}
