/// Domain Mastery Profile Entity (TITAN-KO-023.0 P23).
///
/// Immutable domain model capturing the aggregated observed learning evidence,
/// objective completion counts, and Bloom-weighted mastery metrics for ONE
/// curriculum domain for ONE learner.
///
/// Educational Safety Principles:
/// - Represents strictly observed performance metrics ([observedAccuracy], [observedMasteryScore]).
/// - Distinguishes lack of evidence ([hasSufficientEvidence] == false, null scores)
///   from observed low performance (e.g. accuracy = 0.20 with 10 attempts).
/// - If zero attempts are recorded, [observedAccuracy] and [observedMasteryScore]
///   are null rather than 0.0.
/// - Zero-denominator safety is enforced across all ratio calculations.
library;

import 'package:meta/meta.dart';

import 'bloom_mastery_distribution.dart';

@immutable
class DomainMasteryProfile {
  /// Default minimum attempt count required to consider domain evidence statistically sufficient.
  static const int defaultEvidenceThreshold = 5;

  /// Target curriculum domain identifier (e.g., `pol_domain_fr`).
  final String domainId;

  /// Target learner identifier.
  final String learnerId;

  /// Total count of canonical learning objectives contained in this domain.
  final int totalObjectivesCount;

  /// Number of learning objectives in this domain with at least 1 recorded attempt.
  final int attemptedObjectivesCount;

  /// Number of learning objectives in this domain that have met mastery criteria (`achieved`).
  final int achievedObjectivesCount;

  /// Aggregate count of question attempts submitted across all objectives in this domain.
  final int totalAttemptsCount;

  /// Aggregate count of correct question attempts across all objectives in this domain.
  final int totalCorrectCount;

  /// Observed raw accuracy ratio in range [0.0, 1.0],
  /// or null if zero attempts were submitted for this domain.
  final double? observedAccuracy;

  /// Observed mastery score in range [0.0, 1.0],
  /// or null if evidence is insufficient.
  final double? observedMasteryScore;

  /// Whether the learner has accumulated sufficient evidence in this domain
  /// (e.g. [totalAttemptsCount] >= [minimumEvidenceThreshold]).
  final bool hasSufficientEvidence;

  /// Minimum attempts required for sufficient evidence in this evaluation.
  final int minimumEvidenceThreshold;

  /// Optional breakdown of performance across Bloom's taxonomy cognitive levels.
  final BloomMasteryDistribution? bloomDistribution;

  /// Unmodifiable list of canonical learning objective identifiers belonging to this domain.
  final List<String> supportingObjectiveIds;

  /// UTC timestamp when this domain mastery profile was calculated.
  final DateTime calculatedAt;

  /// Immutable diagnostic metadata.
  final Map<String, dynamic> metadata;

