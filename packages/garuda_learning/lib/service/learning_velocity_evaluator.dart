/// Learning Velocity Evaluator (TITAN-KO-023.0 P23 Stage 4).
///
/// Stateless, deterministic evaluation service that calculates [LearningVelocityProfile]
/// for a target learner from P18 attempt evidence and P19 session telemetry.
///
/// Clean Architecture Boundary:
/// - P18 owns atomic attempt logging and progress status. Read-only consumption.
/// - P19 owns session orchestration lifecycle. Read-only consumption.
/// - This evaluator produces strictly descriptive throughput metrics,
///   never inferring intelligence, aptitude, or exam readiness.
///
/// Educational Safety Principles:
/// - Zero attempts or zero sessions yield null rate metrics.
/// - Zero active study duration guards against division-by-zero.
/// - Zero-length window guards against NaN/Infinity for daily rates.
/// - All normalized indices strictly bounded in range [0.0, 1.0].
/// - Pure evaluation without database access, network calls, random numbers, or [DateTime.now].
library;

import '../domain/entities/attempt_result.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/learning_session.dart';
import '../domain/entities/learning_velocity_profile.dart';
import '../domain/entities/question_attempt.dart';

/// Stateless evaluator for computing observed [LearningVelocityProfile].
class LearningVelocityEvaluator {
  const LearningVelocityEvaluator();

