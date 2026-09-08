/// Mastery Progression & Priority Queue Service (TITAN-KO-043.0 P43).
///
/// Production deterministic domain service deriving objective-level mastery classifications,
/// progression decisions, and prioritized learning queues from authoritative evidence.
library;

import 'dart:collection';

import 'package:garuda_pyq/garuda_pyq.dart';

import '../domain/entities/assessment_threshold_config.dart';
import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/content_learning_path.dart';
import '../domain/entities/diagnostic_placement_result.dart';
import '../domain/entities/learner_objective_status.dart';
import '../domain/entities/mastery_progression_decision.dart';
import '../domain/entities/objective_mastery_status.dart';
import '../domain/entities/personalized_learning_priority.dart';
import '../repository/diagnostic_placement_repository.dart';
import '../repository/session_checkpoint_repository.dart';
import 'authoritative_learning_state_recovery_service.dart';
import 'content_learning_path_service.dart';
import 'curriculum_service.dart';
import 'deterministic_remedial_lesson_service.dart';

/// Pure deterministic service managing objective mastery progression and prioritized queues.
class MasteryProgressionService {
  final CurriculumService _curriculumService;
  final AuthoritativeLearningStateRecoveryService _authRecoveryService;
  final SessionCheckpointRepository _checkpointRepository;
  final ContentLearningPathService? _contentService;
  final DiagnosticPlacementRepository? _diagnosticRepository;
  final DeterministicRemedialLessonService? _remedialService;
  final AssessmentThresholdConfig _thresholdConfig;
  final List<NormalizedQuestion> _seedQuestions;

  MasteryProgressionService({
    required CurriculumService curriculumService,
    required AuthoritativeLearningStateRecoveryService authRecoveryService,
    required SessionCheckpointRepository checkpointRepository,
    ContentLearningPathService? contentService,
    DiagnosticPlacementRepository? diagnosticRepository,
    DeterministicRemedialLessonService? remedialService,
    AssessmentThresholdConfig? thresholdConfig,
    List<NormalizedQuestion>? seedQuestions,
  })  : _curriculumService = curriculumService,
        _authRecoveryService = authRecoveryService,
        _checkpointRepository = checkpointRepository,
        _contentService = contentService,
        _diagnosticRepository = diagnosticRepository,
        _remedialService = remedialService,
        _thresholdConfig = thresholdConfig ??
            const AssessmentThresholdConfig(
              minimumAttempts: 3,
              minimumSuccessRate: 0.80,
            ),
        _seedQuestions = seedQuestions ?? const [];

  CurriculumService get curriculumService => _curriculumService;
  SessionCheckpointRepository get checkpointRepository => _checkpointRepository;

  // ---------------------------------------------------------------------------
  // 1. Objective-Level Progression Decisions (Pure Deterministic Logic)
  // ---------------------------------------------------------------------------

