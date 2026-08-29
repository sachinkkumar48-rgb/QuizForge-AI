/// Study Allocation Type Enum (TITAN-KO-024.0 P24).
///
/// Categorizes the priority source of each [StudyAgendaItem] within a
/// [DailyStudyAgenda]. Allocation types are ordered by planning priority
/// (lower ordinal = higher priority).
library;

/// Categorization of a study allocation slot within a daily study agenda.
enum StudyAllocationType {
  /// Overdue spaced-repetition review item (nextReviewDate <= planningDate).
  /// Derived from P20 [ReviewSchedule] evidence. Highest planning priority.
  overdueReview,

  /// Due spaced-repetition review item scheduled within the next 24 hours.
  /// Derived from P20 [ReviewSchedule] evidence.
  dueReview,

  /// Targeted practice for a diagnosed weak objective.
  /// Derived from P23 [WeakSpotProfile] evidence.
  weakSpotPractice,

  /// Study action derived from a P21 [LearningRecommendation].
  recommendedAction,

  /// First-pass study of an objective not yet attempted.
  /// Derived from P17 [LearningObjective] scope minus P18 [LearnerProgress].
  newCurriculum;

  /// Human-readable label for this allocation type.
  String get displayName => switch (this) {
        StudyAllocationType.overdueReview => 'Overdue Spaced Review',
        StudyAllocationType.dueReview => 'Due Spaced Review',
        StudyAllocationType.weakSpotPractice => 'Weak-Spot Practice',
        StudyAllocationType.recommendedAction => 'Recommended Action',
        StudyAllocationType.newCurriculum => 'New Curriculum',
      };
}
