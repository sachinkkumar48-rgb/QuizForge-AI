/// Syllabus Coverage Evaluator (TITAN-KO-023.0 P23 Stage 3).
///
/// Stateless, deterministic evaluation service that calculates [SyllabusCoverageSummary]
/// across a target curriculum scope (framework, domain, unit, or topic) for ONE learner.
///
/// Educational Safety Principles:
/// - Unattempted objectives are explicitly separated from attempted/achieved objectives.
/// - Zero-denominator safety ensures ratios default to 0.0 rather than NaN or Infinity.
/// - All ratios are strictly clamped to range [0.0, 1.0].
/// - Pure evaluation without database access, network calls, random numbers, or [DateTime.now].
library;

import '../domain/entities/curriculum_domain.dart';
import '../domain/entities/curriculum_framework.dart';
import '../domain/entities/curriculum_unit.dart';
import '../domain/entities/learner_objective_status.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/learning_objective.dart';
import '../domain/entities/syllabus_coverage_summary.dart';

/// Stateless evaluator for computing observed [SyllabusCoverageSummary].
class SyllabusCoverageEvaluator {
  const SyllabusCoverageEvaluator();

  /// Evaluates syllabus coverage summary from a list of scoped objective IDs and progress records.
  ///
  /// Parameters:
  /// - [scopeId]: Target curriculum scope identifier (e.g. framework ID, domain ID, unit ID).
  /// - [learnerId]: Target learner identifier (non-empty).
  /// - [scopedObjectiveIds]: List of canonical learning objective IDs within the target scope.
  /// - [progressList]: List of [LearnerProgress] records for this learner.
  /// - [evaluatedAt]: Explicit UTC evaluation timestamp for strict determinism.
  /// - [metadata]: Optional diagnostic metadata.
  SyllabusCoverageSummary evaluate({
    required String scopeId,
    required String learnerId,
    required List<String> scopedObjectiveIds,
    required List<LearnerProgress> progressList,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) {
    if (scopeId.trim().isEmpty) {
      throw ArgumentError('ScopeId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('LearnerId cannot be empty');
    }

    // Deterministically deduplicate and sort objective IDs
    final sortedObjectiveIds = List<String>.from(scopedObjectiveIds.toSet())
      ..sort((a, b) => a.compareTo(b));

    final totalObjectives = sortedObjectiveIds.length;

    // Index progress by objective ID for O(1) lookup
    final progressMap = <String, LearnerProgress>{};
    for (final p in progressList) {
      if (p.learnerId == learnerId) {
        progressMap[p.objectiveId] = p;
      }
    }

    var attemptedObjectives = 0;
    var achievedObjectives = 0;
    var inProgressObjectives = 0;
    var unattemptedObjectives = 0;

    for (final objId in sortedObjectiveIds) {
      final progress = progressMap[objId];
      if (progress == null || progress.attemptCount == 0) {
        unattemptedObjectives++;
      } else {
        attemptedObjectives++;
        if (progress.status == LearnerObjectiveStatus.achieved) {
          achievedObjectives++;
        } else {
          inProgressObjectives++;
        }
      }
    }

    final double coverageRatio = totalObjectives == 0
        ? 0.0
        : (attemptedObjectives / totalObjectives).clamp(0.0, 1.0);

    final double achievementRatio = totalObjectives == 0
        ? 0.0
        : (achievedObjectives / totalObjectives).clamp(0.0, 1.0);

    return SyllabusCoverageSummary(
      scopeId: scopeId,
      learnerId: learnerId,
      totalObjectives: totalObjectives,
      attemptedObjectives: attemptedObjectives,
      achievedObjectives: achievedObjectives,
      inProgressObjectives: inProgressObjectives,
      unattemptedObjectives: unattemptedObjectives,
      coverageRatio: coverageRatio,
      achievementRatio: achievementRatio,
      evaluatedAt: evaluatedAt.toUtc(),
      metadata: metadata,
    );
  }

  /// Convenience evaluation method across an entire [CurriculumFramework].
  SyllabusCoverageSummary evaluateFromFramework({
    required CurriculumFramework framework,
    required String learnerId,
    required List<LearningObjective> allObjectives,
    required List<LearnerProgress> progressList,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) {
    final frameworkUnitIds = <String>{};
    for (final domain in framework.domains) {
      for (final unit in domain.units) {
        frameworkUnitIds.add(unit.id);
      }
    }

    final scopedObjectiveIds = allObjectives
        .where((obj) => frameworkUnitIds.contains(obj.unitId))
        .map((obj) => obj.id)
        .toList();

    return evaluate(
      scopeId: framework.id,
      learnerId: learnerId,
      scopedObjectiveIds: scopedObjectiveIds,
      progressList: progressList,
      evaluatedAt: evaluatedAt,
      metadata: {
        'frameworkTitle': framework.title,
        ...?metadata,
      },
    );
  }

  /// Convenience evaluation method across a single [CurriculumDomain].
  SyllabusCoverageSummary evaluateFromDomain({
    required CurriculumDomain domain,
    required String learnerId,
    required List<LearningObjective> allObjectives,
    required List<LearnerProgress> progressList,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) {
    final domainUnitIds = domain.units.map((u) => u.id).toSet();
    final scopedObjectiveIds = allObjectives
        .where((obj) => domainUnitIds.contains(obj.unitId))
        .map((obj) => obj.id)
        .toList();

    return evaluate(
      scopeId: domain.id,
      learnerId: learnerId,
      scopedObjectiveIds: scopedObjectiveIds,
      progressList: progressList,
      evaluatedAt: evaluatedAt,
      metadata: {
        'domainTitle': domain.title,
        ...?metadata,
      },
    );
  }

  /// Convenience evaluation method across a single [CurriculumUnit].
  SyllabusCoverageSummary evaluateFromUnit({
    required CurriculumUnit unit,
    required String learnerId,
    required List<LearningObjective> allObjectives,
    required List<LearnerProgress> progressList,
    required DateTime evaluatedAt,
    Map<String, dynamic>? metadata,
  }) {
    final scopedObjectiveIds = allObjectives
        .where((obj) => obj.unitId == unit.id)
        .map((obj) => obj.id)
        .toList();

    return evaluate(
      scopeId: unit.id,
      learnerId: learnerId,
      scopedObjectiveIds: scopedObjectiveIds,
      progressList: progressList,
      evaluatedAt: evaluatedAt,
      metadata: {
        'unitTitle': unit.title,
        ...?metadata,
      },
    );
  }
}
