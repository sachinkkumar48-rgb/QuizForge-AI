/// P40 End-to-End Learner Workflow Integration Test (TITAN-KO-040.0 P40).
///
/// Exercises the complete, unbroken learner journey:
/// Content / Exam Selection -> Goal / Topic -> Practice Session -> Question Presented
/// -> Answer Submission -> Deduplication -> Outcome Consolidation -> State Reconciliation
/// -> Authoritative Persistence -> Recovery across Restarts -> Progress Surface.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P40 End-to-End Learner Workflow Integration Tests', () {
    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late AdaptiveLearningStateReconciliationPipeline reconciliationPipeline;
    late AdaptiveLearningJourneyOrchestrator orchestrator;
    late AdaptiveLearningJourneyController controller;
    late List<NormalizedQuestion> sampleCorpus;

    NormalizedQuestion makeQuestion({
      required String id,
      required String correctOption,
      String topic = 'Fundamental Rights',
      String difficulty = 'Medium',
      String objectiveId = 'lo_polity_fr_01',
    }) {
      return NormalizedQuestion(
        id: id,
        examId: 'upsc_prelims_gs1',
        year: 2024,
        paper: 'GS1',
        subject: 'Indian Polity',
        topic: topic,
        normalizedText: 'Question text for $id on $topic',
        originalText: 'Original text for $id',
        options: [
          Option(
              key: 'A',
              text: 'Option A for $id',
              isCorrect: correctOption == 'A'),
          Option(
              key: 'B',
              text: 'Option B for $id',
              isCorrect: correctOption == 'B'),
          Option(
              key: 'C',
              text: 'Option C for $id',
              isCorrect: correctOption == 'C'),
          Option(
              key: 'D',
              text: 'Option D for $id',
              isCorrect: correctOption == 'D'),
        ],
        officialAnswer: Answer(
          correctOptionKeys: [correctOption],
          officialAnswerSource: 'UPSC Answer Key',
        ),
        explanation: 'Detailed explanation for $id',
        difficulty: difficulty,
        source: PyqSourceReference.official(
          examId: 'upsc_prelims_gs1',
          year: 2024,
          paper: 'GS1',
        ),
        objectiveIds: [objectiveId],
      );
    }

    setUp(() {
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      checkpointRepo = InMemorySessionCheckpointRepository();
      authRecoveryService =
          AuthoritativeLearningStateRecoveryService(repository: authRepo);
      sessionRecoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );
      reconciliationPipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: authRepo,
        recoveryService: authRecoveryService,
        reconciler: const AdaptiveLearningStateReconciler(),
        proposer: const LearningStateUpdateProposer(),
        consolidator: const PracticeOutcomeConsolidator(),
      );
      orchestrator = AdaptiveLearningJourneyOrchestrator(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        reconciliationPipeline: reconciliationPipeline,
      );
      controller =
          AdaptiveLearningJourneyController(orchestrator: orchestrator);

      sampleCorpus = [
        makeQuestion(
            id: 'q_polity_01', correctOption: 'A', topic: 'Fundamental Rights'),
        makeQuestion(
            id: 'q_polity_02', correctOption: 'B', topic: 'Fundamental Rights'),
        makeQuestion(
            id: 'q_polity_03',
            correctOption: 'C',
            topic: 'Directive Principles'),
      ];
    });

    test(
        'A. Session starts successfully: creates session with valid spec and cursor at 0',
        () async {
      final success = await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        targetObjectiveId: 'lo_polity_fr_01',
        questionCount: 3,
      );

      expect(success, isTrue);
      expect(controller.session, isNotNull);
      expect(
          controller.status, equals(LearningJourneyStatus.questionPresented));
      expect(controller.currentQuestionIndex, equals(0));
      expect(controller.totalQuestions, equals(3));
      expect(controller.completedCount, equals(0));
      expect(controller.session!.authoritativeState.revision, equals(1));
    });

    test(
        'B. Question is presented: stem, options, and submission availability are verified',
        () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      final question = controller.currentQuestion;
      expect(question, isNotNull);
      expect(question!.normalizedText, contains('q_polity_01'));
      expect(question.options.length, equals(4));
      expect(controller.canSubmitAnswer, isTrue);
    });

    test(
        'C. Learner submits an answer: attempt is recorded and feedback is generated',
        () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      final q = controller.currentQuestion!;
      final correctKey = q.officialAnswer.correctOptionKeys.first;

      final result = await controller.submitAnswer(answer: correctKey);

      expect(result, isTrue);
      expect(controller.lastAnswerResult, isNotNull);
      expect(controller.lastAnswerResult!.isCorrect, isTrue);
      expect(controller.lastAnswerResult!.submittedAnswer, equals(correctKey));
      expect(controller.completedCount, equals(1));
    });

    test(
        'D. Duplicate answer submission is prevented: prevents double answering same question',
        () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      final q = controller.currentQuestion!;
      await controller.submitAnswer(answer: 'A');

      // Attempt duplicate submission using underlying orchestrator directly on answered question
      final duplicateResult = await orchestrator.submitAnswer(
        session: controller.session!,
        questionId: q.id,
        answer: 'B',
      );

      expect(duplicateResult.isFailure, isTrue);
    });

    test(
        'E. Next question is reached: cursor advances and progress percentage updates',
        () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      expect(controller.currentQuestionIndex, equals(0));
      expect(controller.progressPercentage, equals(0.0));

      await controller.submitAnswer(answer: 'A');

      expect(controller.currentQuestionIndex, equals(1));
      expect(controller.currentQuestion!.id, equals('q_polity_02'));
      expect(controller.progressPercentage, equals(0.5));
    });

    test(
        'F. Session completion occurs: transitions to completed when last question is answered',
        () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      // Answer Q1
      await controller.submitAnswer(answer: 'A');
      expect(controller.isCompleted, isFalse);

      // Answer Q2 (final)
      await controller.submitAnswer(answer: 'B');
      expect(controller.isCompleted, isTrue);
      expect(controller.status, equals(LearningJourneyStatus.completed));
      expect(controller.completedCount, equals(2));
      expect(controller.progressPercentage, equals(1.0));
    });

    test(
        'G. Outcome consolidation is triggered: question results are consolidated in execution state',
        () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      await controller.submitAnswer(answer: 'A'); // Correct
      await controller.submitAnswer(answer: 'D'); // Incorrect

      final results = controller.session!.executionState.questionResults;
      expect(results.length, equals(2));
      expect(results['q_polity_01']!.isCorrect, isTrue);
      expect(results['q_polity_02']!.isCorrect, isFalse);
    });

    test(
        'H. Learner state reconciliation is triggered: monotonic revisions advance with each attempt',
        () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      expect(controller.session!.authoritativeState.revision, equals(1));

      await controller.submitAnswer(answer: 'A');
      expect(controller.session!.authoritativeState.revision, equals(2));

      await controller.submitAnswer(answer: 'B');
      expect(controller.session!.authoritativeState.revision, equals(3));
    });

    test(
        'I. Authoritative state is persisted: state is committed to authoritative repository',
        () async {
      const learnerId = 'learner_persist_check';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 2,
      );

      await controller.submitAnswer(answer: 'A');

      final loadedState =
          await authRepo.load(learnerId: learnerId, examId: examId);
      expect(loadedState, isNotNull);
      expect(loadedState!.learnerId, equals(learnerId));
      expect(loadedState.examId, equals(examId));
      expect(loadedState.revision, equals(2));
      expect(loadedState.progressMap.isNotEmpty, isTrue);
    });

    test(
        'J. Persisted state can be recovered: recovery service reconstructs valid session & state',
        () async {
      const learnerId = 'learner_recovery_01';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 3,
      );

      final sessionId = controller.session!.sessionId;
      await controller.submitAnswer(
          answer: 'A'); // Reconciled & checkpointed at cursor 1

      // Interruption / app restart
      controller.interruptJourney(reason: 'simulated_app_exit');

      // Recover via orchestrator
      final recoveryResult = await orchestrator.recoverAndResumeJourney(
        learnerId: learnerId,
        examId: examId,
        sessionId: sessionId,
        corpus: sampleCorpus,
      );

      expect(recoveryResult.isSuccess, isTrue);
      expect(recoveryResult.session!.currentQuestionIndex, equals(1));
      expect(recoveryResult.session!.completedQuestionIds,
          contains('q_polity_01'));
      expect(recoveryResult.session!.authoritativeState.revision, equals(2));
    });

    test(
        'K. Recovered learner can continue: can submit next question from checkpoint cursor',
        () async {
      const learnerId = 'learner_continue_01';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 3,
      );

      final sessionId = controller.session!.sessionId;
      await controller.submitAnswer(answer: 'A');

      // Recreate a new controller (simulating fresh page initialization after resume)
      final resumedController =
          AdaptiveLearningJourneyController(orchestrator: orchestrator);
      final resumed = await resumedController.resumeJourney(
        learnerId: learnerId,
        examId: examId,
        sessionId: sessionId,
        corpus: sampleCorpus,
      );

      expect(resumed, isTrue);
      expect(resumedController.currentQuestionIndex, equals(1));
      expect(resumedController.currentQuestion!.id, equals('q_polity_02'));

      // Learner continues and answers question 2
      final continuedSubmit = await resumedController.submitAnswer(answer: 'B');
      expect(continuedSubmit, isTrue);
      expect(resumedController.currentQuestionIndex, equals(2));
      expect(resumedController.session!.authoritativeState.revision, equals(3));
    });

    test(
        'L. Empty/invalid question set is handled: returns error gracefully rather than throwing',
        () async {
      final res = await controller.startJourney(
        learnerId: 'empty_candidate',
        examId: 'upsc_prelims_gs1',
        corpus: const [],
        questionCount: 5,
      );

      expect(res, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.lastErrorCode,
          equals(LearningJourneyErrorCode.emptyCorpus));
      expect(controller.status, equals(LearningJourneyStatus.created));
    });

    test(
        'M. Service failure produces a usable error state: persistence error is handled safely',
        () async {
      final startRes = await controller.startJourney(
        learnerId: 'fail_candidate',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );
      expect(startRes, isTrue);

      // Arm persistence failure
      authRepo.failNextSave = true;

      // Reconciling state surfaces failure without throwing unhandled exceptions
      final pipelineResult =
          await reconciliationPipeline.reconcileExecutionState(
        baseState: controller.session!.authoritativeState,
        executionState: controller.session!.executionState,
      );

      expect(pipelineResult.isSuccess, isFalse);
      expect(pipelineResult.persistenceError, isNotNull);
      expect(pipelineResult.baseState.revision, equals(1));
    });

    test(
        'N. Progress surface reflects real state: metrics align with underlying authoritative progress',
        () async {
      const learnerId = 'learner_metrics_01';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 2,
      );

      await controller.submitAnswer(answer: 'A'); // Correct
      await controller.submitAnswer(answer: 'C'); // Incorrect (expected B)

      expect(controller.totalQuestions, equals(2));
      expect(controller.completedCount, equals(2));
      expect(controller.progressPercentage, equals(1.0));
      expect(controller.session!.authoritativeState.revision, equals(3));

      // Authoritative progress map contains real updated progress
      final progressMap = controller.session!.authoritativeState.progressMap;
      expect(progressMap.isNotEmpty, isTrue);
      final frProgress = progressMap['lo_polity_fr_01'];
      expect(frProgress, isNotNull);
      expect(frProgress!.attemptCount, greaterThanOrEqualTo(2));
      expect(frProgress.correctCount, greaterThanOrEqualTo(1));
    });
  });
}