  /// Evaluates the progression decision for a single objective from available evidence.
  ObjectiveProgressionDecision evaluateObjective({
    required String objectiveId,
    required AuthoritativeLearnerState authState,
    DiagnosticPlacementResult? diagnosticResult,
    DateTime? evaluatedAt,
  }) {
    final effectiveTs = (evaluatedAt ?? DateTime.now()).toUtc();
    final cleanObjId = objectiveId.trim();

    final obj = _curriculumService.getObjectiveById(cleanObjId);
    final title = obj?.title ?? cleanObjId;

    // 1. Check prerequisite objectives
    final unmetPrereqs = <String>[];
    if (obj != null) {
      for (final prereq in obj.prerequisites) {
        final pId = prereq.prerequisiteObjectiveId;
        final pProg = authState.progressMap[pId];
        final isPrereqDemonstrated = diagnosticResult != null &&
            diagnosticResult.frontier.demonstratedObjectiveIds.contains(pId);
        final bool isPrereqAchieved = (pProg != null &&
                (pProg.isAchieved ||
                    pProg.status == LearnerObjectiveStatus.achieved ||
                    (pProg.attemptCount >= _thresholdConfig.minimumAttempts &&
                        pProg.successRate >=
                            _thresholdConfig.minimumSuccessRate))) ||
            isPrereqDemonstrated;

        if (!isPrereqAchieved) {
          unmetPrereqs.add(pId);
        }
      }
    }
    final bool hasUnmetPrereqs = unmetPrereqs.isNotEmpty;

    // 2. Authoritative and Diagnostic Evidence
    final progress = authState.progressMap[cleanObjId];
    final attempts = progress?.attemptCount ?? 0;
    final correct = progress?.correctCount ?? 0;
    final successRate = progress?.successRate ?? 0.0;

    final isDiagRemediation = diagnosticResult != null &&
        diagnosticResult.frontier.remediationTargetObjectiveIds
            .contains(cleanObjId);
    final isDiagDemonstrated = diagnosticResult != null &&
        diagnosticResult.frontier.demonstratedObjectiveIds.contains(cleanObjId);
    final isDiagFrontier = diagnosticResult != null &&
        diagnosticResult.frontier.activeFrontierObjectiveIds
            .contains(cleanObjId);
    final isDiagDeveloping = diagnosticResult != null &&
        diagnosticResult.frontier.developingObjectiveIds.contains(cleanObjId);

    // 3. Classify Stage & Mastery Status
    ObjectiveMasteryStatus masteryStatus;
    ProgressionStage stage;
    String rationale;

    final int minAttempts = _thresholdConfig.minimumAttempts;
    const double passThreshold = 0.50;
    final double masteryThreshold = _thresholdConfig.minimumSuccessRate;

    if (attempts == 0) {
      if (isDiagDemonstrated) {
        masteryStatus = ObjectiveMasteryStatus.mastered;
        stage = ProgressionStage.mastered;
        rationale =
            'Mastery demonstrated in diagnostic assessment baseline placement.';
      } else if (isDiagRemediation) {
        masteryStatus = ObjectiveMasteryStatus.remediationRequired;
        stage = ProgressionStage.remediationRequired;
        rationale =
            'Diagnostic assessment identified critical weakness requiring remediation.';
      } else if (isDiagFrontier || isDiagDeveloping) {
        masteryStatus = ObjectiveMasteryStatus.inProgress;
        stage = ProgressionStage.learning;
        rationale =
            'Diagnostic assessment placed this objective on your active learning frontier.';
      } else {
        masteryStatus = ObjectiveMasteryStatus.notAttempted;
        stage = ProgressionStage.notStarted;
        rationale = hasUnmetPrereqs
            ? 'Prerequisite foundational concepts must be satisfied before starting this objective.'
            : 'Curriculum objective scheduled; no attempts recorded yet.';
      }
    } else if (attempts < minAttempts) {
      if (isDiagRemediation) {
        masteryStatus = ObjectiveMasteryStatus.remediationRequired;
        stage = ProgressionStage.remediationRequired;
        rationale =
            'Diagnostic weakness confirmed by early attempts ($correct/$attempts correct); remediation recommended.';
      } else {
        masteryStatus = ObjectiveMasteryStatus.insufficientEvidence;
        stage = ProgressionStage.insufficientEvidence;
        rationale =
            'Insufficient evidence ($attempts/$minAttempts minimum attempts). Additional practice needed to establish baseline.';
      }
    } else {
      // attempts >= minAttempts
      final bool previouslyAchieved = (progress != null &&
              (progress.isAchieved ||
                  progress.status == LearnerObjectiveStatus.achieved)) ||
          isDiagDemonstrated;

      if (previouslyAchieved && successRate < passThreshold) {
        masteryStatus = ObjectiveMasteryStatus.regressed;
        stage = ProgressionStage.regressed;
        rationale =
            'Performance dropped to ${(successRate * 100).toInt()}% across $attempts attempts after prior mastery. Retention review or remediation required.';
      } else if (successRate < passThreshold || isDiagRemediation) {
        masteryStatus = ObjectiveMasteryStatus.remediationRequired;
        stage = ProgressionStage.remediationRequired;
        rationale =
            'Persistent difficulty observed (${(successRate * 100).toInt()}% accuracy across $attempts attempts). Targeted remediation required.';
      } else if (successRate >= masteryThreshold) {
        masteryStatus = ObjectiveMasteryStatus.mastered;
        stage = ProgressionStage.mastered;
        rationale =
            'Mastery criteria met ($correct/$attempts correct, ${(successRate * 100).toInt()}% accuracy). Scheduled for spaced retention revision.';
      } else if (successRate >= 0.65) {
        masteryStatus = ObjectiveMasteryStatus.inProgress;
        stage = ProgressionStage.improving;
        rationale =
            'Steady progress demonstrated ($correct/$attempts correct, ${(successRate * 100).toInt()}% accuracy). Reinforcement practice recommended to reach mastery threshold.';
      } else {
        masteryStatus = ObjectiveMasteryStatus.inProgress;
        stage = ProgressionStage.learning;
        rationale =
            'Active practice in development ($correct/$attempts correct, ${(successRate * 100).toInt()}% accuracy). Additional practice appropriate.';
      }
    }

    final bool isRemediationRequired =
        stage == ProgressionStage.remediationRequired ||
            stage == ProgressionStage.regressed;
    final bool canProgress = stage == ProgressionStage.mastered;
    final bool isAdditionalPracticeAppropriate =
        stage != ProgressionStage.mastered;
    final bool isRevisionAppropriate = stage == ProgressionStage.mastered;

    return ObjectiveProgressionDecision(
      objectiveId: cleanObjId,
      objectiveTitle: title,
      masteryStatus: masteryStatus,
      stage: stage,
      evidenceCount: attempts,
      correctCount: correct,
      successRate: successRate,
      isRemediationRequired: isRemediationRequired,
      isAdditionalPracticeAppropriate: isAdditionalPracticeAppropriate,
      canProgress: canProgress,
      isRevisionAppropriate: isRevisionAppropriate,
      hasUnmetPrerequisites: hasUnmetPrereqs,
      unmetPrerequisiteIds: unmetPrereqs,
      rationale: rationale,
      evaluatedAt: effectiveTs,
    );
  }

