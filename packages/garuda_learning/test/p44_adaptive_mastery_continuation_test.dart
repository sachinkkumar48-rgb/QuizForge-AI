/// P44 Adaptive Mastery Continuation Unit Test Suite (TITAN-KO-044.0).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P44 Domain Models & Serialization Tests', () {
    final baseDate = DateTime.utc(2026, 9, 6, 12, 0, 0);

    test('ObjectiveMasteryStatus properties and display names', () {
      expect(ObjectiveMasteryStatus.notAttempted.isMastered, isFalse);
      expect(ObjectiveMasteryStatus.notAttempted.isStruggling, isFalse);
      expect(ObjectiveMasteryStatus.notAttempted.hasEvidence, isFalse);
      expect(ObjectiveMasteryStatus.notAttempted.displayName,
          equals('Not Attempted'));

      expect(ObjectiveMasteryStatus.insufficientEvidence.isMastered, isFalse);
      expect(ObjectiveMasteryStatus.insufficientEvidence.hasEvidence, isTrue);
      expect(ObjectiveMasteryStatus.insufficientEvidence.displayName,
          equals('Insufficient Evidence'));

      expect(ObjectiveMasteryStatus.inProgress.isMastered, isFalse);
      expect(
          ObjectiveMasteryStatus.inProgress.displayName, equals('In Progress'));

      expect(ObjectiveMasteryStatus.mastered.isMastered, isTrue);
      expect(ObjectiveMasteryStatus.mastered.isStruggling, isFalse);
      expect(ObjectiveMasteryStatus.mastered.displayName, equals('Mastered'));

      expect(ObjectiveMasteryStatus.remediationRequired.isMastered, isFalse);
      expect(ObjectiveMasteryStatus.remediationRequired.isStruggling, isTrue);
      expect(ObjectiveMasteryStatus.remediationRequired.displayName,
          equals('Remediation Required'));

      expect(ObjectiveMasteryStatus.regressed.isMastered, isFalse);
      expect(ObjectiveMasteryStatus.regressed.isStruggling, isTrue);
      expect(ObjectiveMasteryStatus.regressed.displayName, equals('Regressed'));
    });

    test('ObjectiveTransitionType properties and display names', () {
      expect(ObjectiveTransitionType.progressed.isPositive, isTrue);
      expect(ObjectiveTransitionType.progressed.isNegative, isFalse);
      expect(ObjectiveTransitionType.mastered.isPositive, isTrue);
      expect(ObjectiveTransitionType.maintainedMastery.isPositive, isTrue);
      expect(ObjectiveTransitionType.remediationResolved.isPositive, isTrue);

      expect(ObjectiveTransitionType.regressed.isNegative, isTrue);
      expect(ObjectiveTransitionType.remediationTriggered.isNegative, isTrue);

      expect(ObjectiveTransitionType.initialAssessment.isPositive, isFalse);
      expect(ObjectiveTransitionType.initialAssessment.isNegative, isFalse);
      expect(ObjectiveTransitionType.unchanged.isPositive, isFalse);
      expect(ObjectiveTransitionType.unchanged.isNegative, isFalse);

      expect(
          ObjectiveTransitionType.progressed.displayName, equals('Progressed'));
      expect(ObjectiveTransitionType.mastered.displayName, equals('Mastered'));
      expect(
          ObjectiveTransitionType.regressed.displayName, equals('Regressed'));
    });

    test('ObjectiveProgressionSummary creation and validation', () {
      final summary = ObjectiveProgressionSummary(
        objectiveId: 'lo_polity_01',
        priorStatus: ObjectiveMasteryStatus.inProgress,
        newStatus: ObjectiveMasteryStatus.mastered,
        transitionType: ObjectiveTransitionType.mastered,
        priorAttempts: 3,
        newAttempts: 2,
        totalAttempts: 5,
        priorCorrect: 2,
        newCorrect: 2,
        totalCorrect: 4,
        priorSuccessRate: 0.6667,
        newSuccessRate: 0.80,
        confidenceScore: 0.94,
        rationale: 'Mastery achieved across 5 attempts.',
      );

      expect(summary.objectiveId, equals('lo_polity_01'));
      expect(summary.isMastered, isTrue);
      expect(summary.isStruggling, isFalse);
      expect(summary.hasSufficientEvidence, isTrue);
      expect(summary.successRateDelta, closeTo(0.1333, 0.001));

      // Argument validation
      expect(
        () => ObjectiveProgressionSummary(
          objectiveId: '',
          priorStatus: ObjectiveMasteryStatus.notAttempted,
          newStatus: ObjectiveMasteryStatus.inProgress,
          transitionType: ObjectiveTransitionType.initialAssessment,
          totalAttempts: 1,
          totalCorrect: 1,
          newSuccessRate: 1.0,
          confidenceScore: 0.5,
          rationale: 'Invalid',
        ),
        throwsArgumentError,
      );

      expect(
        () => ObjectiveProgressionSummary(
          objectiveId: 'lo_1',
          priorStatus: ObjectiveMasteryStatus.notAttempted,
          newStatus: ObjectiveMasteryStatus.inProgress,
          transitionType: ObjectiveTransitionType.initialAssessment,
          totalAttempts: 1,
          totalCorrect: 2, // correct > attempts
          newSuccessRate: 1.0,
          confidenceScore: 0.5,
          rationale: 'Invalid',
        ),
        throwsArgumentError,
      );
    });

    test('ObjectiveProgressionSummary JSON serialization round-trip', () {
      final summary = ObjectiveProgressionSummary(
        objectiveId: 'lo_polity_01',
        priorStatus: ObjectiveMasteryStatus.inProgress,
        newStatus: ObjectiveMasteryStatus.mastered,
        transitionType: ObjectiveTransitionType.mastered,
        priorAttempts: 4,
        newAttempts: 2,
        totalAttempts: 6,
        priorCorrect: 3,
        newCorrect: 2,
        totalCorrect: 5,
        priorSuccessRate: 0.75,
        newSuccessRate: 0.8333,
        confidenceScore: 0.95,
        rationale: 'Transitioned to mastery.',
      );

      final json = summary.toJson();
      final fromJson = ObjectiveProgressionSummary.fromJson(json);

      expect(fromJson.objectiveId, equals(summary.objectiveId));
      expect(fromJson.priorStatus, equals(summary.priorStatus));
      expect(fromJson.newStatus, equals(summary.newStatus));
      expect(fromJson.transitionType, equals(summary.transitionType));
      expect(fromJson.totalAttempts, equals(summary.totalAttempts));
      expect(fromJson.totalCorrect, equals(summary.totalCorrect));
      expect(fromJson.confidenceScore, closeTo(summary.confidenceScore, 0.001));
      expect(fromJson, equals(summary));
    });

    test('ObjectiveWeaknessDetail creation, validation, and JSON round-trip',
        () {
      final detail = ObjectiveWeaknessDetail(
        objectiveId: 'lo_weak_01',
        deficiencyScore: 0.75,
        attemptCount: 4,
        correctCount: 1,
        successRate: 0.25,
        consecutiveIncorrectCount: 3,
        isRegressed: false,
        recommendedRemedialLessonId: 'rem_lesson_01',
        rationale: 'Persistent failure on concept.',
      );

      expect(detail.objectiveId, equals('lo_weak_01'));
      expect(detail.deficiencyScore, equals(0.75));
      expect(detail.consecutiveIncorrectCount, equals(3));
      expect(detail.recommendedRemedialLessonId, equals('rem_lesson_01'));

      final json = detail.toJson();
      final fromJson = ObjectiveWeaknessDetail.fromJson(json);
      expect(fromJson, equals(detail));

      expect(
        () => ObjectiveWeaknessDetail(
          objectiveId: '',
          deficiencyScore: 0.5,
          attemptCount: 2,
          correctCount: 1,
          successRate: 0.5,
          rationale: 'Invalid',
        ),
        throwsArgumentError,
      );
    });

    test('NextLearningAction factories and JSON round-trip', () {
      final actionComp = NextLearningAction.complete();
      expect(actionComp.actionType, equals(LearningDecisionType.complete));
      expect(actionComp.priority, equals(LearningDecisionPriority.none));

      final actionRem = NextLearningAction.remediation(
        objectiveId: 'lo_01',
        remedialLessonId: 'rem_1',
        rationale: 'Needs remediation',
      );
      expect(actionRem.actionType, equals(LearningDecisionType.remediation));
      expect(actionRem.priority, equals(LearningDecisionPriority.urgent));
      expect(actionRem.targetObjectiveId, equals('lo_01'));
      expect(actionRem.remedialLessonId, equals('rem_1'));

      final json = actionRem.toJson();
      final fromJson = NextLearningAction.fromJson(json);
      expect(fromJson, equals(actionRem));

      final actionCont = NextLearningAction.continuation(
        sessionId: 'sess_1',
        cursorIndex: 3,
        rationale: 'Resume session',
      );
      expect(actionCont.actionType, equals(LearningDecisionType.continuation));
      expect(actionCont.parameters['cursorIndex'], equals(3));
    });

    test('MasteryContinuationAuditTrail logging and serialization', () {
      var trail = const MasteryContinuationAuditTrail.empty();
      expect(trail.steps, isEmpty);

      trail = trail.logSuccess('requestValidated',
          details: {'status': 'ok'}, timestamp: baseDate);
      trail = trail.logFailure('stateResolved',
          details: {'error': 'not found'}, timestamp: baseDate);

      expect(trail.steps.length, equals(2));
      expect(trail.steps.first.isSuccess, isTrue);
      expect(trail.steps.first.step, equals('requestValidated'));
      expect(trail.steps.last.isSuccess, isFalse);
      expect(trail.steps.last.step, equals('stateResolved'));

      final json = trail.toJson();
      final fromJson = MasteryContinuationAuditTrail.fromJson(json);
      expect(fromJson.steps.length, equals(2));
      expect(fromJson.steps.first.step, equals('requestValidated'));
    });

    test('AdaptiveContinuationFeedback canonical fingerprint and determinism',
        () {
      final summary = ObjectiveProgressionSummary(
        objectiveId: 'lo_01',
        priorStatus: ObjectiveMasteryStatus.notAttempted,
        newStatus: ObjectiveMasteryStatus.mastered,
        transitionType: ObjectiveTransitionType.initialAssessment,
        totalAttempts: 5,
        totalCorrect: 5,
        newSuccessRate: 1.0,
        confidenceScore: 1.0,
        rationale: 'Mastered',
      );

      final action = NextLearningAction.complete();

      final feedback1 = AdaptiveContinuationFeedback(
        feedbackId: 'mcf_learner1_upsc_rev2',
        learnerId: 'learner1',
        examId: 'upsc',
        authoritativeRevision: 2,
        evaluatedAt: baseDate,
        overallReadinessScore: 1.0,
        overallConfidence: 1.0,
        objectiveProgressions: {'lo_01': summary},
        demonstratedCompetencies: const ['lo_01'],
        detectedWeaknesses: const [],
        recommendedAction: action,
      );

      final feedback2 = AdaptiveContinuationFeedback(
        feedbackId: 'mcf_learner1_upsc_rev2',
        learnerId: 'learner1',
        examId: 'upsc',
        authoritativeRevision: 2,
        evaluatedAt: baseDate,
        overallReadinessScore: 1.0,
        overallConfidence: 1.0,
        objectiveProgressions: {'lo_01': summary},
        demonstratedCompetencies: const ['lo_01'],
        detectedWeaknesses: const [],
        recommendedAction: action,
      );

      expect(feedback1.fingerprint, equals(feedback2.fingerprint));
      expect(feedback1.idempotencyKey, equals(feedback2.idempotencyKey));
      expect(feedback1, equals(feedback2));

      final json = feedback1.toJson();
      final fromJson = AdaptiveContinuationFeedback.fromJson(json);
      expect(fromJson.fingerprint, equals(feedback1.fingerprint));
      expect(fromJson.idempotencyKey, equals(feedback1.idempotencyKey));
    });

    test('InMemoryAdaptiveMasteryContinuationRepository CRUD and isolation',
        () async {
      final repo = InMemoryAdaptiveMasteryContinuationRepository();

      final feedback = AdaptiveContinuationFeedback(
        feedbackId: 'fb_1',
        learnerId: 'learner_a',
        examId: 'upsc',
        authoritativeRevision: 1,
        evaluatedAt: baseDate,
        overallReadinessScore: 0.8,
        overallConfidence: 0.9,
        objectiveProgressions: const {},
        recommendedAction: NextLearningAction.complete(),
      );

      await repo.saveFeedback(feedback);

      final byId = await repo.findById('fb_1');
      expect(byId, isNotNull);
      expect(byId!.learnerId, equals('learner_a'));

      final byIdemp = await repo.findByIdempotencyKey(feedback.idempotencyKey);
      expect(byIdemp, isNotNull);
      expect(byIdemp!.feedbackId, equals('fb_1'));

      // Tenant isolation
      final listA = await repo.findByLearnerAndExam(
          learnerId: 'learner_a', examId: 'upsc');
      expect(listA.length, equals(1));

      final listB = await repo.findByLearnerAndExam(
          learnerId: 'learner_b', examId: 'upsc');
      expect(listB, isEmpty);

      final latest =
          await repo.getLatestFeedback(learnerId: 'learner_a', examId: 'upsc');
      expect(latest, isNotNull);
      expect(latest!.feedbackId, equals('fb_1'));

      await repo.clear();
      expect(await repo.findById('fb_1'), isNull);
    });
  });

  group('P44 Service Safety & Progression Tests', () {
    late InMemoryAuthoritativeLearningStateRepository stateRepo;
    late AuthoritativeLearningStateRecoveryService recoveryService;
    late InMemoryAdaptiveMasteryContinuationRepository contRepo;
    late AdaptiveMasteryContinuationService service;

    final baseDate = DateTime.utc(2026, 9, 6, 12, 0, 0);

    setUp(() {
      stateRepo = InMemoryAuthoritativeLearningStateRepository();
      recoveryService = AuthoritativeLearningStateRecoveryService(
        repository: stateRepo,
      );
      contRepo = InMemoryAdaptiveMasteryContinuationRepository();
      service = AdaptiveMasteryContinuationService(
        stateRepository: stateRepo,
        recoveryService: recoveryService,
        continuationRepository: contRepo,
      );
    });

    test('Rejects request with empty identifiers', () async {
      final req = AdaptiveMasteryContinuationRequest(
        requestId: 'req_1',
        learnerId: 'learner_1',
        examId: 'upsc',
        evaluatedAt: baseDate,
      );
      expect(req.learnerId, equals('learner_1'));

      expect(
        () => AdaptiveMasteryContinuationRequest(
          requestId: '',
          learnerId: 'l1',
          examId: 'e1',
        ),
        throwsArgumentError,
      );
    });

    test('Rejects cross-learner tenant mismatch', () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_actual',
        examId: 'upsc',
        progressMap: const {},
        lastUpdatedAt: baseDate,
        revision: 2,
      );

      final req = AdaptiveMasteryContinuationRequest(
        requestId: 'req_mismatch',
        learnerId: 'learner_attacker',
        examId: 'upsc',
        currentState: state,
        evaluatedAt: baseDate,
      );

      final result = await service.evaluate(req);
      expect(result.status,
          equals(AdaptiveMasteryContinuationStatus.invalidRequest));
      expect(result.error?.code, equals('tenantMismatch'));
    });

    test('Rejects cross-exam tenant mismatch', () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_1',
        examId: 'bpsc',
        progressMap: const {},
        lastUpdatedAt: baseDate,
        revision: 2,
      );

      final req = AdaptiveMasteryContinuationRequest(
        requestId: 'req_mismatch_exam',
        learnerId: 'learner_1',
        examId: 'upsc',
        currentState: state,
        evaluatedAt: baseDate,
      );

      final result = await service.evaluate(req);
      expect(result.status,
          equals(AdaptiveMasteryContinuationStatus.invalidRequest));
      expect(result.error?.code, equals('tenantMismatch'));
    });

    test(
        'Idempotency: Repeated evaluation returns cached result without re-running',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_idemp',
        examId: 'upsc',
        progressMap: {
          'lo_01': LearnerProgress(
            learnerId: 'learner_idemp',
            objectiveId: 'lo_01',
            attemptCount: 5,
            correctCount: 5,
            successRate: 1.0,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 3,
      );

      final req1 = AdaptiveMasteryContinuationRequest(
        requestId: 'req_first',
        learnerId: 'learner_idemp',
        examId: 'upsc',
        currentState: state,
        evaluatedAt: baseDate,
      );

      final result1 = await service.evaluate(req1);
      expect(result1.status, equals(AdaptiveMasteryContinuationStatus.success));
      expect(result1.feedback, isNotNull);

      // Second identical request
      final req2 = AdaptiveMasteryContinuationRequest(
        requestId: 'req_second',
        learnerId: 'learner_idemp',
        examId: 'upsc',
        currentState: state,
        evaluatedAt: baseDate,
      );

      final result2 = await service.evaluate(req2);
      expect(result2.status,
          equals(AdaptiveMasteryContinuationStatus.alreadyEvaluated));
      expect(
          result2.feedback?.feedbackId, equals(result1.feedback?.feedbackId));
      expect(
          result2.feedback?.fingerprint, equals(result1.feedback?.fingerprint));
    });

    test('Objective-level progression: all-correct attempts achieve mastery',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_strong',
        examId: 'upsc',
        progressMap: {
          'lo_polity_01': LearnerProgress(
            learnerId: 'learner_strong',
            objectiveId: 'lo_polity_01',
            attemptCount: 5,
            correctCount: 5,
            successRate: 1.0,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 2,
      );

      final req = AdaptiveMasteryContinuationRequest(
        requestId: 'req_strong',
        learnerId: 'learner_strong',
        examId: 'upsc',
        currentState: state,
        evaluatedAt: baseDate,
      );

      final result = await service.evaluate(req);
      expect(result.status, equals(AdaptiveMasteryContinuationStatus.success));

      final feedback = result.feedback!;
      expect(feedback.overallReadinessScore, equals(1.0));
      expect(feedback.overallConfidence, equals(1.0));
      expect(feedback.demonstratedCompetencies, contains('lo_polity_01'));
      expect(feedback.detectedWeaknesses, isEmpty);

      final prog = feedback.objectiveProgressions['lo_polity_01']!;
      expect(prog.isMastered, isTrue);
      expect(prog.totalAttempts, equals(5));
      expect(prog.totalCorrect, equals(5));
      expect(prog.newSuccessRate, equals(1.0));
      expect(prog.transitionType,
          equals(ObjectiveTransitionType.maintainedMastery));
    });

    test(
        'Objective-level progression: crossing achievement threshold triggers mastered transition',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_progressing',
        examId: 'upsc',
        progressMap: {
          'lo_polity_01': LearnerProgress(
            learnerId: 'learner_progressing',
            objectiveId: 'lo_polity_01',
            attemptCount: 5,
            correctCount: 5,
            successRate: 1.0,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 2,
      );

      final completionResult = LearningActivityCompletionResult(
        requestId: 'comp_req_1',
        activityId: 'act_1',
        status: LearningActivityCompletionStatus.success,
        resultingAuthoritativeState: state,
        auditTrail: const ActivityCompletionAuditTrail.empty(),
        outcome: LearningActivityOutcome.calculate(
          activityId: 'act_1',
          activityType: LearningDecisionType.advancement,
          learnerId: 'learner_progressing',
          examId: 'upsc',
          questionsPresented: 3,
          questionsAttempted: 3,
          correctAnswers: 3,
          incorrectAnswers: 0,
          skippedAnswers: 0,
          unansweredCount: 0,
          completedAt: baseDate,
        ),
        evidence: ActivityOutcomeEvidence(
          activityId: 'act_1',
          activityType: LearningDecisionType.advancement,
          learnerId: 'learner_progressing',
          examId: 'upsc',
          planId: 'plan_1',
          planRevision: 1,
          questionEvidence: [
            for (int i = 0; i < 3; i++)
              PracticeQuestionEvidence(
                questionId: 'q_$i',
                examId: 'upsc',
                year: 2024,
                paper: '1',
                subject: 'Polity',
                topic: 'Constitution',
                objectiveIds: const ['lo_polity_01'],
                difficulty: 'medium',
                questionIndex: i,
                status: PracticeQuestionStatus.answeredCorrect,
                submittedAnswer: 'A',
                correctAnswer: 'A',
                isCorrect: true,
                isAnswered: true,
                isSkipped: false,
                elapsedSeconds: 30,
              ),
          ],
          timestamp: baseDate,
        ),
        completedAt: baseDate,
      );

      final result = await service.evaluateFromCompletion(
        requestId: 'req_cross_mastery',
        completionResult: completionResult,
        evaluatedAt: baseDate,
      );

      expect(result.status, equals(AdaptiveMasteryContinuationStatus.success));
      final prog = result.feedback!.objectiveProgressions['lo_polity_01']!;
      expect(prog.isMastered, isTrue);
      expect(prog.priorAttempts,
          equals(2)); // 5 - 3 = 2 (was insufficient evidence)
      expect(prog.newAttempts, equals(3));
      expect(prog.totalAttempts, equals(5));
      expect(prog.priorStatus,
          equals(ObjectiveMasteryStatus.insufficientEvidence));
      expect(prog.newStatus, equals(ObjectiveMasteryStatus.mastered));
      expect(prog.transitionType, equals(ObjectiveTransitionType.mastered));
    });

    test(
        'Objective-level progression: all-incorrect attempts trigger remediation',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_struggle',
        examId: 'upsc',
        progressMap: {
          'lo_polity_02': LearnerProgress(
            learnerId: 'learner_struggle',
            objectiveId: 'lo_polity_02',
            attemptCount: 5,
            correctCount: 1,
            successRate: 0.20,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 2,
      );

      final req = AdaptiveMasteryContinuationRequest(
        requestId: 'req_struggle',
        learnerId: 'learner_struggle',
        examId: 'upsc',
        currentState: state,
        evaluatedAt: baseDate,
      );

      final result = await service.evaluate(req);
      expect(result.status, equals(AdaptiveMasteryContinuationStatus.success));

      final feedback = result.feedback!;
      expect(feedback.detectedWeaknesses.length, equals(1));
      final weakness = feedback.detectedWeaknesses.first;
      expect(weakness.objectiveId, equals('lo_polity_02'));
      expect(weakness.deficiencyScore, equals(0.80));
      expect(weakness.attemptCount, equals(5));

      // Action determination: must trigger remediation!
      expect(feedback.recommendedAction.actionType,
          equals(LearningDecisionType.remediation));
      expect(
          feedback.recommendedAction.targetObjectiveId, equals('lo_polity_02'));
    });

    test(
        'Objective-level progression: insufficient evidence produces conservative status',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_sparse',
        examId: 'upsc',
        progressMap: {
          'lo_sparse_01': LearnerProgress(
            learnerId: 'learner_sparse',
            objectiveId: 'lo_sparse_01',
            attemptCount: 2, // < minimumAttempts (5)
            correctCount: 2,
            successRate: 1.0,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 2,
      );

      final req = AdaptiveMasteryContinuationRequest(
        requestId: 'req_sparse',
        learnerId: 'learner_sparse',
        examId: 'upsc',
        currentState: state,
        evaluatedAt: baseDate,
      );

      final result = await service.evaluate(req);
      expect(result.status, equals(AdaptiveMasteryContinuationStatus.success));

      final feedback = result.feedback!;
      final prog = feedback.objectiveProgressions['lo_sparse_01']!;
      expect(
          prog.newStatus, equals(ObjectiveMasteryStatus.insufficientEvidence));
      expect(prog.hasSufficientEvidence, isFalse);
      expect(prog.confidenceScore, lessThan(0.70));
    });

    test(
        'Next action determination: active checkpoint triggers continuation with top priority',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_paused',
        examId: 'upsc',
        progressMap: {
          'lo_01': LearnerProgress(
            learnerId: 'learner_paused',
            objectiveId: 'lo_01',
            attemptCount: 5,
            correctCount: 1, // weak spot!
            successRate: 0.20,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 2,
      );

      final chk = SessionCheckpoint(
        checkpointRevision: 2,
        authoritativeStateRevision: 2,
        sessionId: 'sess_paused',
        learnerId: 'learner_paused',
        examId: 'upsc',
        questionIndex: 2,
        completedQuestionIds: const ['q1', 'q2'],
        activeObjectiveId: 'lo_01',
        timestamp: baseDate,
        isCompleted: false,
      );

      final req = AdaptiveMasteryContinuationRequest(
        requestId: 'req_paused',
        learnerId: 'learner_paused',
        examId: 'upsc',
        currentState: state,
        activeCheckpoint: chk,
        evaluatedAt: baseDate,
      );

      final result = await service.evaluate(req);
      expect(result.status, equals(AdaptiveMasteryContinuationStatus.success));

      // Continuation must beat remediation!
      expect(result.feedback!.recommendedAction.actionType,
          equals(LearningDecisionType.continuation));
      expect(result.feedback!.recommendedAction.priority,
          equals(LearningDecisionPriority.urgent));
    });

    test('Next action determination: due spaced review triggers review',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_rev',
        examId: 'upsc',
        progressMap: {
          'lo_mastered_01': LearnerProgress(
            learnerId: 'learner_rev',
            objectiveId: 'lo_mastered_01',
            attemptCount: 6,
            correctCount: 6,
            successRate: 1.0,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 2,
      );

      final reviewItem = ReviewItem(
        objectiveId: 'lo_mastered_01',
        intervalDays: 3,
        easeFactor: 2.5,
        nextReviewDate: baseDate.subtract(const Duration(days: 2)), // overdue!
        lastReviewed: baseDate.subtract(const Duration(days: 5)),
      );

      final req = AdaptiveMasteryContinuationRequest(
        requestId: 'req_rev',
        learnerId: 'learner_rev',
        examId: 'upsc',
        currentState: state,
        reviewItems: [reviewItem],
        evaluatedAt: baseDate,
      );

      final result = await service.evaluate(req);
      expect(result.status, equals(AdaptiveMasteryContinuationStatus.success));
      expect(result.feedback!.recommendedAction.actionType,
          equals(LearningDecisionType.review));
      expect(result.feedback!.recommendedAction.targetObjectiveId,
          equals('lo_mastered_01'));
    });
  });
}
