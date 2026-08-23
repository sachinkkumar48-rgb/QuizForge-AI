/// Represents the state of a user's answer for an individual question during an interactive session.
enum AnswerStatus {
  /// User has not yet chosen an option.
  unanswered,

  /// User has selected one or more options but has not submitted the answer.
  selected,

  /// Answer is submitted and evaluated.
  submitted,

  /// Answer is evaluated and verified as correct.
  correct,

  /// Answer is evaluated and determined to be incorrect.
  incorrect,

  /// Question has been reviewed post-evaluation.
  reviewed;

  /// True if the user has finalized submission for this question.
  bool get isEvaluated =>
      this == AnswerStatus.correct ||
      this == AnswerStatus.incorrect ||
      this == AnswerStatus.reviewed;
}
