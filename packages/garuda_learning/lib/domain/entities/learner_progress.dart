/// Learner Progress Model (TITAN-KO-018.0 P18).
///
/// Tracks aggregate attempt count, correct count, success rate, and achievement
/// status toward ONE learning objective for ONE learner.
library;

import 'package:meta/meta.dart';

import 'learner_objective_status.dart';

@immutable
class LearnerProgress {
  /// Target learner identifier.
  final String learnerId;

  /// Target canonical learning objective identifier.
  final String objectiveId;

  /// Total number of attempts submitted by the learner for this objective.
  final int attemptCount;

  /// Total number of correct attempts for this objective.
  final int correctCount;

  /// Calculated success rate in range [0.0, 1.0].
  final double successRate;

  /// Timestamp of the most recent attempt.
  final DateTime? lastAttemptAt;

  /// Progress status (`notStarted`, `inProgress`, `achieved`).
  final LearnerObjectiveStatus status;

  /// Timestamp when achievement threshold was first met, if achieved.
  final DateTime? achievedAt;

  LearnerProgress({
    required this.learnerId,
    required this.objectiveId,
    this.attemptCount = 0,
    this.correctCount = 0,
    double? successRate,
    this.lastAttemptAt,
    this.status = LearnerObjectiveStatus.notStarted,
    this.achievedAt,
  }) : successRate = successRate ??
            (attemptCount == 0
                ? 0.0
                : (correctCount / attemptCount).clamp(0.0, 1.0)) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty for LearnerProgress');
    }
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError('ObjectiveId cannot be empty for LearnerProgress');
    }
    if (attemptCount < 0) {
      throw ArgumentError('AttemptCount cannot be negative');
    }
    if (correctCount < 0 || correctCount > attemptCount) {
      throw ArgumentError(
          'CorrectCount ($correctCount) must be between 0 and attemptCount ($attemptCount)');
    }
  }

  /// Whether the objective has been achieved by the learner.
  bool get isAchieved => status == LearnerObjectiveStatus.achieved;

  Map<String, dynamic> toJson() => {
        'learnerId': learnerId,
        'objectiveId': objectiveId,
        'attemptCount': attemptCount,
        'correctCount': correctCount,
        'successRate': successRate,
        if (lastAttemptAt != null)
          'lastAttemptAt': lastAttemptAt!.toIso8601String(),
        'status': status.name,
        if (achievedAt != null) 'achievedAt': achievedAt!.toIso8601String(),
      };

  factory LearnerProgress.fromJson(Map<String, dynamic> json) =>
      LearnerProgress(
        learnerId: json['learnerId'] as String? ?? '',
        objectiveId: json['objectiveId'] as String? ?? '',
        attemptCount: json['attemptCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        successRate: (json['successRate'] as num?)?.toDouble(),
        lastAttemptAt: json['lastAttemptAt'] != null
            ? DateTime.parse(json['lastAttemptAt'] as String).toUtc()
            : null,
        status: LearnerObjectiveStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => LearnerObjectiveStatus.notStarted,
        ),
        achievedAt: json['achievedAt'] != null
            ? DateTime.parse(json['achievedAt'] as String).toUtc()
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearnerProgress &&
          learnerId == other.learnerId &&
          objectiveId == other.objectiveId &&
          attemptCount == other.attemptCount &&
          correctCount == other.correctCount &&
          status == other.status;

  @override
  int get hashCode => Object.hash(learnerId, objectiveId, attemptCount, status);

  @override
  String toString() =>
      'LearnerProgress($learnerId, obj: $objectiveId, attempts: $attemptCount, status: ${status.name})';
}
