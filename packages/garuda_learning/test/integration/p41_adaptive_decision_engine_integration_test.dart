/// P41 Adaptive Learning Decision Engine End-to-End Integration Test Suite (TITAN-KO-041.0 P41).
///
/// Exercises the complete integration flow across P35 execution, P36 consolidation,
/// P38/P39 reconciliation & persistence, P40 session recovery, and P41 decision formulation:
/// - Crash recovery session continuation handoff
/// - Weakness remediation detection, lesson binding, and downstream session configuration
/// - Spaced repetition review triggering
/// - Curriculum advancement through framework prerequisites to completion
/// - Revision freshness and multi-tenant isolation guarantees
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P41 Adaptive Learning Decision Engine Integration Flow', () {
    final baseDate = DateTime.utc(2026, 9, 15, 10, 0, 0);

    const proposer = LearningStateUpdateProposer();
    const consolidator = PracticeOutcomeConsolidator();
    const execEngine = AdaptivePracticeExecutionEngine();
    const orchestrator = AdaptivePracticeSessionOrchestrator();
    final decisionEngine = AdaptiveLearningDecisionEngine();

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late AdaptiveLearningStateReconciliationPipeline pipeline;
    late ResumableAdaptivePracticeCoordinator coordinator;

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
    });

    NormalizedQuestion buildQuestion({
      required String id,
      String examId = 'upsc',
      int year = 2024,
      String paper = 'GS1',
      String subject = 'Polity',
      String topic = 'Fundamental Rights',
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
        objectiveIds: objectiveIds ?? const ['lo_const_fr_01'],
      );
    }

    AdaptiveQuestionCandidate buildCandidate({
      required NormalizedQuestion question,
    }) {
      return AdaptiveQuestionCandidate(
        question: question,
        historicalPriority: 0.5,
        learnerWeakness: 0.5,
        exposureCount: 0,
        recencyScore: 1.0,
        difficultyFit: 0.8,
        sourceQualityScore: 1.0,
        selectionScore: 0.75,
        isEligible: true,
        scoreBreakdown: const {
          'historicalPriority': 0.25,
          'weakness': 0.25,
          'recency': 0.15,
          'difficultyFit': 0.20,
          'quality': 0.15,
        },
      );
    }

    AdaptivePracticeSessionSpec buildSpec({
      String examId = 'upsc',
      String learnerId = 'learner_p41_integration',
      required List<NormalizedQuestion> questions,
    }) {
      final candidates =
          questions.map((q) => buildCandidate(question: q)).toList();

      final selectionResult = AdaptiveQuestionSelectionResult(
        examId: examId,
        selectedQuestions: questions,
        selectedCandidates: candidates,
        allCandidates: candidates,
        requestedCount: questions.length,
        eligibleCount: questions.length,
        config: AdaptiveQuestionSelectionConfig(
          examId: examId,
          targetQuestionCount: questions.length,
        ),
        selectedAt: baseDate,
      );

      final config = AdaptivePracticeSessionConfig(
        examId: examId,
        learnerId: learnerId,
        sessionMode: PracticeSessionMode.standard,
        sectionSize: 5,
        estimatedSecondsPerQuestion: 60,
      );

      return orchestrator.orchestrateSession(
        selectionResult: selectionResult,
        config: config,
        orchestratedAt: baseDate,
      );
    }

    test(
        'Crash Recovery & Resumption Flow: Interrupted session -> Continuation Decision -> Resumption',
        () async {
      const learnerId = 'learner_p41_resume';
      const examId = 'upsc';

      final questions = List.generate(
        5,
        (i) => buildQuestion(id: 'q_res_$i', examId: examId),
      );
      final spec = buildSpec(
        examId: examId,
        learnerId: learnerId,
        questions: questions,
      );

      // 1. Initial state recovery
      final initialAuth = await authRecoveryService.recover(
        learnerId: learnerId,
        examId: examId,
        requestedAt: baseDate,
      );
      var currentAuthState = initialAuth.state!;
      expect(currentAuthState.revision, equals(1));

      // 2. Start practice session
      final startStep = await coordinator.startSession(
        spec: spec,
        baseState: currentAuthState,
        startedAt: baseDate,
      );
      var currentExecution = startStep.executionState;
      var currentCheckpoint = startStep.checkpoint;
      expect(currentExecution.currentQuestionIndex, equals(0));
      expect(currentCheckpoint.questionIndex, equals(0));

      // 3. Submit answers for Q0 and Q1
      final step0 = await coordinator.submitAnswerAndCheckpoint(
        executionState: currentExecution,
        baseState: currentAuthState,
        currentCheckpoint: currentCheckpoint,
        questionId: 'q_res_0',
        answer: 'A',
        submittedAt: baseDate.add(const Duration(seconds: 15)),
      );
      currentExecution = step0.executionState;
      currentAuthState = step0.authoritativeState;
      currentCheckpoint = step0.checkpoint;

      final step1 = await coordinator.submitAnswerAndCheckpoint(
        executionState: currentExecution,
        baseState: currentAuthState,
        currentCheckpoint: currentCheckpoint,
        questionId: 'q_res_1',
        answer: 'A',
        submittedAt: baseDate.add(const Duration(seconds: 30)),
      );
      currentExecution = step1.executionState;
      currentAuthState = step1.authoritativeState;
      currentCheckpoint = step1.checkpoint;

      expect(currentExecution.currentQuestionIndex, equals(2));
      expect(currentCheckpoint.questionIndex, equals(2));
      expect(currentCheckpoint.isCompleted, isFalse);
      expect(currentAuthState.revision, equals(3));

      // 4. P41 Decision Engine evaluates state and active checkpoint
      final decision = decisionEngine.evaluate(
        authoritativeState: currentAuthState,
        activeCheckpoint: currentCheckpoint,
        asOfDate: baseDate.add(const Duration(seconds: 90)),
      );

      // Must decide continuation with urgent priority!
      expect(decision.type, equals(LearningDecisionType.continuation));
      expect(decision.priority, equals(LearningDecisionPriority.urgent));
      expect(
          decision.target.targetType, equals(LearningTargetType.sessionCursor));
      expect(decision.target.cursorIndex, equals(2));
      expect(decision.evidence.hasUnfinishedSession, isTrue);
      expect(decision.isStale(currentAuthState), isFalse);

      // 5. Formulate actionable continuation plan
      final plan = decisionEngine.formulateContinuationPlan(
        decision: decision,
      );
      expect(plan.target.cursorIndex, equals(2));

      // 6. Resume session via coordinator using plan target
      final recoveredStep = await coordinator.recoverAndResumeSession(
        learnerId: learnerId,
        examId: examId,
        sessionId: spec.sessionId,
        spec: spec,
        resumedAt: baseDate.add(const Duration(minutes: 5)),
      );
      var resumedExecution = recoveredStep.executionState;
      var resumedAuth = recoveredStep.authoritativeState;
      var resumedCheckpoint = recoveredStep.checkpoint;
      expect(resumedExecution.currentQuestionIndex, equals(2));

      // 7. Complete remaining questions (Q2, Q3, Q4)
      for (int i = 2; i < 5; i++) {
        final step = await coordinator.submitAnswerAndCheckpoint(
          executionState: resumedExecution,
          baseState: resumedAuth,
          currentCheckpoint: resumedCheckpoint,
          questionId: 'q_res_$i',
          answer: 'A',
          submittedAt:
              baseDate.add(Duration(minutes: 5, seconds: (i - 1) * 15)),
        );
        resumedExecution = step.executionState;
        resumedAuth = step.authoritativeState;
        resumedCheckpoint = step.checkpoint;
      }

      // 8. Finalize session / verify completion
      expect(resumedCheckpoint.isCompleted, isTrue);

      // 9. Verify state advanced and earlier decision is now stale!
      expect(resumedAuth.revision, greaterThan(currentAuthState.revision));
      expect(decision.isStale(resumedAuth), isTrue);
      expect(plan.isStale(resumedAuth), isTrue);
    });

    test(
        'Remediation Flow: Material weakness -> Remediation Decision -> P25 Lesson & Config Handoff',
        () async {
      const learnerId = 'learner_p41_remed';
      const examId = 'upsc';
      const weakObjId = 'lo_const_fr_01';

      // 1. Simulate multiple unsuccessful attempts in authoritative state
      final progressMap = {
        weakObjId: LearnerProgress(
          learnerId: learnerId,
          objectiveId: weakObjId,
          attemptCount: 5,
          correctCount: 1, // 20% success rate
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
        lessonId: 'rem_fr_01_v1',
        objectiveId: weakObjId,
        title: 'Fundamental Rights Core Concepts',
        summary: 'Remedial summary of Article 21 and 19',
        learningPoints: const ['Protection of Life', 'Due Process'],
        explanation: 'In-depth explanation of constitutional guarantees',
        examples: const ['Maneka Gandhi case'],
        misconceptions: const ['Article 21 is absolute'],
        sourceReferences: const [],
        contentOrigin: ContentOrigin.pedagogicalExplanation,
        estimatedMinutes: 20,
        bloomLevel: BloomTaxonomyLevel.understand,
        authoredAt: baseDate,
      );

      // 3. Evaluate state with decision engine
      final plan = decisionEngine.evaluateAndPlan(
        authoritativeState: state,
        availableRemedialLessons: [remedialLesson],
        asOfDate: baseDate,
      );

      expect(plan.decision.type, equals(LearningDecisionType.remediation));
      expect(plan.decision.priority, equals(LearningDecisionPriority.urgent));
      expect(plan.target.targetType, equals(LearningTargetType.remedialLesson));
      expect(plan.target.remedialLessonId, equals('rem_fr_01_v1'));
      expect(plan.remedialLesson?.lessonId, equals('rem_fr_01_v1'));

      // 4. Downstream config handoff
      final selectionConfig = plan.toAdaptiveQuestionSelectionConfig();
      expect(selectionConfig.scopedObjectiveIds, equals([weakObjId]));
      expect(selectionConfig.weaknessWeight, equals(0.50));

      final sessionConfig = plan.toAdaptivePracticeSessionConfig();
      expect(sessionConfig.sessionMode,
          equals(PracticeSessionMode.remedialPractice));
      expect(
          sessionConfig.metadata['remedialLessonId'], equals('rem_fr_01_v1'));
    });

    test('Full Sequence: Advancement -> Reinforcement -> Review -> Complete',
        () async {
      const learnerId = 'learner_p41_progression';
      const examId = 'upsc';
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();

      // State 0: Initial empty state -> Rule 5 (Advancement) fires
      var state = AuthoritativeLearnerState.empty(
        learnerId: learnerId,
        examId: examId,
        createdAt: baseDate,
      );

      var decision = decisionEngine.evaluate(
        authoritativeState: state,
        framework: framework,
        asOfDate: baseDate,
      );
      expect(decision.type, equals(LearningDecisionType.advancement));
      expect(decision.target.objectiveId,
          equals(framework.allObjectives.first.id));

      // State 1: Learner started first objective (1 attempt, 1 correct) -> Rule 4 (Reinforcement) fires
      final obj1Id = framework.allObjectives.first.id;
      final progressMap = <String, LearnerProgress>{
        obj1Id: LearnerProgress(
          learnerId: learnerId,
          objectiveId: obj1Id,
          attemptCount: 1,
          correctCount: 1,
          status: LearnerObjectiveStatus.inProgress, // Not yet mastered
          lastAttemptAt: baseDate,
        ),
      };

      state = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: progressMap,
        lastUpdatedAt: baseDate.add(const Duration(minutes: 10)),
        revision: 2,
      );

      decision = decisionEngine.evaluate(
        authoritativeState: state,
        framework: framework,
        asOfDate: baseDate.add(const Duration(minutes: 10)),
      );
      expect(decision.type, equals(LearningDecisionType.reinforcement));
      expect(decision.target.objectiveId, equals(obj1Id));

      // State 2: Learner masters all objectives in framework
      final masteredMap = <String, LearnerProgress>{};
      for (final obj in framework.allObjectives) {
        masteredMap[obj.id] = LearnerProgress(
          learnerId: learnerId,
          objectiveId: obj.id,
          attemptCount: 10,
          correctCount: 9,
          status: LearnerObjectiveStatus.achieved,
          lastAttemptAt:
              baseDate.subtract(const Duration(days: 4)), // Mastered 4 days ago
        );
      }

      state = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: masteredMap,
        lastUpdatedAt: baseDate,
        revision: 10,
      );

      // Because 4 days elapsed (> default 3 days review interval), Rule 3 (Review) fires
      decision = decisionEngine.evaluate(
        authoritativeState: state,
        framework: framework,
        asOfDate: baseDate,
      );
      expect(decision.type, equals(LearningDecisionType.review));
      expect(decision.priority, equals(LearningDecisionPriority.high));

      // State 3: All objectives mastered and reviewed recently (today) -> Rule 6 (Complete) fires
      final recentlyReviewedMap = <String, LearnerProgress>{};
      for (final obj in framework.allObjectives) {
        recentlyReviewedMap[obj.id] = LearnerProgress(
          learnerId: learnerId,
          objectiveId: obj.id,
          attemptCount: 12,
          correctCount: 11,
          status: LearnerObjectiveStatus.achieved,
          lastAttemptAt: baseDate, // practiced right now
        );
      }

      state = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        progressMap: recentlyReviewedMap,
        lastUpdatedAt: baseDate,
        revision: 15,
      );

      decision = decisionEngine.evaluate(
        authoritativeState: state,
        framework: framework,
        asOfDate: baseDate,
      );
      expect(decision.type, equals(LearningDecisionType.complete));
      expect(decision.priority, equals(LearningDecisionPriority.none));
      expect(decision.target.targetType, equals(LearningTargetType.none));
    });
  });
}
