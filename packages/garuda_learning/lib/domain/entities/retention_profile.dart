/// Retention Profile Entity (TITAN-KO-023.0 P23 Stage 2).
///
/// Immutable domain model capturing the observed spaced repetition review telemetry,
/// review overdue counts, and memory retention health metrics for ONE learner.
///
/// Clean Architecture Boundary:
/// - P20 remains the sole owner of SM-2 scheduling, interval updates, and review queues.
/// - [RetentionProfile] is strictly a read-only analytical observer and aggregator.
///
/// Educational Safety Principles:
/// - Zero review evidence ([totalTrackedObjectives] == 0 or [activeReviewItemsCount] == 0)
///   is explicitly represented with null metric values and [hasSufficientEvidence] == false,
///   never as poor retention or memory decay.
/// - Zero-denominator safety ensures ratios default to 0.0 rather than NaN or Infinity.
/// - All normalized indices are strictly bounded in range [0.0, 1.0].
library;

import 'package:meta/meta.dart';

@immutable
class RetentionProfile {
  /// Default minimum count of active review items required for statistically sufficient evidence.
  static const int defaultEvidenceThreshold = 3;

  /// Target learner identifier.
  final String learnerId;

  /// Optional curriculum scope identifier (e.g. framework ID or domain ID).
  final String? scopeId;

  /// Total count of learning objectives currently tracked in the learner's spaced repetition schedule.
  final int totalTrackedObjectives;

  /// Count of tracked objectives that have had at least one completed review.
  final int activeReviewItemsCount;

  /// Count of tracked objectives that are overdue for review at [evaluatedAt].
  final int overdueItemsCount;

  /// Count of tracked objectives scheduled for future review at [evaluatedAt].
  final int upcomingItemsCount;

  /// Arithmetic mean of SM-2 ease factors across tracked objectives in range [1.3, 2.5],
  /// or null if zero objectives are tracked.
  final double? averageEaseFactor;

  /// Arithmetic mean of scheduled review intervals in days,
  /// or null if zero objectives are tracked.
  final double? averageIntervalDays;

  /// Observed ratio of satisfactory review attempts in range [0.0, 1.0],
  /// or null if zero review attempts have been recorded.
  final double? observedRetentionRate;

  /// Normalized composite retention stability score in range [0.0, 1.0],
  /// or null if evidence is insufficient.
  final double? projectedMemoryStability;

  /// Whether sufficient review evidence exists to produce reliable retention analytics.
  final bool hasSufficientEvidence;

  /// Minimum active review items threshold required for sufficient evidence.
  final int minimumEvidenceThreshold;

  /// UTC timestamp when this retention profile was calculated.
  final DateTime evaluatedAt;

  /// Immutable diagnostic metadata.
  final Map<String, dynamic> metadata;

