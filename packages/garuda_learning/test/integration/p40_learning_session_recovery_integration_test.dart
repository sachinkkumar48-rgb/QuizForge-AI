/// P40 Learning Session Recovery End-to-End Integration Test Suite (TITAN-KO-040.0 P40).
///
/// Exercises the complete offline crash-recovery lifecycle:
/// Start practice session -> Answer questions with reconciliation & checkpointing
/// -> Simulate application crash / memory wipe -> Recover session
/// -> Verify resumption at first uncompleted question -> Continue practice
/// -> Finalize session and verify revision monotonicity & idempotency.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P40 Learning Session Recovery End-to-End Integration Flow', () {
    final fixedDate = DateTime.utc(2026, 9, 15, 10, 0, 0);

    const proposer = LearningStateUpdateProposer();
    const consolidator = PracticeOutcomeConsolidator();
    const engine = AdaptivePracticeExecutionEngine();
    const orchestrator = AdaptivePracticeSessionOrchestrator();

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
        engine: engine,
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
        objectiveIds: objectiveIds ?? const ['obj_polity_fr'],
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
      String? learnerId = 'learner_e2e_p40',
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
        selectedAt: fixedDate,
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
        orchestratedAt: fixedDate,
      );
    }

    test(
        'Full End-to-End Lifecycle: Start -> Answer Q0..Q2 -> Crash -> Recover -> Resume Q3..Q4 -> Finalize',
        () async {
      const learnerId = 'learner_e2e_p40';
      const examId = 'upsc';

      // 1. Initial Cold Start: Authoritative learner state initialized at rev 1
      final coldStartAuth = await authRecoveryService.recover(
        learnerId: learnerId,
        examId: examId,
        requestedAt: fixedDate,
      );
      expect(coldStartAuth.decision,
          equals(AuthoritativeRecoveryDecision.initialized));
      var currentAuthState = coldStartAuth.state!;
      expect(currentAuthState.revision, equals(1));

      // 2. Build 5-question session specification
      final questions = List.generate(
        5,
        (i) => buildQuestion(
          id: 'q_p40_$i',
          objectiveIds: ['obj_polity_$i'],
        ),
      );
      final spec = buildSpec(
        learnerId: learnerId,
        examId: examId,
        questions: questions,
      );

      // 3. Start Session & Persist Initial Checkpoint (rev 1, cursor 0)
      final startStep = await coordinator.startSession(
        spec: spec,
        baseState: currentAuthState,
        startedAt: fixedDate,
      );
      var currentExecution = startStep.executionState;
      var currentCheckpoint = startStep.checkpoint;

      expect(
          currentExecution.status, equals(PracticeExecutionStatus.inProgress));
      expect(currentExecution.currentQuestionIndex, equals(0));
      expect(currentCheckpoint.checkpointRevision, equals(1));
      expect(currentCheckpoint.questionIndex, equals(0));

      // 4. Answer Question 0 (Correct)
      final step0 = await coordinator.submitAnswerAndCheckpoint(
        executionState: currentExecution,
        baseState: currentAuthState,
        currentCheckpoint: currentCheckpoint,
        questionId: 'q_p40_0',
        answer: 'A',
        submittedAt: fixedDate.add(const Duration(seconds: 15)),
      );
      currentExecution = step0.executionState;
      currentAuthState = step0.authoritativeState;
      currentCheckpoint = step0.checkpoint;

      expect(currentExecution.currentQuestionIndex, equals(1));
      expect(currentCheckpoint.questionIndex, equals(1));
      expect(currentCheckpoint.completedQuestionIds, equals(['q_p40_0']));
      expect(currentCheckpoint.checkpointRevision, equals(2));
      expect(currentAuthState.revision, equals(2));

      // 5. Answer Question 1 (Correct)
      final step1 = await coordinator.submitAnswerAndCheckpoint(
        executionState: currentExecution,
        baseState: currentAuthState,
        currentCheckpoint: currentCheckpoint,
        questionId: 'q_p40_1',
        answer: 'A',
        submittedAt: fixedDate.add(const Duration(seconds: 30)),
      );
      currentExecution = step1.executionState;
      currentAuthState = step1.authoritativeState;
      currentCheckpoint = step1.checkpoint;

      expect(currentExecution.currentQuestionIndex, equals(2));
      expect(currentCheckpoint.questionIndex, equals(2));
      expect(currentCheckpoint.completedQuestionIds,
          equals(['q_p40_0', 'q_p40_1']));
      expect(currentCheckpoint.checkpointRevision, equals(3));
      expect(currentAuthState.revision, equals(3));

      // 6. Answer Question 2 (Incorrect 'B')
      final step2 = await coordinator.submitAnswerAndCheckpoint(
        executionState: currentExecution,
        baseState: currentAuthState,
        currentCheckpoint: currentCheckpoint,
        questionId: 'q_p40_2',
        answer: 'B',
        submittedAt: fixedDate.add(const Duration(seconds: 45)),
      );
      currentExecution = step2.executionState;
      currentAuthState = step2.authoritativeState;
      currentCheckpoint = step2.checkpoint;

      expect(currentExecution.currentQuestionIndex, equals(3));
      expect(currentCheckpoint.questionIndex, equals(3));
      expect(currentCheckpoint.completedQuestionIds,
          equals(['q_p40_0', 'q_p40_1', 'q_p40_2']));
      expect(currentCheckpoint.checkpointRevision, equals(4));
      expect(currentAuthState.revision, equals(4));

      // =======================================================================
      // SIMULATE APPLICATION CRASH / MEMORY WIPE
      // All in-memory execution states and coordinator references are discarded.
      // Persistent storage (authRepo and checkpointRepo) remains durable.
      // =======================================================================

      // 7. Restart Application: Instantiate fresh coordinator & services
      final freshAuthRecovery = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );
      final freshSessionRecovery = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: freshAuthRecovery,
      );
      final freshPipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: authRepo,
        recoveryService: freshAuthRecovery,
        reconciler: const AdaptiveLearningStateReconciler(),
        proposer: proposer,
        consolidator: consolidator,
      );
      final freshCoordinator = ResumableAdaptivePracticeCoordinator(
        engine: engine,
        pipeline: freshPipeline,
        recoveryService: freshSessionRecovery,
      );

      // 8. Recover Interrupted Session
      final recoveredStep = await freshCoordinator.recoverAndResumeSession(
        learnerId: learnerId,
        examId: examId,
        sessionId: spec.sessionId,
        spec: spec,
        resumedAt: fixedDate.add(const Duration(minutes: 5)),
      );

      var resumedExecution = recoveredStep.executionState;
      var resumedAuth = recoveredStep.authoritativeState;
      var resumedCheckpoint = recoveredStep.checkpoint;

      // Assert that resumed state starts at Question 3 (cursor 3)
      expect(
          resumedExecution.status, equals(PracticeExecutionStatus.inProgress));
      expect(resumedExecution.currentQuestionIndex, equals(3));
      expect(resumedExecution.currentQuestionId, equals('q_p40_3'));

      // Assert that questions 0, 1, 2 are preserved as completed without re-presentation
      expect(resumedExecution.questionResults['q_p40_0']!.isAnswered, isTrue);
      expect(resumedExecution.questionResults['q_p40_1']!.isAnswered, isTrue);
      expect(resumedExecution.questionResults['q_p40_2']!.isAnswered, isTrue);
      expect(resumedExecution.questionResults['q_p40_3']!.isAnswered, isFalse);
      expect(resumedExecution.questionResults['q_p40_4']!.isAnswered, isFalse);

      // Assert authoritative learner state revision is preserved at 4
      expect(resumedAuth.revision, equals(4));
      expect(resumedCheckpoint.checkpointRevision, equals(4));

      // 9. Continue Learning: Answer Question 3 (Correct 'A')
      final step3 = await freshCoordinator.submitAnswerAndCheckpoint(
        executionState: resumedExecution,
        baseState: resumedAuth,
        currentCheckpoint: resumedCheckpoint,
        questionId: 'q_p40_3',
        answer: 'A',
        submittedAt: fixedDate.add(const Duration(minutes: 6)),
      );
      resumedExecution = step3.executionState;
      resumedAuth = step3.authoritativeState;
      resumedCheckpoint = step3.checkpoint;

      expect(resumedExecution.currentQuestionIndex, equals(4));
      expect(resumedExecution.currentQuestionId, equals('q_p40_4'));
      expect(resumedCheckpoint.checkpointRevision, equals(5));
      expect(resumedAuth.revision, equals(5));

      // 10. Answer Final Question 4 (Correct 'A')
      final step4 = await freshCoordinator.submitAnswerAndCheckpoint(
        executionState: resumedExecution,
        baseState: resumedAuth,
        currentCheckpoint: resumedCheckpoint,
        questionId: 'q_p40_4',
        answer: 'A',
        submittedAt: fixedDate.add(const Duration(minutes: 7)),
      );
      resumedExecution = step4.executionState;
      resumedAuth = step4.authoritativeState;
      resumedCheckpoint = step4.checkpoint;

      // 11. Final Session Verification
      expect(
          resumedExecution.status, equals(PracticeExecutionStatus.completed));
      expect(resumedExecution.isFinished, isTrue);
      expect(resumedCheckpoint.isCompleted, isTrue);
      expect(resumedCheckpoint.completedCount, equals(5));
      expect(resumedCheckpoint.checkpointRevision, equals(6));
      expect(resumedAuth.revision, equals(6));

      // 12. Post-Completion Recovery Guard: Attempting to recover completed session
      final completedRecovery = await freshSessionRecovery.recoverSession(
        learnerId: learnerId,
        examId: examId,
        sessionId: spec.sessionId,
      );
      expect(completedRecovery.isAlreadyCompleted, isTrue);
      expect(completedRecovery.session, isNull);
    });

    test('Multi-Tenant Session Checkpoint Isolation across Learners and Exams',
        () async {
      final specA = buildSpec(
        learnerId: 'learner_alpha',
        examId: 'upsc',
        questions: [buildQuestion(id: 'q_a1')],
      );
      final specB = buildSpec(
        learnerId: 'learner_beta',
        examId: 'upsc',
        questions: [buildQuestion(id: 'q_b1')],
      );

      final stateA = AuthoritativeLearnerState.empty(
        learnerId: 'learner_alpha',
        examId: 'upsc',
        createdAt: fixedDate,
      );
      final stateB = AuthoritativeLearnerState.empty(
        learnerId: 'learner_beta',
        examId: 'upsc',
        createdAt: fixedDate,
      );

      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateA));
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateB));

      await coordinator.startSession(spec: specA, baseState: stateA);
      await coordinator.startSession(spec: specB, baseState: stateB);

      // Verify each learner only recovers their own session
      final recA = await sessionRecoveryService.recoverSession(
        learnerId: 'learner_alpha',
        examId: 'upsc',
        sessionId: specA.sessionId,
      );
      final recB = await sessionRecoveryService.recoverSession(
        learnerId: 'learner_beta',
        examId: 'upsc',
        sessionId: specB.sessionId,
      );

      expect(recA.isSuccess, isTrue);
      expect(recA.session!.learnerId, equals('learner_alpha'));

      expect(recB.isSuccess, isTrue);
      expect(recB.session!.learnerId, equals('learner_beta'));

      // Cross-recovery attempt returns identity mismatch or cold-start
      final crossRecovery = await sessionRecoveryService.recoverSession(
        learnerId: 'learner_alpha',
        examId: 'upsc',
        sessionId: specB.sessionId,
      );
      expect(crossRecovery.isColdStart, isTrue);
    });
  });
}
