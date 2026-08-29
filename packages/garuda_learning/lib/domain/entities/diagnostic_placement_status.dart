/// Diagnostic Placement Status Enum (TITAN-KO-026.0 P26).
///
/// Categorizes the observed performance state of a learner against a specific
/// learning objective.
///
/// Educational Safety Invariants:
/// - Describes observed assessment evidence ONLY.
/// - NEVER claims innate intelligence, aptitude, fixed potential, or human worth.
/// - Incomplete or missing evidence is NEVER classified as deficiency.
library;

enum DiagnosticPlacementStatus {
  /// Learner has demonstrated mastery meeting or exceeding the accuracy threshold
  /// with sufficient evidence.
  demonstrated,

  /// Learner has demonstrated developing performance (below mastery threshold)
  /// with sufficient evidence.
  developing,

  /// Assessment attempts were recorded, but sample size is below the minimum
  /// evidence threshold required for a deterministic determination.
  insufficientEvidence,

  /// No assessment attempts were recorded for this objective.
  notAssessed;

  /// Human-readable label.
  String get displayName {
    switch (this) {
      case DiagnosticPlacementStatus.demonstrated:
        return 'Demonstrated';
      case DiagnosticPlacementStatus.developing:
        return 'Developing';
      case DiagnosticPlacementStatus.insufficientEvidence:
        return 'Insufficient Evidence';
      case DiagnosticPlacementStatus.notAssessed:
        return 'Not Assessed';
    }
  }

  /// Whether performance has been positively demonstrated.
  bool get isDemonstrated => this == DiagnosticPlacementStatus.demonstrated;

  /// Whether the objective requires further instructional reinforcement.
  bool get isDeveloping => this == DiagnosticPlacementStatus.developing;

  String toJson() => name;

  static DiagnosticPlacementStatus fromJson(String value) {
    return DiagnosticPlacementStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DiagnosticPlacementStatus.notAssessed,
    );
  }
}
