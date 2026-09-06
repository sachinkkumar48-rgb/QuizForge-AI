/// Objective Weakness Detail Domain Entity (TITAN-KO-044.0 P44).
///
/// Encapsulates diagnostic deficiency metrics, streak information,
/// regression signals, and remedial recommendations for a struggling objective.
library;

import 'package:meta/meta.dart';

@immutable
class ObjectiveWeaknessDetail {
  /// Canonical learning objective identifier.
  final String objectiveId;

  /// Normalized deficiency index in range [0.0, 1.0], where 1.0 represents
  /// maximum observed struggle.
  final double deficiencyScore;

  /// Total attempts recorded for this objective.
  final int attemptCount;

  /// Total correct attempts recorded.
  final int correctCount;

  /// Success rate in range [0.0, 1.0].
  final double successRate;

  /// Number of consecutive incorrect answers at the tail of attempts.
  final int consecutiveIncorrectCount;

  /// Whether this weakness is due to a regression from previously achieved mastery.
  final bool isRegressed;

  /// Optional identifier of a bound P25 remedial lesson suited for this objective.
  final String? recommendedRemedialLessonId;

  /// Auditable pedagogical explanation of why this objective is flagged.
  final String rationale;

  ObjectiveWeaknessDetail({
    required String objectiveId,
    required this.deficiencyScore,
    required this.attemptCount,
    required this.correctCount,
    required this.successRate,
    this.consecutiveIncorrectCount = 0,
    this.isRegressed = false,
    this.recommendedRemedialLessonId,
    required this.rationale,
  })  : objectiveId = objectiveId.trim(),
        assert(deficiencyScore >= 0.0 && deficiencyScore <= 1.0,
            'deficiencyScore must be in [0.0, 1.0]'),
        assert(attemptCount >= 0, 'attemptCount cannot be negative'),
        assert(correctCount >= 0, 'correctCount cannot be negative'),
        assert(correctCount <= attemptCount,
            'correctCount cannot exceed attemptCount'),
        assert(successRate >= 0.0 && successRate <= 1.0,
            'successRate must be in [0.0, 1.0]'),
        assert(consecutiveIncorrectCount >= 0,
            'consecutiveIncorrectCount cannot be negative') {
    if (this.objectiveId.isEmpty) {
      throw ArgumentError('objectiveId cannot be empty');
    }
    if (attemptCount < 0) {
      throw ArgumentError('attemptCount cannot be negative');
    }
    if (correctCount < 0 || correctCount > attemptCount) {
      throw ArgumentError(
          'correctCount ($correctCount) must be between 0 and attemptCount ($attemptCount)');
    }
  }

  Map<String, dynamic> toJson() => {
        'objectiveId': objectiveId,
        'deficiencyScore': deficiencyScore,
        'attemptCount': attemptCount,
        'correctCount': correctCount,
        'successRate': successRate,
        'consecutiveIncorrectCount': consecutiveIncorrectCount,
        'isRegressed': isRegressed,
        if (recommendedRemedialLessonId != null)
          'recommendedRemedialLessonId': recommendedRemedialLessonId,
        'rationale': rationale,
      };

  factory ObjectiveWeaknessDetail.fromJson(Map<String, dynamic> json) {
    return ObjectiveWeaknessDetail(
      objectiveId: json['objectiveId'] as String? ?? '',
      deficiencyScore: (json['deficiencyScore'] as num?)?.toDouble() ?? 0.0,
      attemptCount: json['attemptCount'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
      consecutiveIncorrectCount: json['consecutiveIncorrectCount'] as int? ?? 0,
      isRegressed: json['isRegressed'] as bool? ?? false,
      recommendedRemedialLessonId:
          json['recommendedRemedialLessonId'] as String?,
      rationale: json['rationale'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ObjectiveWeaknessDetail &&
          runtimeType == other.runtimeType &&
          objectiveId == other.objectiveId &&
          deficiencyScore == other.deficiencyScore &&
          attemptCount == other.attemptCount &&
          correctCount == other.correctCount &&
          successRate == other.successRate &&
          consecutiveIncorrectCount == other.consecutiveIncorrectCount &&
          isRegressed == other.isRegressed &&
          recommendedRemedialLessonId == other.recommendedRemedialLessonId &&
          rationale == other.rationale;

  @override
  int get hashCode => Object.hash(
        objectiveId,
        deficiencyScore,
        attemptCount,
        correctCount,
        successRate,
        consecutiveIncorrectCount,
        isRegressed,
        recommendedRemedialLessonId,
        rationale,
      );

  @override
  String toString() =>
      'ObjectiveWeaknessDetail(obj: $objectiveId, def: ${(deficiencyScore * 100).toStringAsFixed(1)}%, '
      'att: $attemptCount, succ: ${(successRate * 100).toStringAsFixed(1)}%, regressed: $isRegressed)';
}
