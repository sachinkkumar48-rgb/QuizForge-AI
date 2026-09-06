/// Mastery Classification Domain Entity (TITAN-KO-040.0 P40).
///
/// Discrete, deterministic classification levels representing a learner's
/// progressive mastery of a topic or concept within Project TITAN.
library;

/// Categorical classification of topic or concept mastery.
enum MasteryClassification {
  /// No evidence or attempts have been recorded for this topic/concept.
  notStarted,

  /// Initial or struggling performance below foundational competence.
  emerging,

  /// Demonstrating partial understanding; advancing through intermediate practice.
  developing,

  /// Consistent, reliable performance meeting standard qualification expectations.
  proficient,

  /// Thorough, sustained mastery with high accuracy across challenging questions.
  mastered;

  /// Human-readable display label.
  String get displayName {
    switch (this) {
      case MasteryClassification.notStarted:
        return 'Not Started';
      case MasteryClassification.emerging:
        return 'Emerging';
      case MasteryClassification.developing:
        return 'Developing';
      case MasteryClassification.proficient:
        return 'Proficient';
      case MasteryClassification.mastered:
        return 'Mastered';
    }
  }

  /// Whether the topic/concept has achieved the highest mastery standard.
  bool get isMastered => this == MasteryClassification.mastered;

  /// Whether the topic/concept is at or above standard proficiency.
  bool get isProficientOrAbove =>
      this == MasteryClassification.proficient ||
      this == MasteryClassification.mastered;

  /// Whether any evidence has been evaluated for this topic/concept.
  bool get hasStarted => this != MasteryClassification.notStarted;

  /// Serializes to snake_case string for persistent storage and contracts.
  String toJson() {
    switch (this) {
      case MasteryClassification.notStarted:
        return 'not_started';
      case MasteryClassification.emerging:
        return 'emerging';
      case MasteryClassification.developing:
        return 'developing';
      case MasteryClassification.proficient:
        return 'proficient';
      case MasteryClassification.mastered:
        return 'mastered';
    }
  }

  /// Deserializes from string format with deterministic fallback.
  static MasteryClassification fromJson(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'not_started':
      case 'notstarted':
        return MasteryClassification.notStarted;
      case 'emerging':
        return MasteryClassification.emerging;
      case 'developing':
        return MasteryClassification.developing;
      case 'proficient':
        return MasteryClassification.proficient;
      case 'mastered':
        return MasteryClassification.mastered;
      default:
        return MasteryClassification.notStarted;
    }
  }
}
