/// Recommendation Effectiveness Entity (TITAN-KO-022.0 P22).
///
/// Immutable domain model/value object capturing the observed execution and
/// post-recommendation performance evaluation.
///
/// Educational Safety Principles:
/// - Represents strictly observed performance differences ([observedPerformanceDelta]),
///   never causal learning improvement, mastery attainment, or exam readiness.
/// - Preserves nullable semantics for unmeasured baseline or follow-up attempts.
/// - Marks [insufficientEvidence] as true when attempts are zero or baseline is unknown.
/// - Zero-denominator safety is enforced across all metric calculations.
library;

import 'package:meta/meta.dart';

/// Categorization of observed performance outcome.
enum EffectivenessCategory {
  /// Observed follow-up accuracy is measurably higher than baseline.
  observedImprovement,

  /// Observed follow-up accuracy is measurably lower than baseline.
  observedDecline,

  /// Observed follow-up accuracy shows no measurable difference from baseline.
  noMeasurableChange,

  /// Baseline or follow-up evidence is missing or insufficient to draw a conclusion.
  insufficientEvidence;
}

@immutable
class RecommendationEffectiveness {
  /// Default significance threshold for classifying performance differences.
  static const double defaultDeltaThreshold = 0.001;

  /// Target [RecommendationInstance.instanceId] evaluated.
  final String instanceId;

  /// Target P17 Learning Objective identifier.
  final String objectiveId;

  /// Target learner identifier.
  final String learnerId;

  /// Observed P18 baseline accuracy prior to recommendation issuance,
  /// or null if no baseline attempts were recorded.
  final double? baselineAccuracy;

  /// Total number of baseline attempts prior to recommendation issuance.
  final int baselineAttemptsCount;

  /// Observed follow-up accuracy after recommendation execution,
  /// or null if no follow-up attempts were recorded.
  final double? followUpAccuracy;

  /// Total number of follow-up attempts recorded.
  final int followUpAttemptsCount;

  /// Observed difference in accuracy (`followUpAccuracy - baselineAccuracy`),
  /// or null if either baseline or follow-up accuracy is unavailable.
  final double? observedPerformanceDelta;

  /// Whether evidence is insufficient to evaluate effectiveness reliably
  /// (e.g. zero baseline attempts, zero follow-up attempts, or missing outcome).
  final bool insufficientEvidence;

  /// Duration window during which follow-up attempts were evaluated.
  final Duration measurementWindow;

  /// UTC timestamp when this effectiveness evaluation was performed.
  final DateTime evaluatedAt;

  /// Immutable diagnostic metadata.
  final Map<String, dynamic> metadata;

