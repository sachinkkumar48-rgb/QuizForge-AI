/// P43 Learning Activity Completion & Outcome Feedback Integration Test Suite (TITAN-KO-043.0).
///
/// End-to-end integration verifying complete closed-loop lifecycle across:
/// P41 Decision -> P42 Plan Execution -> Practice Session -> P43 Completion ->
/// Normalized Outcome & Evidence -> P36 Consolidation -> P38 Reconciliation ->
/// P39 Persistence -> Next P41 Decision.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P43 Learning Activity Completion End-to-End Integration Flows', () {
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

    final baseDate = DateTime.utc(2026, 9, 4, 14, 0, 0);

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
            (objectiveId != null ? [objectiveId] : const ['lo_const_01']),
      );
    }

    test('Flow 1: P42 -> complete activity -> P43 outcome -> P36 consolidation',
        () async {
      const learnerId = 'learner_flow1';
      const examId = 'upsc';
      const objId = 'lo_const_01';

      final questions = List<NormalizedQuestion>.generate(
        3,
        (i) => buildQuestion(id: 'q_f1_$i', examId: examId, objectiveId: objId),
      );

      // 1. Setup cold start state at revision 1
      final coldStart = await authRecoveryService.recover(
        learnerId: learnerId,
        examId: examId,
        requestedAt: baseDate,
      );
      final currentAuthState = coldStart.state!;
      expect(currentAuthState.revision, equals(1));

      // 2. P41 Advancement Plan
      final plan = LearningContinuationPlan(
        planId: 'plan_f1',
        decision: AdaptiveLearningDecision(
          decisionId: 'dec_f1',
          learnerId: learnerId,
          examId: examId,
          type: LearningDecisionType.advancement,
          priority: LearningDecisionPriority.medium,
          reason: 'Advance to $objId',
          target: LearningTarget.objective(
            objectiveId: objId,
            type: LearningTargetType.curriculumObjective,
            topic: 'Fundamental Rights',
            subject: 'Polity',
          ),
          evidence: LearningDecisionEvidence(
              objectiveId: objId, authoritativeStateRevision: 1),
          authoritativeStateRevision: 1,
          decidedAt: baseDate,
        ),
        createdAt: baseDate,
      );

      // 3. P42 Executes Plan -> Starts Session
      final execRequest = LearningActivityExecutionRequest(
        requestId: 'req_f1_exec',
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
      expect(execResult.hasSession, isTrue);

      var sessionState = execResult.executionState!;

      // 4. Learner answers all 3 questions
      for (int i = 0; i < 3; i++) {
        sessionState = execEngine
            .submitAnswer(
              state: sessionState,
              questionId: 'q_f1_$i',
              answer: 'A',
              submittedAt: baseDate.add(Duration(seconds: (i + 1) * 15)),
            )
            .valueOrThrow;
      }
      expect(sessionState.status, equals(PracticeExecutionStatus.completed));

      // 5. P43 Activity Completion
      final completionRequest = LearningActivityCompletionRequest(
        requestId: 'req_f1_comp',
        learnerId: learnerId,
        examId: examId,
        activityId: 'act_f1',
        activityType: LearningDecisionType.advancement,
        planId: plan.planId,
        planRevision: plan.decision.authoritativeStateRevision,
        executionState: sessionState,
        completedAt: baseDate.add(const Duration(seconds: 50)),
      );

      final compResult =
          await completionService.completeActivity(completionRequest);

      // 6. Verify P43 outcome and P36 consolidation
      expect(
          compResult.status, equals(LearningActivityCompletionStatus.success));
      expect(compResult.isSuccess, isTrue);
      expect(compResult.outcome, isNotNull);
      expect(compResult.outcome?.questionsPresented, equals(3));
      expect(compResult.outcome?.questionsAttempted, equals(3));
      expect(compResult.outcome?.correctAnswers, equals(3));
      expect(compResult.outcome?.score, equals(1.0));
      expect(compResult.outcome?.accuracy, equals(1.0));

      expect(compResult.consolidatedOutcome, isNotNull);
      expect(compResult.consolidatedOutcome?.totalQuestions, equals(3));
      expect(compResult.consolidatedOutcome?.correctCount, equals(3));
      expect(
          compResult.consolidatedOutcome?.topicEvidence
              .containsKey('Fundamental Rights'),
          isTrue);

      expect(compResult.evidence, isNotNull);
      expect(compResult.evidence?.questionEvidence.length, equals(3));
      expect(compResult.auditTrail.allStepsSuccessful, isTrue);
    });

    test('Flow 2: P42 -> complete -> P36 -> P38 -> P39 persistence', () async {
      const learnerId = 'learner_flow2';
      const examId = 'upsc';
      const objId = 'lo_const_01';

      final questions = List<NormalizedQuestion>.generate(
        3,
        (i) => buildQuestion(id: 'q_f2_$i', examId: examId, objectiveId: objId),
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: learnerId,
        examId: examId,
        createdAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final plan = LearningContinuationPlan(
        planId: 'plan_f2',
        decision: AdaptiveLearningDecision(
          decisionId: 'dec_f2',
          learnerId: learnerId,
          examId: examId,
          type: LearningDecisionType.advancement,
          priority: LearningDecisionPriority.medium,
          reason: 'Advance',
          target: LearningTarget.objective(
            objectiveId: objId,
            type: LearningTargetType.curriculumObjective,
            topic: 'Fundamental Rights',
            subject: 'Polity',
          ),
          evidence: LearningDecisionEvidence(authoritativeStateRevision: 1),
          authoritativeStateRevision: 1,
          decidedAt: baseDate,
        ),
        createdAt: baseDate,
      );

      final execResult = await planExecutor.execute(
        LearningActivityExecutionRequest(
          requestId: 'req_f2_exec',
          learnerId: learnerId,
          examId: examId,
          plan: plan,
          currentState: state,
          corpus: questions,
          requestedAt: baseDate,
        ),
      );

      var sessionState = execResult.executionState!;
      for (int i = 0; i < 3; i++) {
        sessionState = execEngine
            .submitAnswer(
              state: sessionState,
              questionId: 'q_f2_$i',
              answer: 'A',
              submittedAt: baseDate.add(Duration(seconds: (i + 1) * 10)),
            )
            .valueOrThrow;
      }

      final compResult = await completionService.completeActivity(
        LearningActivityCompletionRequest(
          requestId: 'req_f2_comp',
          learnerId: learnerId,
          examId: examId,
          activityId: 'act_f2',
          activityType: LearningDecisionType.advancement,
          planId: plan.planId,
          planRevision: plan.decision.authoritativeStateRevision,
          executionState: sessionState,
          completedAt: baseDate.add(const Duration(seconds: 40)),
        ),
      );

      expect(
          compResult.status, equals(LearningActivityCompletionStatus.success));
      expect(compResult.hasStateAdvanced, isTrue);

      // Verify P39 persistence
      final persisted =
          await authRepo.load(learnerId: learnerId, examId: examId);
      expect(persisted, isNotNull);
      expect(persisted!.revision, equals(2));
      expect(persisted.progressMap[objId]!.attemptCount, equals(3));
      expect(persisted.progressMap[objId]!.correctCount, equals(3));
    });

    test(
        'Flow 3: Persisted state -> restart/recovery -> duplicate completion -> no double counting',
        () async {
      const learnerId = 'learner_flow3';
      const examId = 'upsc';
      const objId = 'lo_const_01';

      final questions = List<NormalizedQuestion>.generate(
        2,
        (i) => buildQuestion(id: 'q_f3_$i', examId: examId, objectiveId: objId),
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: learnerId,
        examId: examId,
        createdAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final plan = LearningContinuationPlan(
        planId: 'plan_f3',
        decision: AdaptiveLearningDecision(
          decisionId: 'dec_f3',
          learnerId: learnerId,
          examId: examId,
          type: LearningDecisionType.advancement,
          priority: LearningDecisionPriority.medium,
          reason: 'Advance',
          target: LearningTarget.objective(
            objectiveId: objId,
            type: LearningTargetType.curriculumObjective,
            topic: 'Fundamental Rights',
            subject: 'Polity',
          ),
          evidence: LearningDecisionEvidence(authoritativeStateRevision: 1),
          authoritativeStateRevision: 1,
          decidedAt: baseDate,
        ),
        createdAt: baseDate,
      );

      final execResult = await planExecutor.execute(
        LearningActivityExecutionRequest(
          requestId: 'req_f3_exec',
          learnerId: learnerId,
          examId: examId,
          plan: plan,
          currentState: state,
          corpus: questions,
          requestedAt: baseDate,
        ),
      );

      var sessionState = execResult.executionState!;
      sessionState = execEngine
          .submitAnswer(
            state: sessionState,
            questionId: 'q_f3_0',
            answer: 'A',
            submittedAt: baseDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;
      sessionState = execEngine
          .submitAnswer(
            state: sessionState,
            questionId: 'q_f3_1',
            answer: 'A',
            submittedAt: baseDate.add(const Duration(seconds: 20)),
          )
          .valueOrThrow;

      final completionRequest = LearningActivityCompletionRequest(
        requestId: 'req_f3_comp',
        learnerId: learnerId,
        examId: examId,
        activityId: 'act_f3',
        activityType: LearningDecisionType.advancement,
        planId: plan.planId,
        planRevision: plan.decision.authoritativeStateRevision,
        executionState: sessionState,
        completedAt: baseDate.add(const Duration(seconds: 25)),
      );

      // 1. Initial completion succeeds
      final firstComp =
          await completionService.completeActivity(completionRequest);
      expect(
          firstComp.status, equals(LearningActivityCompletionStatus.success));
      expect(firstComp.hasStateAdvanced, isTrue);

      final stateAfterFirst =
          (await authRepo.load(learnerId: learnerId, examId: examId))!;
      expect(stateAfterFirst.revision, equals(2));
      expect(stateAfterFirst.progressMap[objId]!.attemptCount, equals(2));

      // 2. Simulate service restart with new service instance sharing same repositories
      final restartedService = LearningActivityCompletionService(
        stateRepository: authRepo,
        recoveryService: authRecoveryService,
        reconciliationPipeline: pipeline,
        consolidator: consolidator,
        completionRepository: completionRepo,
      );

      // 3. Duplicate completion attempt
      final duplicateComp =
          await restartedService.completeActivity(completionRequest);

      // 4. Recognized as already completed!
      expect(duplicateComp.status,
          equals(LearningActivityCompletionStatus.alreadyCompleted));
      expect(duplicateComp.isSuccess, isTrue);
      expect(duplicateComp.isAlreadyCompleted, isTrue);
      expect(duplicateComp.hasStateAdvanced, isFalse);

      // 5. Authoritative state remains completely untouched (NO DOUBLE COUNTING)
      final stateAfterDuplicate =
          (await authRepo.load(learnerId: learnerId, examId: examId))!;
      expect(stateAfterDuplicate.revision, equals(2));
      expect(stateAfterDuplicate.progressMap[objId]!.attemptCount, equals(2));
      expect(stateAfterDuplicate.progressMap[objId]!.correctCount, equals(2));
    });

    test(
        'Flow 4: P41 -> P42 -> P43 -> P36 -> P38/P39 -> Next P41 Decision Loop',
        () async {
      const learnerId = 'learner_flow4_loop';
      const examId = 'upsc';
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final firstObjId = framework.allObjectives.first.id;
      final targetTopic = framework.allUnits
          .firstWhere((u) => u.objectives.any((o) => o.id == firstObjId))
          .title;

      final questions = List<NormalizedQuestion>.generate(
        5,
        (i) => buildQuestion(
          id: 'q_f4_$i',
          examId: examId,
          subject: framework.title,
          topic: targetTopic,
          objectiveId: firstObjId,
        ),
      );

      // 1. Cold start state (Rev 1)
      final coldStart = await authRecoveryService.recover(
        learnerId: learnerId,
        examId: examId,
        requestedAt: baseDate,
      );
      var currentAuthState = coldStart.state!;
      expect(currentAuthState.revision, equals(1));

      // 2. P41 Decision Engine formulates advancement plan
      final plan = decisionEngine.evaluateAndPlan(
        authoritativeState: currentAuthState,
        framework: framework,
        asOfDate: baseDate,
      );
      expect(plan.decision.type, equals(LearningDecisionType.advancement));
      expect(plan.target.objectiveId, equals(firstObjId));

      // 3. P42 Plan Executor starts session
      final execResult = await planExecutor.execute(
        LearningActivityExecutionRequest(
          requestId: 'req_f4_exec',
          learnerId: learnerId,
          examId: examId,
          plan: plan,
          currentState: currentAuthState,
          corpus: questions,
          requestedAt: baseDate,
        ),
      );
      expect(
          execResult.status, equals(LearningActivityExecutionStatus.success));

      // 4. Learner answers all 5 questions correctly
      var sessionState = execResult.executionState!;
      for (int i = 0; i < 5; i++) {
        sessionState = execEngine
            .submitAnswer(
              state: sessionState,
              questionId: 'q_f4_$i',
              answer: 'A',
              submittedAt: baseDate.add(Duration(seconds: (i + 1) * 20)),
            )
            .valueOrThrow;
      }
      expect(sessionState.status, equals(PracticeExecutionStatus.completed));

      // 5. P43 Activity Completion -> Normalizes -> Consolidates -> Reconciles
      final compResult = await completionService.completeActivity(
        LearningActivityCompletionRequest(
          requestId: 'req_f4_comp',
          learnerId: learnerId,
          examId: examId,
          activityId: 'act_f4',
          activityType: plan.decision.type,
          planId: plan.planId,
          planRevision: plan.decision.authoritativeStateRevision,
          executionState: sessionState,
          completedAt: baseDate.add(const Duration(minutes: 2)),
        ),
      );

      expect(
          compResult.status, equals(LearningActivityCompletionStatus.success));
      expect(compResult.hasStateAdvanced, isTrue);

      currentAuthState = compResult.resultingAuthoritativeState!;
      expect(currentAuthState.revision, equals(2));
      expect(currentAuthState.progressMap[firstObjId]!.attemptCount, equals(5));
      expect(currentAuthState.progressMap[firstObjId]!.correctCount, equals(5));
      expect(currentAuthState.progressMap[firstObjId]!.isAchieved, isTrue);

      // 6. Verify earlier plan is now stale
      expect(plan.isStale(currentAuthState), isTrue);

      // 7. Next P41 Decision Loop with updated state!
      final nextPlan = decisionEngine.evaluateAndPlan(
        authoritativeState: currentAuthState,
        framework: framework,
        asOfDate: baseDate.add(const Duration(minutes: 3)),
      );

      // Evaluates next unachieved objective in curriculum
      expect(nextPlan.decision.type, equals(LearningDecisionType.advancement));
      expect(nextPlan.target.objectiveId, isNot(equals(firstObjId)));
      expect(nextPlan.decision.authoritativeStateRevision, equals(2));
    });

    test('Flow 5: Stale P42 plan -> P43 completion rejected', () async {
      const learnerId = 'learner_flow5_stale';
      const examId = 'upsc';

      // State is at revision 3
      final state = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: const {},
        lastUpdatedAt: baseDate,
        revision: 3,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final request = LearningActivityCompletionRequest(
        requestId: 'req_f5_stale',
        learnerId: learnerId,
        examId: examId,
        activityId: 'act_f5',
        activityType: LearningDecisionType.complete,
        planId: 'plan_f5_rev1',
        planRevision: 1, // Stale! Current is 3
        completedAt: baseDate,
      );

      final result = await completionService.completeActivity(request);
      expect(result.status, equals(LearningActivityCompletionStatus.stalePlan));
      expect(result.error?.code, equals(ActivityCompletionErrorCode.stalePlan));
      expect(result.hasStateAdvanced, isFalse);
    });

    test(
        'Flow 6: Remediation activity -> completion -> remediation evidence preserved',
        () async {
      const learnerId = 'learner_flow6_remed';
      const examId = 'upsc';
      const weakObjId = 'lo_weak_01';

      final questions = List<NormalizedQuestion>.generate(
        3,
        (i) => buildQuestion(
            id: 'q_f6_$i', examId: examId, objectiveId: weakObjId),
      );

      // State with material weakness at revision 1
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
        revision: 1,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final remedialLesson = RemedialLesson(
        lessonId: 'rem_lesson_p43',
        objectiveId: weakObjId,
        title: 'Remedial Law',
        summary: 'Summary',
        learningPoints: const ['Point 1'],
        explanation: 'Detailed explanation',
        examples: const ['Example 1'],
        misconceptions: const ['Misconception 1'],
        sourceReferences: const [],
        contentOrigin: ContentOrigin.pedagogicalExplanation,
        estimatedMinutes: 15,
        bloomLevel: BloomTaxonomyLevel.understand,
        authoredAt: baseDate,
      );

      // P41 formulates remediation plan
      final plan = decisionEngine.evaluateAndPlan(
        authoritativeState: state,
        availableRemedialLessons: [remedialLesson],
        asOfDate: baseDate,
      );
      expect(plan.decision.type, equals(LearningDecisionType.remediation));
      expect(plan.remedialLesson?.lessonId, equals('rem_lesson_p43'));

      // P42 starts remedial session
      final execResult = await planExecutor.execute(
        LearningActivityExecutionRequest(
          requestId: 'req_f6_exec',
          learnerId: learnerId,
          examId: examId,
          plan: plan,
          currentState: state,
          corpus: questions,
          requestedAt: baseDate,
        ),
      );
      expect(
          execResult.status, equals(LearningActivityExecutionStatus.success));

      var sessionState = execResult.executionState!;
      for (int i = 0; i < 3; i++) {
        sessionState = execEngine
            .submitAnswer(
              state: sessionState,
              questionId: 'q_f6_$i',
              answer: 'A',
              submittedAt: baseDate.add(Duration(seconds: (i + 1) * 15)),
            )
            .valueOrThrow;
      }

      // P43 completes remediation activity
      final compResult = await completionService.completeActivity(
        LearningActivityCompletionRequest(
          requestId: 'req_f6_comp',
          learnerId: learnerId,
          examId: examId,
          activityId: 'act_f6_remed',
          activityType: LearningDecisionType.remediation,
          planId: plan.planId,
          planRevision: plan.decision.authoritativeStateRevision,
          executionState: sessionState,
          remedialLessonId: remedialLesson.lessonId,
          remedialLessonCompleted: true,
          completedAt: baseDate.add(const Duration(minutes: 2)),
        ),
      );

      expect(
          compResult.status, equals(LearningActivityCompletionStatus.success));
      expect(compResult.outcome?.activityType,
          equals(LearningDecisionType.remediation));
      expect(compResult.outcome?.remedialEvidence?['remedialLessonId'],
          equals('rem_lesson_p43'));
      expect(compResult.outcome?.remedialEvidence?['isCompleted'], isTrue);
      expect(compResult.evidence?.remedialLessonId, equals('rem_lesson_p43'));
      expect(compResult.evidence?.remedialLessonCompleted, isTrue);
      expect(compResult.hasStateAdvanced, isTrue);
    });

    test(
        'Flow 7: Continuation activity -> completion -> resumed session outcome preserved',
        () async {
      const learnerId = 'learner_flow7_cont';
      const examId = 'upsc';
      const objId = 'lo_const_01';

      final questions = List<NormalizedQuestion>.generate(
        4,
        (i) => buildQuestion(id: 'q_f7_$i', examId: examId, objectiveId: objId),
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: learnerId,
        examId: examId,
        createdAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      // Orchestrate and start session
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
        requestedCount: 4,
        eligibleCount: 4,
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

      final initialStep = await coordinator.startSession(
        spec: spec,
        baseState: state,
        startedAt: baseDate,
      );

      // Answer Q0 and Q1
      final step0 = await coordinator.submitAnswerAndCheckpoint(
        executionState: initialStep.executionState,
        baseState: initialStep.authoritativeState,
        currentCheckpoint: initialStep.checkpoint,
        questionId: 'q_f7_0',
        answer: 'A',
        submittedAt: baseDate.add(const Duration(seconds: 10)),
      );

      final step1 = await coordinator.submitAnswerAndCheckpoint(
        executionState: step0.executionState,
        baseState: step0.authoritativeState,
        currentCheckpoint: step0.checkpoint,
        questionId: 'q_f7_1',
        answer: 'A',
        submittedAt: baseDate.add(const Duration(seconds: 20)),
      );

      final activeCheckpoint = step1.checkpoint;
      final currentAuthState = step1.authoritativeState;
      expect(activeCheckpoint.questionIndex, equals(2));

      // P41 formulates continuation plan
      final contPlan = decisionEngine.evaluateAndPlan(
        authoritativeState: currentAuthState,
        activeCheckpoint: activeCheckpoint,
        asOfDate: baseDate.add(const Duration(seconds: 25)),
      );
      expect(contPlan.decision.type, equals(LearningDecisionType.continuation));

      // P42 resumes session at cursor 2
      final resumeExecResult = await planExecutor.execute(
        LearningActivityExecutionRequest(
          requestId: 'req_f7_resume',
          learnerId: learnerId,
          examId: examId,
          plan: contPlan,
          currentState: currentAuthState,
          existingSessionSpec: spec,
          activeCheckpoint: activeCheckpoint,
          requestedAt: baseDate.add(const Duration(seconds: 30)),
        ),
      );
      expect(resumeExecResult.status,
          equals(LearningActivityExecutionStatus.resumed));

      // Answer remaining Q2 and Q3 in resumed session
      var resumedState = resumeExecResult.executionState!;
      resumedState = execEngine
          .submitAnswer(
            state: resumedState,
            questionId: 'q_f7_2',
            answer: 'A',
            submittedAt: baseDate.add(const Duration(seconds: 40)),
          )
          .valueOrThrow;

      resumedState = execEngine
          .submitAnswer(
            state: resumedState,
            questionId: 'q_f7_3',
            answer: 'A',
            submittedAt: baseDate.add(const Duration(seconds: 50)),
          )
          .valueOrThrow;
      expect(resumedState.status, equals(PracticeExecutionStatus.completed));

      // P43 completes continuation activity
      final compResult = await completionService.completeActivity(
        LearningActivityCompletionRequest(
          requestId: 'req_f7_comp',
          learnerId: learnerId,
          examId: examId,
          activityId: 'act_f7_continuation',
          activityType: LearningDecisionType.continuation,
          planId: contPlan.planId,
          planRevision: contPlan.decision.authoritativeStateRevision,
          executionState: resumedState,
          completedAt: baseDate.add(const Duration(seconds: 60)),
        ),
      );

      expect(
          compResult.status, equals(LearningActivityCompletionStatus.success));
      expect(compResult.outcome?.activityType,
          equals(LearningDecisionType.continuation));
      expect(compResult.outcome?.questionsPresented, equals(4));
      expect(compResult.outcome?.questionsAttempted, equals(4));
      expect(compResult.outcome?.correctAnswers, equals(4));
      expect(compResult.outcome?.score, equals(1.0));
      expect(compResult.outcome?.accuracy, equals(1.0));
    });
  });
}
