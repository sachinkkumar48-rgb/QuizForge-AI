/// Learner Objective Status (TITAN-KO-018.0 P18).
///
/// Status of a learner's progress toward a single learning objective.
library;

enum LearnerObjectiveStatus {
  /// No attempts submitted yet.
  notStarted,

  /// Attempts submitted, but achievement thresholds not yet met.
  inProgress,

  /// Achievement thresholds met (minimum attempts & minimum success rate).
  achieved;

  String get displayName => switch (this) {
        LearnerObjectiveStatus.notStarted => 'Not Started',
        LearnerObjectiveStatus.inProgress => 'In Progress',
        LearnerObjectiveStatus.achieved => 'Achieved',
      };
}