  /// Evaluates learning velocity from P18 attempt/result evidence and P19 session telemetry.
  ///
  /// Parameters:
  /// - [learnerId]: Target learner identifier (non-empty).
  /// - [scopeId]: Optional curriculum scope identifier.
  /// - [windowStart]: Start of measurement window (UTC-normalized).
  /// - [windowEnd]: End of measurement window (UTC-normalized, must be >= windowStart).
  /// - [sessions]: List of P19 [LearningSession] records.
  /// - [attempts]: List of P18 [QuestionAttempt] records.
  /// - [attemptResults]: List of P18 [AttemptResult] records.
  /// - [progressList]: List of P18 [LearnerProgress] records for newly-achieved tracking.
  /// - [minimumEvidenceThreshold]: Attempts required for sufficient evidence (default: 5).
  /// - [evaluatedAt]: Explicit UTC evaluation timestamp for strict determinism.
  /// - [metadata]: Optional diagnostic metadata.
  LearningVelocityProfile evaluate({
    required String learnerId,
    String? scopeId,
    required DateTime windowStart,
    required DateTime windowEnd,
    required List<LearningSession> sessions,
    required List<QuestionAttempt> attempts,
    required List<AttemptResult> attemptResults,
    required List<LearnerProgress> progressList,
    int minimumEvidenceThreshold =
        LearningVelocityProfile.defaultEvidenceThreshold,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty');
    }
    if (minimumEvidenceThreshold < 1) {
      throw ArgumentError('MinimumEvidenceThreshold must be at least 1');
    }

    // Step 1: Normalize timestamps to UTC.
    final utcWindowStart = windowStart.toUtc();
    final utcWindowEnd = windowEnd.toUtc();
    final utcEvaluatedAt = evaluatedAt.toUtc();

    // Step 2: Require windowEnd >= windowStart.
    if (utcWindowEnd.isBefore(utcWindowStart)) {
      throw ArgumentError('WindowEnd cannot be before WindowStart');
    }

    // Step 3: Filter sessions belonging to learner with completed state intersecting window.
    final filteredSessions = sessions.where((s) {
      if (s.learnerId != learnerId) return false;
      if (s.completedAt == null) return false;
      final sessionStart = s.startedAt.toUtc();
      final sessionEnd = s.completedAt!.toUtc();
      // Session intersects window if session started before window end
      // and session ended after window start.
      return !sessionStart.isAfter(utcWindowEnd) &&
          !sessionEnd.isBefore(utcWindowStart);
    }).toList();

    // Step 4: Sessions count.
    final sessionsCount = filteredSessions.length;

    // Step 5: Active study duration from completed sessions within window.
    var activeStudyDurationSeconds = 0;
    for (final session in filteredSessions) {
      final sessionStart = session.startedAt.toUtc();
      final sessionEnd = session.completedAt!.toUtc();
      final durationSeconds = sessionEnd.difference(sessionStart).inSeconds;
      if (durationSeconds > 0) {
        activeStudyDurationSeconds += durationSeconds;
      }
    }
    final activeStudyDuration = Duration(seconds: activeStudyDurationSeconds);

    // Step 6: Filter attempts by learner and within window.
    final filteredAttempts = attempts.where((a) {
      if (a.learnerId != learnerId) return false;
      final attemptTime = a.attemptedAt.toUtc();
      return !attemptTime.isBefore(utcWindowStart) &&
          !attemptTime.isAfter(utcWindowEnd);
    }).toList();

    // Step 7: Attempts count.
    final attemptsCount = filteredAttempts.length;

    // Step 8: Match AttemptResult records deterministically by attemptId.
    final resultMap = <String, AttemptResult>{};
    for (final result in attemptResults) {
      resultMap[result.attemptId] = result;
    }

    // Step 9: Correct attempts count.
    var correctAttemptsCount = 0;
    for (final attempt in filteredAttempts) {
      final result = resultMap[attempt.attemptId];
      if (result != null && result.isCorrect) {
        correctAttemptsCount++;
      }
    }

    // Step 10: Observed accuracy.
    final double? observedAccuracy;
    if (attemptsCount == 0) {
      observedAccuracy = null;
    } else {
      observedAccuracy = (correctAttemptsCount / attemptsCount).clamp(0.0, 1.0);
    }

    // Step 11: Attempts per hour.
    final double? attemptsPerHour;
    if (attemptsCount == 0 || activeStudyDuration.inSeconds == 0) {
      attemptsPerHour = null;
    } else {
      attemptsPerHour =
          attemptsCount / (activeStudyDuration.inSeconds / 3600.0);
    }

    // Step 12: Newly achieved objectives count within window.
    var newlyAchievedObjectivesCount = 0;
    for (final progress in progressList) {
      if (progress.learnerId != learnerId) continue;
      if (progress.achievedAt == null) continue;
      final achievedUtc = progress.achievedAt!.toUtc();
      if (!achievedUtc.isBefore(utcWindowStart) &&
          !achievedUtc.isAfter(utcWindowEnd)) {
        newlyAchievedObjectivesCount++;
      }
    }

    // Step 13: Objectives achieved per day.
    final totalWindowSeconds =
        utcWindowEnd.difference(utcWindowStart).inSeconds;
    final double? objectivesAchievedPerDay;
    if (totalWindowSeconds <= 0) {
      objectivesAchievedPerDay = null;
    } else {
      objectivesAchievedPerDay =
          newlyAchievedObjectivesCount / (totalWindowSeconds / 86400.0);
    }

    // Step 14: Has sufficient evidence.
    final hasSufficientEvidence = attemptsCount >= minimumEvidenceThreshold &&
        activeStudyDuration.inSeconds > 0;

    return LearningVelocityProfile(
      learnerId: learnerId,
      scopeId: scopeId,
      windowStart: utcWindowStart,
      windowEnd: utcWindowEnd,
      sessionsCount: sessionsCount,
      attemptsCount: attemptsCount,
      correctAttemptsCount: correctAttemptsCount,
      newlyAchievedObjectivesCount: newlyAchievedObjectivesCount,
      activeStudyDuration: activeStudyDuration,
      observedAccuracy: observedAccuracy,
      attemptsPerHour: attemptsPerHour,
      objectivesAchievedPerDay: objectivesAchievedPerDay,
      hasSufficientEvidence: hasSufficientEvidence,
      minimumEvidenceThreshold: minimumEvidenceThreshold,
      evaluatedAt: utcEvaluatedAt,
      metadata: metadata,
    );
  }
}
