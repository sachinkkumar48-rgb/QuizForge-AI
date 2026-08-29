/// Deterministic Diagnostic Placement Evaluator (TITAN-KO-026.0 P26).
///
/// Pure, deterministic calculation engine that evaluates diagnostic evidence
/// and computes curriculum placement frontiers.
///
/// Educational Safety Invariants:
/// - Evaluates ONLY observed evidence. Never claims intelligence or inherent ability.
/// - Incomplete evidence is NEVER treated as failure.
/// - Completely pure, deterministic, and free of DateTime.now() or unseeded randomness.
library;

import '../domain/entities/diagnostic_assessment_request.dart';
import '../domain/entities/diagnostic_evidence_state.dart';
import '../domain/entities/diagnostic_objective_result.dart';
import '../domain/entities/diagnostic_placement_frontier.dart';
import '../domain/entities/diagnostic_placement_result.dart';
import '../domain/entities/diagnostic_placement_status.dart';
import '../repository/attempt_repository.dart';
import 'curriculum_service.dart';
import 'deterministic_sequence_resolver.dart';

class DeterministicDiagnosticEvaluator {
  final CurriculumService _curriculumService;
  final DeterministicSequenceResolver _sequenceResolver;

  DeterministicDiagnosticEvaluator({
    required CurriculumService curriculumService,
    DeterministicSequenceResolver? sequenceResolver,
  })  : _curriculumService = curriculumService,
        _sequenceResolver = sequenceResolver ?? DeterministicSequenceResolver();

  /// Evaluates placement for the given [request] using evidence from [attemptRepository].
  DiagnosticPlacementResult evaluate({
    required DiagnosticAssessmentRequest request,
    required AttemptRepository attemptRepository,
  }) {
    final objectiveResults = <String, DiagnosticObjectiveResult>{};
    final learnerAttempts =
        attemptRepository.getAttemptsForLearner(request.learnerId);

    int totalAttemptsCount = 0;
    int totalCorrectCount = 0;
    int totalAssessedObjectives = 0;
    int demonstratedCount = 0;

    final demonstratedIds = <String>[];
    final developingIds = <String>[];
    final unassessedIds = <String>[];
    final remediationTargetIds = <String>[];

    // 1. Evaluate each requested objective deterministically
    for (final objId in request.targetObjectiveIds) {
      final objAttempts = learnerAttempts
          .where((a) => a.objectiveId == objId)
          .toList()
        ..sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));

      final count = objAttempts.length;
      int correct = 0;

      for (final att in objAttempts) {
        final res = attemptRepository.getResultForAttempt(att.attemptId);
        if (res != null && res.isCorrect) {
          correct++;
        }
      }

      totalAttemptsCount += count;
      totalCorrectCount += correct;

      final DiagnosticEvidenceState evidenceState;
      final DiagnosticPlacementStatus placementStatus;
      final double? observedAccuracy;
      final String notes;

      if (count == 0) {
        evidenceState = DiagnosticEvidenceState.notAssessed;
        placementStatus = DiagnosticPlacementStatus.notAssessed;
        observedAccuracy = null;
        notes = 'No assessment attempts observed for this objective.';
        unassessedIds.add(objId);
      } else if (count < request.thresholdConfig.minimumEvidenceThreshold) {
        totalAssessedObjectives++;
        evidenceState = DiagnosticEvidenceState.insufficientEvidence;
        placementStatus = DiagnosticPlacementStatus.insufficientEvidence;
        final rawAcc = correct / count;
        observedAccuracy = rawAcc.clamp(0.0, 1.0);
        notes =
            'Recorded $count attempt(s) (threshold: ${request.thresholdConfig.minimumEvidenceThreshold}). Sample insufficient for placement determination.';
        unassessedIds.add(objId);
      } else {
        totalAssessedObjectives++;
        evidenceState = DiagnosticEvidenceState.sufficientEvidence;
        final rawAcc = correct / count;
        observedAccuracy = rawAcc.clamp(0.0, 1.0);

        if (observedAccuracy >= request.thresholdConfig.masteryThreshold) {
          placementStatus = DiagnosticPlacementStatus.demonstrated;
          notes =
              'Demonstrated performance: observed accuracy ${(observedAccuracy * 100).toStringAsFixed(1)}% across $count attempts.';
          demonstratedIds.add(objId);
          demonstratedCount++;
        } else {
          placementStatus = DiagnosticPlacementStatus.developing;
          notes =
              'Developing performance: observed accuracy ${(observedAccuracy * 100).toStringAsFixed(1)}% across $count attempts.';
          developingIds.add(objId);
          if (observedAccuracy < request.thresholdConfig.developingThreshold) {
            remediationTargetIds.add(objId);
          }
        }
      }

      objectiveResults[objId] = DiagnosticObjectiveResult(
        objectiveId: objId,
        evidenceState: evidenceState,
        placementStatus: placementStatus,
        attemptsCount: count,
        correctCount: correct,
        observedAccuracy: observedAccuracy,
        evaluatedAt: request.requestedAt,
        notes: notes,
      );
    }

    // 2. Resolve prerequisite-respecting frontier in curriculum topological order
    final demonstratedSet = demonstratedIds.toSet();
    final activeFrontierIds = <String>[];

    // Determine topological order by sequencing framework objectives
    final allFrameworkObjectives =
        _curriculumService.framework.objectiveMap.values.toList();
    final fullSequence =
        _sequenceResolver.resolveSequence(allFrameworkObjectives);
    final targetSet = request.targetObjectiveIds.toSet();
    final sortedTargets = fullSequence
        .where((o) => targetSet.contains(o.id))
        .map((o) => o.id)
        .toList();

    for (final objId in sortedTargets) {
      // If already demonstrated, it is behind the active frontier
      if (demonstratedSet.contains(objId)) continue;

      // Check whether prerequisites in the framework are satisfied
      final obj = _curriculumService.getObjectiveById(objId);
      bool prereqsSatisfied = true;
      if (obj != null) {
        for (final prereq in obj.prerequisites) {
          final prereqId = prereq.prerequisiteObjectiveId;
          // If prerequisite is part of targets, must be demonstrated
          if (request.targetObjectiveIds.contains(prereqId) &&
              !demonstratedSet.contains(prereqId)) {
            prereqsSatisfied = false;
            break;
          }
        }
      }

      if (prereqsSatisfied) {
        activeFrontierIds.add(objId);
      }
    }

    final frontier = DiagnosticPlacementFrontier(
      activeFrontierObjectiveIds: activeFrontierIds,
      demonstratedObjectiveIds: demonstratedIds..sort(),
      developingObjectiveIds: developingIds..sort(),
      unassessedObjectiveIds: unassessedIds..sort(),
      remediationTargetObjectiveIds: remediationTargetIds..sort(),
    );

    final double? aggregateAccuracy = totalAttemptsCount == 0
        ? null
        : (totalCorrectCount / totalAttemptsCount).clamp(0.0, 1.0);

    return DiagnosticPlacementResult(
      assessmentId: 'diag_${request.requestId}',
      learnerId: request.learnerId,
      evaluatedAt: request.requestedAt,
      objectiveResults: objectiveResults,
      frontier: frontier,
      totalAssessedObjectives: totalAssessedObjectives,
      demonstratedObjectivesCount: demonstratedCount,
      totalAttemptsCount: totalAttemptsCount,
      totalCorrectCount: totalCorrectCount,
      aggregateAccuracy: aggregateAccuracy,
      provenance: 'GARUDA Learning P26 Deterministic Diagnostic Engine',
    );
  }
}
