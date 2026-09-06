/// Objective Mastery & Transition Status Enums (TITAN-KO-044.0 P44).
///
/// Encapsulates discrete mastery states and longitudinal transition events
/// for individual curriculum learning objectives within Project TITAN.
library;

/// Represents the discrete mastery classification of a learning objective.
enum ObjectiveMasteryStatus {
  /// Zero attempts have been recorded for this objective.
  notAttempted,

  /// Attempts have been recorded, but total attempts are below the statistical
  /// evidence threshold (e.g. < 3 attempts).
  insufficientEvidence,

  /// Sufficient attempts exist, and accuracy is within standard learning range
  /// (e.g. 50% to 79%).
  inProgress,

  /// Objective criteria met: sufficient attempts and high success rate (e.g. >= 80%).
  mastered,

  /// Material weakness diagnosed: sufficient attempts with low success rate (e.g. < 50%).
  remediationRequired,

  /// Previously mastered objective where recent performance has dropped below
  /// retention/mastery thresholds.
  regressed;

  /// Whether this objective is considered mastered.
  bool get isMastered => this == ObjectiveMasteryStatus.mastered;

  /// Whether this objective is in a struggling state needing intervention.
  bool get isStruggling =>
      this == ObjectiveMasteryStatus.remediationRequired ||
      this == ObjectiveMasteryStatus.regressed;

  /// Whether any attempts have been recorded.
  bool get hasEvidence => this != ObjectiveMasteryStatus.notAttempted;

  /// Human-readable display label.
  String get displayName {
    switch (this) {
      case ObjectiveMasteryStatus.notAttempted:
        return 'Not Attempted';
      case ObjectiveMasteryStatus.insufficientEvidence:
        return 'Insufficient Evidence';
      case ObjectiveMasteryStatus.inProgress:
        return 'In Progress';
      case ObjectiveMasteryStatus.mastered:
        return 'Mastered';
      case ObjectiveMasteryStatus.remediationRequired:
        return 'Remediation Required';
      case ObjectiveMasteryStatus.regressed:
        return 'Regressed';
    }
  }
}

/// Represents the directional state transition of an objective following new evidence.
enum ObjectiveTransitionType {
  /// Objective was evaluated for the first time.
  initialAssessment,

  /// Performance improved or positive progression towards mastery was observed.
  progressed,

  /// Objective crossed the threshold into full mastery.
  mastered,

  /// Learner sustained strong performance, maintaining mastery status.
  maintainedMastery,

  /// Performance degraded below retention standards after prior mastery.
  regressed,

  /// Persistent struggle detected, triggering remedial intervention.
  remediationTriggered,

  /// Remedial practice or review resolved previous weakness.
  remediationResolved,

  /// No material change in objective status.
  unchanged;

  /// Whether this transition represents positive learning progress.
  bool get isPositive =>
      this == ObjectiveTransitionType.progressed ||
      this == ObjectiveTransitionType.mastered ||
      this == ObjectiveTransitionType.maintainedMastery ||
      this == ObjectiveTransitionType.remediationResolved;

  /// Whether this transition represents negative learning progress or struggle.
  bool get isNegative =>
      this == ObjectiveTransitionType.regressed ||
      this == ObjectiveTransitionType.remediationTriggered;

  /// Human-readable display label.
  String get displayName {
    switch (this) {
      case ObjectiveTransitionType.initialAssessment:
        return 'Initial Assessment';
      case ObjectiveTransitionType.progressed:
        return 'Progressed';
      case ObjectiveTransitionType.mastered:
        return 'Mastered';
      case ObjectiveTransitionType.maintainedMastery:
        return 'Maintained Mastery';
      case ObjectiveTransitionType.regressed:
        return 'Regressed';
      case ObjectiveTransitionType.remediationTriggered:
        return 'Remediation Triggered';
      case ObjectiveTransitionType.remediationResolved:
        return 'Remediation Resolved';
      case ObjectiveTransitionType.unchanged:
        return 'Unchanged';
    }
  }
}
