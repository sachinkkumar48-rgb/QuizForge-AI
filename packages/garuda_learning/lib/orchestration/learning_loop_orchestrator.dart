/// Learning Loop Orchestrator (TITAN Closed-Loop Product Integration).
///
/// Unifies the end-to-end learning lifecycle across:
/// 1. PYQ Question & Adapter (garuda_pyq / Track 1)
/// 2. P18 Assessment Evidence (AssessmentService)
/// 3. P26 Diagnostic Assessment & Placement (DiagnosticAssessmentService)
/// 4. P23 Analytics & Weak-Spot Diagnostics (WeakSpotDiagnosticEvaluator)
/// 5. P24 Dynamic Study Planning (DeterministicStudyPlannerService)
/// 6. P25 Remedial Framework (DeterministicRemedialLessonService)
/// 7. Targeted Reassessment & Placement Advancement
library;

import '../domain/entities/attempt_result.dart';
import '../domain/entities/diagnostic_assessment_request.dart';
import '../domain/entities/diagnostic_placement_result.dart';
import '../domain/entities/learning_objective.dart';
import '../domain/entities/remedial_lesson.dart';
import '../domain/entities/remedial_practice_session_config.dart';
import '../domain/entities/study_plan.dart';
import '../domain/entities/study_plan_request.dart';
import '../domain/entities/study_time_budget.dart';
import '../domain/entities/weak_spot_profile.dart';
import '../repository/attempt_repository.dart';
import '../repository/progress_repository.dart';
import '../service/assessment_service.dart';
import '../service/curriculum_service.dart';
import '../service/deterministic_study_planner_service.dart';
import '../service/deterministic_remedial_lesson_service.dart';
import '../service/diagnostic_assessment_service.dart';
import '../service/weak_spot_diagnostic_evaluator.dart';

/// Orchestrates the unified, deterministic closed-loop learning lifecycle.
class LearningLoopOrchestrator {
  final AssessmentService _assessmentService;
  final DiagnosticAssessmentService _diagnosticService;
  final CurriculumService _curriculumService;
  final DeterministicStudyPlannerService _studyPlannerService;
  final DeterministicRemedialLessonService _remedialService;
  final WeakSpotDiagnosticEvaluator _weakSpotEvaluator;
  final AttemptRepository _attemptRepository;
  final ProgressRepository _progressRepository;

  LearningLoopOrchestrator({
    required AssessmentService assessmentService,
    required DiagnosticAssessmentService diagnosticService,
    required CurriculumService curriculumService,
    DeterministicStudyPlannerService studyPlannerService =
        const DeterministicStudyPlannerService(),
    required DeterministicRemedialLessonService remedialService,
    WeakSpotDiagnosticEvaluator weakSpotEvaluator =
        const WeakSpotDiagnosticEvaluator(),
    required AttemptRepository attemptRepository,
    required ProgressRepository progressRepository,
  })  : _assessmentService = assessmentService,
        _diagnosticService = diagnosticService,
        _curriculumService = curriculumService,
        _studyPlannerService = studyPlannerService,
        _remedialService = remedialService,
        _weakSpotEvaluator = weakSpotEvaluator,
        _attemptRepository = attemptRepository,
        _progressRepository = progressRepository;

  /// 1. Submits an assessment attempt into authoritative P18 storage.
  AttemptResult recordAssessmentAttempt({
    required String learnerId,
    required String questionId,
    required String objectiveId,
    required String submittedAnswer,
    String? attemptId,
    String? sessionId,
  }) {
    return _assessmentService.submitAttempt(
      learnerId: learnerId,
      questionId: questionId,
      objectiveId: objectiveId,
      submittedAnswer: submittedAnswer,
      attemptId: attemptId,
      sessionId: sessionId,
    );
  }

  /// 2. Executes P26 Diagnostic Placement Evaluation over target objectives.
  DiagnosticPlacementResult runDiagnosticPlacement({
    required String learnerId,
    required List<String> targetObjectiveIds,
    required DateTime evaluatedAt,
    String? requestId,
  }) {
    final req = DiagnosticAssessmentRequest(
      requestId: requestId ??
          'diag_${learnerId}_${evaluatedAt.toUtc().millisecondsSinceEpoch}',
      learnerId: learnerId,
      targetObjectiveIds: targetObjectiveIds,
      requestedAt: evaluatedAt,
    );
    return _diagnosticService.evaluatePlacement(req);
  }

