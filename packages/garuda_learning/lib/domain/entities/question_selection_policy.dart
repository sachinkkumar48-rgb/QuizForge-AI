/// Question Selection Policy Enum (TITAN-KO-019.0 P19).
///
/// Deterministic strategy for selecting P15 questions for a learning session.
library;

enum QuestionSelectionPolicy {
  /// Selects all available questions mapped to the target objective(s).
  allObjectiveQuestions,

  /// Filters out questions already attempted by the learner for this objective.
  unattemptedOnly,

  /// Focuses on questions previously answered incorrectly by the learner.
  incorrectFocus,

  /// Combines unattempted questions and prior incorrect questions.
  balanced;

  String get displayName => switch (this) {
        QuestionSelectionPolicy.allObjectiveQuestions =>
          'All Objective Questions',
        QuestionSelectionPolicy.unattemptedOnly => 'Unattempted Only',
        QuestionSelectionPolicy.incorrectFocus => 'Incorrect Answer Focus',
        QuestionSelectionPolicy.balanced => 'Balanced (Unattempted + Review)',
      };
}
