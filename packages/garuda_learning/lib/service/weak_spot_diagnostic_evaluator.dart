/// Weak-Spot Diagnostic Evaluator (TITAN-KO-023.0 P23 Stage 4).
///
/// Stateless, deterministic evaluation service that calculates [WeakSpotProfile]
/// for a target learner from P18 progress evidence and P17 learning objectives.
///
/// Clean Architecture Boundary:
/// - P18 owns atomic attempt logging and progress status. Read-only consumption.
/// - P21 owns recommendation generation. This evaluator produces diagnostics only.
/// - P22 owns effectiveness evaluation. No effectiveness scoring here.
///
/// Educational Safety Principles:
/// - CRITICAL: 0 attempts != weak spot. Unattempted objectives are excluded.
/// - CRITICAL: Sparse evidence (< [minimumEvidenceThreshold]) != weak spot.
/// - Only objectives with sufficient evidence AND accuracy below [weaknessThreshold]
///   are diagnosed as weak spots.
/// - Absence of evidence NEVER becomes a negative learner score.
/// - No recommendation payloads, no remediation strategies, no P21 invocations.
/// - Pure evaluation without database access, network calls, random numbers, or [DateTime.now].
library;

import '../domain/entities/attempt_result.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/learning_objective.dart';
import '../domain/entities/question_attempt.dart';
import '../domain/entities/weak_spot_profile.dart';

/// Stateless evaluator for computing observed [WeakSpotProfile].
class WeakSpotDiagnosticEvaluator {
  const WeakSpotDiagnosticEvaluator();

