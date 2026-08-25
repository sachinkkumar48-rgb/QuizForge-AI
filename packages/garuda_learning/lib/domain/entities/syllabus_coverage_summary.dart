/// Syllabus Coverage Summary Entity (TITAN-KO-023.0 P23).
///
/// Immutable domain model capturing the deterministic syllabus coverage and
/// completion ratios across a curriculum framework, domain, or unit for ONE learner.
///
/// Educational Safety Principles:
/// - Unattempted objectives are explicitly distinguished from failed objectives.
/// - Zero-denominator safety ensures coverage and achievement ratios default to 0.0
///   rather than NaN or Infinity when total objectives is zero.
/// - All ratios are strictly clamped to range [0.0, 1.0].
library;

import 'package:meta/meta.dart';

@immutable
class SyllabusCoverageSummary {
  /// Target curriculum scope identifier (e.g. framework ID, domain ID, or unit ID).
  final String scopeId;

  /// Target learner identifier.
  final String learnerId;

  /// Total count of canonical learning objectives in the evaluated scope.
  final int totalObjectives;

  /// Count of learning objectives that have at least one recorded attempt.
  final int attemptedObjectives;

  /// Count of learning objectives that have achieved mastery status (`achieved`).
  final int achievedObjectives;

  /// Count of learning objectives with recorded attempts that are not yet achieved (`inProgress`).
  final int inProgressObjectives;

  /// Count of learning objectives with zero recorded attempts (`notStarted`).
  final int unattemptedObjectives;

  /// Ratio of attempted objectives to total objectives in range [0.0, 1.0].
  final double coverageRatio;

  /// Ratio of achieved objectives to total objectives in range [0.0, 1.0].
  final double achievementRatio;

  /// UTC timestamp when this coverage evaluation was calculated.
  final DateTime evaluatedAt;

  /// Immutable diagnostic metadata.
  final Map<String, dynamic> metadata;

  SyllabusCoverageSummary({
    required this.scopeId,
    required this.learnerId,
    required this.totalObjectives,
    required this.attemptedObjectives,
    required this.achievedObjectives,
    int? inProgressObjectives,
    int? unattemptedObjectives,
    double? coverageRatio,
    double? achievementRatio,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  })  : inProgressObjectives = inProgressObjectives ??
            (attemptedObjectives - achievedObjectives)
                .clamp(0, totalObjectives),
        unattemptedObjectives = unattemptedObjectives ??
            (totalObjectives - attemptedObjectives).clamp(0, totalObjectives),
        coverageRatio = totalObjectives == 0
            ? 0.0
            : (coverageRatio ??
                    (attemptedObjectives / totalObjectives).clamp(0.0, 1.0))
                .clamp(0.0, 1.0),
        achievementRatio = totalObjectives == 0
            ? 0.0
            : (achievementRatio ??
                    (achievedObjectives / totalObjectives).clamp(0.0, 1.0))
                .clamp(0.0, 1.0),
        evaluatedAt = evaluatedAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (scopeId.trim().isEmpty) {
      throw ArgumentError(
          'ScopeId cannot be empty for SyllabusCoverageSummary');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError(
          'LearnerId cannot be empty for SyllabusCoverageSummary');
    }
    if (totalObjectives < 0) {
      throw ArgumentError('TotalObjectives cannot be negative');
    }
    if (attemptedObjectives < 0 || attemptedObjectives > totalObjectives) {
      throw ArgumentError(
          'AttemptedObjectives ($attemptedObjectives) must be between 0 and totalObjectives ($totalObjectives)');
    }
    if (achievedObjectives < 0 || achievedObjectives > attemptedObjectives) {
      throw ArgumentError(
          'AchievedObjectives ($achievedObjectives) must be between 0 and attemptedObjectives ($attemptedObjectives)');
    }
    if (this.inProgressObjectives < 0) {
      throw ArgumentError('InProgressObjectives cannot be negative');
    }
    if (this.unattemptedObjectives < 0) {
      throw ArgumentError('UnattemptedObjectives cannot be negative');
    }
  }

  /// Whether all objectives in the scope have been attempted.
  bool get isFullyAttempted =>
      totalObjectives > 0 && attemptedObjectives == totalObjectives;

  /// Whether all objectives in the scope have achieved mastery.
  bool get isFullyAchieved =>
      totalObjectives > 0 && achievedObjectives == totalObjectives;

  /// Serializes summary to JSON map.
  Map<String, dynamic> toJson() => {
        'scopeId': scopeId,
        'learnerId': learnerId,
        'totalObjectives': totalObjectives,
        'attemptedObjectives': attemptedObjectives,
        'achievedObjectives': achievedObjectives,
        'inProgressObjectives': inProgressObjectives,
        'unattemptedObjectives': unattemptedObjectives,
        'coverageRatio': coverageRatio,
        'achievementRatio': achievementRatio,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'metadata': metadata,
      };

  /// Deserializes summary from JSON map.
  factory SyllabusCoverageSummary.fromJson(Map<String, dynamic> json) =>
      SyllabusCoverageSummary(
        scopeId: json['scopeId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        totalObjectives: json['totalObjectives'] as int? ?? 0,
        attemptedObjectives: json['attemptedObjectives'] as int? ?? 0,
        achievedObjectives: json['achievedObjectives'] as int? ?? 0,
        inProgressObjectives: json['inProgressObjectives'] as int?,
        unattemptedObjectives: json['unattemptedObjectives'] as int?,
        coverageRatio: (json['coverageRatio'] as num?)?.toDouble(),
        achievementRatio: (json['achievementRatio'] as num?)?.toDouble(),
        evaluatedAt: json['evaluatedAt'] != null
            ? DateTime.parse(json['evaluatedAt'] as String).toUtc()
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        metadata: json['metadata'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyllabusCoverageSummary &&
          runtimeType == other.runtimeType &&
          scopeId == other.scopeId &&
          learnerId == other.learnerId &&
          totalObjectives == other.totalObjectives &&
          attemptedObjectives == other.attemptedObjectives &&
          achievedObjectives == other.achievedObjectives &&
          inProgressObjectives == other.inProgressObjectives &&
          unattemptedObjectives == other.unattemptedObjectives &&
          coverageRatio == other.coverageRatio &&
          achievementRatio == other.achievementRatio &&
          evaluatedAt == other.evaluatedAt;

  @override
  int get hashCode => Object.hash(
        scopeId,
        learnerId,
        totalObjectives,
        attemptedObjectives,
        achievedObjectives,
        inProgressObjectives,
        unattemptedObjectives,
        coverageRatio,
        achievementRatio,
        evaluatedAt,
      );

  @override
  String toString() =>
      'SyllabusCoverageSummary(scopeId: $scopeId, learnerId: $learnerId, '
      'coverage: ${(coverageRatio * 100).toStringAsFixed(1)}%, '
      'achievement: ${(achievementRatio * 100).toStringAsFixed(1)}%)';
}
