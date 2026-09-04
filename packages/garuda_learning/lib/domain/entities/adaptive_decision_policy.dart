/// Adaptive Decision Policy Domain Entity (TITAN-KO-041.0 P41).
///
/// Encapsulates configurable thresholds, evaluation rules, and deterministic
/// priority hierarchies for pedagogical decision making.
library;

import 'package:meta/meta.dart';

/// Categorical type of pedagogical decision produced by the decision engine.
enum LearningDecisionType {
  /// Resume an active, paused, or interrupted session at its checkpoint cursor.
  continuation,

  /// Targeted conceptual remediation on an identified weakness.
  remediation,

  /// Spaced repetition review of previously mastered objectives to prevent memory decay.
  review,

  /// Additional practice on an in-progress objective with unstable accuracy.
  reinforcement,

  /// Progression to the next logical unattempted objective in the curriculum sequence.
  advancement,

  /// All curriculum objectives are achieved and zero reviews are pending.
  complete;

  /// Human-readable display label.
  String get displayName => switch (this) {
        LearningDecisionType.continuation => 'Session Continuation',
        LearningDecisionType.remediation => 'Concept Remediation',
        LearningDecisionType.review => 'Spaced Review',
        LearningDecisionType.reinforcement => 'Mastery Reinforcement',
        LearningDecisionType.advancement => 'Curriculum Advancement',
        LearningDecisionType.complete => 'Curriculum Completed',
      };
}

/// Priority tier assigned to a learning decision.
enum LearningDecisionPriority {
  /// Critical priority (active session resumption or urgent failure remediation).
  urgent,

  /// High priority (scheduled remediation or overdue spaced review).
  high,

  /// Medium priority (in-progress objective reinforcement).
  medium,

  /// Low priority (new curriculum advancement).
  low,

  /// Baseline priority (curriculum complete or no pending action).
  none;

  /// Numeric score for deterministic sorting (higher value = higher priority).
  int get rank => switch (this) {
        LearningDecisionPriority.urgent => 4,
        LearningDecisionPriority.high => 3,
        LearningDecisionPriority.medium => 2,
        LearningDecisionPriority.low => 1,
        LearningDecisionPriority.none => 0,
      };
}

/// Configurable, immutable policy governing deterministic decision evaluation.
@immutable
class AdaptiveDecisionPolicy {
  /// Default minimum question attempts before an objective can be assessed for remediation.
  static const int defaultRemediationMinAttempts = 3;

  /// Default success rate threshold below which remediation is triggered.
  static const double defaultRemediationSuccessRateThreshold = 0.50;

  /// Default minimum question attempts before an objective is considered mastered.
  static const int defaultMasteryMinAttempts = 5;

  /// Default success rate threshold required to achieve objective mastery.
  static const double defaultMasterySuccessRateThreshold = 0.80;

  /// Default elapsed days threshold before a mastered objective becomes due for review.
  static const int defaultReviewIntervalDays = 3;

  /// Minimum question attempts required before triggering remediation.
  final int remediationMinAttempts;

  /// Maximum success rate (exclusive) triggering remediation when attempts threshold is met.
  final double remediationSuccessRateThreshold;

  /// Minimum question attempts required for mastery achievement.
  final int masteryMinAttempts;

  /// Minimum success rate required for mastery achievement.
  final double masterySuccessRateThreshold;

  /// Days between spaced reviews when explicit review items are absent.
  final int reviewIntervalDays;

  /// Explicit deterministic priority evaluation order.
  final List<LearningDecisionType> priorityOrder;

  AdaptiveDecisionPolicy({
    this.remediationMinAttempts = defaultRemediationMinAttempts,
    this.remediationSuccessRateThreshold =
        defaultRemediationSuccessRateThreshold,
    this.masteryMinAttempts = defaultMasteryMinAttempts,
    this.masterySuccessRateThreshold = defaultMasterySuccessRateThreshold,
    this.reviewIntervalDays = defaultReviewIntervalDays,
    List<LearningDecisionType>? priorityOrder,
  }) : priorityOrder = List<LearningDecisionType>.unmodifiable(
          priorityOrder ??
              const [
                LearningDecisionType.continuation,
                LearningDecisionType.remediation,
                LearningDecisionType.review,
                LearningDecisionType.reinforcement,
                LearningDecisionType.advancement,
                LearningDecisionType.complete,
              ],
        ) {
    if (remediationMinAttempts < 1) {
      throw ArgumentError('remediationMinAttempts must be >= 1');
    }
    if (remediationSuccessRateThreshold < 0.0 ||
        remediationSuccessRateThreshold > 1.0) {
      throw ArgumentError(
          'remediationSuccessRateThreshold must be between 0.0 and 1.0');
    }
    if (masteryMinAttempts < 1) {
      throw ArgumentError('masteryMinAttempts must be >= 1');
    }
    if (masterySuccessRateThreshold < 0.0 ||
        masterySuccessRateThreshold > 1.0) {
      throw ArgumentError(
          'masterySuccessRateThreshold must be between 0.0 and 1.0');
    }
    if (reviewIntervalDays < 1) {
      throw ArgumentError('reviewIntervalDays must be >= 1');
    }
    if (this.priorityOrder.isEmpty) {
      throw ArgumentError('priorityOrder cannot be empty');
    }
  }

  /// Default standard policy instance.
  static final AdaptiveDecisionPolicy standard = AdaptiveDecisionPolicy();

  Map<String, dynamic> toJson() => {
        'remediationMinAttempts': remediationMinAttempts,
        'remediationSuccessRateThreshold': remediationSuccessRateThreshold,
        'masteryMinAttempts': masteryMinAttempts,
        'masterySuccessRateThreshold': masterySuccessRateThreshold,
        'reviewIntervalDays': reviewIntervalDays,
        'priorityOrder': priorityOrder.map((e) => e.name).toList(),
      };

  factory AdaptiveDecisionPolicy.fromJson(Map<String, dynamic> json) =>
      AdaptiveDecisionPolicy(
        remediationMinAttempts: json['remediationMinAttempts'] as int? ??
            defaultRemediationMinAttempts,
        remediationSuccessRateThreshold:
            (json['remediationSuccessRateThreshold'] as num?)?.toDouble() ??
                defaultRemediationSuccessRateThreshold,
        masteryMinAttempts:
            json['masteryMinAttempts'] as int? ?? defaultMasteryMinAttempts,
        masterySuccessRateThreshold:
            (json['masterySuccessRateThreshold'] as num?)?.toDouble() ??
                defaultMasterySuccessRateThreshold,
        reviewIntervalDays:
            json['reviewIntervalDays'] as int? ?? defaultReviewIntervalDays,
        priorityOrder: (json['priorityOrder'] as List<dynamic>?)
            ?.map((e) => LearningDecisionType.values.firstWhere(
                  (t) => t.name == e.toString(),
                  orElse: () => LearningDecisionType.continuation,
                ))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveDecisionPolicy &&
          remediationMinAttempts == other.remediationMinAttempts &&
          remediationSuccessRateThreshold ==
              other.remediationSuccessRateThreshold &&
          masteryMinAttempts == other.masteryMinAttempts &&
          masterySuccessRateThreshold == other.masterySuccessRateThreshold &&
          reviewIntervalDays == other.reviewIntervalDays;

  @override
  int get hashCode => Object.hash(
        remediationMinAttempts,
        remediationSuccessRateThreshold,
        masteryMinAttempts,
        masterySuccessRateThreshold,
        reviewIntervalDays,
      );
}
