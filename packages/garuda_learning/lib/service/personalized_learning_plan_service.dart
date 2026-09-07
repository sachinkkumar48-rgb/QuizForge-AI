/// Personalized Learning Plan Service (TITAN-KO-043.0 P43).
///
/// Pure deterministic domain service formulating an explainable, executable,
/// and closed-loop personalized learning plan for QuizForge AI.
///
/// Prioritization pipeline:
/// 1. Incomplete / recoverable in-flight learning sessions
/// 2. Diagnosed weaknesses & persistent failure remediation
/// 3. Prerequisite foundational objectives
/// 4. Active knowledge frontier practice
/// 5. Remaining curriculum syllabus topics
/// 6. Spaced revision & reinforcement of achieved milestones
library;

import 'package:garuda_pyq/garuda_pyq.dart';

import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/content_learning_path.dart';
import '../domain/entities/diagnostic_placement_result.dart';
import '../domain/entities/learner_objective_status.dart';
import '../domain/entities/personalized_learning_plan.dart';
import '../repository/diagnostic_placement_repository.dart';
import '../repository/session_checkpoint_repository.dart';
import 'authoritative_learning_state_recovery_service.dart';
import 'content_learning_path_service.dart';
import 'curriculum_service.dart';
import 'deterministic_remedial_lesson_service.dart';

/// Service formulating personalized learning plans from authoritative evidence.
class PersonalizedLearningPlanService {
  final CurriculumService _curriculumService;
  final AuthoritativeLearningStateRecoveryService _authRecoveryService;
  final SessionCheckpointRepository _checkpointRepository;
  final ContentLearningPathService _contentService;
  final DiagnosticPlacementRepository? _diagnosticRepository;
  final DeterministicRemedialLessonService? _remedialService;
  final List<NormalizedQuestion> _seedQuestions;

  PersonalizedLearningPlanService({
    required CurriculumService curriculumService,
    required AuthoritativeLearningStateRecoveryService authRecoveryService,
    required SessionCheckpointRepository checkpointRepository,
    required ContentLearningPathService contentService,
    DiagnosticPlacementRepository? diagnosticRepository,
    DeterministicRemedialLessonService? remedialService,
    List<NormalizedQuestion>? seedQuestions,
  })  : _curriculumService = curriculumService,
        _authRecoveryService = authRecoveryService,
        _checkpointRepository = checkpointRepository,
        _contentService = contentService,
        _diagnosticRepository = diagnosticRepository,
        _remedialService = remedialService,
        _seedQuestions = seedQuestions ?? const [];

