/// Bloom Mastery Distribution Entity (TITAN-KO-023.0 P23).
///
/// Immutable domain model capturing the observed performance, attempt counts,
/// and mastery metrics distributed across Bloom's Taxonomy cognitive complexity levels.
///
/// Educational Safety Principles:
/// - Reuses existing [BloomTaxonomyLevel] definitions without creating parallel taxonomy enums.
/// - Explicitly distinguishes levels with zero evidence ([hasSufficientEvidence] == false, null accuracy)
///   from levels with observed poor performance.
/// - Enforces zero-denominator safety across all level ratios.
library;

import 'package:meta/meta.dart';

import 'bloom_taxonomy_level.dart';

/// Performance and completion metrics for a single [BloomTaxonomyLevel].
@immutable
class BloomLevelMetric {
  /// Default minimum attempt count required for sufficient evidence at an individual Bloom level.
  static const int defaultLevelEvidenceThreshold = 3;

  /// Target cognitive complexity level.
  final BloomTaxonomyLevel level;

  /// Count of canonical learning objectives at this Bloom level.
  final int totalObjectivesCount;

  /// Count of learning objectives at this Bloom level with at least 1 attempt.
  final int attemptedObjectivesCount;

  /// Count of learning objectives at this Bloom level marked `achieved`.
  final int achievedObjectivesCount;

  /// Total question attempts submitted for objectives at this Bloom level.
  final int totalAttemptsCount;

  /// Total correct question attempts submitted for objectives at this Bloom level.
  final int totalCorrectCount;

  /// Observed raw accuracy ratio in range [0.0, 1.0],
  /// or null if zero attempts were submitted at this Bloom level.
  final double? observedAccuracy;

  /// Whether sufficient evidence exists to evaluate performance at this level.
  final bool hasSufficientEvidence;

  /// Minimum attempt threshold used to determine evidence sufficiency.
  final int minimumEvidenceThreshold;

  BloomLevelMetric({
    required this.level,
    required this.totalObjectivesCount,
    required this.attemptedObjectivesCount,
    required this.achievedObjectivesCount,
    required this.totalAttemptsCount,
    required this.totalCorrectCount,
    double? observedAccuracy,
    bool? hasSufficientEvidence,
    this.minimumEvidenceThreshold = defaultLevelEvidenceThreshold,
  })  : observedAccuracy = totalAttemptsCount == 0
            ? null
            : (observedAccuracy ??
                    (totalCorrectCount / totalAttemptsCount).clamp(0.0, 1.0))
                .clamp(0.0, 1.0),
        hasSufficientEvidence = hasSufficientEvidence ??
            (totalAttemptsCount >= minimumEvidenceThreshold &&
                attemptedObjectivesCount > 0) {
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

  /// Ratio of achieved objectives to total objectives at this Bloom level in range [0.0, 1.0].
  double get achievementRatio => totalObjectivesCount == 0
      ? 0.0
      : (achievedObjectivesCount / totalObjectivesCount).clamp(0.0, 1.0);

  /// Ratio of attempted objectives to total objectives at this Bloom level in range [0.0, 1.0].
  double get coverageRatio => totalObjectivesCount == 0
      ? 0.0
      : (attemptedObjectivesCount / totalObjectivesCount).clamp(0.0, 1.0);

  /// Serializes level metric to JSON map.
  Map<String, dynamic> toJson() => {
        'level': level.name,
        'totalObjectivesCount': totalObjectivesCount,
        'attemptedObjectivesCount': attemptedObjectivesCount,
        'achievedObjectivesCount': achievedObjectivesCount,
        'totalAttemptsCount': totalAttemptsCount,
        'totalCorrectCount': totalCorrectCount,
        if (observedAccuracy != null) 'observedAccuracy': observedAccuracy,
        'hasSufficientEvidence': hasSufficientEvidence,
        'minimumEvidenceThreshold': minimumEvidenceThreshold,
      };

  /// Deserializes level metric from JSON map.
  factory BloomLevelMetric.fromJson(Map<String, dynamic> json) =>
      BloomLevelMetric(
        level: BloomTaxonomyLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => BloomTaxonomyLevel.understand,
        ),
        totalObjectivesCount: json['totalObjectivesCount'] as int? ?? 0,
        attemptedObjectivesCount: json['attemptedObjectivesCount'] as int? ?? 0,
        achievedObjectivesCount: json['achievedObjectivesCount'] as int? ?? 0,
        totalAttemptsCount: json['totalAttemptsCount'] as int? ?? 0,
        totalCorrectCount: json['totalCorrectCount'] as int? ?? 0,
        observedAccuracy: (json['observedAccuracy'] as num?)?.toDouble(),
        hasSufficientEvidence: json['hasSufficientEvidence'] as bool?,
        minimumEvidenceThreshold: json['minimumEvidenceThreshold'] as int? ??
            defaultLevelEvidenceThreshold,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BloomLevelMetric &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          totalObjectivesCount == other.totalObjectivesCount &&
          attemptedObjectivesCount == other.attemptedObjectivesCount &&
          achievedObjectivesCount == other.achievedObjectivesCount &&
          totalAttemptsCount == other.totalAttemptsCount &&
          totalCorrectCount == other.totalCorrectCount &&
          observedAccuracy == other.observedAccuracy &&
          hasSufficientEvidence == other.hasSufficientEvidence &&
          minimumEvidenceThreshold == other.minimumEvidenceThreshold;

  @override
  int get hashCode => Object.hash(
        level,
        totalObjectivesCount,
        attemptedObjectivesCount,
        achievedObjectivesCount,
        totalAttemptsCount,
        totalCorrectCount,
        observedAccuracy,
        hasSufficientEvidence,
        minimumEvidenceThreshold,
      );

  @override
  String toString() =>
      'BloomLevelMetric(${level.name}: attempts=$totalAttemptsCount, '
      'accuracy=${observedAccuracy?.toStringAsFixed(2) ?? "none"}, '
      'achieved=$achievedObjectivesCount/$totalObjectivesCount)';
}

/// Distribution of observed cognitive performance across all Bloom's Taxonomy levels.
@immutable
class BloomMasteryDistribution {
  /// Target learner identifier.
  final String learnerId;

