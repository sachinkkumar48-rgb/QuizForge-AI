/// Adaptive PYQ Learning Priority Configuration (TITAN-KO-032.0 P32).
///
/// Validated, immutable configuration governing the deterministic priority formula,
/// evidence thresholds, and component weights.
///
/// Educational Safety Invariants:
/// - All weights must be non-negative (>= 0.0).
/// - Sum of weights must be strictly positive (> 0.0).
/// - All minimum thresholds must be >= 1.
/// - NaN and Infinity values are strictly rejected.
library;

import 'package:meta/meta.dart';

@immutable
class PyqLearningPriorityConfig {
  /// Default minimum questions required in historical exam corpus for sufficient evidence.
  static const int defaultMinimumHistoricalQuestions = 5;

  /// Default minimum distinct years required for trend/recurrence confidence.
  static const int defaultMinimumYears = 2;

  /// Default minimum learner attempts required before weakness is considered valid.
  static const int defaultMinimumLearnerAttempts = 5;

  /// Default weight for historical share component.
  static const double defaultHistoricalWeight = 0.25;

  /// Default weight for recurrence across exam years component.
  static const double defaultRecurrenceWeight = 0.20;

  /// Default weight for recent exam activity component.
  static const double defaultRecencyWeight = 0.15;

  /// Default weight for learner weakness component.
  static const double defaultWeaknessWeight = 0.40;

  /// Minimum historical questions for sufficient exam evidence.
  final int minimumHistoricalQuestions;

  /// Minimum distinct years observed for recurrence reliability.
  final int minimumYears;

  /// Minimum learner attempts required to establish observed weakness.
  final int minimumLearnerAttempts;

  /// Raw weight for historical share.
  final double historicalWeight;

  /// Raw weight for recurrence.
  final double recurrenceWeight;

  /// Raw weight for recent historical activity.
  final double recencyWeight;

  /// Raw weight for learner weakness.
  final double weaknessWeight;

  /// Whether confidence gating scales historical component on sparse corpus.
  final bool confidenceGating;

  /// Normalized weight for historical share [0.0, 1.0].
  final double normalizedHistoricalWeight;

  /// Normalized weight for recurrence [0.0, 1.0].
  final double normalizedRecurrenceWeight;

  /// Normalized weight for recent historical activity [0.0, 1.0].
  final double normalizedRecencyWeight;

  /// Normalized weight for learner weakness [0.0, 1.0].
  final double normalizedWeaknessWeight;

  PyqLearningPriorityConfig({
    this.minimumHistoricalQuestions = defaultMinimumHistoricalQuestions,
    this.minimumYears = defaultMinimumYears,
    this.minimumLearnerAttempts = defaultMinimumLearnerAttempts,
    this.historicalWeight = defaultHistoricalWeight,
    this.recurrenceWeight = defaultRecurrenceWeight,
    this.recencyWeight = defaultRecencyWeight,
    this.weaknessWeight = defaultWeaknessWeight,
    this.confidenceGating = true,
  })  : normalizedHistoricalWeight = _computeNormalized(
          historicalWeight,
          historicalWeight + recurrenceWeight + recencyWeight + weaknessWeight,
        ),
        normalizedRecurrenceWeight = _computeNormalized(
          recurrenceWeight,
          historicalWeight + recurrenceWeight + recencyWeight + weaknessWeight,
        ),
        normalizedRecencyWeight = _computeNormalized(
          recencyWeight,
          historicalWeight + recurrenceWeight + recencyWeight + weaknessWeight,
        ),
        normalizedWeaknessWeight = _computeNormalized(
          weaknessWeight,
          historicalWeight + recurrenceWeight + recencyWeight + weaknessWeight,
        ) {
    if (minimumHistoricalQuestions < 1) {
      throw ArgumentError(
          'minimumHistoricalQuestions must be >= 1 (got $minimumHistoricalQuestions)');
    }
    if (minimumYears < 1) {
      throw ArgumentError('minimumYears must be >= 1 (got $minimumYears)');
    }
    if (minimumLearnerAttempts < 1) {
      throw ArgumentError(
          'minimumLearnerAttempts must be >= 1 (got $minimumLearnerAttempts)');
    }
    if (historicalWeight < 0.0 ||
        historicalWeight.isNaN ||
        historicalWeight.isInfinite) {
      throw ArgumentError('historicalWeight must be non-negative and finite');
    }
    if (recurrenceWeight < 0.0 ||
        recurrenceWeight.isNaN ||
        recurrenceWeight.isInfinite) {
      throw ArgumentError('recurrenceWeight must be non-negative and finite');
    }
    if (recencyWeight < 0.0 ||
        recencyWeight.isNaN ||
        recencyWeight.isInfinite) {
      throw ArgumentError('recencyWeight must be non-negative and finite');
    }
    if (weaknessWeight < 0.0 ||
        weaknessWeight.isNaN ||
        weaknessWeight.isInfinite) {
      throw ArgumentError('weaknessWeight must be non-negative and finite');
    }

    final totalWeight =
        historicalWeight + recurrenceWeight + recencyWeight + weaknessWeight;
    if (totalWeight <= 0.0 || totalWeight.isNaN || totalWeight.isInfinite) {
      throw ArgumentError('Total weight must be strictly positive and finite');
    }
  }

