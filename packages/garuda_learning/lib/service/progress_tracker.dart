/// Progress Tracker Service (TITAN-KO-018.0 P18).
///
/// Deterministically aggregates question attempt results and calculates objective
/// achievement status against configurable thresholds.
library;

import '../domain/entities/assessment_threshold_config.dart';
import '../domain/entities/learner_objective_status.dart';
import '../domain/entities/learner_progress.dart';
import '../repository/attempt_repository.dart';
import '../repository/progress_repository.dart';

class ProgressTracker {
  final AttemptRepository _attemptRepository;
  final ProgressRepository _progressRepository;
  final AssessmentThresholdConfig _thresholdConfig;

  ProgressTracker({
    required AttemptRepository attemptRepository,
    required ProgressRepository progressRepository,
    AssessmentThresholdConfig? thresholdConfig,
  })  : _attemptRepository = attemptRepository,
        _progressRepository = progressRepository,
        _thresholdConfig = thresholdConfig ?? const AssessmentThresholdConfig();

  /// Returns the current threshold configuration.
  AssessmentThresholdConfig get thresholdConfig => _thresholdConfig;

  /// Recalculates and updates [LearnerProgress] for a single learner and objective pair.
  LearnerProgress updateProgress({
    required String learnerId,
    required String objectiveId,
  }) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty');
    }
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError('ObjectiveId cannot be empty');
    }

    final attempts = _attemptRepository.getAttemptsForLearnerAndObjective(
        learnerId, objectiveId);
    final results = _attemptRepository.getResultsForLearnerAndObjective(
        learnerId, objectiveId);

    final attemptCount = attempts.length;
    var correctCount = 0;
    for (final r in results) {
      if (r.isCorrect) correctCount++;
    }

    final successRate =
        attemptCount == 0 ? 0.0 : (correctCount / attemptCount).clamp(0.0, 1.0);

    final lastAttemptAt =
        attempts.isNotEmpty ? attempts.last.attemptedAt : null;

    final existing = _progressRepository.getProgress(learnerId, objectiveId);

    LearnerObjectiveStatus status;
    DateTime? achievedAt = existing?.achievedAt;

    if (attemptCount == 0) {
      status = LearnerObjectiveStatus.notStarted;
    } else if (_thresholdConfig.isAchieved(
        attemptCount: attemptCount, successRate: successRate)) {
      status = LearnerObjectiveStatus.achieved;
      achievedAt ??= lastAttemptAt ?? DateTime.now().toUtc();
    } else {
      status = LearnerObjectiveStatus.inProgress;
    }

    final updated = LearnerProgress(
      learnerId: learnerId,
      objectiveId: objectiveId,
      attemptCount: attemptCount,
      correctCount: correctCount,
      successRate: successRate,
      lastAttemptAt: lastAttemptAt,
      status: status,
      achievedAt: achievedAt,
    );

    _progressRepository.saveProgress(updated);
    return updated;
  }

  /// Retrieves progress for a learner and objective pair, or null if absent.
  LearnerProgress? getProgress(String learnerId, String objectiveId) {
    return _progressRepository.getProgress(learnerId, objectiveId);
  }

  /// Retrieves all progress records for a learner.
  List<LearnerProgress> getLearnerProgressSummary(String learnerId) {
    return _progressRepository.getProgressForLearner(learnerId);
  }
}
