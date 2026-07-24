/// Represents the operational state of a quiz session attempt.
enum QuizSessionStatus {
  notStarted,
  inProgress,
  paused,
  completed,
  expired,
  abandoned;

  bool get isTerminal =>
      this == QuizSessionStatus.completed ||
      this == QuizSessionStatus.expired ||
      this == QuizSessionStatus.abandoned;

  bool get isActive => this == QuizSessionStatus.inProgress;
}
