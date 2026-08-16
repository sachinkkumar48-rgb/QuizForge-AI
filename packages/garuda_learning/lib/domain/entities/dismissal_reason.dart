/// Dismissal Reason Enum (TITAN-KO-022.0 P22).
///
/// Structured classification of learner dismissal reasons for recommended
/// learning objectives, avoiding unstructured free-text ambiguity.
library;

enum DismissalReason {
  /// Learner is currently not interested in this topic.
  notInterested,

  /// Learner perceives the recommended objective as too difficult at this time.
  tooDifficult,

  /// Learner perceives the recommended objective as too easy / already known.
  tooEasy,

  /// Learner claims prior mastery of the objective outside the system.
  alreadyMastered,

  /// Learner intends to study this objective at a later scheduled time.
  deferredForLater,

  /// Other miscellaneous reason provided by the learner.
  other;

  /// Human-readable display label for the dismissal reason.
  String get displayName => switch (this) {
        DismissalReason.notInterested => 'Not interested right now',
        DismissalReason.tooDifficult => 'Too difficult at this stage',
        DismissalReason.tooEasy => 'Too easy / basic',
        DismissalReason.alreadyMastered => 'Already mastered this topic',
        DismissalReason.deferredForLater => 'Postponed for later',
        DismissalReason.other => 'Other reason',
      };
}
