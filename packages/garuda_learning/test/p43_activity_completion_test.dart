/// P43 Learning Activity Completion & Outcome Feedback Unit Test Suite (TITAN-KO-043.0).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P43 Domain Models & Serialization Tests', () {
    final baseDate = DateTime.utc(2026, 9, 4, 12, 0, 0);

    test('LearningActivityCompletionStatus properties and display names', () {
      expect(LearningActivityCompletionStatus.success.isSuccess, isTrue);
      expect(LearningActivityCompletionStatus.success.isFailure, isFalse);
      expect(
          LearningActivityCompletionStatus.success.isAlreadyCompleted, isFalse);
      expect(LearningActivityCompletionStatus.success.displayName,
          equals('Success'));

      expect(
          LearningActivityCompletionStatus.alreadyCompleted.isSuccess, isTrue);
      expect(
          LearningActivityCompletionStatus.alreadyCompleted.isAlreadyCompleted,
          isTrue);
      expect(LearningActivityCompletionStatus.alreadyCompleted.displayName,
          equals('Already Completed'));

      expect(LearningActivityCompletionStatus.stalePlan.isFailure, isTrue);
      expect(LearningActivityCompletionStatus.stalePlan.displayName,
          equals('Stale Plan'));

      expect(LearningActivityCompletionStatus.futurePlanRevision.isFailure,
          isTrue);
      expect(LearningActivityCompletionStatus.missingSession.isFailure, isTrue);
      expect(
          LearningActivityCompletionStatus.invalidAttempts.isFailure, isTrue);
      expect(LearningActivityCompletionStatus.consolidationFailed.isFailure,
          isTrue);
      expect(LearningActivityCompletionStatus.reconciliationFailed.isFailure,
          isTrue);
      expect(
          LearningActivityCompletionStatus.executionFailed.isFailure, isTrue);
    });

    test('ActivityCompletionError and Exception models', () {
      final error = ActivityCompletionError(
        code: ActivityCompletionErrorCode.duplicateAttempt,
        message: 'Duplicate question attempt detected',
        cause: StateError('duplicate'),
        timestamp: baseDate,
        details: {'questionId': 'q1'},
      );

      expect(error.code, equals(ActivityCompletionErrorCode.duplicateAttempt));
      expect(error.message, equals('Duplicate question attempt detected'));
      expect(error.details['questionId'], equals('q1'));

      final json = error.toJson();
      final roundTrip = ActivityCompletionError.fromJson(json);
      expect(roundTrip.code, equals(error.code));
      expect(roundTrip.message, equals(error.message));
      expect(roundTrip.details['questionId'], equals('q1'));

      final exception = ActivityCompletionException(error);
      expect(exception.code, equals(error.code));
      expect(exception.message, equals(error.message));
      expect(exception.toString(), contains('duplicateAttempt'));
    });

    test(
        'ActivityCompletionAuditStep and ActivityCompletionAuditTrail models & serialization',
        () {
      var trail = const ActivityCompletionAuditTrail.empty();
      expect(trail.steps.isEmpty, isTrue);
      expect(trail.allStepsSuccessful, isFalse);

      trail = trail.logSuccess('requestValidated',
          details: {'planId': 'p1'}, timestamp: baseDate);
      trail = trail.logSuccess('tenantValidated', timestamp: baseDate);
      expect(trail.steps.length, equals(2));
      expect(trail.allStepsSuccessful, isTrue);
      expect(trail.hasFailures, isFalse);

      trail = trail.logFailure('planValidated',
          details: {'reason': 'stale'}, timestamp: baseDate);
      expect(trail.steps.length, equals(3));
      expect(trail.allStepsSuccessful, isFalse);
      expect(trail.hasFailures, isTrue);

      final found = trail.findStep('planValidated');
      expect(found, isNotNull);
      expect(found!.isSuccess, isFalse);

      final jsonList = trail.toJson();
      final roundTrip = ActivityCompletionAuditTrail.fromJson(jsonList);
      expect(roundTrip.steps.length, equals(3));
      expect(roundTrip.steps[0].stepName, equals('requestValidated'));
      expect(roundTrip.steps[0].isSuccess, isTrue);
      expect(roundTrip.steps[2].stepName, equals('planValidated'));
      expect(roundTrip.steps[2].isSuccess, isFalse);
    });

    test('LearningActivityOutcome mathematical safety for boundary cases', () {
      // 1. 0 questions: safe score=0.0, accuracy=null, completionRate=1.0
      final zeroQ = LearningActivityOutcome.calculate(
        activityId: 'act_zero_q',
        activityType: LearningDecisionType.advancement,
        learnerId: 'l1',
        examId: 'upsc',
        questionsPresented: 0,
        questionsAttempted: 0,
        correctAnswers: 0,
        incorrectAnswers: 0,
        skippedAnswers: 0,
        completedAt: baseDate,
      );
      expect(zeroQ.score, equals(0.0));
      expect(zeroQ.accuracy, isNull);
      expect(zeroQ.accuracyPercentage, isNull);
      expect(zeroQ.completionRate, equals(1.0));
      expect(zeroQ.fingerprint.isNotEmpty, isTrue);

      // 2. Complete activity with 0 questions produces score=1.0
      final completeAct = LearningActivityOutcome.calculate(
        activityId: 'act_complete',
        activityType: LearningDecisionType.complete,
        learnerId: 'l1',
        examId: 'upsc',
        questionsPresented: 0,
        questionsAttempted: 0,
        correctAnswers: 0,
        incorrectAnswers: 0,
        skippedAnswers: 0,
        completedAt: baseDate,
      );
      expect(completeAct.score, equals(1.0));
      expect(completeAct.accuracy, isNull);
      expect(completeAct.completionRate, equals(1.0));

      // 3. 0 attempts with 5 questions presented: accuracy=null, score=0.0
      final zeroAttempt = LearningActivityOutcome.calculate(
        activityId: 'act_zero_att',
        activityType: LearningDecisionType.advancement,
        learnerId: 'l1',
        examId: 'upsc',
        questionsPresented: 5,
        questionsAttempted: 0,
        correctAnswers: 0,
        incorrectAnswers: 0,
        skippedAnswers: 0,
        completedAt: baseDate,
      );
      expect(zeroAttempt.score, equals(0.0));
      expect(zeroAttempt.accuracy, isNull);
      expect(zeroAttempt.accuracyPercentage, isNull);
      expect(zeroAttempt.completionRate, equals(0.0));

      // 4. All skipped (5 presented, 0 attempted, 5 skipped)
      final allSkipped = LearningActivityOutcome.calculate(
        activityId: 'act_skipped',
        activityType: LearningDecisionType.review,
        learnerId: 'l1',
        examId: 'upsc',
        questionsPresented: 5,
        questionsAttempted: 0,
        correctAnswers: 0,
        incorrectAnswers: 0,
        skippedAnswers: 5,
        completedAt: baseDate,
      );
      expect(allSkipped.score, equals(0.0));
      expect(allSkipped.accuracy, isNull);
      expect(allSkipped.completionRate, equals(1.0));
      expect(allSkipped.unansweredCount, equals(0));

      // 5. 100% correct (5 presented, 5 attempted, 5 correct)
      final fullCorrect = LearningActivityOutcome.calculate(
        activityId: 'act_perfect',
        activityType: LearningDecisionType.reinforcement,
        learnerId: 'l1',
        examId: 'upsc',
        questionsPresented: 5,
        questionsAttempted: 5,
        correctAnswers: 5,
        incorrectAnswers: 0,
        skippedAnswers: 0,
        completedAt: baseDate,
      );
      expect(fullCorrect.score, equals(1.0));
      expect(fullCorrect.accuracy, equals(1.0));
      expect(fullCorrect.accuracyPercentage, equals(100.0));
      expect(fullCorrect.completionRate, equals(1.0));

      // 6. 0% correct (4 presented, 4 attempted, 0 correct, 4 incorrect)
      final zeroCorrect = LearningActivityOutcome.calculate(
        activityId: 'act_zero_corr',
        activityType: LearningDecisionType.remediation,
        learnerId: 'l1',
        examId: 'upsc',
        questionsPresented: 4,
        questionsAttempted: 4,
        correctAnswers: 0,
        incorrectAnswers: 4,
        skippedAnswers: 0,
        completedAt: baseDate,
      );
      expect(zeroCorrect.score, equals(0.0));
      expect(zeroCorrect.accuracy, equals(0.0));
      expect(zeroCorrect.accuracyPercentage, equals(0.0));
      expect(zeroCorrect.completionRate, equals(1.0));
    });

    test('LearningActivityOutcome JSON serialization round-trip', () {
      final outcome = LearningActivityOutcome.calculate(
        activityId: 'act_serialize_01',
        activityType: LearningDecisionType.advancement,
        learnerId: 'learner_p43',
        examId: 'upsc',
        sessionId: 'sess_123',
        questionsPresented: 10,
        questionsAttempted: 8,
        correctAnswers: 6,
        incorrectAnswers: 2,
        skippedAnswers: 2,
        totalDurationSeconds: 150,
        topicEvidence: {'Polity': 6},
        objectiveEvidence: {'lo_const_01': 6},
        remedialEvidence: {'remedialLessonId': 'rem_01'},
        completedAt: baseDate,
        outcomeRevision: 1,
      );

      final json = outcome.toJson();
      final roundTrip = LearningActivityOutcome.fromJson(json);

      expect(roundTrip.activityId, equals(outcome.activityId));
      expect(roundTrip.activityType, equals(outcome.activityType));
      expect(roundTrip.learnerId, equals(outcome.learnerId));
      expect(roundTrip.examId, equals(outcome.examId));
      expect(roundTrip.sessionId, equals(outcome.sessionId));
      expect(roundTrip.questionsPresented, equals(10));
      expect(roundTrip.questionsAttempted, equals(8));
      expect(roundTrip.correctAnswers, equals(6));
      expect(roundTrip.incorrectAnswers, equals(2));
      expect(roundTrip.skippedAnswers, equals(2));
      expect(roundTrip.score, equals(0.6));
      expect(roundTrip.accuracy, equals(0.75));
      expect(roundTrip.accuracyPercentage, equals(75.0));
      expect(roundTrip.completionRate, equals(1.0));
      expect(roundTrip.fingerprint, equals(outcome.fingerprint));
      expect(roundTrip.topicEvidence['Polity'], equals(6));
    });

    test('ActivityOutcomeEvidence model & serialization round-trip', () {
      final evidence = ActivityOutcomeEvidence(
        activityId: 'act_ev_01',
        activityType: LearningDecisionType.remediation,
        learnerId: 'l1',
        examId: 'upsc',
        planId: 'plan_01',
        planRevision: 2,
        sessionId: 'sess_01',
        remedialLessonId: 'rem_lesson_01',
        remedialLessonCompleted: true,
        timestamp: baseDate,
      );

      final json = evidence.toJson();
      final roundTrip = ActivityOutcomeEvidence.fromJson(json);

      expect(roundTrip.activityId, equals('act_ev_01'));
      expect(roundTrip.activityType, equals(LearningDecisionType.remediation));
      expect(roundTrip.planRevision, equals(2));
      expect(roundTrip.remedialLessonId, equals('rem_lesson_01'));
      expect(roundTrip.remedialLessonCompleted, isTrue);
    });

    test('LearningActivityCompletionRequest validation & serialization', () {
      expect(
        () => LearningActivityCompletionRequest(
          requestId: '',
          learnerId: 'l1',
          examId: 'upsc',
          activityId: 'act1',
          activityType: LearningDecisionType.advancement,
          planId: 'p1',
          planRevision: 1,
        ),
        throwsArgumentError,
      );

      final req = LearningActivityCompletionRequest(
        requestId: 'req_01',
        learnerId: 'l1',
        examId: 'upsc',
        activityId: 'act1',
        activityType: LearningDecisionType.advancement,
        planId: 'p1',
        planRevision: 1,
        sessionId: 'sess_01',
        completedAt: baseDate,
      );

      expect(req.resolvedIdempotencyKey, equals('comp_l1_upsc_act1_sess_01'));

      final json = req.toJson();
      final roundTrip = LearningActivityCompletionRequest.fromJson(json);
      expect(roundTrip.requestId, equals('req_01'));
      expect(roundTrip.resolvedIdempotencyKey,
          equals('comp_l1_upsc_act1_sess_01'));
    });

    test('LearningActivityCompletionResult getters and serialization', () {
      final outcome = LearningActivityOutcome.calculate(
        activityId: 'act1',
        activityType: LearningDecisionType.advancement,
        learnerId: 'l1',
        examId: 'upsc',
        questionsPresented: 5,
        questionsAttempted: 5,
        correctAnswers: 5,
        incorrectAnswers: 0,
        skippedAnswers: 0,
        completedAt: baseDate,
      );

      final result = LearningActivityCompletionResult(
        requestId: 'req_res_01',
        activityId: 'act1',
        status: LearningActivityCompletionStatus.success,
        outcome: outcome,
        auditTrail: const ActivityCompletionAuditTrail.empty(),
        completedAt: baseDate,
      );

      expect(result.isSuccess, isTrue);
      expect(result.isAlreadyCompleted, isFalse);

      final json = result.toJson();
      final roundTrip = LearningActivityCompletionResult.fromJson(json);
      expect(roundTrip.requestId, equals('req_res_01'));
      expect(
          roundTrip.status, equals(LearningActivityCompletionStatus.success));
      expect(roundTrip.outcome?.score, equals(1.0));
    });

    test('LearningActivityCompletionRecord and InMemoryRepository CRUD',
        () async {
      final repo = InMemoryLearningActivityCompletionRepository();

      final outcome = LearningActivityOutcome.calculate(
        activityId: 'act_repo_01',
        activityType: LearningDecisionType.advancement,
        learnerId: 'l1',
        examId: 'upsc',
        questionsPresented: 5,
        questionsAttempted: 5,
        correctAnswers: 5,
        incorrectAnswers: 0,
        skippedAnswers: 0,
        completedAt: baseDate,
      );

      final record = LearningActivityCompletionRecord(
        idempotencyKey: 'key_123',
        learnerId: 'l1',
        examId: 'upsc',
        activityId: 'act_repo_01',
        sessionId: 'sess_1',
        planId: 'plan_1',
        planRevision: 1,
        outcome: outcome,
        completedAt: baseDate,
      );

      await repo.saveCompletionRecord(record);

      final fetchedByKey = await repo.findByIdempotencyKey('key_123');
      expect(fetchedByKey, isNotNull);
      expect(fetchedByKey!.activityId, equals('act_repo_01'));

      final fetchedByActivity = await repo.findByActivityId(
        learnerId: 'l1',
        examId: 'upsc',
        activityId: 'act_repo_01',
      );
      expect(fetchedByActivity, isNotNull);
      expect(fetchedByActivity!.idempotencyKey, equals('key_123'));

      final list =
          await repo.getCompletedActivities(learnerId: 'l1', examId: 'upsc');
      expect(list.length, equals(1));

      await repo.clear();
      expect(await repo.findByIdempotencyKey('key_123'), isNull);
    });
  });

  group('P43 Service Safety & Precondition Validation Tests', () {
    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late AuthoritativeLearningStateRecoveryService recoveryService;
    late AdaptiveLearningStateReconciliationPipeline pipeline;
    late InMemoryLearningActivityCompletionRepository completionRepo;
    late LearningActivityCompletionService completionService;

    final baseDate = DateTime.utc(2026, 9, 4, 12, 0, 0);

    setUp(() {
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      recoveryService =
          AuthoritativeLearningStateRecoveryService(repository: authRepo);
      pipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: authRepo,
        recoveryService: recoveryService,
      );
      completionRepo = InMemoryLearningActivityCompletionRepository();
      completionService = LearningActivityCompletionService(
        stateRepository: authRepo,
        recoveryService: recoveryService,
        reconciliationPipeline: pipeline,
        completionRepository: completionRepo,
      );
    });

    final orchestrator = AdaptivePracticeSessionOrchestrator();
    const execEngine = AdaptivePracticeExecutionEngine();

    NormalizedQuestion buildQuestion({
      required String id,
      String examId = 'upsc',
      String objectiveId = 'lo_1',
    }) {
      return NormalizedQuestion(
        id: id,
        examId: examId,
        year: 2024,
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        normalizedText: 'Question text for $id',
        originalText: 'Question text for $id',
        options: const [
          Option(key: 'A', text: 'Option A', isCorrect: true),
          Option(key: 'B', text: 'Option B', isCorrect: false),
          Option(key: 'C', text: 'Option C', isCorrect: false),
          Option(key: 'D', text: 'Option D', isCorrect: false),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['A'],
          officialAnswerSource: 'Official Key',
        ),
        explanation: 'Explanation for $id',
        difficulty: 'Medium',
        source: PyqSourceReference.official(
          examId: examId,
          year: 2024,
          paper: 'GS1',
        ),
        objectiveIds: [objectiveId],
      );
    }

    PracticeExecutionState buildExecutionState({
      required String learnerId,
      required String examId,
      String sessionId = 'sess_default',
      int questionCount = 2,
    }) {
      final questions = List<NormalizedQuestion>.generate(
        questionCount,
        (i) => buildQuestion(id: 'q_${sessionId}_$i', examId: examId),
      );
      final candidates = questions
          .map((q) => AdaptiveQuestionCandidate(
                question: q,
                historicalPriority: 1.0,
                learnerWeakness: 0.0,
                exposureCount: 0,
                recencyScore: 1.0,
                difficultyFit: 1.0,
                sourceQualityScore: 1.0,
                selectionScore: 1.0,
                isEligible: true,
                scoreBreakdown: const {},
              ))
          .toList();
      final selection = AdaptiveQuestionSelectionResult(
        examId: examId,
        selectedCandidates: candidates,
        selectedQuestions: questions,
        allCandidates: candidates,
        requestedCount: questionCount,
        eligibleCount: questionCount,
        config: AdaptiveQuestionSelectionConfig(examId: examId),
      );
      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: AdaptivePracticeSessionConfig(
          examId: examId,
          learnerId: learnerId,
        ),
        orchestratedAt: baseDate,
      );
      final initial = execEngine.initializeSession(spec: spec);
      return execEngine
          .startSession(state: initial, startedAt: baseDate)
          .valueOrThrow;
    }

    test('rejects cross-learner tenant mismatch', () async {
      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_alice',
        examId: 'upsc',
        createdAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final execState = buildExecutionState(
        learnerId: 'learner_alice',
        examId: 'upsc',
        sessionId: 'sess_alice',
      );

      // Request claims learner_bob, but executionState has learner_alice
      final request = LearningActivityCompletionRequest(
        requestId: 'req_mismatch_learner',
        learnerId: 'learner_bob',
        examId: 'upsc',
        activityId: 'act_01',
        activityType: LearningDecisionType.advancement,
        planId: 'plan_01',
        planRevision: 1,
        executionState: execState,
        completedAt: baseDate,
      );

      final result = await completionService.completeActivity(request);
      expect(result.status,
          equals(LearningActivityCompletionStatus.invalidRequest));
      expect(result.error?.code,
          equals(ActivityCompletionErrorCode.tenantMismatch));
    });

    test('rejects cross-exam tenant mismatch', () async {
      final execState = buildExecutionState(
        learnerId: 'learner_01',
        examId: 'bpsc',
        sessionId: 'sess_exam',
      );

      // Request claims upsc, but executionState has bpsc
      final request = LearningActivityCompletionRequest(
        requestId: 'req_mismatch_exam',
        learnerId: 'learner_01',
        examId: 'upsc',
        activityId: 'act_01',
        activityType: LearningDecisionType.advancement,
        planId: 'plan_01',
        planRevision: 1,
        executionState: execState,
        completedAt: baseDate,
      );

      final result = await completionService.completeActivity(request);
      expect(result.status,
          equals(LearningActivityCompletionStatus.invalidRequest));
      expect(result.error?.code,
          equals(ActivityCompletionErrorCode.tenantMismatch));
    });

    test('rejects stale plan when authoritative state has advanced', () async {
      const learnerId = 'learner_stale';
      const examId = 'upsc';

      // State is already at revision 3
      final state = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: const {},
        lastUpdatedAt: baseDate,
        revision: 3,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      // Plan was formulated at revision 2
      final request = LearningActivityCompletionRequest(
        requestId: 'req_stale',
        learnerId: learnerId,
        examId: examId,
        activityId: 'act_stale',
        activityType: LearningDecisionType.complete,
        planId: 'plan_stale',
        planRevision: 2,
        completedAt: baseDate,
      );

      final result = await completionService.completeActivity(request);
      expect(result.status, equals(LearningActivityCompletionStatus.stalePlan));
      expect(result.error?.code, equals(ActivityCompletionErrorCode.stalePlan));
    });

    test('rejects premature plan when plan revision is ahead of state',
        () async {
      const learnerId = 'learner_future';
      const examId = 'upsc';

      final state = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: const {},
        lastUpdatedAt: baseDate,
        revision: 1,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      // Plan claims revision 3
      final request = LearningActivityCompletionRequest(
        requestId: 'req_future',
        learnerId: learnerId,
        examId: examId,
        activityId: 'act_future',
        activityType: LearningDecisionType.complete,
        planId: 'plan_future',
        planRevision: 3,
        completedAt: baseDate,
      );

      final result = await completionService.completeActivity(request);
      expect(result.status,
          equals(LearningActivityCompletionStatus.futurePlanRevision));
      expect(result.error?.code,
          equals(ActivityCompletionErrorCode.futurePlanRevision));
    });

    test(
        'rejects practice activity when both executionState and attempts are missing',
        () async {
      const learnerId = 'learner_missing_sess';
      const examId = 'upsc';

      final state = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: const {},
        lastUpdatedAt: baseDate,
        revision: 1,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final request = LearningActivityCompletionRequest(
        requestId: 'req_no_sess',
        learnerId: learnerId,
        examId: examId,
        activityId: 'act_no_sess',
        activityType: LearningDecisionType.advancement,
        planId: 'plan_no_sess',
        planRevision: 1,
        completedAt: baseDate,
      );

      final result = await completionService.completeActivity(request);
      expect(result.status,
          equals(LearningActivityCompletionStatus.missingSession));
      expect(result.error?.code,
          equals(ActivityCompletionErrorCode.missingSession));
    });

    test('rejects duplicate question attempts in explicit attempts', () async {
      const learnerId = 'learner_dup_att';
      const examId = 'upsc';

      final state = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: const {},
        lastUpdatedAt: baseDate,
        revision: 1,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final attempts = [
        QuestionAttempt(
          attemptId: 'att1',
          learnerId: learnerId,
          questionId: 'q_duplicate',
          objectiveId: 'lo1',
          submittedAnswer: 'A',
          attemptedAt: baseDate,
        ),
        QuestionAttempt(
          attemptId: 'att2',
          learnerId: learnerId,
          questionId: 'q_duplicate', // Duplicate question!
          objectiveId: 'lo1',
          submittedAnswer: 'B',
          attemptedAt: baseDate,
        ),
      ];

      final request = LearningActivityCompletionRequest(
        requestId: 'req_dup',
        learnerId: learnerId,
        examId: examId,
        activityId: 'act_dup',
        activityType: LearningDecisionType.advancement,
        planId: 'plan_dup',
        planRevision: 1,
        attempts: attempts,
        completedAt: baseDate,
      );

      final result = await completionService.completeActivity(request);
      expect(result.status,
          equals(LearningActivityCompletionStatus.invalidAttempts));
      expect(result.error?.code,
          equals(ActivityCompletionErrorCode.duplicateAttempt));
    });

    test('rejects contradictory attempt results (correct with score 0)',
        () async {
      const learnerId = 'learner_contradict';
      const examId = 'upsc';

      final state = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: const {},
        lastUpdatedAt: baseDate,
        revision: 1,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final attempts = [
        QuestionAttempt(
          attemptId: 'att1',
          learnerId: learnerId,
          questionId: 'q1',
          objectiveId: 'lo1',
          submittedAnswer: 'A',
          attemptedAt: baseDate,
        ),
      ];

      final results = [
        AttemptResult(
          attemptId: 'att1',
          isCorrect: true,
          score: 0.0, // Contradictory: correct but score 0!
          evaluationMethod: EvaluationMethod.multipleChoice,
        ),
      ];

      final request = LearningActivityCompletionRequest(
        requestId: 'req_contra',
        learnerId: learnerId,
        examId: examId,
        activityId: 'act_contra',
        activityType: LearningDecisionType.advancement,
        planId: 'plan_contra',
        planRevision: 1,
        attempts: attempts,
        attemptResults: results,
        completedAt: baseDate,
      );

      final result = await completionService.completeActivity(request);
      expect(result.status,
          equals(LearningActivityCompletionStatus.invalidAttempts));
      expect(result.error?.code,
          equals(ActivityCompletionErrorCode.invalidAttempts));
    });

    test('idempotent replay returns alreadyCompleted without double counting',
        () async {
      const learnerId = 'learner_idempotent';
      const examId = 'upsc';

      final state = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: const {},
        lastUpdatedAt: baseDate,
        revision: 1,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final request = LearningActivityCompletionRequest(
        requestId: 'req_idem_1',
        learnerId: learnerId,
        examId: examId,
        activityId: 'act_terminal',
        activityType: LearningDecisionType.complete,
        planId: 'plan_terminal',
        planRevision: 1,
        completedAt: baseDate,
      );

      // 1. First execution -> accepted
      final firstResult = await completionService.completeActivity(request);
      expect(
          firstResult.status, equals(LearningActivityCompletionStatus.success));
      expect(firstResult.isSuccess, isTrue);
      expect(firstResult.isAlreadyCompleted, isFalse);

      // 2. Second identical execution -> alreadyCompleted
      final secondResult = await completionService.completeActivity(request);
      expect(secondResult.status,
          equals(LearningActivityCompletionStatus.alreadyCompleted));
      expect(secondResult.isSuccess, isTrue);
      expect(secondResult.isAlreadyCompleted, isTrue);
      expect(secondResult.outcome?.activityId, equals('act_terminal'));

      // 3. Verification: Repository has exactly 1 completion record
      final records = await completionRepo.getCompletedActivities(
        learnerId: learnerId,
        examId: examId,
      );
      expect(records.length, equals(1));
    });

    test(
        'remediation activity normalizes outcome and preserves remedial evidence',
        () async {
      const learnerId = 'learner_remed_norm';
      const examId = 'upsc';

      final state = AuthoritativeLearnerState.empty(
        learnerId: learnerId,
        examId: examId,
        createdAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final execState = buildExecutionState(
        learnerId: learnerId,
        examId: examId,
        sessionId: 'sess_remed',
        questionCount: 2,
      );

      final request = LearningActivityCompletionRequest(
        requestId: 'req_remed',
        learnerId: learnerId,
        examId: examId,
        activityId: 'act_remed_01',
        activityType: LearningDecisionType.remediation,
        planId: 'plan_remed_01',
        planRevision: 1,
        executionState: execState,
        remedialLessonId: 'lesson_const_01',
        remedialLessonCompleted: true,
        completedAt: baseDate,
      );

      final result = await completionService.completeActivity(request);
      expect(result.status, equals(LearningActivityCompletionStatus.success));
      expect(result.outcome?.activityType,
          equals(LearningDecisionType.remediation));
      expect(result.outcome?.remedialEvidence?['remedialLessonId'],
          equals('lesson_const_01'));
      expect(result.outcome?.remedialEvidence?['isCompleted'], isTrue);
      expect(result.evidence?.remedialLessonId, equals('lesson_const_01'));
      expect(result.evidence?.remedialLessonCompleted, isTrue);
    });

    test(
        'advancement activity normalizes outcome and calculates correct accuracy',
        () async {
      const learnerId = 'learner_adv_norm';
      const examId = 'upsc';

      final state = AuthoritativeLearnerState.empty(
        learnerId: learnerId,
        examId: examId,
        createdAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      var execState = buildExecutionState(
        learnerId: learnerId,
        examId: examId,
        sessionId: 'sess_adv',
        questionCount: 2,
      );

      // Answer Q0 correctly (Option A) and Q1 correctly
      execState = execEngine
          .submitAnswer(
            state: execState,
            questionId: 'q_sess_adv_0',
            answer: 'A',
            submittedAt: baseDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      execState = execEngine
          .submitAnswer(
            state: execState,
            questionId: 'q_sess_adv_1',
            answer: 'A',
            submittedAt: baseDate.add(const Duration(seconds: 20)),
          )
          .valueOrThrow;

      expect(execState.status, equals(PracticeExecutionStatus.completed));

      final request = LearningActivityCompletionRequest(
        requestId: 'req_adv',
        learnerId: learnerId,
        examId: examId,
        activityId: 'act_adv_01',
        activityType: LearningDecisionType.advancement,
        planId: 'plan_adv_01',
        planRevision: 1,
        executionState: execState,
        completedAt: baseDate.add(const Duration(seconds: 25)),
      );

      final result = await completionService.completeActivity(request);
      expect(result.status, equals(LearningActivityCompletionStatus.success));
      expect(result.isSuccess, isTrue);
      expect(result.outcome?.questionsPresented, equals(2));
      expect(result.outcome?.questionsAttempted, equals(2));
      expect(result.outcome?.correctAnswers, equals(2));
      expect(result.outcome?.score, equals(1.0));
      expect(result.outcome?.accuracy, equals(1.0));
      expect(result.outcome?.completionRate, equals(1.0));
      expect(result.hasStateAdvanced, isTrue);
      expect(result.resultingAuthoritativeState?.revision, equals(2));
    });
  });
}
