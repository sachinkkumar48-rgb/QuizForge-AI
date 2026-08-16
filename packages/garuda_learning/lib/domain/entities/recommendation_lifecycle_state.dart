/// Recommendation Lifecycle State Enum (TITAN-KO-022.0 P22).
///
/// States for lifecycle management, interaction telemetry, and outcome evaluation
/// of persisted learning recommendation instances in Project TITAN.
library;

enum RecommendationLifecycleState {
  /// Recommendation instance generated and persisted, awaiting learner interaction.
  issued,

  /// Recommendation has been rendered / surfaced to the learner.
  viewed,

  /// Learner has explicitly accepted the recommendation for practice.
  accepted,

  /// Learner has dismissed the recommendation with a structured reason.
  dismissed,

  /// Learner has deferred the recommendation for later review.
  deferred,

  /// A learning session linked to this recommendation has been started.
  started,

  /// The linked learning session has reached terminal completion.
  completed,

  /// The linked learning session was cancelled, abandoned, or timed out.
  abandoned,

  /// The recommendation validity window has expired without action.
  expired,

  /// The recommendation was superseded by a subsequent recommendation queue.
  superseded;

  /// Human-readable display title for the lifecycle state.
  String get displayName => switch (this) {
        RecommendationLifecycleState.issued => 'Issued',
        RecommendationLifecycleState.viewed => 'Viewed',
        RecommendationLifecycleState.accepted => 'Accepted',
        RecommendationLifecycleState.dismissed => 'Dismissed',
        RecommendationLifecycleState.deferred => 'Deferred',
        RecommendationLifecycleState.started => 'Started',
        RecommendationLifecycleState.completed => 'Completed',
        RecommendationLifecycleState.abandoned => 'Abandoned',
        RecommendationLifecycleState.expired => 'Expired',
        RecommendationLifecycleState.superseded => 'Superseded',
      };

  /// Whether this state is a terminal lifecycle state.
  bool get isTerminal =>
      this == RecommendationLifecycleState.dismissed ||
      this == RecommendationLifecycleState.completed ||
      this == RecommendationLifecycleState.abandoned ||
      this == RecommendationLifecycleState.expired ||
      this == RecommendationLifecycleState.superseded;

  /// Validates whether a transition from this state to [target] is permitted.
  ///
  /// Enforces deterministic state progression and strict supersession guards:
  /// - Only `issued` and `viewed` recommendations may transition to `superseded`.
  /// - `accepted`, `deferred`, and `started` recommendations must NOT automatically transition to `superseded`.
  /// - Terminal states do not permit any outgoing transitions.
  bool canTransitionTo(RecommendationLifecycleState target) => switch (this) {
        RecommendationLifecycleState.issued =>
          target == RecommendationLifecycleState.viewed ||
              target == RecommendationLifecycleState.accepted ||
              target == RecommendationLifecycleState.dismissed ||
              target == RecommendationLifecycleState.deferred ||
              target == RecommendationLifecycleState.expired ||
              target == RecommendationLifecycleState.superseded,
        RecommendationLifecycleState.viewed =>
          target == RecommendationLifecycleState.accepted ||
              target == RecommendationLifecycleState.dismissed ||
              target == RecommendationLifecycleState.deferred ||
              target == RecommendationLifecycleState.expired ||
              target == RecommendationLifecycleState.superseded,
        RecommendationLifecycleState.accepted =>
          target == RecommendationLifecycleState.started ||
              target == RecommendationLifecycleState.deferred ||
              target == RecommendationLifecycleState.dismissed ||
              target == RecommendationLifecycleState.abandoned,
        RecommendationLifecycleState.deferred =>
          target == RecommendationLifecycleState.viewed ||
              target == RecommendationLifecycleState.accepted ||
              target == RecommendationLifecycleState.dismissed ||
              target == RecommendationLifecycleState.expired,
        RecommendationLifecycleState.started =>
          target == RecommendationLifecycleState.completed ||
              target == RecommendationLifecycleState.abandoned,
        RecommendationLifecycleState.dismissed => false,
        RecommendationLifecycleState.completed => false,
        RecommendationLifecycleState.abandoned => false,
        RecommendationLifecycleState.expired => false,
        RecommendationLifecycleState.superseded => false,
      };
}