  /// Generates a deterministic personalized learning plan for [learnerId] and [examId].
  Future<PersonalizedLearningPlan> generatePlan({
    required String learnerId,
    required String examId,
    DateTime? asOfDate,
    List<NormalizedQuestion>? corpus,
    DiagnosticPlacementResult? diagnosticResultOverride,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();
    final effectiveDate = (asOfDate ?? DateTime.now()).toUtc();
    final activeCorpus = corpus ?? _seedQuestions;

    if (cleanLearner.isEmpty) {
      throw ArgumentError('learnerId cannot be blank');
    }
    if (cleanExam.isEmpty) {
      throw ArgumentError('examId cannot be blank');
    }

    // 1. Recover Authoritative Learner State
    final recoveryResult = await _authRecoveryService.recover(
      learnerId: cleanLearner,
      examId: cleanExam,
      requestedAt: effectiveDate,
    );

    final authState = recoveryResult.state ??
        AuthoritativeLearnerState.empty(
          learnerId: cleanLearner,
          examId: cleanExam,
          createdAt: effectiveDate,
        );

    // 2. Query In-Flight Checkpoints
    final checkpoints = await _checkpointRepository.listCheckpoints(
      learnerId: cleanLearner,
      examId: cleanExam,
    );
    final uncompletedCheckpoints = checkpoints
        .where((cp) => !cp.isCompleted)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 3. Query Diagnostic Placement Evidence
    final diagnosticResult = diagnosticResultOverride ??
        _diagnosticRepository?.getLatestResultForLearner(cleanLearner);

    // 4. Discover Content Coordinates
    final subjects = _contentService.getSubjectsForExam(cleanExam);
    final allTopics = <TopicContext>[];
    for (final s in subjects) {
      allTopics.addAll(
        _contentService.getTopicsForSubject(cleanExam, s.id,
            corpus: activeCorpus),
      );
    }

    TopicContext? findTopicForObjective(String objectiveId) {
      for (final t in allTopics) {
        if (t.objectiveId == objectiveId) return t;
      }
      return null;
    }

    int countQuestionsForTopic(String topicName) {
      final tLower = topicName.trim().toLowerCase();
      return activeCorpus.where((q) {
        return q.topic.trim().toLowerCase() == tLower ||
            q.objectiveIds.any((oid) => oid.trim().toLowerCase() == tLower);
      }).length;
    }

    final rawActions = <PersonalizedLearningAction>[];
    final processedObjectiveIds = <String>{};

    // Priority 1: In-Flight Session Checkpoints (Resumption)
    for (final cp in uncompletedCheckpoints) {
      final objId = cp.activeObjectiveId;
      if (objId.isEmpty) continue;

      final obj = _curriculumService.getObjectiveById(objId);
      final topic = findTopicForObjective(objId);
      final topicName = topic?.name ??
          cp.metadata['topic']?.toString() ??
          obj?.title ??
          'Practice Drill';
      final subjectName = topic != null
          ? (subjects
              .firstWhere((s) => s.id == topic.subjectId,
                  orElse: () => subjects.first)
              .name)
          : 'Indian Polity';
      final totalQ = cp.metadata['totalQuestions'] as int? ??
          (cp.completedQuestionIds.length + 3);
      final cursor = cp.questionIndex;

      rawActions.add(
        PersonalizedLearningAction(
          id: 'act_resume_${cp.sessionId}',
          examId: cleanExam,
          subjectId: topic?.subjectId ?? 'indian_polity',
          subjectName: subjectName,
          topicId: topic?.id ?? 'fundamental_rights',
          topicName: topicName,
          objectiveId: objId,
          objectiveTitle: obj?.title ?? topicName,
          actionType: PlanActionType.continueSession,
          orderIndex: 0,
          reasonCode: PlanReasonCode.inFlightSession,
          reason:
              'Continue unfinished practice session on $topicName from question ${cursor + 1} of $totalQ',
          status: PlanActionStatus.recommended,
          sessionId: cp.sessionId,
          sessionCursor: cursor,
          targetQuestionCount: totalQ,
          isExecutable: true,
        ),
      );
      processedObjectiveIds.add(objId);
    }

    // Check if Cold-Start Diagnostic is Required
    final bool isColdStart = authState.progressMap.isEmpty &&
        diagnosticResult == null &&
        uncompletedCheckpoints.isEmpty;

    if (isColdStart) {
      rawActions.add(
        const PersonalizedLearningAction(
          id: 'act_diag_cold_start',
          examId: 'upsc_prelims_gs1',
          subjectId: 'indian_polity',
          subjectName: 'Indian Polity',
          topicId: 'fundamental_rights',
          topicName: 'Indian Polity & Constitution',
          objectiveId: 'lo_article_21_foundations',
          objectiveTitle: 'Evaluate the Expansion of Article 21 Rights',
          actionType: PlanActionType.takeDiagnostic,
          orderIndex: 0,
          reasonCode: PlanReasonCode.activeFrontier,
          reason:
              'Diagnostic indicates baseline knowledge must be evaluated to map personalized start point',
          status: PlanActionStatus.recommended,
          targetQuestionCount: 5,
          isExecutable: true,
        ),
      );
      processedObjectiveIds.add('lo_article_21_foundations');
    }

    // 5. Evaluate Objectives from Framework Sequence
    final sequence = _curriculumService.getDeterministicSequence();
    final orderedObjectives = sequence.isNotEmpty
        ? sequence
        : _curriculumService.framework.allObjectives;

    final weaknessActions = <PersonalizedLearningAction>[];
    final prerequisiteActions = <PersonalizedLearningAction>[];
    final frontierActions = <PersonalizedLearningAction>[];
    final remainingActions = <PersonalizedLearningAction>[];
    final completedActions = <PersonalizedLearningAction>[];

    // Collect all prerequisite objective IDs across framework
    final allPrerequisiteObjectiveIds = <String>{};
    for (final o in orderedObjectives) {
      for (final p in o.prerequisites) {
        allPrerequisiteObjectiveIds.add(p.prerequisiteObjectiveId);
      }
    }

    for (final obj in orderedObjectives) {
      if (processedObjectiveIds.contains(obj.id)) continue;

      final topic = findTopicForObjective(obj.id);
      final topicName = topic?.name ?? obj.title;
      final subjectId = topic?.subjectId ?? 'indian_polity';
      final subject = subjects.firstWhere(
        (s) => s.id == subjectId,
        orElse: () => subjects.isNotEmpty
            ? subjects.first
            : const SubjectContext(
                id: 'indian_polity',
                name: 'Indian Polity',
                examId: 'upsc_prelims_gs1',
              ),
      );
      final qCount = topic != null
          ? topic.questionCount
          : countQuestionsForTopic(topicName);
      final bool hasContent = qCount > 0;

      final progress = authState.progressMap[obj.id];
      final diagObj = diagnosticResult?.objectiveResults[obj.id];
      final isDiagRemediation = diagnosticResult
              ?.frontier.remediationTargetObjectiveIds
              .contains(obj.id) ??
          false;
      final isDiagActiveFrontier = diagnosticResult
              ?.frontier.activeFrontierObjectiveIds
              .contains(obj.id) ??
          false;
      final isDiagDeveloping =
          diagnosticResult?.frontier.developingObjectiveIds.contains(obj.id) ??
              false;

      final bool isAchieved = progress != null &&
          (progress.isAchieved ||
              progress.status == LearnerObjectiveStatus.achieved);
      final bool isWeak = isDiagRemediation ||
          (progress != null &&
              progress.attemptCount >= 3 &&
              progress.successRate < 0.6);
      final bool hasAttempts = progress != null && progress.attemptCount > 0;

      // Completed Objective
      if (isAchieved) {
        completedActions.add(
          PersonalizedLearningAction(
            id: 'act_comp_${obj.id}',
            examId: cleanExam,
            subjectId: subject.id,
            subjectName: subject.name,
            topicId: topic?.id ?? obj.id,
            topicName: topicName,
            objectiveId: obj.id,
            objectiveTitle: obj.title,
            actionType: PlanActionType.reviewRevision,
            orderIndex: 0,
            reasonCode: PlanReasonCode.revisionReinforcement,
            reason:
                'Mastery achieved (${progress.correctCount}/${progress.attemptCount} correct, ${(progress.successRate * 100).toInt()}% accuracy). Scheduled for spaced retention review',
            status: PlanActionStatus.completed,
            targetQuestionCount: qCount,
            isExecutable: hasContent,
          ),
        );
        processedObjectiveIds.add(obj.id);
        continue;
      }

      // Weak Spot / Remedial Action
      if (isWeak) {
        String? lessonId;
        final remedialService = _remedialService;
        if (remedialService != null) {
          final lesson = await remedialService.findBestLessonForObjective(
            objectiveId: obj.id,
          );
          lessonId = lesson?.lessonId;
        }

        final baseReason = isDiagRemediation
            ? 'Diagnostic indicates this objective needs remediation: ${(diagObj?.observedAccuracy != null ? "${(diagObj!.observedAccuracy! * 100).toInt()}% accuracy" : "developing performance")}'
            : 'Remedial lesson recommended for conceptual gaps (${(progress!.successRate * 100).toInt()}% accuracy over ${progress.attemptCount} attempts)';
        final reasonStr = (lessonId == null && !hasContent)
            ? '$baseReason; questions currently in acquisition'
            : baseReason;

        weaknessActions.add(
          PersonalizedLearningAction(
            id: 'act_rem_${obj.id}',
            examId: cleanExam,
            subjectId: subject.id,
            subjectName: subject.name,
            topicId: topic?.id ?? obj.id,
            topicName: topicName,
            objectiveId: obj.id,
            objectiveTitle: obj.title,
            actionType: lessonId != null
                ? PlanActionType.startRemedialLesson
                : PlanActionType.practiceObjective,
            orderIndex: 0,
            reasonCode: isDiagRemediation
                ? PlanReasonCode.diagnosticWeakness
                : PlanReasonCode.persistentFailure,
            reason: reasonStr,
            status: PlanActionStatus.pending,
            remedialLessonId: lessonId,
            targetQuestionCount: qCount,
            isExecutable: hasContent || lessonId != null,
          ),
        );
        processedObjectiveIds.add(obj.id);
        continue;
      }

      // Active Frontier Practice (in-progress attempts or diagnostic frontier)
      if (hasAttempts || isDiagActiveFrontier || isDiagDeveloping) {
        final reasonStr = !hasContent
            ? 'Active learning frontier; questions currently in acquisition'
            : (progress != null)
                ? 'Practice recommended to advance competency toward mastery threshold (${(progress.successRate * 100).toInt()}% current accuracy)'
                : 'Diagnostic identified this objective on your active learning frontier';

        frontierActions.add(
          PersonalizedLearningAction(
            id: 'act_front_${obj.id}',
            examId: cleanExam,
            subjectId: subject.id,
            subjectName: subject.name,
            topicId: topic?.id ?? obj.id,
            topicName: topicName,
            objectiveId: obj.id,
            objectiveTitle: obj.title,
            actionType: PlanActionType.practiceObjective,
            orderIndex: 0,
            reasonCode: PlanReasonCode.activeFrontier,
            reason: reasonStr,
            status: PlanActionStatus.pending,
            targetQuestionCount: qCount,
            isExecutable: hasContent,
          ),
        );
        processedObjectiveIds.add(obj.id);
        continue;
      }

      // Check for Unmet Prerequisites
      final bool hasUnmetPrereqs = obj.prerequisites.any((prereq) {
        final pProg = authState.progressMap[prereq.prerequisiteObjectiveId];
        return pProg == null ||
            (!pProg.isAchieved &&
                pProg.status != LearnerObjectiveStatus.achieved);
      });

      // Foundational Prerequisite Action (unstarted objective that unlocks subsequent topics)
      if (!hasUnmetPrereqs && allPrerequisiteObjectiveIds.contains(obj.id)) {
        prerequisiteActions.add(
          PersonalizedLearningAction(
            id: 'act_prereq_${obj.id}',
            examId: cleanExam,
            subjectId: subject.id,
            subjectName: subject.name,
            topicId: topic?.id ?? obj.id,
            topicName: topicName,
            objectiveId: obj.id,
            objectiveTitle: obj.title,
            actionType: PlanActionType.practiceObjective,
            orderIndex: 0,
            reasonCode: PlanReasonCode.prerequisiteFoundation,
            reason: hasContent
                ? 'Prerequisite foundational concept required before proceeding to advanced curriculum units'
                : 'Prerequisite foundational concept required before proceeding; questions currently in acquisition',
            status: PlanActionStatus.pending,
            targetQuestionCount: qCount,
            isExecutable: hasContent,
          ),
        );
        processedObjectiveIds.add(obj.id);
        continue;
      }

      // Remaining Syllabus Topic (or topic pending prerequisites)
      remainingActions.add(
        PersonalizedLearningAction(
          id: 'act_sched_${obj.id}',
          examId: cleanExam,
          subjectId: subject.id,
          subjectName: subject.name,
          topicId: topic?.id ?? obj.id,
          topicName: topicName,
          objectiveId: obj.id,
          objectiveTitle: obj.title,
          actionType: PlanActionType.practiceObjective,
          orderIndex: 0,
          reasonCode: PlanReasonCode.curriculumRemaining,
          reason: hasContent
              ? (hasUnmetPrereqs
                  ? 'Curriculum topic pending completion of prerequisite foundational units'
                  : 'Foundational syllabus topic scheduled in deterministic curriculum sequence')
              : 'Topic scheduled in curriculum sequence; questions currently in acquisition',
          status: PlanActionStatus.pending,
          targetQuestionCount: qCount,
          isExecutable: hasContent,
        ),
      );
      processedObjectiveIds.add(obj.id);
    }

    // 6. Assemble Actions in Deterministic Priority Order
    final combinedActions = <PersonalizedLearningAction>[
      ...rawActions,
      ...weaknessActions,
      ...frontierActions,
      ...prerequisiteActions,
      ...remainingActions,
      ...completedActions,
    ];

    // Ensure strictly one action is marked 'recommended'
    bool hasRecommended = false;
    final finalActions = <PersonalizedLearningAction>[];

    for (int i = 0; i < combinedActions.length; i++) {
      final act = combinedActions[i];
      PlanActionStatus adjustedStatus = act.status;

      if (act.status == PlanActionStatus.completed) {
        adjustedStatus = PlanActionStatus.completed;
      } else if (!hasRecommended) {
        adjustedStatus = PlanActionStatus.recommended;
        hasRecommended = true;
      } else {
        adjustedStatus = PlanActionStatus.pending;
      }

      finalActions.add(
        act.copyWith(
          orderIndex: i,
          status: adjustedStatus,
        ),
      );
    }

    // Deterministic Plan ID
    final planId = 'plan_${cleanLearner}_${cleanExam}_rev${authState.revision}';

    return PersonalizedLearningPlan(
      planId: planId,
      learnerId: cleanLearner,
      examId: cleanExam,
      generatedAt: effectiveDate,
      stateRevision: authState.revision,
      actions: finalActions,
    );
  }
}
