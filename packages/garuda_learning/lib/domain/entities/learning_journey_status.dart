/// Learning Journey Status Domain Enum (TITAN-KO-041.0 P41).
///
/// Complete, discrete lifecycle states for production adaptive learning journeys.
library;

/// Discrete lifecycle states of an end-to-end adaptive learning journey.
enum LearningJourneyStatus {
  /// Journey session has been created and configured, but question presentation has not yet begun.
  created,

  /// Journey session is active and execution has commenced.
  active,

  /// A specific question has been selected, formatted, and presented to the learner.
  questionPresented,

  /// Learner has submitted an answer for the current question.
  answerReceived,

  /// Attempt has been evaluated and consolidated into verified practice outcome evidence.
  outcomeRecorded,

  /// Authoritative learner state has been updated, reconciled, and persisted with monotonic revision.
  stateReconciled,

  /// Durable session checkpoint has been computed, verified, and saved to repository.
  checkpointed,

  /// Session execution was interrupted by crash, network drop, or user navigation.
  interrupted,

  /// Interrupted session is actively validating checkpoints and reconstructing execution coordinates.
  recovering,

  /// Interrupted session was successfully recovered and positioned at the exact unattempted question.
  resumed,

  /// All questions in the session specification have been completed and finalized.
  completed,

  /// Session was terminated prematurely by user abandonment or administrative cancellation.
  abandoned,

  /// Session encountered an unrecoverable corruption or fatal infrastructure failure.
  failed;

  /// Whether the session has reached an immutable terminal state.
  bool get isTerminal =>
      this == LearningJourneyStatus.completed ||
      this == LearningJourneyStatus.abandoned ||
      this == LearningJourneyStatus.failed;

  /// Whether the session is in an active state that can accept an answer submission.
  bool get canAcceptAnswer =>
      this == LearningJourneyStatus.active ||
      this == LearningJourneyStatus.questionPresented ||
      this == LearningJourneyStatus.resumed;

  /// Whether the session is currently interrupted or awaiting resumption.
  bool get isInterrupted =>
      this == LearningJourneyStatus.interrupted ||
      this == LearningJourneyStatus.recovering;

  /// Validates whether a state transition from `this` to [target] is legally permitted.
  bool canTransitionTo(LearningJourneyStatus target) {
    if (isTerminal) return false;
    if (this == target) return true;

    switch (this) {
      case LearningJourneyStatus.created:
        return target == LearningJourneyStatus.active ||
            target == LearningJourneyStatus.questionPresented ||
            target == LearningJourneyStatus.abandoned ||
            target == LearningJourneyStatus.failed;

      case LearningJourneyStatus.active:
        return target == LearningJourneyStatus.questionPresented ||
            target == LearningJourneyStatus.interrupted ||
            target == LearningJourneyStatus.completed ||
            target == LearningJourneyStatus.abandoned ||
            target == LearningJourneyStatus.failed;

      case LearningJourneyStatus.questionPresented:
        return target == LearningJourneyStatus.answerReceived ||
            target == LearningJourneyStatus.interrupted ||
            target == LearningJourneyStatus.abandoned ||
            target == LearningJourneyStatus.failed;

      case LearningJourneyStatus.answerReceived:
        return target == LearningJourneyStatus.outcomeRecorded ||
            target == LearningJourneyStatus.interrupted ||
            target == LearningJourneyStatus.failed;

      case LearningJourneyStatus.outcomeRecorded:
        return target == LearningJourneyStatus.stateReconciled ||
            target == LearningJourneyStatus.interrupted ||
            target == LearningJourneyStatus.failed;

      case LearningJourneyStatus.stateReconciled:
        return target == LearningJourneyStatus.checkpointed ||
            target == LearningJourneyStatus.interrupted ||
            target == LearningJourneyStatus.failed;

      case LearningJourneyStatus.checkpointed:
        return target == LearningJourneyStatus.questionPresented ||
            target == LearningJourneyStatus.completed ||
            target == LearningJourneyStatus.interrupted ||
            target == LearningJourneyStatus.abandoned ||
            target == LearningJourneyStatus.failed;

      case LearningJourneyStatus.interrupted:
        return target == LearningJourneyStatus.recovering ||
            target == LearningJourneyStatus.resumed ||
            target == LearningJourneyStatus.abandoned ||
            target == LearningJourneyStatus.failed;

      case LearningJourneyStatus.recovering:
        return target == LearningJourneyStatus.resumed ||
            target == LearningJourneyStatus.abandoned ||
            target == LearningJourneyStatus.failed;

      case LearningJourneyStatus.resumed:
        return target == LearningJourneyStatus.active ||
            target == LearningJourneyStatus.questionPresented ||
            target == LearningJourneyStatus.interrupted ||
            target == LearningJourneyStatus.completed ||
            target == LearningJourneyStatus.abandoned ||
            target == LearningJourneyStatus.failed;

      case LearningJourneyStatus.completed:
      case LearningJourneyStatus.abandoned:
      case LearningJourneyStatus.failed:
        return false;
    }
  }

  /// Human-readable display label.
  String get displayName => switch (this) {
        LearningJourneyStatus.created => 'Created',
        LearningJourneyStatus.active => 'Active',
        LearningJourneyStatus.questionPresented => 'Question Presented',
        LearningJourneyStatus.answerReceived => 'Answer Received',
        LearningJourneyStatus.outcomeRecorded => 'Outcome Recorded',
        LearningJourneyStatus.stateReconciled => 'State Reconciled',
        LearningJourneyStatus.checkpointed => 'Checkpointed',
        LearningJourneyStatus.interrupted => 'Interrupted',
        LearningJourneyStatus.recovering => 'Recovering',
        LearningJourneyStatus.resumed => 'Resumed',
        LearningJourneyStatus.completed => 'Completed',
        LearningJourneyStatus.abandoned => 'Abandoned',
        LearningJourneyStatus.failed => 'Failed',
      };
}