  DomainMasteryProfile({
    required this.domainId,
    required this.learnerId,
    required this.totalObjectivesCount,
    required this.attemptedObjectivesCount,
    required this.achievedObjectivesCount,
    required this.totalAttemptsCount,
    required this.totalCorrectCount,
    double? observedAccuracy,
    double? observedMasteryScore,
    bool? hasSufficientEvidence,
    this.minimumEvidenceThreshold = defaultEvidenceThreshold,
    this.bloomDistribution,
    List<String>? supportingObjectiveIds,
    required DateTime calculatedAt,
    Map<String, dynamic>? metadata,
  })  : calculatedAt = calculatedAt.toUtc(),
        supportingObjectiveIds = List<String>.unmodifiable(
            supportingObjectiveIds ?? const <String>[]),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}),
        observedAccuracy = totalAttemptsCount == 0
            ? null
            : (observedAccuracy ??
                    (totalCorrectCount / totalAttemptsCount).clamp(0.0, 1.0))
                .clamp(0.0, 1.0),
        observedMasteryScore = totalAttemptsCount == 0
            ? null
            : (observedMasteryScore?.clamp(0.0, 1.0)),
        hasSufficientEvidence = hasSufficientEvidence ??
            (totalAttemptsCount >= minimumEvidenceThreshold &&
                attemptedObjectivesCount > 0) {
    if (domainId.trim().isEmpty) {
      throw ArgumentError('DomainId cannot be empty for DomainMasteryProfile');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty for DomainMasteryProfile');
    }
    if (totalObjectivesCount < 0) {
      throw ArgumentError('TotalObjectivesCount cannot be negative');
    }
    if (attemptedObjectivesCount < 0 ||
        attemptedObjectivesCount > totalObjectivesCount) {
      throw ArgumentError(
          'AttemptedObjectivesCount ($attemptedObjectivesCount) must be between 0 and totalObjectivesCount ($totalObjectivesCount)');
    }
    if (achievedObjectivesCount < 0 ||
        achievedObjectivesCount > attemptedObjectivesCount) {
      throw ArgumentError(
          'AchievedObjectivesCount ($achievedObjectivesCount) must be between 0 and attemptedObjectivesCount ($attemptedObjectivesCount)');
    }
    if (totalAttemptsCount < 0) {
      throw ArgumentError('TotalAttemptsCount cannot be negative');
    }
    if (totalCorrectCount < 0 || totalCorrectCount > totalAttemptsCount) {
      throw ArgumentError(
          'TotalCorrectCount ($totalCorrectCount) must be between 0 and totalAttemptsCount ($totalAttemptsCount)');
    }
    if (minimumEvidenceThreshold < 1) {
      throw ArgumentError('MinimumEvidenceThreshold must be at least 1');
    }
  }

  /// Ratio of achieved objectives to total objectives in range [0.0, 1.0].
  /// Safely returns 0.0 if [totalObjectivesCount] is zero.
  double get achievementRatio => totalObjectivesCount == 0
      ? 0.0
      : (achievedObjectivesCount / totalObjectivesCount).clamp(0.0, 1.0);

  /// Ratio of attempted objectives to total objectives in range [0.0, 1.0].
  /// Safely returns 0.0 if [totalObjectivesCount] is zero.
  double get coverageRatio => totalObjectivesCount == 0
      ? 0.0
      : (attemptedObjectivesCount / totalObjectivesCount).clamp(0.0, 1.0);

  /// Number of objectives in this domain that remain unattempted.
  int get unattemptedObjectivesCount =>
      totalObjectivesCount - attemptedObjectivesCount;

  /// Serializes profile to JSON map.
  Map<String, dynamic> toJson() => {
        'domainId': domainId,
        'learnerId': learnerId,
        'totalObjectivesCount': totalObjectivesCount,
        'attemptedObjectivesCount': attemptedObjectivesCount,
        'achievedObjectivesCount': achievedObjectivesCount,
        'totalAttemptsCount': totalAttemptsCount,
        'totalCorrectCount': totalCorrectCount,
        if (observedAccuracy != null) 'observedAccuracy': observedAccuracy,
        if (observedMasteryScore != null)
          'observedMasteryScore': observedMasteryScore,
        'hasSufficientEvidence': hasSufficientEvidence,
        'minimumEvidenceThreshold': minimumEvidenceThreshold,
        if (bloomDistribution != null)
          'bloomDistribution': bloomDistribution!.toJson(),
        'supportingObjectiveIds': supportingObjectiveIds,
        'calculatedAt': calculatedAt.toIso8601String(),
        'metadata': metadata,
      };

  /// Deserializes profile from JSON map.
  factory DomainMasteryProfile.fromJson(Map<String, dynamic> json) =>
      DomainMasteryProfile(
        domainId: json['domainId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        totalObjectivesCount: json['totalObjectivesCount'] as int? ?? 0,
        attemptedObjectivesCount: json['attemptedObjectivesCount'] as int? ?? 0,
        achievedObjectivesCount: json['achievedObjectivesCount'] as int? ?? 0,
        totalAttemptsCount: json['totalAttemptsCount'] as int? ?? 0,
        totalCorrectCount: json['totalCorrectCount'] as int? ?? 0,
        observedAccuracy: (json['observedAccuracy'] as num?)?.toDouble(),
        observedMasteryScore:
            (json['observedMasteryScore'] as num?)?.toDouble(),
        hasSufficientEvidence: json['hasSufficientEvidence'] as bool?,
        minimumEvidenceThreshold: json['minimumEvidenceThreshold'] as int? ??
            defaultEvidenceThreshold,
        bloomDistribution: json['bloomDistribution'] != null
            ? BloomMasteryDistribution.fromJson(
                json['bloomDistribution'] as Map<String, dynamic>)
            : null,
        supportingObjectiveIds:
            (json['supportingObjectiveIds'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const <String>[],
        calculatedAt: json['calculatedAt'] != null
            ? DateTime.parse(json['calculatedAt'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        metadata: json['metadata'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainMasteryProfile &&
          runtimeType == other.runtimeType &&
          domainId == other.domainId &&
          learnerId == other.learnerId &&
          totalObjectivesCount == other.totalObjectivesCount &&
          attemptedObjectivesCount == other.attemptedObjectivesCount &&
          achievedObjectivesCount == other.achievedObjectivesCount &&
          totalAttemptsCount == other.totalAttemptsCount &&
          totalCorrectCount == other.totalCorrectCount &&
          observedAccuracy == other.observedAccuracy &&
          observedMasteryScore == other.observedMasteryScore &&
          hasSufficientEvidence == other.hasSufficientEvidence &&
          minimumEvidenceThreshold == other.minimumEvidenceThreshold &&
          calculatedAt == other.calculatedAt;

  @override
  int get hashCode => Object.hash(
        domainId,
        learnerId,
        totalObjectivesCount,
        attemptedObjectivesCount,
        achievedObjectivesCount,
        totalAttemptsCount,
        totalCorrectCount,
        observedAccuracy,
        observedMasteryScore,
        hasSufficientEvidence,
        minimumEvidenceThreshold,
        calculatedAt,
      );

  @override
  String toString() =>
      'DomainMasteryProfile(domainId: $domainId, learnerId: $learnerId, '
      'achieved: $achievedObjectivesCount/$totalObjectivesCount, '
      'accuracy: ${observedAccuracy?.toStringAsFixed(2) ?? "none"}, '
      'sufficientEvidence: $hasSufficientEvidence)';
}