  static double _computeNormalized(double part, double total) {
    if (total <= 0.0 || total.isNaN || total.isInfinite) return 0.0;
    return (part / total).clamp(0.0, 1.0);
  }

  /// Default configuration instance.
  static final PyqLearningPriorityConfig defaultConfig =
      PyqLearningPriorityConfig();

  PyqLearningPriorityConfig copyWith({
    int? minimumHistoricalQuestions,
    int? minimumYears,
    int? minimumLearnerAttempts,
    double? historicalWeight,
    double? recurrenceWeight,
    double? recencyWeight,
    double? weaknessWeight,
    bool? confidenceGating,
  }) {
    return PyqLearningPriorityConfig(
      minimumHistoricalQuestions:
          minimumHistoricalQuestions ?? this.minimumHistoricalQuestions,
      minimumYears: minimumYears ?? this.minimumYears,
      minimumLearnerAttempts:
          minimumLearnerAttempts ?? this.minimumLearnerAttempts,
      historicalWeight: historicalWeight ?? this.historicalWeight,
      recurrenceWeight: recurrenceWeight ?? this.recurrenceWeight,
      recencyWeight: recencyWeight ?? this.recencyWeight,
      weaknessWeight: weaknessWeight ?? this.weaknessWeight,
      confidenceGating: confidenceGating ?? this.confidenceGating,
    );
  }

  Map<String, dynamic> toJson() => {
        'minimumHistoricalQuestions': minimumHistoricalQuestions,
        'minimumYears': minimumYears,
        'minimumLearnerAttempts': minimumLearnerAttempts,
        'historicalWeight': historicalWeight,
        'recurrenceWeight': recurrenceWeight,
        'recencyWeight': recencyWeight,
        'weaknessWeight': weaknessWeight,
        'confidenceGating': confidenceGating,
        'normalizedHistoricalWeight': normalizedHistoricalWeight,
        'normalizedRecurrenceWeight': normalizedRecurrenceWeight,
        'normalizedRecencyWeight': normalizedRecencyWeight,
        'normalizedWeaknessWeight': normalizedWeaknessWeight,
      };

  factory PyqLearningPriorityConfig.fromJson(Map<String, dynamic> json) =>
      PyqLearningPriorityConfig(
        minimumHistoricalQuestions:
            (json['minimumHistoricalQuestions'] as num?)?.toInt() ??
                defaultMinimumHistoricalQuestions,
        minimumYears:
            (json['minimumYears'] as num?)?.toInt() ?? defaultMinimumYears,
        minimumLearnerAttempts:
            (json['minimumLearnerAttempts'] as num?)?.toInt() ??
                defaultMinimumLearnerAttempts,
        historicalWeight: (json['historicalWeight'] as num?)?.toDouble() ??
            defaultHistoricalWeight,
        recurrenceWeight: (json['recurrenceWeight'] as num?)?.toDouble() ??
            defaultRecurrenceWeight,
        recencyWeight:
            (json['recencyWeight'] as num?)?.toDouble() ?? defaultRecencyWeight,
        weaknessWeight: (json['weaknessWeight'] as num?)?.toDouble() ??
            defaultWeaknessWeight,
        confidenceGating: json['confidenceGating'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PyqLearningPriorityConfig &&
          runtimeType == other.runtimeType &&
          minimumHistoricalQuestions == other.minimumHistoricalQuestions &&
          minimumYears == other.minimumYears &&
          minimumLearnerAttempts == other.minimumLearnerAttempts &&
          historicalWeight == other.historicalWeight &&
          recurrenceWeight == other.recurrenceWeight &&
          recencyWeight == other.recencyWeight &&
          weaknessWeight == other.weaknessWeight &&
          confidenceGating == other.confidenceGating;

  @override
  int get hashCode => Object.hash(
        minimumHistoricalQuestions,
        minimumYears,
        minimumLearnerAttempts,
        historicalWeight,
        recurrenceWeight,
        recencyWeight,
        weaknessWeight,
        confidenceGating,
      );
}
