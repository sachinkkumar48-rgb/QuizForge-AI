/// Diagnostic Evidence State Enum (TITAN-KO-026.0 P26).
///
/// Represents the epistemic sufficiency of observed assessment evidence for
/// a curriculum learning objective.
///
/// Educational Safety Invariant: Absence of evidence is NEVER treated as
/// failure, low ability, or learning weakness.
library;

enum DiagnosticEvidenceState {
  /// Sufficient assessment attempts have been observed to satisfy the diagnostic threshold.
  sufficientEvidence,

  /// Some assessment attempts exist, but the sample size is below the minimum threshold.
  insufficientEvidence,

  /// Zero assessment attempts have been recorded for this objective.
  notAssessed;

  /// Human-readable label describing the epistemic evidence state.
  String get displayName {
    switch (this) {
      case DiagnosticEvidenceState.sufficientEvidence:
        return 'Sufficient Evidence';
      case DiagnosticEvidenceState.insufficientEvidence:
        return 'Insufficient Evidence';
      case DiagnosticEvidenceState.notAssessed:
        return 'Not Assessed';
    }
  }

  /// Whether this state permits deterministic placement evaluation.
  bool get hasSufficientEvidence =>
      this == DiagnosticEvidenceState.sufficientEvidence;

  String toJson() => name;

  static DiagnosticEvidenceState fromJson(String value) {
    return DiagnosticEvidenceState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DiagnosticEvidenceState.notAssessed,
    );
  }
}
