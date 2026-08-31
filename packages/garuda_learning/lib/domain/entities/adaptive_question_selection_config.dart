/// Adaptive Question Selection Configuration (TITAN-KO-033.0 P33).
///
/// Validated, immutable configuration specifying scoping, exposure limits,
/// session diversity constraints, and scoring weights for question selection.
///
/// Educational Safety Invariants:
/// - Target question count must be strictly positive (>= 1).
/// - All weights must be non-negative (>= 0.0) with total weight > 0.0.
/// - Diversity limits must be >= 1 when specified.
/// - NaN and Infinity values are strictly rejected.
library;

import 'package:meta/meta.dart';

@immutable
class AdaptiveQuestionSelectionConfig {
  /// Default requested question count per practice session.
  static const int defaultTargetQuestionCount = 10;

  /// Default maximum times a question can be presented to the learner.
  static const int defaultMaxExposureCount = 3;

  /// Default weight for observed learner weakness.
  static const double defaultWeaknessWeight = 0.35;

  /// Default weight for P32 historical PYQ priority.
  static const double defaultPyqPriorityWeight = 0.30;

  /// Default weight for question freshness / exposure decay.
  static const double defaultFreshnessWeight = 0.20;

  /// Default weight for target difficulty fit.
  static const double defaultDifficultyWeight = 0.10;

  /// Default weight for source provenance quality.
  static const double defaultQualityWeight = 0.05;

  /// Target exam identifier (e.g. 'upsc', 'bpsc', 'ssc').
  final String examId;

  /// Number of questions requested for the practice session.
  final int targetQuestionCount;

  /// Optional curriculum objective IDs to restrict selection scope.
  final List<String>? scopedObjectiveIds;

  /// Optional topic names to restrict selection scope.
  final List<String>? scopedTopics;

  /// Optional subject names to restrict selection scope.
  final List<String>? scopedSubjects;

  /// Optional desired difficulty level (e.g. 'Easy', 'Medium', 'Hard').
  final String? targetDifficulty;

  /// Maximum allowed questions for any single objective in this session.
  final int? maxQuestionsPerObjective;

  /// Maximum allowed questions for any single topic in this session.
  final int? maxQuestionsPerTopic;

  /// Maximum allowed questions from any single examination year in this session.
  final int? maxQuestionsPerYear;

  /// Maximum previous attempts allowed before a question is excluded.
  final int maxExposureCount;

  /// Minimum time that must elapse before an attempted question can be re-selected.
  final Duration? cooldownPeriod;

  /// If true, excludes all questions previously attempted by the learner.
  final bool excludePreviouslySeen;

  /// Raw weight for learner weakness.
  final double weaknessWeight;

  /// Raw weight for P32 historical priority.
  final double pyqPriorityWeight;

  /// Raw weight for question freshness.
  final double freshnessWeight;

  /// Raw weight for difficulty fit.
  final double difficultyWeight;

  /// Raw weight for source provenance quality.
  final double qualityWeight;

  /// Normalized weight for learner weakness [0.0, 1.0].
  final double normalizedWeaknessWeight;

  /// Normalized weight for P32 historical priority [0.0, 1.0].
  final double normalizedPyqPriorityWeight;

  /// Normalized weight for question freshness [0.0, 1.0].
  final double normalizedFreshnessWeight;

  /// Normalized weight for difficulty fit [0.0, 1.0].
  final double normalizedDifficultyWeight;

  /// Normalized weight for source quality [0.0, 1.0].
  final double normalizedQualityWeight;

