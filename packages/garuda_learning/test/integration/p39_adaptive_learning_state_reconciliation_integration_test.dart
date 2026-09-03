/// P39 Adaptive Learning State Reconciliation End-to-End Integration Test.
///
/// Exercises the complete offline flow specified in Phase 9:
/// practice evidence -> consolidated outcome -> learning-state proposal
/// -> P38 reconciliation -> P39 persistence -> reload -> verify authoritative state.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group(
      'P39 Adaptive Learning State Reconciliation Integration (Phase 9 Complete Flow)',
      () {
    final fixedDate = DateTime.utc(2026, 9, 10, 10, 0, 0);

    const proposer = LearningStateUpdateProposer();
    const consolidator = PracticeOutcomeConsolidator();
    const engine = AdaptivePracticeExecutionEngine();
    const orchestrator = AdaptivePracticeSessionOrchestrator();

    late InMemoryAuthoritativeLearningStateRepository repository;
    late AuthoritativeLearningStateRecoveryService recoveryService;
    late AdaptiveLearningStateReconciler reconciler;
    late AdaptiveLearningStateReconciliationPipeline pipeline;

    setUp(() {
      repository = InMemoryAuthoritativeLearningStateRepository();
      recoveryService = AuthoritativeLearningStateRecoveryService(
        repository: repository,
      );
      reconciler = const AdaptiveLearningStateReconciler();
      pipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: repository,
        recoveryService: recoveryService,
        reconciler: reconciler,
        proposer: proposer,
        consolidator: consolidator,
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
        originalText: 'Normalized question text for $id',
        options: const [
          Option(key: 'A', text: 'Option A', isCorrect: true),
          Option(key: 'B', text: 'Option B', isCorrect: false),
          Option(key: 'C', text: 'Option C', isCorrect: false),
          Option(key: 'D', text: 'Option D', isCorrect: false),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['A'],
          officialAnswerSource: 'Official Commission Key',
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
      String? learnerId = 'learner_e2e',
      required List<NormalizedQuestion> questions,
    }) {
      final candidates =
          questions.map((q) => buildCandidate(question: q)).toList();

      final selectionResult = AdaptiveQuestionSelectionResult(
        examId: examId,
        selectedQuestions: questions,
        selectedCandidates: candidates,
        allCandidates: candidates,
        requestedCount: questions.isEmpty ? 1 : questions.length,
        eligibleCount: questions.isEmpty ? 1 : questions.length,
        config: AdaptiveQuestionSelectionConfig(
          examId: examId,
          targetQuestionCount: questions.isEmpty ? 1 : questions.length,
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

    PracticeExecutionState buildExecution({
      required String examId,
      required String learnerId,
      required int correctCount,
      required int incorrectCount,
      List<String>? objectiveIds,
    }) {
      final total = correctCount + incorrectCount;
      final questions = List.generate(
        total,
        (i) => buildQuestion(
          id: 'q_$i',
          examId: examId,
          objectiveIds: objectiveIds ?? ['obj_unit_$i'],
        ),
      );
      final spec = buildSpec(
        examId: examId,
        learnerId: learnerId,
        questions: questions,
      );
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      int qIdx = 0;
      for (int i = 0; i < correctCount; i++, qIdx++) {
        state = engine
            .submitAnswer(
              state: state,
              questionId: 'q_$qIdx',
              answer: 'A',
              submittedAt: fixedDate.add(Duration(seconds: (qIdx + 1) * 10)),
            )
            .valueOrThrow;
      }
      for (int i = 0; i < incorrectCount; i++, qIdx++) {
        state = engine
            .submitAnswer(
              state: state,
              questionId: 'q_$qIdx',
              answer: 'B',
              submittedAt: fixedDate.add(Duration(seconds: (qIdx + 1) * 10)),
            )
            .valueOrThrow;
      }
      return state;
    }

    test(
        'Complete offline flow: practice execution -> outcome consolidation -> proposal -> reconciliation -> persistence -> reload verification',
        () async {
      // 1. Initial State Recovery (Case A — Cold start)
      final coldStart = await recoveryService.recover(
        learnerId: 'learner_e2e',
        examId: 'upsc',
        requestedAt: fixedDate,
        persistInitialIfAbsent: true,
      );
      expect(coldStart.isSuccess, isTrue);
      expect(coldStart.state!.revision, equals(1));
      expect(coldStart.state!.progressMap, isEmpty);

      // 2. Practice Execution State with real session execution
      final executionState1 = buildExecution(
        examId: 'upsc',
        learnerId: 'learner_e2e',
        correctCount: 2,
        incorrectCount: 1,
        objectiveIds: const ['obj_polity_preamble'],
      );

      // 3. Reconcile execution state through pipeline
      final pipelineResult1 = await pipeline.reconcileExecutionState(
        baseState: coldStart.state!,
        executionState: executionState1,
        expectedRevision: 1,
        timestamp: fixedDate.add(const Duration(minutes: 15)),
      );

      expect(pipelineResult1.isSuccess, isTrue);
      expect(pipelineResult1.previousRevision, equals(1));
      expect(pipelineResult1.resultingRevision, equals(2));
      expect(pipelineResult1.isIdempotentReplay, isFalse);

      final v2State = pipelineResult1.resultingState!;
      expect(v2State.revision, equals(2));
      expect(v2State.hasProcessedSession(executionState1.sessionId), isTrue);
      expect(v2State.progressMap.containsKey('obj_polity_preamble'), isTrue);
      expect(
        v2State.progressMap['obj_polity_preamble']!.attemptCount,
        equals(3),
      );
      expect(
        v2State.progressMap['obj_polity_preamble']!.correctCount,
        equals(2),
      );

      // 4. Simulate application restart: load directly from repository
      final restartRecovery = await recoveryService.recover(
        learnerId: 'learner_e2e',
        examId: 'upsc',
        requestedAt: fixedDate.add(const Duration(hours: 1)),
      );

      expect(restartRecovery.isSuccess, isTrue);
      expect(restartRecovery.decision,
          equals(AuthoritativeRecoveryDecision.restored));
      final reloadedState = restartRecovery.state!;
      expect(reloadedState.revision, equals(2));
      expect(reloadedState.stateFingerprint, equals(v2State.stateFingerprint));
      expect(
          reloadedState.hasProcessedSession(executionState1.sessionId), isTrue);

      // 5. Idempotent replay after restart
      final replayResult = await pipeline.reconcileExecutionState(
        baseState: reloadedState,
        executionState: executionState1,
        timestamp: fixedDate.add(const Duration(hours: 1, minutes: 5)),
      );

      expect(replayResult.isSuccess, isTrue);
      expect(replayResult.isIdempotentReplay, isTrue);
      expect(replayResult.resultingRevision, equals(2)); // No change
      expect(
        replayResult
            .resultingState!.progressMap['obj_polity_preamble']!.attemptCount,
        equals(3),
      );

      // 6. Session 2: Accumulate additional learning evidence
      final executionState2 = buildExecution(
        examId: 'upsc',
        learnerId: 'learner_e2e',
        correctCount: 2,
        incorrectCount: 0,
        objectiveIds: const ['obj_polity_preamble'],
      );

      final pipelineResult2 = await pipeline.reconcileExecutionState(
        baseState: reloadedState,
        executionState: executionState2,
        expectedRevision: 2,
        timestamp: fixedDate.add(const Duration(hours: 2)),
      );

      expect(pipelineResult2.isSuccess, isTrue);
      expect(pipelineResult2.previousRevision, equals(2));
      expect(pipelineResult2.resultingRevision, equals(3));
      final v3State = pipelineResult2.resultingState!;
      expect(v3State.revision, equals(3));
      expect(
        v3State.progressMap['obj_polity_preamble']!.attemptCount,
        equals(5),
      );
      expect(
        v3State.progressMap['obj_polity_preamble']!.correctCount,
        equals(4),
      );

      // 7. Multi-tenant and Multi-exam isolation check
      final bpscRecovery = await recoveryService.recover(
        learnerId: 'learner_e2e',
        examId: 'bpsc',
        requestedAt: fixedDate.add(const Duration(hours: 3)),
        persistInitialIfAbsent: true,
      );

      expect(bpscRecovery.state!.progressMap, isEmpty);
      expect(bpscRecovery.state!.hasProcessedSession(executionState1.sessionId),
          isFalse);
    });
  });
}