  RecommendationEffectiveness({
    required this.instanceId,
    required this.objectiveId,
    required this.learnerId,
    double? baselineAccuracy,
    required this.baselineAttemptsCount,
    double? followUpAccuracy,
    required this.followUpAttemptsCount,
    double? observedPerformanceDelta,
    bool? insufficientEvidence,
    this.measurementWindow = const Duration(days: 7),
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  })  : baselineAccuracy = baselineAccuracy?.clamp(0.0, 1.0),
        followUpAccuracy = followUpAccuracy?.clamp(0.0, 1.0),
        observedPerformanceDelta =
            (baselineAccuracy != null && followUpAccuracy != null)
                ? (observedPerformanceDelta ??
                    (followUpAccuracy.clamp(0.0, 1.0) -
                        baselineAccuracy.clamp(0.0, 1.0)))
                : null,
        insufficientEvidence = insufficientEvidence ??
            (baselineAccuracy == null ||
                followUpAccuracy == null ||
                baselineAttemptsCount == 0 ||
                followUpAttemptsCount == 0),
        evaluatedAt = evaluatedAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (instanceId.trim().isEmpty) {
      throw ArgumentError('instanceId cannot be empty');
    }
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError('objectiveId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (baselineAttemptsCount < 0) {
      throw ArgumentError(
        'baselineAttemptsCount cannot be negative (got $baselineAttemptsCount)',
      );
    }
    if (followUpAttemptsCount < 0) {
      throw ArgumentError(
        'followUpAttemptsCount cannot be negative (got $followUpAttemptsCount)',
      );
    }
    if (measurementWindow.isNegative) {
      throw ArgumentError('measurementWindow cannot be negative');
    }
  }

  /// Categorizes the observed outcome based on [observedPerformanceDelta]
  /// and [deltaThreshold].
  EffectivenessCategory get category =>
      categorize(deltaThreshold: defaultDeltaThreshold);

  /// Categorizes the observed outcome using a custom [deltaThreshold].
  EffectivenessCategory categorize({
    double deltaThreshold = defaultDeltaThreshold,
  }) {
    if (insufficientEvidence || observedPerformanceDelta == null) {
      return EffectivenessCategory.insufficientEvidence;
    }
    final delta = observedPerformanceDelta!;
    if (delta > deltaThreshold) {
      return EffectivenessCategory.observedImprovement;
    } else if (delta < -deltaThreshold) {
      return EffectivenessCategory.observedDecline;
    } else {
      return EffectivenessCategory.noMeasurableChange;
    }
  }

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'objectiveId': objectiveId,
        'learnerId': learnerId,
        if (baselineAccuracy != null) 'baselineAccuracy': baselineAccuracy,
        'baselineAttemptsCount': baselineAttemptsCount,
        if (followUpAccuracy != null) 'followUpAccuracy': followUpAccuracy,
        'followUpAttemptsCount': followUpAttemptsCount,
        if (observedPerformanceDelta != null)
          'observedPerformanceDelta': observedPerformanceDelta,
        'insufficientEvidence': insufficientEvidence,
        'measurementWindowDays': measurementWindow.inDays,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory RecommendationEffectiveness.fromJson(Map<String, dynamic> json) =>
      RecommendationEffectiveness(
        instanceId: json['instanceId'] as String? ?? '',
        objectiveId: json['objectiveId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        baselineAccuracy: (json['baselineAccuracy'] as num?)?.toDouble(),
        baselineAttemptsCount: json['baselineAttemptsCount'] as int? ?? 0,
        followUpAccuracy: (json['followUpAccuracy'] as num?)?.toDouble(),
        followUpAttemptsCount: json['followUpAttemptsCount'] as int? ?? 0,
        observedPerformanceDelta:
            (json['observedPerformanceDelta'] as num?)?.toDouble(),
        insufficientEvidence: json['insufficientEvidence'] as bool?,
        measurementWindow: Duration(
          days: json['measurementWindowDays'] as int? ?? 7,
        ),
        evaluatedAt: DateTime.parse(json['evaluatedAt'] as String).toUtc(),
        metadata:
            Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationEffectiveness &&
          instanceId == other.instanceId &&
          objectiveId == other.objectiveId &&
          learnerId == other.learnerId &&
          baselineAccuracy == other.baselineAccuracy &&
          baselineAttemptsCount == other.baselineAttemptsCount &&
          followUpAccuracy == other.followUpAccuracy &&
          followUpAttemptsCount == other.followUpAttemptsCount &&
          observedPerformanceDelta == other.observedPerformanceDelta &&
          insufficientEvidence == other.insufficientEvidence &&
          measurementWindow == other.measurementWindow &&
          evaluatedAt == other.evaluatedAt;

  @override
  int get hashCode => Object.hash(
        instanceId,
        objectiveId,
        learnerId,
        baselineAccuracy,
        baselineAttemptsCount,
        followUpAccuracy,
        followUpAttemptsCount,
        observedPerformanceDelta,
        insufficientEvidence,
        measurementWindow,
        evaluatedAt,
      );

  @override
  String toString() =>
      'RecommendationEffectiveness(instance: $instanceId, category: $category, delta: $observedPerformanceDelta, insufficient: $insufficientEvidence)';
}