  AdaptiveQuestionSelectionConfig({
    required String examId,
    this.targetQuestionCount = defaultTargetQuestionCount,
    List<String>? scopedObjectiveIds,
    List<String>? scopedTopics,
    List<String>? scopedSubjects,
    this.targetDifficulty,
    this.maxQuestionsPerObjective,
    this.maxQuestionsPerTopic,
    this.maxQuestionsPerYear,
    this.maxExposureCount = defaultMaxExposureCount,
    this.cooldownPeriod,
    this.excludePreviouslySeen = false,
    this.weaknessWeight = defaultWeaknessWeight,
    this.pyqPriorityWeight = defaultPyqPriorityWeight,
    this.freshnessWeight = defaultFreshnessWeight,
    this.difficultyWeight = defaultDifficultyWeight,
    this.qualityWeight = defaultQualityWeight,
  })  : examId = examId.trim().toLowerCase(),
        scopedObjectiveIds = scopedObjectiveIds != null
            ? List<String>.unmodifiable(scopedObjectiveIds)
            : null,
        scopedTopics = scopedTopics != null
            ? List<String>.unmodifiable(scopedTopics)
            : null,
        scopedSubjects = scopedSubjects != null
            ? List<String>.unmodifiable(scopedSubjects)
            : null,
        normalizedWeaknessWeight = _computeNormalized(
          weaknessWeight,
          weaknessWeight +
              pyqPriorityWeight +
              freshnessWeight +
              difficultyWeight +
              qualityWeight,
        ),
        normalizedPyqPriorityWeight = _computeNormalized(
          pyqPriorityWeight,
          weaknessWeight +
              pyqPriorityWeight +
              freshnessWeight +
              difficultyWeight +
              qualityWeight,
        ),
        normalizedFreshnessWeight = _computeNormalized(
          freshnessWeight,
          weaknessWeight +
              pyqPriorityWeight +
              freshnessWeight +
              difficultyWeight +
              qualityWeight,
        ),
        normalizedDifficultyWeight = _computeNormalized(
          difficultyWeight,
          weaknessWeight +
              pyqPriorityWeight +
              freshnessWeight +
              difficultyWeight +
              qualityWeight,
        ),
        normalizedQualityWeight = _computeNormalized(
          qualityWeight,
          weaknessWeight +
              pyqPriorityWeight +
              freshnessWeight +
              difficultyWeight +
              qualityWeight,
        ) {
    if (examId.trim().isEmpty) {
      throw ArgumentError('examId cannot be empty for question selection');
    }
    if (targetQuestionCount < 1) {
      throw ArgumentError(
          'targetQuestionCount must be >= 1 (got $targetQuestionCount)');
    }
    if (maxExposureCount < 0) {
      throw ArgumentError(
          'maxExposureCount cannot be negative (got $maxExposureCount)');
    }
    if (cooldownPeriod != null && cooldownPeriod!.isNegative) {
      throw ArgumentError('cooldownPeriod cannot be negative');
    }
    if (maxQuestionsPerObjective != null && maxQuestionsPerObjective! < 1) {
      throw ArgumentError(
          'maxQuestionsPerObjective must be >= 1 (got $maxQuestionsPerObjective)');
    }
    if (maxQuestionsPerTopic != null && maxQuestionsPerTopic! < 1) {
      throw ArgumentError(
          'maxQuestionsPerTopic must be >= 1 (got $maxQuestionsPerTopic)');
    }
    if (maxQuestionsPerYear != null && maxQuestionsPerYear! < 1) {
      throw ArgumentError(
          'maxQuestionsPerYear must be >= 1 (got $maxQuestionsPerYear)');
    }
    if (weaknessWeight < 0.0 ||
        weaknessWeight.isNaN ||
        weaknessWeight.isInfinite) {
      throw ArgumentError('weaknessWeight must be non-negative and finite');
    }
    if (pyqPriorityWeight < 0.0 ||
        pyqPriorityWeight.isNaN ||
        pyqPriorityWeight.isInfinite) {
      throw ArgumentError('pyqPriorityWeight must be non-negative and finite');
    }
    if (freshnessWeight < 0.0 ||
        freshnessWeight.isNaN ||
        freshnessWeight.isInfinite) {
      throw ArgumentError('freshnessWeight must be non-negative and finite');
    }
    if (difficultyWeight < 0.0 ||
        difficultyWeight.isNaN ||
        difficultyWeight.isInfinite) {
      throw ArgumentError('difficultyWeight must be non-negative and finite');
    }
    if (qualityWeight < 0.0 ||
        qualityWeight.isNaN ||
        qualityWeight.isInfinite) {
      throw ArgumentError('qualityWeight must be non-negative and finite');
    }

    final total = weaknessWeight +
        pyqPriorityWeight +
        freshnessWeight +
        difficultyWeight +
        qualityWeight;
    if (total <= 0.0 || total.isNaN || total.isInfinite) {
      throw ArgumentError('Total weight must be strictly positive and finite');
    }
  }

  static double _computeNormalized(double part, double total) {
    if (total <= 0.0 || total.isNaN || total.isInfinite) return 0.0;
    return (part / total).clamp(0.0, 1.0);
  }