  RetentionProfile({
    required this.learnerId,
    this.scopeId,
    required this.totalTrackedObjectives,
    required this.activeReviewItemsCount,
    required this.overdueItemsCount,
    int? upcomingItemsCount,
    double? averageEaseFactor,
    double? averageIntervalDays,
    double? observedRetentionRate,
    double? projectedMemoryStability,
    bool? hasSufficientEvidence,
    this.minimumEvidenceThreshold = defaultEvidenceThreshold,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  })  : upcomingItemsCount = upcomingItemsCount ??
            (totalTrackedObjectives - overdueItemsCount)
                .clamp(0, totalTrackedObjectives),
        averageEaseFactor = totalTrackedObjectives == 0
            ? null
            : averageEaseFactor?.clamp(1.3, 2.5),
        averageIntervalDays = totalTrackedObjectives == 0
            ? null
            : (averageIntervalDays != null && averageIntervalDays >= 0.0
                ? averageIntervalDays
                : null),
        observedRetentionRate = activeReviewItemsCount == 0
            ? null
            : (observedRetentionRate?.clamp(0.0, 1.0)),
        projectedMemoryStability = (totalTrackedObjectives == 0 ||
                activeReviewItemsCount < minimumEvidenceThreshold)
            ? null
            : (projectedMemoryStability?.clamp(0.0, 1.0)),
        hasSufficientEvidence = hasSufficientEvidence ??
            (totalTrackedObjectives > 0 &&
                activeReviewItemsCount >= minimumEvidenceThreshold),
        evaluatedAt = evaluatedAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty for RetentionProfile');
    }
    if (totalTrackedObjectives < 0) {
      throw ArgumentError('TotalTrackedObjectives cannot be negative');
    }
    if (activeReviewItemsCount < 0 ||
        activeReviewItemsCount > totalTrackedObjectives) {
      throw ArgumentError(
          'ActiveReviewItemsCount ($activeReviewItemsCount) must be between 0 and totalTrackedObjectives ($totalTrackedObjectives)');
    }
    if (overdueItemsCount < 0 || overdueItemsCount > totalTrackedObjectives) {
      throw ArgumentError(
          'OverdueItemsCount ($overdueItemsCount) must be between 0 and totalTrackedObjectives ($totalTrackedObjectives)');
    }
    if (this.upcomingItemsCount < 0) {
      throw ArgumentError('UpcomingItemsCount cannot be negative');
    }
    if (minimumEvidenceThreshold < 1) {
      throw ArgumentError('MinimumEvidenceThreshold must be at least 1');
    }
  }

  /// Ratio of overdue review items to total tracked objectives in range [0.0, 1.0].
  /// Safely defaults to 0.0 if [totalTrackedObjectives] is zero.
  double get overdueRatio => totalTrackedObjectives == 0
      ? 0.0
      : (overdueItemsCount / totalTrackedObjectives).clamp(0.0, 1.0);

  /// Whether the learner has zero overdue items and at least one active review item.
  bool get isReviewScheduleUpToDate =>
      totalTrackedObjectives > 0 && overdueItemsCount == 0;

  /// Serializes retention profile to JSON map.
  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        if (scopeId != null) 'scopeId': scopeId,
        'totalTrackedObjectives': totalTrackedObjectives,
        'activeReviewItemsCount': activeReviewItemsCount,
        'overdueItemsCount': overdueItemsCount,
        'upcomingItemsCount': upcomingItemsCount,
        if (averageEaseFactor != null) 'averageEaseFactor': averageEaseFactor,
        if (averageIntervalDays != null)
          'averageIntervalDays': averageIntervalDays,
        if (observedRetentionRate != null)
          'observedRetentionRate': observedRetentionRate,
        if (projectedMemoryStability != null)
          'projectedMemoryStability': projectedMemoryStability,
        'hasSufficientEvidence': hasSufficientEvidence,
        'minimumEvidenceThreshold': minimumEvidenceThreshold,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'metadata': metadata,
      };

  /// Deserializes retention profile from JSON map.
  factory RetentionProfile.fromJson(Map<String, dynamic> json) =>
      RetentionProfile(
        learnerId: json['learnerId'] as String? ?? '',
        scopeId: json['scopeId'] as String?,
        totalTrackedObjectives: json['totalTrackedObjectives'] as int? ?? 0,
        activeReviewItemsCount: json['activeReviewItemsCount'] as int? ?? 0,
        overdueItemsCount: json['overdueItemsCount'] as int? ?? 0,
        upcomingItemsCount: json['upcomingItemsCount'] as int?,
        averageEaseFactor: (json['averageEaseFactor'] as num?)?.toDouble(),
        averageIntervalDays: (json['averageIntervalDays'] as num?)?.toDouble(),
        observedRetentionRate:
            (json['observedRetentionRate'] as num?)?.toDouble(),
        projectedMemoryStability:
            (json['projectedMemoryStability'] as num?)?.toDouble(),
        hasSufficientEvidence: json['hasSufficientEvidence'] as bool?,
        minimumEvidenceThreshold: json['minimumEvidenceThreshold'] as int? ??
            defaultEvidenceThreshold,
        evaluatedAt: json['evaluatedAt'] != null
            ? DateTime.parse(json['evaluatedAt'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        metadata: json['metadata'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetentionProfile &&
          runtimeType == other.runtimeType &&
          learnerId == other.learnerId &&
          scopeId == other.scopeId &&
          totalTrackedObjectives == other.totalTrackedObjectives &&
          activeReviewItemsCount == other.activeReviewItemsCount &&
          overdueItemsCount == other.overdueItemsCount &&
          upcomingItemsCount == other.upcomingItemsCount &&
          averageEaseFactor == other.averageEaseFactor &&
          averageIntervalDays == other.averageIntervalDays &&
          observedRetentionRate == other.observedRetentionRate &&
          projectedMemoryStability == other.projectedMemoryStability &&
          hasSufficientEvidence == other.hasSufficientEvidence &&
          minimumEvidenceThreshold == other.minimumEvidenceThreshold &&
          evaluatedAt == other.evaluatedAt;

  @override
  int get hashCode => Object.hash(
        learnerId,
        scopeId,
        totalTrackedObjectives,
        activeReviewItemsCount,
        overdueItemsCount,
        upcomingItemsCount,
        averageEaseFactor,
        averageIntervalDays,
        observedRetentionRate,
        projectedMemoryStability,
        hasSufficientEvidence,
        minimumEvidenceThreshold,
        evaluatedAt,
      );

  @override
  String toString() =>
      'RetentionProfile(learnerId: $learnerId, tracked: $totalTrackedObjectives, '
      'overdue: $overdueItemsCount, retention: ${observedRetentionRate?.toStringAsFixed(2) ?? "none"}, '
      'sufficientEvidence: $hasSufficientEvidence)';
}