  /// 3. Calculates P23 Weak-Spot Profile from authoritative P18 evidence.
  WeakSpotProfile evaluateWeakSpots({
    required String learnerId,
    required List<String> objectiveIds,
    required DateTime evaluatedAt,
    double weaknessThreshold = WeakSpotProfile.defaultWeaknessThreshold,
    int minimumEvidenceThreshold = 3,
  }) {
    final objectives = objectiveIds
        .map((id) => _curriculumService.getObjectiveById(id))
        .whereType<LearningObjective>()
        .toList();

    final progressList = _progressRepository.getProgressForLearner(learnerId);
    final attempts = _attemptRepository.getAttemptsForLearner(learnerId);
    final attemptResults = attempts
        .map((a) => _attemptRepository.getResultForAttempt(a.attemptId))
        .whereType<AttemptResult>()
        .toList();

    return _weakSpotEvaluator.evaluate(
      learnerId: learnerId,
      objectives: objectives,
      progressList: progressList,
      attempts: attempts,
      attemptResults: attemptResults,
      weaknessThreshold: weaknessThreshold,
      minimumEvidenceThreshold: minimumEvidenceThreshold,
      evaluatedAt: evaluatedAt,
    );
  }

  /// 4. Generates a P24 Dynamic Study Plan prioritized by P26 active frontier and P23 weak spots.
  StudyPlan generateFrontierStudyPlan({
    required String learnerId,
    required DiagnosticPlacementResult diagnosticResult,
    WeakSpotProfile? weakSpotProfile,
    required DateTime planningStart,
    required DateTime planningEnd,
    int dailyAvailableMinutes = 60,
    int preferredSessionDurationMinutes = 30,
    int maxSessionsPerDay = 2,
  }) {
    final frontierObjectiveIds =
        diagnosticResult.frontier.activeFrontierObjectiveIds;
    final availableObjectives = frontierObjectiveIds
        .map((id) => _curriculumService.getObjectiveById(id))
        .whereType<LearningObjective>()
        .toList();

    final request = StudyPlanRequest(
      learnerId: learnerId,
      planningWindowStart: planningStart,
      planningWindowEnd: planningEnd,
      scopedObjectiveIds: frontierObjectiveIds,
      requestedAt: planningStart,
      timeBudget: StudyTimeBudget(
        learnerId: learnerId,
        dailyAvailableMinutes: dailyAvailableMinutes,
        preferredSessionDurationMinutes: preferredSessionDurationMinutes,
        maxSessionsPerDay: maxSessionsPerDay,
        effectiveFrom: planningStart,
      ),
    );

    return _studyPlannerService.generatePlan(
      request: request,
      weakSpotProfile: weakSpotProfile,
      availableObjectives: availableObjectives,
    );
  }

  /// 5. Binds P25 Remedial Lessons for all remediation targets identified by P26.
  Future<Map<String, RemedialLesson?>> bindRemedialLessons({
    required DiagnosticPlacementResult diagnosticResult,
  }) async {
    final results = <String, RemedialLesson?>{};
    for (final objId
        in diagnosticResult.frontier.remediationTargetObjectiveIds) {
      final lesson = await _remedialService.findBestLessonForObjective(
        objectiveId: objId,
      );
      results[objId] = lesson;
    }
    return results;
  }

  /// 6. Generates a P25 Remedial Practice Session Config for targeted reassessment.
  RemedialPracticeSessionConfig createReassessmentConfig({
    required String learnerId,
    required RemedialLesson remedialLesson,
    required List<String> targetQuestionIds,
    required DateTime createdAt,
    int questionLimit = 5,
    String? configId,
  }) {
    return RemedialPracticeSessionConfig(
      configId: configId ??
          'reassess_${learnerId}_${remedialLesson.objectiveId}_${createdAt.toUtc().millisecondsSinceEpoch}',
      learnerId: learnerId,
      objectiveId: remedialLesson.objectiveId,
      remedialLessonId: remedialLesson.lessonId,
      targetQuestionIds: targetQuestionIds,
      questionLimit: questionLimit,
      createdAt: createdAt,
    );
  }

  /// 7. Submits a reassessment attempt and records updated P18 progress.
  AttemptResult submitReassessmentAttempt({
    required String learnerId,
    required String questionId,
    required String objectiveId,
    required String submittedAnswer,
    String? attemptId,
    String? sessionId,
  }) {
    return _assessmentService.submitAttempt(
      learnerId: learnerId,
      questionId: questionId,
      objectiveId: objectiveId,
      submittedAnswer: submittedAnswer,
      attemptId: attemptId,
      sessionId: sessionId,
    );
  }

  /// 8. Re-evaluates diagnostic placement after reassessment to verify progression.
  DiagnosticPlacementResult reevaluatePlacement({
    required String learnerId,
    required List<String> targetObjectiveIds,
    required DateTime evaluatedAt,
    String? requestId,
  }) {
    return runDiagnosticPlacement(
      learnerId: learnerId,
      targetObjectiveIds: targetObjectiveIds,
      evaluatedAt: evaluatedAt,
      requestId: requestId,
    );
  }
}
