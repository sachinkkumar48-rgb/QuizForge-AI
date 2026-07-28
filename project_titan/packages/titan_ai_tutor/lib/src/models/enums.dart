library;

/// Personas / modes supported by the TITAN AI Tutor.
enum TutorPersona {
  eli5,
  beginner,
  intermediate,
  advanced,
  upscMode,
  interviewMode,
}

typedef TutorTeachingMode = TutorPersona;

extension TutorPersonaX on TutorPersona {
  String get displayName {
    switch (this) {
      case TutorPersona.eli5:
        return "Explain Like I'm 5";
      case TutorPersona.beginner:
        return 'Beginner Foundation';
      case TutorPersona.intermediate:
        return 'Intermediate Core';
      case TutorPersona.advanced:
        return 'Advanced Conceptual';
      case TutorPersona.upscMode:
        return 'UPSC Mains & Prelims Mode';
      case TutorPersona.interviewMode:
        return 'UPSC Personality Test Mode';
    }
  }
}

/// Lifecycle status of a tutoring session.
enum TutorSessionStatus {
  idle,
  active,
  evaluating,
  paused,
  completed,
}

/// Types of questions posed by the AI Tutor during Socratic sessions.
enum TutorQuestionType {
  multipleChoice,
  openEnded,
  socratic,
  assertionReason,
}

/// Status of practice exercises assigned by the AI Tutor.
enum TutorExerciseStatus {
  pending,
  inProgress,
  completed,
  failed,
}

/// Dynamic difficulty levels for adaptive tutoring.
enum TutorDifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

/// Status of learner goals.
enum TutorGoalStatus {
  notStarted,
  inProgress,
  achieved,
  failed,
}

/// Classification of student misconceptions.
enum MisconceptionType {
  factual,
  conceptual,
  procedural,
  reasoning,
}

/// Severity of detected misconceptions.
enum MisconceptionSeverity {
  low,
  medium,
  high,
  critical,
}

/// Evaluation grades for answers and exercises.
enum EvaluationGrade {
  needsImprovement,
  satisfactory,
  good,
  excellent,
  mastered,
}
