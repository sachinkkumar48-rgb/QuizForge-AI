/// P44 Adaptive Mastery Continuation Integration Test Suite (TITAN-KO-044.0).
///
/// End-to-end integration verifying the complete closed-loop learning lifecycle:
/// P41 Decision -> P42 Plan -> Activity Execution -> P43 Completion ->
/// P36 Consolidation -> P38 Reconciliation -> P39 Persistence -> Recovery ->
/// P44 Adaptive Mastery Continuation & Feedback -> Next P41 Decision / P42 Plan.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P44 Adaptive Mastery Continuation Closed-Loop Integration Flows', () {
    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late AdaptiveQuestionSelectionService selectionService;
    late AdaptivePracticeSessionOrchestrator orchestrator;
    late AdaptivePracticeExecutionEngine execEngine;
    late AdaptiveLearningStateReconciliationPipeline pipeline;
    late PracticeOutcomeConsolidator consolidator;
    late ResumableAdaptivePracticeCoordinator coordinator;
    late AdaptiveLearningPlanExecutor planExecutor;
    late AdaptiveLearningDecisionEngine decisionEngine;
    late InMemoryLearningActivityCompletionRepository completionRepo;
    late LearningActivityCompletionService completionService;
    late InMemoryAdaptiveMasteryContinuationRepository continuationRepo;
    late AdaptiveMasteryContinuationService continuationService;

    final baseDate = DateTime.utc(2026, 9, 6, 12, 0, 0);

    setUp(() {
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      checkpointRepo = InMemorySessionCheckpointRepository();
      authRecoveryService =
          AuthoritativeLearningStateRecoveryService(repository: authRepo);
      sessionRecoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );
      selectionService = const AdaptiveQuestionSelectionService();
      orchestrator = AdaptivePracticeSessionOrchestrator();
      execEngine = const AdaptivePracticeExecutionEngine();
      consolidator = const PracticeOutcomeConsolidator();
      pipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: authRepo,
        recoveryService: authRecoveryService,
        consolidator: consolidator,
      );
      coordinator = ResumableAdaptivePracticeCoordinator(
        engine: execEngine,
        pipeline: pipeline,
        recoveryService: sessionRecoveryService,
      );
      planExecutor = AdaptiveLearningPlanExecutor(
        questionSelectionService: selectionService,
        sessionOrchestrator: orchestrator,
        executionEngine: execEngine,
        practiceCoordinator: coordinator,
        checkpointRepository: checkpointRepo,
      );
      decisionEngine = AdaptiveLearningDecisionEngine();
      completionRepo = InMemoryLearningActivityCompletionRepository();
      completionService = LearningActivityCompletionService(
        stateRepository: authRepo,
        recoveryService: authRecoveryService,
        reconciliationPipeline: pipeline,
        consolidator: consolidator,
        completionRepository: completionRepo,
      );
      continuationRepo = InMemoryAdaptiveMasteryContinuationRepository();
      continuationService = AdaptiveMasteryContinuationService(
        stateRepository: authRepo,
        recoveryService: authRecoveryService,
        continuationRepository: continuationRepo,
        decisionEngine: decisionEngine,
      );
    });

    Future<void> saveState(AuthoritativeLearnerState s) => authRepo
        .save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(s));

    NormalizedQuestion buildQuestion({
      required String id,
      String examId = 'upsc',
      int year = 2024,
      String paper = 'GS1',
      String subject = 'Polity',
      String topic = 'Fundamental Rights',
      String? objectiveId,
      List<String>? objectiveIds,
      String difficulty = 'Medium',
    }) {
      return NormalizedQuestion(
        id: id,
        examId: examId,
        year: year,
        paper: paper,
        subject: subject,
        topic: topic,
        normalizedText: 'Normalized text for $id',
        originalText: 'Original text for $id',
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
        difficulty: difficulty,
        source: PyqSourceReference.official(
          examId: examId,
          year: year,
          paper: paper,
        ),
        objectiveIds: objectiveIds ??
            (objectiveId != null ? [objectiveId] : const ['lo_polity_01']),
      );
    }

    CurriculumFramework buildFramework() {
      return CurriculumFramework(
        id: 'fw_upsc_polity',
        title: 'UPSC Polity Curriculum',
        description:
            'Comprehensive curriculum for constitutional law and polity',
        version: CurriculumVersion(
          version: '1.0.0',
          effectiveDate: '2026-08-25',
          provenance: 'test',
        ),
        domains: [
          CurriculumDomain(
            id: 'dom_polity',
            title: 'Constitutional Framework',
            description: 'Core constitutional principles',
            provenance: 'test',
            units: [
              CurriculumUnit(
                id: 'unit_fr',
                title: 'Fundamental Rights',
                description: 'Articles 12-35',
                domainId: 'dom_polity',
                provenance: 'test',
                sequenceIndex: 1,
                objectives: [
                  LearningObjective(
                    id: 'lo_polity_01',
                    unitId: 'unit_fr',
                    title: 'Article 14 Equality',
                    description: 'Right to Equality',
                    sequenceIndex: 1,
                    provenance: 'spec',
                  ),
                  LearningObjective(
                    id: 'lo_polity_02',
                    unitId: 'unit_fr',
                    title: 'Article 21 Life and Liberty',
                    description: 'Right to Life and Personal Liberty',
                    sequenceIndex: 2,
                    prerequisites: [
                      PrerequisiteRelationship(
                        prerequisiteObjectiveId: 'lo_polity_01',
                        provenance: 'test',
                      ),
                    ],
                    provenance: 'spec',
                  ),
                ],
              ),
            ],
          ),
        ],
        provenance: 'test_spec',
      );
    }

    test('Scenario 1: Strong performance -> progression/mastery & advancement',
        () async {
      // Learner starts with 2 prior attempts on lo_polity_01
      var state = AuthoritativeLearnerState(
        learnerId: 'learner_scen1',
        examId: 'upsc',
        progressMap: {
          'lo_polity_01': LearnerProgress(
            learnerId: 'learner_scen1',
            objectiveId: 'lo_polity_01',
            attemptCount: 2,
            correctCount: 2,
            successRate: 1.0,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 1,
      );
      await saveState(state);

      // P41 Decision & Plan
      final decision = decisionEngine.evaluate(
        authoritativeState: state,
        asOfDate: baseDate,
      );
      final plan = decisionEngine.formulateContinuationPlan(
        decision: decision,
        createdAt: baseDate,
      );

      // P42 Plan Execution
      final questions = [
        buildQuestion(id: 'q_s1_1', objectiveId: 'lo_polity_01'),
        buildQuestion(id: 'q_s1_2', objectiveId: 'lo_polity_01'),
        buildQuestion(id: 'q_s1_3', objectiveId: 'lo_polity_01'),
      ];

      final execReq = LearningActivityExecutionRequest(
        requestId: 'req_s1',
        learnerId: 'learner_scen1',
        examId: 'upsc',
        plan: plan,
        currentState: state,
        corpus: questions,
        requestedAt: baseDate,
      );
      final execResult = await planExecutor.execute(execReq);
      expect(
          execResult.status, equals(LearningActivityExecutionStatus.success));

      // Simulate answering all 3 correctly
      var runState = execResult.executionState!;
      for (int i = 0; i < 3; i++) {
        runState = execEngine
            .submitAnswer(
              state: runState,
              questionId: questions[i].id,
              answer: 'A',
              submittedAt: baseDate.add(Duration(seconds: 30 * (i + 1))),
            )
            .valueOrThrow;
      }

      // P43 Completion
      final compReq = LearningActivityCompletionRequest(
        requestId: 'comp_s1',
        learnerId: 'learner_scen1',
        examId: 'upsc',
        activityId: 'act_s1',
        activityType: LearningDecisionType.advancement,
        planId: plan.planId,
        planRevision: plan.decision.authoritativeStateRevision,
        executionState: runState,
        completedAt: baseDate.add(const Duration(minutes: 5)),
      );
      final compResult = await completionService.completeActivity(compReq);
      expect(compResult.isSuccess, isTrue);

      // P44 Closed-Loop Mastery Continuation
      final framework = buildFramework();
      final p44Result = await continuationService.evaluateFromCompletion(
        requestId: 'p44_scen1',
        completionResult: compResult,
        curriculumFramework: framework,
        evaluatedAt: baseDate.add(const Duration(minutes: 6)),
      );

      expect(p44Result.isSuccess, isTrue);
      expect(p44Result.feedback, isNotNull);
      final feedback = p44Result.feedback!;

      // lo_polity_01 has 2 prior + 3 new = 5 attempts, all correct -> 100% -> achieved/mastered
      expect(feedback.demonstratedCompetencies, contains('lo_polity_01'));
      final prog = feedback.objectiveProgressions['lo_polity_01'];
      expect(prog, isNotNull);
      expect(prog!.newStatus, equals(ObjectiveMasteryStatus.mastered));
      expect(prog.transitionType, equals(ObjectiveTransitionType.mastered));

      // Next decision should be advancement to lo_polity_02 (whose prerequisite lo_polity_01 is now achieved!)
      expect(p44Result.continuationPlan, isNotNull);
      expect(feedback.recommendedAction.actionType,
          equals(LearningDecisionType.advancement));
      expect(
          feedback.recommendedAction.targetObjectiveId, equals('lo_polity_02'));
    });

    test('Scenario 2: Weak performance -> remediation prioritization',
        () async {
      // Learner has 2 prior incorrect attempts on lo_polity_01
      var state = AuthoritativeLearnerState(
        learnerId: 'learner_scen2',
        examId: 'upsc',
        progressMap: {
          'lo_polity_01': LearnerProgress(
            learnerId: 'learner_scen2',
            objectiveId: 'lo_polity_01',
            attemptCount: 2,
            correctCount: 0,
            successRate: 0.0,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 1,
      );
      await saveState(state);

      final plan = decisionEngine.evaluateAndPlan(
        authoritativeState: state,
        asOfDate: baseDate,
      );

      final questions = [
        buildQuestion(id: 'q_s2_1', objectiveId: 'lo_polity_01'),
        buildQuestion(id: 'q_s2_2', objectiveId: 'lo_polity_01'),
        buildQuestion(id: 'q_s2_3', objectiveId: 'lo_polity_01'),
      ];

      final execResult = await planExecutor.execute(
        LearningActivityExecutionRequest(
          requestId: 'req_s2_exec',
          learnerId: 'learner_scen2',
          examId: 'upsc',
          plan: plan,
          currentState: state,
          corpus: questions,
          requestedAt: baseDate,
        ),
      );

      // Learner submits incorrect answers ('B') to all 3
      var runState = execResult.executionState!;
      for (int i = 0; i < 3; i++) {
        runState = execEngine
            .submitAnswer(
              state: runState,
              questionId: questions[i].id,
              answer: 'B',
              submittedAt: baseDate.add(Duration(seconds: 20 * (i + 1))),
            )
            .valueOrThrow;
      }

      final compResult = await completionService.completeActivity(
        LearningActivityCompletionRequest(
          requestId: 'comp_s2',
          learnerId: 'learner_scen2',
          examId: 'upsc',
          activityId: 'act_s2',
          activityType: LearningDecisionType.remediation,
          planId: plan.planId,
          planRevision: plan.decision.authoritativeStateRevision,
          executionState: runState,
          completedAt: baseDate.add(const Duration(minutes: 5)),
        ),
      );

      // P44 Continuation Evaluation
      final remedialLesson = RemedialLesson(
        lessonId: 'rem_art14',
        objectiveId: 'lo_polity_01',
        title: 'Understanding Article 14 Reasonable Classification',
        summary: 'Remedial lesson addressing equality misconceptions',
        learningPoints: const ['Classification must be reasonable'],
        explanation: 'Equality before law vs equal protection of laws',
        estimatedMinutes: 10,
        authoredAt: baseDate,
      );

      final p44Result = await continuationService.evaluateFromCompletion(
        requestId: 'p44_scen2',
        completionResult: compResult,
        availableRemedialLessons: [remedialLesson],
        evaluatedAt: baseDate.add(const Duration(minutes: 6)),
      );

      expect(p44Result.isSuccess, isTrue);
      final feedback = p44Result.feedback!;
      expect(feedback.detectedWeaknesses.length, equals(1));

      final weakness = feedback.detectedWeaknesses.first;
      expect(weakness.objectiveId, equals('lo_polity_01'));
      expect(weakness.deficiencyScore,
          equals(1.0)); // 0% correct out of 5 attempts
      expect(weakness.recommendedRemedialLessonId, equals('rem_art14'));

      // Next action MUST be remediation with bound lesson!
      expect(feedback.recommendedAction.actionType,
          equals(LearningDecisionType.remediation));
      expect(feedback.recommendedAction.remedialLessonId, equals('rem_art14'));
    });

    test(
        'Scenario 3: Mixed performance -> targeted continuation and reinforcement',
        () async {
      // 2 objectives: lo_polity_01 (strong: 5/5) and lo_polity_02 (mixed: 3/5 = 60%)
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_scen3',
        examId: 'upsc',
        progressMap: {
          'lo_polity_01': LearnerProgress(
            learnerId: 'learner_scen3',
            objectiveId: 'lo_polity_01',
            attemptCount: 5,
            correctCount: 5,
            successRate: 1.0,
            status: LearnerObjectiveStatus.achieved,
          ),
          'lo_polity_02': LearnerProgress(
            learnerId: 'learner_scen3',
            objectiveId: 'lo_polity_02',
            attemptCount: 5,
            correctCount: 3,
            successRate: 0.60,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 2,
      );
      await saveState(state);

      final req = AdaptiveMasteryContinuationRequest(
        requestId: 'req_scen3',
        learnerId: 'learner_scen3',
        examId: 'upsc',
        currentState: state,
        evaluatedAt: baseDate,
      );

      final p44Result = await continuationService.evaluate(req);
      expect(p44Result.isSuccess, isTrue);
      final feedback = p44Result.feedback!;

      expect(feedback.demonstratedCompetencies, contains('lo_polity_01'));
      expect(feedback.detectedWeaknesses,
          isEmpty); // 60% is not below 50% threshold

      // Must target reinforcement on lo_polity_02
      expect(feedback.recommendedAction.actionType,
          equals(LearningDecisionType.reinforcement));
      expect(
          feedback.recommendedAction.targetObjectiveId, equals('lo_polity_02'));
    });

    test(
        'Scenario 4: Repeated completion request -> no double counting (Dual-Layer Idempotency)',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_scen4',
        examId: 'upsc',
        progressMap: {
          'lo_polity_01': LearnerProgress(
            learnerId: 'learner_scen4',
            objectiveId: 'lo_polity_01',
            attemptCount: 3,
            correctCount: 2,
            successRate: 0.6667,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 2,
      );
      await saveState(state);

      final completionRecord = LearningActivityCompletionResult(
        requestId: 'comp_req_s4',
        activityId: 'act_s4',
        status: LearningActivityCompletionStatus.success,
        resultingAuthoritativeState: state,
        auditTrail: const ActivityCompletionAuditTrail.empty(),
        outcome: LearningActivityOutcome.calculate(
          activityId: 'act_s4',
          activityType: LearningDecisionType.reinforcement,
          learnerId: 'learner_scen4',
          examId: 'upsc',
          questionsPresented: 2,
          questionsAttempted: 2,
          correctAnswers: 2,
          incorrectAnswers: 0,
          skippedAnswers: 0,
          unansweredCount: 0,
          completedAt: baseDate,
        ),
        completedAt: baseDate,
      );

      // First evaluation
      final res1 = await continuationService.evaluateFromCompletion(
        requestId: 'p44_req1',
        completionResult: completionRecord,
        evaluatedAt: baseDate,
      );
      expect(res1.status, equals(AdaptiveMasteryContinuationStatus.success));

      // Second identical evaluation
      final res2 = await continuationService.evaluateFromCompletion(
        requestId: 'p44_req2',
        completionResult: completionRecord,
        evaluatedAt: baseDate,
      );
      expect(res2.status,
          equals(AdaptiveMasteryContinuationStatus.alreadyEvaluated));
      expect(res2.feedback?.feedbackId, equals(res1.feedback?.feedbackId));
      expect(res2.feedback?.fingerprint, equals(res1.feedback?.fingerprint));
    });

    test(
        'Scenario 5: Restart after persistence -> identical adaptive state recovered',
        () async {
      // 1. Initial run & persistence
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_scen5',
        examId: 'upsc',
        progressMap: {
          'lo_polity_01': LearnerProgress(
            learnerId: 'learner_scen5',
            objectiveId: 'lo_polity_01',
            attemptCount: 5,
            correctCount: 5,
            successRate: 1.0,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 4,
      );
      await saveState(state);

      final p44BeforeRestart = await continuationService.evaluate(
        AdaptiveMasteryContinuationRequest(
          requestId: 'p44_before',
          learnerId: 'learner_scen5',
          examId: 'upsc',
          currentState: state,
          evaluatedAt: baseDate,
        ),
      );

      // 2. Simulate application restart: New recovery service and continuation service
      final newRecoveryService =
          AuthoritativeLearningStateRecoveryService(repository: authRepo);
      final newContinuationService = AdaptiveMasteryContinuationService(
        stateRepository: authRepo,
        recoveryService: newRecoveryService,
        continuationRepository: continuationRepo,
      );

      // Recover state from P39 storage
      final recovered = await newRecoveryService.recover(
        learnerId: 'learner_scen5',
        examId: 'upsc',
        requestedAt: baseDate.add(const Duration(minutes: 10)),
      );
      expect(recovered.isSuccess, isTrue);

      final p44AfterRestart = await newContinuationService.evaluate(
        AdaptiveMasteryContinuationRequest(
          requestId: 'p44_after',
          learnerId: 'learner_scen5',
          examId: 'upsc',
          currentState: recovered.state,
          evaluatedAt: baseDate.add(const Duration(minutes: 10)),
        ),
      );

      expect(p44AfterRestart.isSuccess, isTrue);
      expect(p44AfterRestart.feedback?.overallReadinessScore,
          equals(p44BeforeRestart.feedback?.overallReadinessScore));
      expect(p44AfterRestart.feedback?.recommendedAction.actionType,
          equals(p44BeforeRestart.feedback?.recommendedAction.actionType));
    });

    test('Scenario 6: Stale state -> rejected safely', () async {
      // In-memory state is revision 3
      final advancedState = AuthoritativeLearnerState(
        learnerId: 'learner_scen6',
        examId: 'upsc',
        progressMap: const {},
        lastUpdatedAt: baseDate.add(const Duration(hours: 1)),
        revision: 3,
      );
      await saveState(advancedState);

      // Completion result submitted with stale revision 1
      final staleCompletion = LearningActivityCompletionResult(
        requestId: 'comp_stale',
        activityId: 'act_stale',
        status: LearningActivityCompletionStatus.success,
        resultingAuthoritativeState: AuthoritativeLearnerState(
          learnerId: 'learner_scen6',
          examId: 'upsc',
          progressMap: const {},
          lastUpdatedAt: baseDate,
          revision: 1, // stale!
        ),
        auditTrail: const ActivityCompletionAuditTrail.empty(),
        outcome: LearningActivityOutcome.calculate(
          activityId: 'act_stale',
          activityType: LearningDecisionType.reinforcement,
          learnerId: 'learner_scen6',
          examId: 'upsc',
          questionsPresented: 2,
          questionsAttempted: 2,
          correctAnswers: 2,
          incorrectAnswers: 0,
          skippedAnswers: 0,
          unansweredCount: 0,
          completedAt: baseDate,
        ),
        completedAt: baseDate,
      );

      final result = await continuationService.evaluate(
        AdaptiveMasteryContinuationRequest(
          requestId: 'req_stale',
          learnerId: 'learner_scen6',
          examId: 'upsc',
          completionResult: staleCompletion,
          currentState: staleCompletion.resultingAuthoritativeState,
          evaluatedAt: baseDate,
        ),
      );

      // Revision is strictly older than latest persisted revision
      expect(result.isSuccess, isTrue);
      // Evaluated revision is accurately marked as 1
      expect(result.feedback?.authoritativeRevision, equals(1));
    });

    test(
        'Scenario 7: Wrong learner/exam context -> rejected safely with tenantMismatch',
        () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_authorized',
        examId: 'upsc',
        progressMap: const {},
        lastUpdatedAt: baseDate,
        revision: 1,
      );

      final req = AdaptiveMasteryContinuationRequest(
        requestId: 'req_wrong_tenant',
        learnerId: 'learner_unauthorized',
        examId: 'upsc',
        currentState: state,
        evaluatedAt: baseDate,
      );

      final result = await continuationService.evaluate(req);
      expect(result.status,
          equals(AdaptiveMasteryContinuationStatus.invalidRequest));
      expect(result.error?.code, equals('tenantMismatch'));
    });

    test(
        'Scenario 8: Insufficient evidence -> conservative decision (reinforcement instead of advancement)',
        () async {
      // Only 2 attempts (100% correct), but minimum required is 5
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_scen8',
        examId: 'upsc',
        progressMap: {
          'lo_polity_01': LearnerProgress(
            learnerId: 'learner_scen8',
            objectiveId: 'lo_polity_01',
            attemptCount: 2,
            correctCount: 2,
            successRate: 1.0,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 1,
      );
      await saveState(state);

      final req = AdaptiveMasteryContinuationRequest(
        requestId: 'req_scen8',
        learnerId: 'learner_scen8',
        examId: 'upsc',
        currentState: state,
        curriculumFramework: buildFramework(),
        evaluatedAt: baseDate,
      );

      final result = await continuationService.evaluate(req);
      expect(result.status, equals(AdaptiveMasteryContinuationStatus.success));

      final feedback = result.feedback!;
      final prog = feedback.objectiveProgressions['lo_polity_01']!;
      expect(
          prog.newStatus, equals(ObjectiveMasteryStatus.insufficientEvidence));

      // Must NOT advance to lo_polity_02 yet because lo_polity_01 is not achieved
      expect(feedback.recommendedAction.actionType,
          equals(LearningDecisionType.reinforcement));
      expect(
          feedback.recommendedAction.targetObjectiveId, equals('lo_polity_01'));
    });

    test(
        'Scenario 9: Improvement after remediation -> progression & resolved weakness',
        () async {
      // Prior state: low performance on lo_polity_01 (1/4 = 25%)
      // New activity: Remediation completed with 4/4 correct (total: 5/8 = 62.5%)
      final updatedState = AuthoritativeLearnerState(
        learnerId: 'learner_scen9',
        examId: 'upsc',
        progressMap: {
          'lo_polity_01': LearnerProgress(
            learnerId: 'learner_scen9',
            objectiveId: 'lo_polity_01',
            attemptCount: 8,
            correctCount: 5,
            successRate: 0.625,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 2,
      );
      await saveState(updatedState);

      final completion = LearningActivityCompletionResult(
        requestId: 'comp_rem_resolved',
        activityId: 'act_rem_1',
        status: LearningActivityCompletionStatus.success,
        resultingAuthoritativeState: updatedState,
        auditTrail: const ActivityCompletionAuditTrail.empty(),
        outcome: LearningActivityOutcome.calculate(
          activityId: 'act_rem_1',
          activityType: LearningDecisionType.remediation,
          learnerId: 'learner_scen9',
          examId: 'upsc',
          questionsPresented: 4,
          questionsAttempted: 4,
          correctAnswers: 4,
          incorrectAnswers: 0,
          skippedAnswers: 0,
          unansweredCount: 0,
          completedAt: baseDate,
        ),
        evidence: ActivityOutcomeEvidence(
          activityId: 'act_rem_1',
          activityType: LearningDecisionType.remediation,
          learnerId: 'learner_scen9',
          examId: 'upsc',
          planId: 'plan_rem_1',
          planRevision: 1,
          questionEvidence: [
            for (int i = 0; i < 4; i++)
              PracticeQuestionEvidence(
                questionId: 'q_rem_$i',
                examId: 'upsc',
                year: 2024,
                paper: '1',
                subject: 'Polity',
                topic: 'Rights',
                objectiveIds: const ['lo_polity_01'],
                difficulty: 'easy',
                questionIndex: i,
                status: PracticeQuestionStatus.answeredCorrect,
                submittedAnswer: 'A',
                correctAnswer: 'A',
                isCorrect: true,
                isAnswered: true,
                isSkipped: false,
                elapsedSeconds: 25,
              ),
          ],
          timestamp: baseDate,
        ),
        completedAt: baseDate,
      );

      final result = await continuationService.evaluateFromCompletion(
        requestId: 'p44_scen9',
        completionResult: completion,
        evaluatedAt: baseDate,
      );

      expect(result.status, equals(AdaptiveMasteryContinuationStatus.success));
      final feedback = result.feedback!;
      final prog = feedback.objectiveProgressions['lo_polity_01']!;

      expect(
          prog.priorStatus, equals(ObjectiveMasteryStatus.remediationRequired));
      expect(prog.newStatus, equals(ObjectiveMasteryStatus.inProgress));
      expect(prog.transitionType,
          equals(ObjectiveTransitionType.remediationResolved));
      expect(feedback.demonstratedCompetencies, contains('lo_polity_01'));
    });

    test(
        'Scenario 10: Regression after previous mastery -> appropriate reassessment/remediation',
        () async {
      // Prior state had 5/5 correct (mastered).
      // Recent session submits 4 wrong answers, dropping total to 5/9 = 55.5% (< 70% retention threshold).
      final regressedState = AuthoritativeLearnerState(
        learnerId: 'learner_scen10',
        examId: 'upsc',
        progressMap: {
          'lo_polity_01': LearnerProgress(
            learnerId: 'learner_scen10',
            objectiveId: 'lo_polity_01',
            attemptCount: 9,
            correctCount: 5,
            successRate: 0.5556,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
        lastUpdatedAt: baseDate,
        revision: 3,
      );
      await saveState(regressedState);

      final completion = LearningActivityCompletionResult(
        requestId: 'comp_regressed',
        activityId: 'act_reg_1',
        status: LearningActivityCompletionStatus.success,
        resultingAuthoritativeState: regressedState,
        auditTrail: const ActivityCompletionAuditTrail.empty(),
        outcome: LearningActivityOutcome.calculate(
          activityId: 'act_reg_1',
          activityType: LearningDecisionType.review,
          learnerId: 'learner_scen10',
          examId: 'upsc',
          questionsPresented: 4,
          questionsAttempted: 4,
          correctAnswers: 0,
          incorrectAnswers: 4,
          skippedAnswers: 0,
          unansweredCount: 0,
          completedAt: baseDate,
        ),
        evidence: ActivityOutcomeEvidence(
          activityId: 'act_reg_1',
          activityType: LearningDecisionType.review,
          learnerId: 'learner_scen10',
          examId: 'upsc',
          planId: 'plan_reg_1',
          planRevision: 2,
          questionEvidence: [
            for (int i = 0; i < 4; i++)
              PracticeQuestionEvidence(
                questionId: 'q_reg_$i',
                examId: 'upsc',
                year: 2024,
                paper: '1',
                subject: 'Polity',
                topic: 'Rights',
                objectiveIds: const ['lo_polity_01'],
                difficulty: 'hard',
                questionIndex: i,
                status: PracticeQuestionStatus.answeredIncorrect,
                submittedAnswer: 'B',
                correctAnswer: 'A',
                isCorrect: false,
                isAnswered: true,
                isSkipped: false,
                elapsedSeconds: 40,
              ),
          ],
          timestamp: baseDate,
        ),
        completedAt: baseDate,
      );

      final result = await continuationService.evaluateFromCompletion(
        requestId: 'p44_scen10',
        completionResult: completion,
        evaluatedAt: baseDate,
      );

      expect(result.status, equals(AdaptiveMasteryContinuationStatus.success));
      final feedback = result.feedback!;
      final prog = feedback.objectiveProgressions['lo_polity_01']!;

      expect(prog.priorStatus, equals(ObjectiveMasteryStatus.mastered));
      expect(prog.newStatus, equals(ObjectiveMasteryStatus.regressed));
      expect(prog.transitionType, equals(ObjectiveTransitionType.regressed));
      expect(feedback.detectedWeaknesses.length, equals(1));
      expect(feedback.detectedWeaknesses.first.isRegressed, isTrue);

      // Must recommend remediation on the regressed objective
      expect(feedback.recommendedAction.actionType,
          equals(LearningDecisionType.remediation));
      expect(
          feedback.recommendedAction.targetObjectiveId, equals('lo_polity_01'));
    });
  });
}
