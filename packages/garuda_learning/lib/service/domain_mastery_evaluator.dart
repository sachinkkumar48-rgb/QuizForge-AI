/// Domain Mastery Evaluator (TITAN-KO-023.0 P23 Stage 3).
///
/// Stateless, deterministic evaluation service that calculates [DomainMasteryProfile]
/// for a target curriculum domain and learner from verified learning evidence.
///
/// Educational Safety Principles:
/// - Represents strictly observed performance metrics ([observedAccuracy], [observedMasteryScore]).
/// - Zero attempts explicitly yields null accuracy and null mastery score with [hasSufficientEvidence] == false.
/// - Sparse attempts below [minimumEvidenceThreshold] maintain null mastery score.
/// - Where evidence is sufficient, [observedMasteryScore] equals [observedAccuracy].
/// - Pure evaluation without database access, network calls, random numbers, or [DateTime.now].
library;

import '../domain/entities/bloom_mastery_distribution.dart';
import '../domain/entities/curriculum_domain.dart';
import '../domain/entities/domain_mastery_profile.dart';
import '../domain/entities/learner_objective_status.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/learning_objective.dart';

/// Stateless evaluator for computing observed [DomainMasteryProfile].
class DomainMasteryEvaluator {
  const DomainMasteryEvaluator();

  /// Evaluates domain mastery profile from explicit objective IDs and progress records.
  ///
  /// Parameters:
  /// - [learnerId]: Target learner identifier (non-empty).
  /// - [domainId]: Target curriculum domain identifier (non-empty).
  /// - [objectiveIds]: List of canonical learning objective IDs belonging to this domain.
  /// - [progressList]: List of [LearnerProgress] records for this learner.
  /// - [bloomDistribution]: Optional co-evaluated Bloom cognitive complexity breakdown.
  /// - [minimumEvidenceThreshold]: Attempt count required for statistical sufficiency.
  /// - [evaluatedAt]: Explicit UTC evaluation timestamp for strict determinism.
  /// - [metadata]: Optional diagnostic metadata.
  DomainMasteryProfile evaluate({
    required String learnerId,
    required String domainId,
    required List<String> objectiveIds,
    required List<LearnerProgress> progressList,
    BloomMasteryDistribution? bloomDistribution,
    int minimumEvidenceThreshold =
        DomainMasteryProfile.defaultEvidenceThreshold,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty');
    }
    if (domainId.trim().isEmpty) {
      throw ArgumentError('DomainId cannot be empty');
    }
    if (minimumEvidenceThreshold < 1) {
      throw ArgumentError('MinimumEvidenceThreshold must be at least 1');
    }

    // Deterministically deduplicate and sort objective IDs
    final sortedObjectiveIds = List<String>.from(objectiveIds.toSet())
      ..sort((a, b) => a.compareTo(b));

    final totalObjectivesCount = sortedObjectiveIds.length;

    // Index progress by objective ID for O(1) lookup
    final progressMap = <String, LearnerProgress>{};
    for (final p in progressList) {
      if (p.learnerId == learnerId) {
        progressMap[p.objectiveId] = p;
      }
    }

    var attemptedObjectivesCount = 0;
    var achievedObjectivesCount = 0;
    var totalAttemptsCount = 0;
    var totalCorrectCount = 0;

    for (final objId in sortedObjectiveIds) {
      final progress = progressMap[objId];
      if (progress != null && progress.attemptCount > 0) {
        attemptedObjectivesCount++;
        totalAttemptsCount += progress.attemptCount;
        totalCorrectCount += progress.correctCount;

        if (progress.status == LearnerObjectiveStatus.achieved) {
          achievedObjectivesCount++;
        }
      }
    }

    final bool hasSufficientEvidence =
        totalAttemptsCount >= minimumEvidenceThreshold &&
            attemptedObjectivesCount > 0;

    final double? observedAccuracy = totalAttemptsCount == 0
        ? null
        : (totalCorrectCount / totalAttemptsCount).clamp(0.0, 1.0);

    final double? observedMasteryScore =
        hasSufficientEvidence ? observedAccuracy : null;

    return DomainMasteryProfile(
      domainId: domainId,
      learnerId: learnerId,
      totalObjectivesCount: totalObjectivesCount,
      attemptedObjectivesCount: attemptedObjectivesCount,
      achievedObjectivesCount: achievedObjectivesCount,
      totalAttemptsCount: totalAttemptsCount,
      totalCorrectCount: totalCorrectCount,
      observedAccuracy: observedAccuracy,
      observedMasteryScore: observedMasteryScore,
      hasSufficientEvidence: hasSufficientEvidence,
      minimumEvidenceThreshold: minimumEvidenceThreshold,
      bloomDistribution: bloomDistribution,
      supportingObjectiveIds: sortedObjectiveIds,
      calculatedAt: evaluatedAt.toUtc(),
      metadata: metadata,
    );
  }

  /// Convenience evaluation method directly accepting [CurriculumDomain] and [LearningObjective]s.
  DomainMasteryProfile evaluateFromDomain({
    required String learnerId,
    required CurriculumDomain domain,
    required List<LearningObjective> allObjectives,
    required List<LearnerProgress> progressList,
    BloomMasteryDistribution? bloomDistribution,
    int minimumEvidenceThreshold =
        DomainMasteryProfile.defaultEvidenceThreshold,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) {
    final domainUnitIds = domain.units.map((u) => u.id).toSet();
    final domainObjectiveIds = allObjectives
        .where((obj) => domainUnitIds.contains(obj.unitId))
        .map((obj) => obj.id)
        .toList();

    return evaluate(
      learnerId: learnerId,
      domainId: domain.id,
      objectiveIds: domainObjectiveIds,
      progressList: progressList,
      bloomDistribution: bloomDistribution,
      minimumEvidenceThreshold: minimumEvidenceThreshold,
      evaluatedAt: evaluatedAt,
      metadata: {
        'domainTitle': domain.title,
        ...?metadata,
      },
    );
  }
}