  AdaptiveQuestionSelectionConfig copyWith({
    String? examId,
    int? targetQuestionCount,
    List<String>? scopedObjectiveIds,
    List<String>? scopedTopics,
    List<String>? scopedSubjects,
    String? targetDifficulty,
    int? maxQuestionsPerObjective,
    int? maxQuestionsPerTopic,
    int? maxQuestionsPerYear,
    int? maxExposureCount,
    Duration? cooldownPeriod,
    bool? excludePreviouslySeen,
    double? weaknessWeight,
    double? pyqPriorityWeight,
    double? freshnessWeight,
    double? difficultyWeight,
    double? qualityWeight,
  }) {
    return AdaptiveQuestionSelectionConfig(
      examId: examId ?? this.examId,
      targetQuestionCount: targetQuestionCount ?? this.targetQuestionCount,
      scopedObjectiveIds: scopedObjectiveIds ?? this.scopedObjectiveIds,
      scopedTopics: scopedTopics ?? this.scopedTopics,
      scopedSubjects: scopedSubjects ?? this.scopedSubjects,
      targetDifficulty: targetDifficulty ?? this.targetDifficulty,
      maxQuestionsPerObjective:
          maxQuestionsPerObjective ?? this.maxQuestionsPerObjective,
      maxQuestionsPerTopic: maxQuestionsPerTopic ?? this.maxQuestionsPerTopic,
      maxQuestionsPerYear: maxQuestionsPerYear ?? this.maxQuestionsPerYear,
      maxExposureCount: maxExposureCount ?? this.maxExposureCount,
      cooldownPeriod: cooldownPeriod ?? this.cooldownPeriod,
      excludePreviouslySeen:
          excludePreviouslySeen ?? this.excludePreviouslySeen,
      weaknessWeight: weaknessWeight ?? this.weaknessWeight,
      pyqPriorityWeight: pyqPriorityWeight ?? this.pyqPriorityWeight,
      freshnessWeight: freshnessWeight ?? this.freshnessWeight,
      difficultyWeight: difficultyWeight ?? this.difficultyWeight,
      qualityWeight: qualityWeight ?? this.qualityWeight,
    );
  }

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'targetQuestionCount': targetQuestionCount,
        if (scopedObjectiveIds != null)
          'scopedObjectiveIds': scopedObjectiveIds,
        if (scopedTopics != null) 'scopedTopics': scopedTopics,
        if (scopedSubjects != null) 'scopedSubjects': scopedSubjects,
        if (targetDifficulty != null) 'targetDifficulty': targetDifficulty,
        if (maxQuestionsPerObjective != null)
          'maxQuestionsPerObjective': maxQuestionsPerObjective,
        if (maxQuestionsPerTopic != null)
          'maxQuestionsPerTopic': maxQuestionsPerTopic,
        if (maxQuestionsPerYear != null)
          'maxQuestionsPerYear': maxQuestionsPerYear,
        'maxExposureCount': maxExposureCount,
        if (cooldownPeriod != null)
          'cooldownPeriodMillis': cooldownPeriod!.inMilliseconds,
        'excludePreviouslySeen': excludePreviouslySeen,
        'weaknessWeight': weaknessWeight,
        'pyqPriorityWeight': pyqPriorityWeight,
        'freshnessWeight': freshnessWeight,
        'difficultyWeight': difficultyWeight,
        'qualityWeight': qualityWeight,
      };

  factory AdaptiveQuestionSelectionConfig.fromJson(Map<String, dynamic> json) =>
      AdaptiveQuestionSelectionConfig(
        examId: json['examId'] as String? ?? 'upsc',
        targetQuestionCount: (json['targetQuestionCount'] as num?)?.toInt() ??
            defaultTargetQuestionCount,
        scopedObjectiveIds: (json['scopedObjectiveIds'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        scopedTopics:
            (json['scopedTopics'] as List?)?.map((e) => e.toString()).toList(),
        scopedSubjects: (json['scopedSubjects'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        targetDifficulty: json['targetDifficulty'] as String?,
        maxQuestionsPerObjective:
            (json['maxQuestionsPerObjective'] as num?)?.toInt(),
        maxQuestionsPerTopic: (json['maxQuestionsPerTopic'] as num?)?.toInt(),
        maxQuestionsPerYear: (json['maxQuestionsPerYear'] as num?)?.toInt(),
        maxExposureCount: (json['maxExposureCount'] as num?)?.toInt() ??
            defaultMaxExposureCount,
        cooldownPeriod: json['cooldownPeriodMillis'] != null
            ? Duration(
                milliseconds: (json['cooldownPeriodMillis'] as num).toInt())
            : null,
        excludePreviouslySeen: json['excludePreviouslySeen'] as bool? ?? false,
        weaknessWeight: (json['weaknessWeight'] as num?)?.toDouble() ??
            defaultWeaknessWeight,
        pyqPriorityWeight: (json['pyqPriorityWeight'] as num?)?.toDouble() ??
            defaultPyqPriorityWeight,
        freshnessWeight: (json['freshnessWeight'] as num?)?.toDouble() ??
            defaultFreshnessWeight,
        difficultyWeight: (json['difficultyWeight'] as num?)?.toDouble() ??
            defaultDifficultyWeight,
        qualityWeight:
            (json['qualityWeight'] as num?)?.toDouble() ?? defaultQualityWeight,
      );
}
