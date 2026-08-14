/// Performance rating for a review attempt based on SuperMemo 2 (SM-2) standards.
enum PerformanceRating {
  /// Complete failure; inability to recall. Triggers interval reset to 1 day.
  again(2, 'Again'),

  /// Difficult recall; took significant effort. Reduces interval growth.
  hard(3, 'Hard'),

  /// Successful recall with moderate effort. Standard interval growth.
  good(4, 'Good'),

  /// Trivial recall; instant recall with zero effort. Accelerated interval growth.
  easy(5, 'Easy');

  const PerformanceRating(this.grade, this.label);

  /// SM-2 numeric grade (2 to 5).
  final int grade;

  /// Display label for UI/logging.
  final String label;

  /// Deterministically maps a normalized assessment score ([0.0, 1.0])
  /// to a corresponding [PerformanceRating].
  factory PerformanceRating.fromScore(double score) {
    final clampedScore = score.clamp(0.0, 1.0);
    if (clampedScore >= 0.8) {
      return PerformanceRating.easy;
    } else if (clampedScore >= 0.6) {
      return PerformanceRating.good;
    } else if (clampedScore >= 0.4) {
      return PerformanceRating.hard;
    } else {
      return PerformanceRating.again;
    }
  }
}