  /// Evaluates weak-spot diagnostics from P17 objectives and P18 progress evidence.
  ///
  /// Parameters:
  /// - [learnerId]: Target learner identifier (non-empty).
  /// - [scopeId]: Optional curriculum scope identifier.
  /// - [objectives]: List of P17 [LearningObjective] entities to evaluate.
  /// - [progressList]: List of P18 [LearnerProgress] records for the learner.
  /// - [attempts]: Optional list of P18 [QuestionAttempt] records for consecutive-incorrect derivation.
  /// - [attemptResults]: Optional list of P18 [AttemptResult] records for consecutive-incorrect derivation.
  /// - [weaknessThreshold]: Accuracy threshold below which an objective is classified as weak (default: 0.60).
  /// - [minimumEvidenceThreshold]: Minimum attempts required per objective (default: 5).
  /// - [evaluatedAt]: Explicit UTC evaluation timestamp for strict determinism.
  /// - [metadata]: Optional diagnostic metadata.
  WeakSpotProfile evaluate({
    required String learnerId,
    String? scopeId,
    required List<LearningObjective> objectives,
    required List<LearnerProgress> progressList,
    List<QuestionAttempt>? attempts,
    List<AttemptResult>? attemptResults,
    double weaknessThreshold = WeakSpotProfile.defaultWeaknessThreshold,
    int minimumEvidenceThreshold = WeakSpotProfile.defaultEvidenceThreshold,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty');
    }
    if (minimumEvidenceThreshold < 1) {
      throw ArgumentError('MinimumEvidenceThreshold must be at least 1');
    }
    if (weaknessThreshold < 0.0 || weaknessThreshold > 1.0) {
      throw ArgumentError(
          'WeaknessThreshold must be between 0.0 and 1.0 (got $weaknessThreshold)');
    }

    final utcEvaluatedAt = evaluatedAt.toUtc();

    // Step 1: Deduplicate objectives by objective ID.
    final uniqueObjectives = <String, LearningObjective>{};
    for (final obj in objectives) {
      uniqueObjectives.putIfAbsent(obj.id, () => obj);
    }

    // Step 2: Total evaluated objectives.
    final totalEvaluatedObjectives = uniqueObjectives.length;

    // Step 3: Index progress by objectiveId for the target learner.
    final progressMap = <String, LearnerProgress>{};
    for (final p in progressList) {
      if (p.learnerId == learnerId) {
        progressMap[p.objectiveId] = p;
      }
    }

    // Build attempt result lookup for consecutive-incorrect derivation.
    final resultMap = <String, AttemptResult>{};
    if (attemptResults != null) {
      for (final result in attemptResults) {
        resultMap[result.attemptId] = result;
      }
    }

    // Build per-objective attempt history sorted by timestamp for consecutive-incorrect derivation.
    final objectiveAttempts = <String, List<QuestionAttempt>>{};
    if (attempts != null) {
      for (final attempt in attempts) {
        if (attempt.learnerId == learnerId) {
          objectiveAttempts
              .putIfAbsent(attempt.objectiveId, () => <QuestionAttempt>[])
              .add(attempt);
        }
      }
      // Sort each objective's attempts by timestamp ascending for tail analysis.
      for (final list in objectiveAttempts.values) {
        list.sort(
            (a, b) => a.attemptedAt.toUtc().compareTo(b.attemptedAt.toUtc()));
      }
    }

    var evaluatedWithSufficientEvidence = 0;
    final weakObjectives = <WeakObjectiveDiagnostic>[];

    // Step 3 (per objective): Evaluate each objective against evidence thresholds.
    for (final entry in uniqueObjectives.entries) {
      final objectiveId = entry.key;
      final objective = entry.value;
      final progress = progressMap[objectiveId];

      // No progress OR attemptCount == 0: unattempted. NEVER weak.
      if (progress == null || progress.attemptCount == 0) {
        continue;
      }

      // attemptCount < minimumEvidenceThreshold: sparse evidence. NEVER weak.
      if (progress.attemptCount < minimumEvidenceThreshold) {
        continue;
      }

      // Sufficient evidence for this objective.
      evaluatedWithSufficientEvidence++;

      // Calculate accuracy.
      final accuracy =
          (progress.correctCount / progress.attemptCount).clamp(0.0, 1.0);

      // If accuracy >= weaknessThreshold: not a weak spot.
      if (accuracy >= weaknessThreshold) {
        continue;
      }

      // Diagnosed as a weak spot.
      final deficiencyScore = (1.0 - accuracy).clamp(0.0, 1.0);

      // Step 4: Derive consecutiveIncorrectCount from attempt history tail.
      var consecutiveIncorrectCount = 0;
      final objAttempts = objectiveAttempts[objectiveId];
      if (objAttempts != null && objAttempts.isNotEmpty) {
        // Walk backwards through sorted attempts to count consecutive incorrect.
        for (var i = objAttempts.length - 1; i >= 0; i--) {
          final result = resultMap[objAttempts[i].attemptId];
          if (result != null && !result.isCorrect) {
            consecutiveIncorrectCount++;
          } else {
            break; // Stop at first correct or missing result.
          }
        }
      }
      // Step 5: If no raw attempt history, consecutiveIncorrectCount remains 0.

      weakObjectives.add(WeakObjectiveDiagnostic(
        objectiveId: objectiveId,
        domainId: scopeId,
        attemptCount: progress.attemptCount,
        correctCount: progress.correctCount,
        observedAccuracy: accuracy,
        bloomLevel: objective.bloomLevel,
        consecutiveIncorrectCount: consecutiveIncorrectCount,
        deficiencyScore: deficiencyScore,
        lastAttemptedAt: progress.lastAttemptAt,
      ));
    }

    // Step 6: Sort handled by WeakSpotProfile constructor
    // (deficiencyScore DESC, then objectiveId ASC).

    // Step 7: Return WeakSpotProfile.
    return WeakSpotProfile(
      learnerId: learnerId,
      scopeId: scopeId,
      totalEvaluatedObjectives: totalEvaluatedObjectives,
      evaluatedWithSufficientEvidence: evaluatedWithSufficientEvidence,
      weakObjectives: weakObjectives,
      weaknessThreshold: weaknessThreshold,
      minimumEvidenceThreshold: minimumEvidenceThreshold,
      evaluatedAt: utcEvaluatedAt,
      metadata: metadata,
    );
  }
}
