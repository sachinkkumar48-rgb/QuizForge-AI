/// P42 Adaptive Learning Plan Execution End-to-End Integration Test Suite (TITAN-KO-042.0 P42).
///
/// Exercises the complete integration loop across the TITAN learning operating system:
/// P39 Persisted State -> P40 Session Recovery -> P41 Decision Formulation
/// -> P42 Plan Execution -> P35 Practice Session -> P36 Consolidation
/// -> P38 Reconciliation -> P39 Persistence -> P40 Checkpointing.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P42 Adaptive Learning Plan Execution End-to-End Integration Flow', () {
    final baseDate = DateTime.utc(2026, 9, 15, 10, 0, 0);

    const proposer = LearningStateUpdateProposer();
    const consolidator = PracticeOutcomeConsolidator();
    const execEngine = AdaptivePracticeExecutionEngine();
    const orchestrator = AdaptivePracticeSessionOrchestrator();
    const selectionService = AdaptiveQuestionSelectionService();
    final decisionEngine = AdaptiveLearningDecisionEngine();

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late AdaptiveLearningStateReconciliationPipeline pipeline;
    late ResumableAdaptivePracticeCoordinator coordinator;
    late AdaptiveLearningPlanExecutor planExecutor;

    setUp(() {
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      checkpointRepo = InMemorySessionCheckpointRepository();

      authRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );

      sessionRecoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );

      pipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: authRepo,
        recoveryService: authRecoveryService,
        reconciler: const AdaptiveLearningStateReconciler(),
        proposer: proposer,
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
    });

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
        normalizedText: 'Normalized question text for $id',
        originalText: 'Original question text for $id',
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
            (objectiveId != null ? [objectiveId] : const ['lo_const_01']),
      );
    }

    test(
        'Flow 1: P41 Continuation Plan -> P42 Executor -> Resumes Session at Cursor 2',
        () async {
      const learnerId = 'learner_p42_flow1';
      const examId = 'upsc';

      final questions = List<NormalizedQuestion>.generate(
        5,
        (i) => buildQuestion(
            id: 'q_f1_$i', examId: examId, objectiveId: 'lo_const_01'),
      );

      // 1. Initialize cold start state
      final authInit = await authRecoveryService.recover(
        learnerId: learnerId,
        examId: examId,
        requestedAt: baseDate,
      );
      var currentAuthState = authInit.state!;

      // 2. Build initial session spec
      final selection = selectionService.selectQuestions(
        corpus: questions,
        config: AdaptiveQuestionSelectionConfig(
            examId: examId, targetQuestionCount: 5),
        selectedAt: baseDate,
      );
      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config:
            AdaptivePracticeSessionConfig(examId: examId, learnerId: learnerId),
        orchestratedAt: baseDate,
      );

      // 3. Start session and answer Q0, Q1
      final startStep = await coordinator.startSession(
        spec: spec,
        baseState: currentAuthState,
        startedAt: baseDate,
      );

      final step0 = await coordinator.submitAnswerAndCheckpoint(
        executionState: startStep.executionState,
        baseState: currentAuthState,
        currentCheckpoint: startStep.checkpoint,
        questionId: 'q_f1_0',
        answer: 'A',
        submittedAt: baseDate.add(const Duration(seconds: 15)),
      );

      final step1 = await coordinator.submitAnswerAndCheckpoint(
        executionState: step0.executionState,
        baseState: step0.authoritativeState,
        currentCheckpoint: step0.checkpoint,
        questionId: 'q_f1_1',
        answer: 'A',
        submittedAt: baseDate.add(const Duration(seconds: 30)),
      );

      currentAuthState = step1.authoritativeState;
      final activeCheckpoint = step1.checkpoint;
      expect(activeCheckpoint.questionIndex, equals(2));

      // 4. P41 Decision Engine formulates continuation plan
      final plan = decisionEngine.evaluateAndPlan(
        authoritativeState: currentAuthState,
        activeCheckpoint: activeCheckpoint,
        asOfDate: baseDate.add(const Duration(seconds: 45)),
      );
      expect(plan.decision.type, equals(LearningDecisionType.continuation));
      expect(plan.target.cursorIndex, equals(2));

      // 5. P42 Executor executes the continuation plan
      final executionRequest = LearningActivityExecutionRequest(
        requestId: 'req_f1_resume',
        learnerId: learnerId,
        examId: examId,
        plan: plan,
        currentState: currentAuthState,
        existingSessionSpec: spec,
        activeCheckpoint: activeCheckpoint,
        requestedAt: baseDate.add(const Duration(seconds: 50)),
      );

      final result = await planExecutor.execute(executionRequest);

      // Verify resumption
      expect(result.status, equals(LearningActivityExecutionStatus.resumed));
      expect(result.isSuccess, isTrue);
      expect(result.executionState?.currentQuestionIndex, equals(2));
      expect(result.checkpoint?.questionIndex, equals(2));
      expect(result.sessionSpec?.sessionId, equals(spec.sessionId));
      expect(result.auditTrail.allStepsSuccessful, isTrue);
    });

    test(
        'Flow 2: P41 Remediation Plan -> P42 Executor -> Binds Lesson & Starts Remedial Session',
        () async {
      const learnerId = 'learner_p42_flow2';
      const examId = 'upsc';
      const weakObjId = 'lo_const_weak';

      final questions = List<NormalizedQuestion>.generate(
        5,
        (i) => buildQuestion(
            id: 'q_f2_$i', examId: examId, objectiveId: weakObjId),
      );

      // 1. Authoritative state with material weakness (4 attempts, 1 correct = 25%)
      final progressMap = {
        weakObjId: LearnerProgress(
          learnerId: learnerId,
          objectiveId: weakObjId,
          attemptCount: 4,
          correctCount: 1,
          status: LearnerObjectiveStatus.inProgress,
          lastAttemptAt: baseDate,
        ),
      };

      final state = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: progressMap,
        lastUpdatedAt: baseDate,
        revision: 2,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      // 2. Setup remedial lesson
      final remedialLesson = RemedialLesson(
        lessonId: 'rem_weak_01',
        objectiveId: weakObjId,
        title: 'Remedial Constitutional Law',
        summary: 'Deep dive into fundamental concepts',
        learningPoints: const ['Point 1', 'Point 2'],
        explanation: 'Detailed explanation',
        examples: const ['Example 1'],
        misconceptions: const ['Common misconception'],
        sourceReferences: const [],
        contentOrigin: ContentOrigin.pedagogicalExplanation,
        estimatedMinutes: 20,
        bloomLevel: BloomTaxonomyLevel.understand,
        authoredAt: baseDate,
      );

      // 3. P41 Decision Engine formulates remediation plan
      final plan = decisionEngine.evaluateAndPlan(
        authoritativeState: state,
        availableRemedialLessons: [remedialLesson],
        asOfDate: baseDate,
      );
      expect(plan.decision.type, equals(LearningDecisionType.remediation));
      expect(plan.remedialLesson?.lessonId, equals('rem_weak_01'));

      // 4. P42 Executor dispatches remediation plan
      final request = LearningActivityExecutionRequest(
        requestId: 'req_f2_remed',
        learnerId: learnerId,
        examId: examId,
        plan: plan,
        currentState: state,
        corpus: questions,
        requestedAt: baseDate,
      );

      final result = await planExecutor.execute(request);

      expect(result.status, equals(LearningActivityExecutionStatus.success));
      expect(result.isSuccess, isTrue);
      expect(result.remedialLesson?.lessonId, equals('rem_weak_01'));
      expect(result.sessionSpec?.config.sessionMode,
          equals(PracticeSessionMode.remedialPractice));
      expect(result.executionState?.status,
          equals(PracticeExecutionStatus.inProgress));
      expect(result.checkpoint?.checkpointRevision, equals(1));
    });

    test(
        'Flow 3: Complete Closed Loop across P39 -> P40 -> P41 -> P42 -> P35 -> P36 -> P38 -> P39',
        () async {
      const learnerId = 'learner_p42_loop';
      const examId = 'upsc';
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final objId = framework.allObjectives.first.id;
      final targetTopic = framework.allUnits
          .firstWhere((u) => u.objectives.any((o) => o.id == objId))
          .title;

      final questions = List<NormalizedQuestion>.generate(
        5,
        (i) => buildQuestion(
          id: 'q_loop_$i',
          examId: examId,
          subject: framework.title,
          topic: targetTopic,
          objectiveId: objId,
        ),
      );

      // 1. Initial State (Rev 1)
      final coldStart = await authRecoveryService.recover(
        learnerId: learnerId,
        examId: examId,
        requestedAt: baseDate,
      );
      var currentAuthState = coldStart.state!;
      expect(currentAuthState.revision, equals(1));

      // 2. P41 Plan Formulation (Unattempted -> Advancement)
      final plan = decisionEngine.evaluateAndPlan(
        authoritativeState: currentAuthState,
        framework: framework,
        asOfDate: baseDate,
      );
      expect(plan.decision.type, equals(LearningDecisionType.advancement));

      // 3. P42 Plan Execution -> Starts Session
      final execRequest = LearningActivityExecutionRequest(
        requestId: 'req_loop_start',
        learnerId: learnerId,
        examId: examId,
        plan: plan,
        currentState: currentAuthState,
        corpus: questions,
        requestedAt: baseDate,
      );

      final execResult = await planExecutor.execute(execRequest);
      expect(
          execResult.status, equals(LearningActivityExecutionStatus.success));

      var execution = execResult.executionState!;
      var checkpoint = execResult.checkpoint!;

      // 4. Learner answers all 5 questions
      for (int i = 0; i < 5; i++) {
        final step = await coordinator.submitAnswerAndCheckpoint(
          executionState: execution,
          baseState: currentAuthState,
          currentCheckpoint: checkpoint,
          questionId: 'q_loop_$i',
          answer: 'A',
          submittedAt: baseDate.add(Duration(seconds: (i + 1) * 20)),
        );
        execution = step.executionState;
        checkpoint = step.checkpoint;
        currentAuthState = step.authoritativeState;
      }

      // 5. Session reaches completion
      expect(checkpoint.isCompleted, isTrue);
      expect(checkpoint.completedQuestionIds.length, equals(5));

      // 6. Authoritative state advanced via pipeline
      expect(currentAuthState.revision,
          equals(6)); // initial 1 + 5 answer reconciliations
      expect(currentAuthState.progressMap[objId]!.attemptCount,
          greaterThanOrEqualTo(5));
      expect(currentAuthState.progressMap[objId]!.correctCount,
          greaterThanOrEqualTo(5));
      expect(currentAuthState.progressMap[objId]!.isAchieved, isTrue);

      // 7. Verify earlier plan is now stale
      expect(plan.isStale(currentAuthState), isTrue);

      // 8. Attempting to execute the earlier plan with the new state is safely rejected!
      final staleExecRequest = LearningActivityExecutionRequest(
        requestId: 'req_stale_attempt',
        learnerId: learnerId,
        examId: examId,
        plan: plan,
        currentState: currentAuthState,
        corpus: questions,
        requestedAt: baseDate.add(const Duration(minutes: 5)),
      );

      final staleResult = await planExecutor.execute(staleExecRequest);
      expect(staleResult.status,
          equals(LearningActivityExecutionStatus.stalePlan));
      expect(staleResult.error?.code, equals(PlanExecutionErrorCode.stalePlan));
    });

    test(
        'Flow 4: Curriculum Complete -> P42 Executor produces terminal result with 0 sessions',
        () async {
      const learnerId = 'learner_p42_complete';
      const examId = 'upsc';
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();

      final masteredMap = <String, LearnerProgress>{};
      for (final obj in framework.allObjectives) {
        masteredMap[obj.id] = LearnerProgress(
          learnerId: learnerId,
          objectiveId: obj.id,
          attemptCount: 10,
          correctCount: 10,
          status: LearnerObjectiveStatus.achieved,
          lastAttemptAt: baseDate, // recently practiced, no reviews due
        );
      }

      final state = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: masteredMap,
        lastUpdatedAt: baseDate,
        revision: 10,
      );

      // P41 decides complete
      final plan = decisionEngine.evaluateAndPlan(
        authoritativeState: state,
        framework: framework,
        asOfDate: baseDate,
      );
      expect(plan.decision.type, equals(LearningDecisionType.complete));

      // P42 executes complete plan
      final request = LearningActivityExecutionRequest(
        requestId: 'req_complete',
        learnerId: learnerId,
        examId: examId,
        plan: plan,
        currentState: state,
        requestedAt: baseDate,
      );

      final result = await planExecutor.execute(request);
      expect(result.status, equals(LearningActivityExecutionStatus.completed));
      expect(result.isCompleted, isTrue);
      expect(result.hasSession, isFalse);
    });

    test(
        'Flow 5: Recovery Required error when continuation checkpoint is missing',
        () async {
      const learnerId = 'learner_p42_missing_chk';
      const examId = 'upsc';

      final plan = LearningContinuationPlan(
        planId: 'plan_missing_chk',
        decision: AdaptiveLearningDecision(
          decisionId: 'dec_missing_chk',
          learnerId: learnerId,
          examId: examId,
          type: LearningDecisionType.continuation,
          priority: LearningDecisionPriority.urgent,
          reason: 'Continuation needed',
          target: LearningTarget.sessionCursor(
            sessionId: 'sess_nonexistent',
            cursorIndex: 2,
          ),
          evidence: LearningDecisionEvidence(authoritativeStateRevision: 1),
          authoritativeStateRevision: 1,
          decidedAt: baseDate,
        ),
        createdAt: baseDate,
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: learnerId,
        examId: examId,
        createdAt: baseDate,
      );

      final request = LearningActivityExecutionRequest(
        requestId: 'req_missing_chk',
        learnerId: learnerId,
        examId: examId,
        plan: plan,
        currentState: state,
        requestedAt: baseDate,
      );

      final result = await planExecutor.execute(request);
      expect(result.status,
          equals(LearningActivityExecutionStatus.recoveryRequired));
      expect(
          result.error?.code, equals(PlanExecutionErrorCode.recoveryRequired));
    });
  });
}