  /// Optional curriculum scope identifier (e.g. domain ID or framework ID).
  final String? scopeId;

  /// Unmodifiable map of performance metrics per [BloomTaxonomyLevel].
  final Map<BloomTaxonomyLevel, BloomLevelMetric> levels;

  /// UTC timestamp when this distribution was evaluated.
  final DateTime calculatedAt;

  /// Immutable diagnostic metadata.
  final Map<String, dynamic> metadata;

  BloomMasteryDistribution({
    required this.learnerId,
    this.scopeId,
    required Map<BloomTaxonomyLevel, BloomLevelMetric> levels,
    required DateTime calculatedAt,
    Map<String, dynamic>? metadata,
  })  : levels = Map<BloomTaxonomyLevel, BloomLevelMetric>.unmodifiable(levels),
        calculatedAt = calculatedAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError(
          'LearnerId cannot be empty for BloomMasteryDistribution');
    }
  }

  /// Looks up the metric for a specific Bloom level, or returns null if not recorded.
  BloomLevelMetric? getMetric(BloomTaxonomyLevel level) => levels[level];

  /// Looks up observed accuracy for a specific Bloom level, or null if no attempts exist.
  double? getAccuracy(BloomTaxonomyLevel level) =>
      levels[level]?.observedAccuracy;

  /// Aggregate count of attempts across all Bloom levels.
  int get totalAttemptsAcrossAllLevels =>
      levels.values.fold(0, (sum, m) => sum + m.totalAttemptsCount);

  /// Aggregate count of correct attempts across all Bloom levels.
  int get totalCorrectAcrossAllLevels =>
      levels.values.fold(0, (sum, m) => sum + m.totalCorrectCount);

  /// Overall aggregate accuracy across all recorded Bloom levels in range [0.0, 1.0],
  /// or null if zero attempts exist across all levels.
  double? get overallAccuracy => totalAttemptsAcrossAllLevels == 0
      ? null
      : (totalCorrectAcrossAllLevels / totalAttemptsAcrossAllLevels)
          .clamp(0.0, 1.0);

  /// Serializes distribution to JSON map.
  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        if (scopeId != null) 'scopeId': scopeId,
        'levels': levels.map(
          (key, value) => MapEntry(key.name, value.toJson()),
        ),
        'calculatedAt': calculatedAt.toIso8601String(),
        'metadata': metadata,
      };

  /// Deserializes distribution from JSON map.
  factory BloomMasteryDistribution.fromJson(Map<String, dynamic> json) {
    final rawLevels = json['levels'] as Map<String, dynamic>? ?? {};
    final parsedLevels = <BloomTaxonomyLevel, BloomLevelMetric>{};

    for (final entry in rawLevels.entries) {
      final level = BloomTaxonomyLevel.values.firstWhere(
        (e) => e.name == entry.key,
        orElse: () => BloomTaxonomyLevel.understand,
      );
      parsedLevels[level] = BloomLevelMetric.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    return BloomMasteryDistribution(
      learnerId: json['learnerId'] as String? ?? '',
      scopeId: json['scopeId'] as String?,
      levels: parsedLevels,
      calculatedAt: json['calculatedAt'] != null
          ? DateTime.parse(json['calculatedAt'] as String).toUtc()
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      metadata: json['metadata'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BloomMasteryDistribution ||
        runtimeType != other.runtimeType ||
        learnerId != other.learnerId ||
        scopeId != other.scopeId ||
        calculatedAt != other.calculatedAt ||
        levels.length != other.levels.length) {
      return false;
    }
    for (final key in levels.keys) {
      if (other.levels[key] != levels[key]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    var levelsHash = 0;
    for (final entry in levels.entries) {
      levelsHash ^= Object.hash(entry.key, entry.value);
    }
    return Object.hash(
      learnerId,
      scopeId,
      levelsHash,
      calculatedAt,
    );
  }

  @override
  String toString() =>
      'BloomMasteryDistribution(learnerId: $learnerId, scopeId: $scopeId, '
      'levelsCount: ${levels.length}, totalAttempts: $totalAttemptsAcrossAllLevels)';
}
