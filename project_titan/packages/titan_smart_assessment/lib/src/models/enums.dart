library;

/// Types of assessments supported by the Smart Assessment Engine.
enum AssessmentType {
  practiceTest,
  topicTest,
  mockExam,
  adaptiveTest,
  pyq,
  aiGenerated,
  dailyQuiz,
  revisionTest,
}

extension AssessmentTypeX on AssessmentType {
  String get displayName {
    switch (this) {
      case AssessmentType.practiceTest:
        return 'Practice Test';
      case AssessmentType.topicTest:
        return 'Topic Test';
      case AssessmentType.mockExam:
        return 'UPSC Mock Exam';
      case AssessmentType.adaptiveTest:
        return 'Adaptive CAT Assessment';
      case AssessmentType.pyq:
        return 'Previous Year Question (PYQ)';
      case AssessmentType.aiGenerated:
        return 'AI-Generated Drill';
      case AssessmentType.dailyQuiz:
        return 'Daily Practice Quiz';
      case AssessmentType.revisionTest:
        return 'Targeted Revision Test';
    }
  }
}

/// Lifecycle status of an assessment session.
enum AssessmentStatus {
  draft,
  ready,
  inProgress,
  paused,
  completed,
  evaluated,
  archived,
}

/// Scoring rules and modes.
enum ScoringMode {
  standard,
  negativeMarking,
  weighted,
  partialCredit,
}

/// Performance grade scale levels.
enum GradeLevel {
  novice,
  developing,
  proficient,
  advanced,
  master,
}
