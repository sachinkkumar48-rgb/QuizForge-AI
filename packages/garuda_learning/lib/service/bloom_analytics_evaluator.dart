/// Bloom Analytics Evaluator (TITAN-KO-023.0 P23 Stage 3).
///
/// Stateless, deterministic evaluation service that calculates [BloomMasteryDistribution]
/// distributing observed learner performance across Bloom's Taxonomy cognitive complexity levels.
///
/// Educational Safety Principles:
/// - Reuses canonical [BloomTaxonomyLevel] definitions without parallel taxonomy models.
/// - Distinguishes unattempted cognitive levels (null accuracy, sufficientEvidence == false)
///   from observed poor performance.
/// - Pure evaluation without database access, network calls, random numbers, or [DateTime.now].
library;

import '../domain/entities/bloom_mastery_distribution.dart';
import '../domain/entities/bloom_taxonomy_level.dart';
import '../domain/entities/curriculum_domain.dart';
import '../domain/entities/curriculum_framework.dart';
import '../domain/entities/learner_objective_status.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/learning_objective.dart';

/// Stateless evaluator for computing observed [BloomMasteryDistribution].
class BloomAnalyticsEvaluator {
  const BloomAnalyticsEvaluator();

  /// Evaluates Bloom cognitive level performance distribution for a learner across scoped objectives.
  ///
  /// Parameters:
  /// - [learnerId]: Target learner identifier (non-empty).
  /// - [scopeId]: Optional curriculum scope identifier (e.g. domain ID or framework ID).
  /// - [objectives]: List of canonical [LearningObjective]s in scope.
  /// - [progressList]: List of [LearnerProgress] records for this learner.
  /// - [minimumLevelEvidenceThreshold]: Minimum attempt count required per level for sufficient evidence.
  /// - [evaluatedAt]: Explicit UTC evaluation timestamp for strict determinism.
  /// - [metadata]: Optional diagnostic metadata.
  BloomMasteryDistribution evaluate({
    required String learnerId,
    String? scopeId,
    required List<LearningObjective> objectives,
    required List<LearnerProgress> progressList,
    int minimumLevelEvidenceThreshold =
        BloomLevelMetric.defaultLevelEvidenceThreshold,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) {
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty');
    }
    if (minimumLevelEvidenceThreshold < 1) {
      throw ArgumentError('MinimumLevelEvidenceThreshold must be at least 1');
    }

    // Index progress by objective ID for O(1) lookup
    final progressMap = <String, LearnerProgress>{};
    for (final p in progressList) {
      if (p.learnerId == learnerId) {
        progressMap[p.objectiveId] = p;
      }
    }

    // Deterministically deduplicate objectives by ID
    final uniqueObjectives = <String, LearningObjective>{};
    for (final obj in objectives) {
      uniqueObjectives[obj.id] = obj;
    }

    // Group deduplicated objectives by Bloom level
    final objectivesByLevel = <BloomTaxonomyLevel, List<LearningObjective>>{};
    for (final level in BloomTaxonomyLevel.values) {
      objectivesByLevel[level] = [];
    }

    for (final obj in uniqueObjectives.values) {
      objectivesByLevel[obj.bloomLevel]?.add(obj);
    }

    final levelMetrics = <BloomTaxonomyLevel, BloomLevelMetric>{};

    for (final level in BloomTaxonomyLevel.values) {
      final levelObjs = objectivesByLevel[level] ?? const [];
      final totalObjectivesCount = levelObjs.length;

      var attemptedObjectivesCount = 0;
      var achievedObjectivesCount = 0;
      var totalAttemptsCount = 0;
      var totalCorrectCount = 0;

      for (final obj in levelObjs) {
        final progress = progressMap[obj.id];
        if (progress != null && progress.attemptCount > 0) {
          attemptedObjectivesCount++;
          totalAttemptsCount += progress.attemptCount;
          totalCorrectCount += progress.correctCount;

          if (progress.status == LearnerObjectiveStatus.achieved) {
            achievedObjectivesCount++;
          }
        }
      }

      final double? observedAccuracy = totalAttemptsCount == 0
          ? null
          : (totalCorrectCount / totalAttemptsCount).clamp(0.0, 1.0);

      final bool hasSufficientEvidence =
          totalAttemptsCount >= minimumLevelEvidenceThreshold &&
              attemptedObjectivesCount > 0;

      levelMetrics[level] = BloomLevelMetric(
        level: level,
        totalObjectivesCount: totalObjectivesCount,
        attemptedObjectivesCount: attemptedObjectivesCount,
        achievedObjectivesCount: achievedObjectivesCount,
        totalAttemptsCount: totalAttemptsCount,
        totalCorrectCount: totalCorrectCount,
        observedAccuracy: observedAccuracy,
        hasSufficientEvidence: hasSufficientEvidence,
        minimumEvidenceThreshold: minimumLevelEvidenceThreshold,
      );
    }

    return BloomMasteryDistribution(
      learnerId: learnerId,
      scopeId: scopeId,
      levels: levelMetrics,
      calculatedAt: evaluatedAt.toUtc(),
      metadata: metadata,
    );
  }

  /// Convenience evaluation method across a single [CurriculumDomain].
  BloomMasteryDistribution evaluateFromDomain({
    required CurriculumDomain domain,
    required String learnerId,
    required List<LearningObjective> allObjectives,
    required List<LearnerProgress> progressList,
    int minimumLevelEvidenceThreshold =
        BloomLevelMetric.defaultLevelEvidenceThreshold,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) {
    final domainUnitIds = domain.units.map((u) => u.id).toSet();
    final domainObjectives = allObjectives
        .where((obj) => domainUnitIds.contains(obj.unitId))
        .toList();

    return evaluate(
      learnerId: learnerId,
      scopeId: domain.id,
      objectives: domainObjectives,
      progressList: progressList,
      minimumLevelEvidenceThreshold: minimumLevelEvidenceThreshold,
      evaluatedAt: evaluatedAt,
      metadata: {
        'domainTitle': domain.title,
        ...?metadata,
      },
    );
  }

  /// Convenience evaluation method across an entire [CurriculumFramework].
  BloomMasteryDistribution evaluateFromFramework({
    required CurriculumFramework framework,
    required String learnerId,
    required List<LearningObjective> allObjectives,
    required List<LearnerProgress> progressList,
    int minimumLevelEvidenceThreshold =
        BloomLevelMetric.defaultLevelEvidenceThreshold,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) {
    final frameworkUnitIds = <String>{};
    for (final domain in framework.domains) {
      for (final unit in domain.units) {
        frameworkUnitIds.add(unit.id);
      }
    }

    final frameworkObjectives = allObjectives
        .where((obj) => frameworkUnitIds.contains(obj.unitId))
        .toList();

    return evaluate(
      learnerId: learnerId,
      scopeId: framework.id,
      objectives: frameworkObjectives,
      progressList: progressList,
      minimumLevelEvidenceThreshold: minimumLevelEvidenceThreshold,
      evaluatedAt: evaluatedAt,
      metadata: {
        'frameworkTitle': framework.title,
        ...?metadata,
      },
    );
  }
}
