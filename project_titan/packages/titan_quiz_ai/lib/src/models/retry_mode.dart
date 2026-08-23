/// Strategy mode for filtering questions when creating a remedial retry session.
enum RetryMode {
  /// Retries questions that were answered incorrectly in the previous session.
  incorrect,

  /// Retries questions that were skipped or unanswered.
  unanswered,

  /// Retries questions marked for review by the user.
  markedForReview,

  /// Retries all questions from the original session.
  all;

  String get label {
    switch (this) {
      case RetryMode.incorrect:
        return 'Retry Incorrect';
      case RetryMode.unanswered:
        return 'Retry Unanswered';
      case RetryMode.markedForReview:
        return 'Retry Marked';
      case RetryMode.all:
        return 'Restart Quiz';
    }
  }
}