  /// Evaluates progression decisions for all objectives in the curriculum framework.
  Map<String, ObjectiveProgressionDecision> evaluateAllObjectives({
    required AuthoritativeLearnerState authState,
    DiagnosticPlacementResult? diagnosticResult,
    DateTime? evaluatedAt,
  }) {
    final effectiveTs = (evaluatedAt ?? DateTime.now()).toUtc();
    final results = SplayTreeMap<String, ObjectiveProgressionDecision>();

    final sequence = _curriculumService.getDeterministicSequence();
    final orderedObjectives = sequence.isNotEmpty
        ? sequence
        : _curriculumService.framework.allObjectives;

    for (final obj in orderedObjectives) {
      results[obj.id] = evaluateObjective(
        objectiveId: obj.id,
        authState: authState,
        diagnosticResult: diagnosticResult,
        evaluatedAt: effectiveTs,
      );
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // 2. Personalized Priority Queue Resolver
  // ---------------------------------------------------------------------------

  /// Resolves the ordered personalized learning queue for [learnerId] and [examId].
  Future<PersonalizedPriorityQueue> resolvePriorityQueue({
    required String learnerId,
    required String examId,
    DateTime? asOfDate,
    List<NormalizedQuestion>? corpus,
    DiagnosticPlacementResult? diagnosticResultOverride,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();
    final effectiveTs = (asOfDate ?? DateTime.now()).toUtc();
    final activeCorpus = corpus ?? _seedQuestions;

    if (cleanLearner.isEmpty) throw ArgumentError('learnerId cannot be empty');
    if (cleanExam.isEmpty) throw ArgumentError('examId cannot be empty');

    if (_curriculumService.framework.allObjectives.isEmpty) {
      return PersonalizedPriorityQueue.empty(
        learnerId: cleanLearner,
        examId: cleanExam,
        stateRevision: 0,
        evaluatedAt: effectiveTs,
      );
    }

    // 1. Recover Authoritative State
    final recovery = await _authRecoveryService.recover(
      learnerId: cleanLearner,
      examId: cleanExam,
      requestedAt: effectiveTs,
    );
    final authState = recovery.state ??
        AuthoritativeLearnerState.empty(
          learnerId: cleanLearner,
          examId: cleanExam,
          createdAt: effectiveTs,
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

    // 3. Query Diagnostic Placement
    final diagnosticResult = diagnosticResultOverride ??
        _diagnosticRepository?.getLatestResultForLearner(cleanLearner);

    // 4. Discover Content Coordinates
    final subjects = _contentService?.getSubjectsForExam(cleanExam) ??
        [
          const SubjectContext(
            id: 'indian_polity',
            name: 'Indian Polity',
            examId: 'upsc_prelims_gs1',
          ),
        ];

    final allTopics = <TopicContext>[];
    final cService = _contentService;
    if (cService != null) {
      for (final s in subjects) {
        allTopics.addAll(
          cService.getTopicsForSubject(cleanExam, s.id, corpus: activeCorpus),
        );
      }
    }

    TopicContext? findTopic(String objectiveId) {
      for (final t in allTopics) {
        if (t.objectiveId == objectiveId) return t;
      }
      return null;
    }

    int countQuestions(String objectiveId, String topicName) {
      final oLower = objectiveId.trim().toLowerCase();
      final tLower = topicName.trim().toLowerCase();
      return activeCorpus.where((q) {
        return q.objectiveIds.any((oid) => oid.trim().toLowerCase() == oLower) ||
            q.topic.trim().toLowerCase() == tLower ||
            q.objectiveIds.any((oid) => oid.trim().toLowerCase() == tLower);
      }).length;
    }

    // 5. Evaluate all objective decisions
    final objectiveDecisions = evaluateAllObjectives(
      authState: authState,
      diagnosticResult: diagnosticResult,
      evaluatedAt: effectiveTs,
    );

    final queueItems = <PersonalizedLearningPriorityItem>[];
    final processedObjectiveIds = <String>{};

    // -------------------------------------------------------------------------
    // Priority Tier 1: Unfinished Active Learning (Resumption)
    // -------------------------------------------------------------------------
    for (final cp in uncompletedCheckpoints) {
      final objId = cp.activeObjectiveId;
      if (objId.isEmpty || processedObjectiveIds.contains(objId)) continue;

      final obj = _curriculumService.getObjectiveById(objId);
      final topic = findTopic(objId);
      final topicName = topic?.name ??
          cp.metadata['topic']?.toString() ??
          obj?.title ??
          'Active Practice Drill';
      final subjectName = topic != null
          ? (subjects
              .firstWhere((s) => s.id == topic.subjectId,
                  orElse: () => subjects.first)
              .name)
          : 'Indian Polity';

      final totalQ = cp.metadata['totalQuestions'] as int? ??
          (cp.completedQuestionIds.length + 3);
      final cursor = cp.questionIndex;
      final progressPct = totalQ > 0
          ? (cp.completedQuestionIds.length / totalQ).clamp(0.0, 1.0)
          : 0.0;

      final decision = objectiveDecisions[objId];

      queueItems.add(
        PersonalizedLearningPriorityItem(
          id: 'prio_resume_${cp.sessionId}',
          examId: cleanExam,
          subjectId: topic?.subjectId ?? 'indian_polity',
          subjectName: subjectName,
          topicId: topic?.id ?? 'fundamental_rights',
          topicName: topicName,
          objectiveId: objId,
          objectiveTitle: obj?.title ?? topicName,
          masteryState:
              decision?.masteryStatus ?? ObjectiveMasteryStatus.inProgress,
          stage: decision?.stage ?? ProgressionStage.learning,
          priorityRank: queueItems.length + 1,
          action: PriorityActionType.continueSession,
          reason:
              'Continue unfinished practice session on $topicName from question ${cursor + 1} of $totalQ',
          progress: progressPct,
          evidenceCount: decision?.evidenceCount ?? 0,
          accuracy: decision?.successRate ?? 0.0,
          sessionId: cp.sessionId,
          questionCursor: cursor,
          targetQuestionCount: totalQ,
          isAvailable: true,
          isExecutable: true,
        ),
      );
      processedObjectiveIds.add(objId);
    }

    // -------------------------------------------------------------------------
    // Cold Start Check: No evidence, no diagnostic, no active session
    // -------------------------------------------------------------------------
    final bool isColdStart = authState.progressMap.isEmpty &&
        diagnosticResult == null &&
        uncompletedCheckpoints.isEmpty;

    if (isColdStart) {
      queueItems.add(
        PersonalizedLearningPriorityItem(
          id: 'prio_diag_cold_start',
          examId: cleanExam,
          subjectId: 'indian_polity',
          subjectName: 'Indian Polity',
          topicId: 'fundamental_rights',
          topicName: 'Indian Polity & Constitution',
          objectiveId: 'lo_article_21_foundations',
          objectiveTitle: 'Evaluate the Expansion of Article 21 Rights',
          masteryState: ObjectiveMasteryStatus.notAttempted,
          stage: ProgressionStage.notStarted,
          priorityRank: queueItems.length + 1,
          action: PriorityActionType.takeDiagnostic,
          reason:
              'Diagnostic indicates baseline knowledge must be evaluated to map personalized start point',
          progress: 0.0,
          evidenceCount: 0,
          accuracy: 0.0,
          targetQuestionCount: 5,
          isAvailable: true,
          isExecutable: true,
        ),
      );
      processedObjectiveIds.add('lo_article_21_foundations');
    }

    // Collect all framework prerequisite target objective IDs
    final allPrereqObjectiveIds = <String>{};
    for (final obj in _curriculumService.framework.allObjectives) {
      for (final p in obj.prerequisites) {
        allPrereqObjectiveIds.add(p.prerequisiteObjectiveId);
      }
    }

    // Lists for tiered prioritization
    final remediationItems = <PersonalizedLearningPriorityItem>[];
    final weakItems = <PersonalizedLearningPriorityItem>[];
    final prerequisiteItems = <PersonalizedLearningPriorityItem>[];
    final insufficientEvidenceItems = <PersonalizedLearningPriorityItem>[];
    final improvingItems = <PersonalizedLearningPriorityItem>[];
    final revisionItems = <PersonalizedLearningPriorityItem>[];
    final remainingCurriculumItems = <PersonalizedLearningPriorityItem>[];
    final completedItems = <PersonalizedLearningPriorityItem>[];

    for (final entry in objectiveDecisions.entries) {
      final objId = entry.key;
      final decision = entry.value;

      if (processedObjectiveIds.contains(objId)) continue;

      final obj = _curriculumService.getObjectiveById(objId);
      final topic = findTopic(objId);
      final topicName = topic?.name ?? obj?.title ?? objId;
      final subjectId = topic?.subjectId ?? 'indian_polity';
      final subject = subjects.firstWhere(
        (s) => s.id == subjectId,
        orElse: () => subjects.first,
      );
      final qCount = countQuestions(objId, topicName) > 0
          ? countQuestions(objId, topicName)
          : (topic?.questionCount ?? 0);
      final bool hasContent = qCount > 0;

      // -----------------------------------------------------------------------
      // Priority Tier 2: Remediation Required
      // -----------------------------------------------------------------------
      if (decision.stage == ProgressionStage.remediationRequired) {
        String? lessonId;
        final remService = _remedialService;
        if (remService != null) {
          final lesson = await remService.findBestLessonForObjective(
            objectiveId: objId,
          );
          lessonId = lesson?.lessonId;
        }

        remediationItems.add(
          PersonalizedLearningPriorityItem(
            id: 'prio_rem_$objId',
            examId: cleanExam,
            subjectId: subject.id,
            subjectName: subject.name,
            topicId: topic?.id ?? objId,
            topicName: topicName,
            objectiveId: objId,
            objectiveTitle: decision.objectiveTitle,
            masteryState: decision.masteryStatus,
            stage: decision.stage,
            priorityRank: 0,
            action: lessonId != null
                ? PriorityActionType.startRemedialLesson
                : PriorityActionType.practice,
            reason: decision.rationale,
            progress: 0.0,
            evidenceCount: decision.evidenceCount,
            accuracy: decision.successRate,
            remedialLessonId: lessonId,
            targetQuestionCount: qCount,
            isAvailable: hasContent || lessonId != null,
            isExecutable: hasContent || lessonId != null,
          ),
        );
        processedObjectiveIds.add(objId);
        continue;
      }

      // -----------------------------------------------------------------------
      // Priority Tier 3: Weak / Regressed Objectives
      // -----------------------------------------------------------------------
      if (decision.stage == ProgressionStage.regressed) {
        weakItems.add(
          PersonalizedLearningPriorityItem(
            id: 'prio_reg_$objId',
            examId: cleanExam,
            subjectId: subject.id,
            subjectName: subject.name,
            topicId: topic?.id ?? objId,
            topicName: topicName,
            objectiveId: objId,
            objectiveTitle: decision.objectiveTitle,
            masteryState: decision.masteryStatus,
            stage: decision.stage,
            priorityRank: 0,
            action: PriorityActionType.practice,
            reason: decision.rationale,
            progress: 0.0,
            evidenceCount: decision.evidenceCount,
            accuracy: decision.successRate,
            targetQuestionCount: qCount,
            isAvailable: hasContent,
            isExecutable: hasContent,
          ),
        );
        processedObjectiveIds.add(objId);
        continue;
      }

      // -----------------------------------------------------------------------
      // Priority Tier 4: Incomplete Prerequisite Foundational Objectives
      // -----------------------------------------------------------------------
      if (!decision.hasUnmetPrerequisites &&
          allPrereqObjectiveIds.contains(objId) &&
          decision.stage != ProgressionStage.mastered) {
        prerequisiteItems.add(
          PersonalizedLearningPriorityItem(
            id: 'prio_prereq_$objId',
            examId: cleanExam,
            subjectId: subject.id,
            subjectName: subject.name,
            topicId: topic?.id ?? objId,
            topicName: topicName,
            objectiveId: objId,
            objectiveTitle: decision.objectiveTitle,
            masteryState: decision.masteryStatus,
            stage: decision.stage,
            priorityRank: 0,
            action: PriorityActionType.practice,
            reason: hasContent
                ? 'Prerequisite foundational concept required before proceeding to advanced syllabus units'
                : 'Prerequisite foundational concept; questions currently in acquisition',
            progress: decision.evidenceCount > 0 ? 0.5 : 0.0,
            evidenceCount: decision.evidenceCount,
            accuracy: decision.successRate,
            targetQuestionCount: qCount,
            isAvailable: hasContent,
            isExecutable: hasContent,
          ),
        );
        processedObjectiveIds.add(objId);
        continue;
      }

      // -----------------------------------------------------------------------
      // Priority Tier 5: Insufficient Evidence (1-2 attempts)
      // -----------------------------------------------------------------------
      if (decision.stage == ProgressionStage.insufficientEvidence) {
        insufficientEvidenceItems.add(
          PersonalizedLearningPriorityItem(
            id: 'prio_insev_$objId',
            examId: cleanExam,
            subjectId: subject.id,
            subjectName: subject.name,
            topicId: topic?.id ?? objId,
            topicName: topicName,
            objectiveId: objId,
            objectiveTitle: decision.objectiveTitle,
            masteryState: decision.masteryStatus,
            stage: decision.stage,
            priorityRank: 0,
            action: PriorityActionType.practice,
            reason: decision.rationale,
            progress: (decision.evidenceCount / _thresholdConfig.minimumAttempts)
                .clamp(0.0, 1.0),
            evidenceCount: decision.evidenceCount,
            accuracy: decision.successRate,
            targetQuestionCount: qCount,
            isAvailable: hasContent,
            isExecutable: hasContent,
          ),
        );
        processedObjectiveIds.add(objId);
        continue;
      }

      // -----------------------------------------------------------------------
      // Priority Tier 6: Improving / Ready for Reinforcement (65% - 79%)
      // -----------------------------------------------------------------------
      if (decision.stage == ProgressionStage.improving ||
          decision.stage == ProgressionStage.learning) {
        improvingItems.add(
          PersonalizedLearningPriorityItem(
            id: 'prio_imp_$objId',
            examId: cleanExam,
            subjectId: subject.id,
            subjectName: subject.name,
            topicId: topic?.id ?? objId,
            topicName: topicName,
            objectiveId: objId,
            objectiveTitle: decision.objectiveTitle,
            masteryState: decision.masteryStatus,
            stage: decision.stage,
            priorityRank: 0,
            action: PriorityActionType.practice,
            reason: decision.rationale,
            progress: decision.successRate,
            evidenceCount: decision.evidenceCount,
            accuracy: decision.successRate,
            targetQuestionCount: qCount,
            isAvailable: hasContent,
            isExecutable: hasContent,
          ),
        );
        processedObjectiveIds.add(objId);
        continue;
      }

      // -----------------------------------------------------------------------
      // Priority Tier 7: Mastered Objectives (Revision)
      // -----------------------------------------------------------------------
      if (decision.stage == ProgressionStage.mastered) {
        revisionItems.add(
          PersonalizedLearningPriorityItem(
            id: 'prio_rev_$objId',
            examId: cleanExam,
            subjectId: subject.id,
            subjectName: subject.name,
            topicId: topic?.id ?? objId,
            topicName: topicName,
            objectiveId: objId,
            objectiveTitle: decision.objectiveTitle,
            masteryState: decision.masteryStatus,
            stage: decision.stage,
            priorityRank: 0,
            action: PriorityActionType.reviewRevision,
            reason: decision.rationale,
            progress: 1.0,
            evidenceCount: decision.evidenceCount,
            accuracy: decision.successRate,
            targetQuestionCount: qCount,
            isAvailable: hasContent,
            isExecutable: hasContent,
          ),
        );
        processedObjectiveIds.add(objId);
        continue;
      }

      // -----------------------------------------------------------------------
      // Priority Tier 8: Remaining Syllabus Topics (Not Started)
      // -----------------------------------------------------------------------
      remainingCurriculumItems.add(
        PersonalizedLearningPriorityItem(
          id: 'prio_sched_$objId',
          examId: cleanExam,
          subjectId: subject.id,
          subjectName: subject.name,
          topicId: topic?.id ?? objId,
          topicName: topicName,
          objectiveId: objId,
          objectiveTitle: decision.objectiveTitle,
          masteryState: decision.masteryStatus,
          stage: decision.stage,
          priorityRank: 0,
          action: PriorityActionType.practice,
          reason: decision.rationale,
          progress: 0.0,
          evidenceCount: 0,
          accuracy: 0.0,
          targetQuestionCount: qCount,
          isAvailable: hasContent,
          isExecutable: hasContent && !decision.hasUnmetPrerequisites,
        ),
      );
      processedObjectiveIds.add(objId);
    }

    // Sort remediation items by lowest accuracy first, then attempt count
    remediationItems.sort((a, b) {
      final accComp = a.accuracy.compareTo(b.accuracy);
      if (accComp != 0) return accComp;
      return b.evidenceCount.compareTo(a.evidenceCount);
    });

    // Sort improving items by highest accuracy first (closest to mastery)
    improvingItems.sort((a, b) => b.accuracy.compareTo(a.accuracy));

    // Combine all tiers deterministically
    final allOrdered = <PersonalizedLearningPriorityItem>[
      ...queueItems,
      ...remediationItems,
      ...weakItems,
      ...prerequisiteItems,
      ...insufficientEvidenceItems,
      ...improvingItems,
      ...revisionItems,
      ...remainingCurriculumItems,
      ...completedItems,
    ];

    // Assign sequential 1-based priority ranks
    final rankedItems = <PersonalizedLearningPriorityItem>[];
    for (var i = 0; i < allOrdered.length; i++) {
      rankedItems.add(
        allOrdered[i].copyWith(priorityRank: i + 1),
      );
    }

    // First executable item is currentPriority
    PersonalizedLearningPriorityItem? topPriority;
    for (final item in rankedItems) {
      if (item.isExecutable && item.action != PriorityActionType.completed) {
        topPriority = item;
        break;
      }
    }

    final queueId =
        'prio_q_${cleanLearner}_${cleanExam}_rev${authState.revision}';

    return PersonalizedPriorityQueue(
      queueId: queueId,
      learnerId: cleanLearner,
      examId: cleanExam,
      stateRevision: authState.revision,
      evaluatedAt: effectiveTs,
      currentPriority: topPriority,
      items: rankedItems,
      objectiveDecisions: objectiveDecisions,
    );
  }
}
