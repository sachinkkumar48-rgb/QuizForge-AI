/// P38 Adaptive Learning State Reconciliation Integration Test Suite (TITAN-KO-038.0 P38).
///
/// Full pipeline integration test verifying end-to-end evidence feedback and reconciliation loop:
/// P30 (Acquisition) -> P29 (Normalization) -> P31 (Historical Intelligence)
/// -> P32 (Adaptive Priority) -> P23 (Learner State) -> P33 (Question Selection)
/// -> P34 (Practice Session Orchestrator) -> P35 (Adaptive Practice Execution Engine)
/// -> P36 (Outcome Consolidation & Evidence Bridge) -> P37 (Learning-State Update Proposal)
/// -> P38 (Adaptive Learning State Reconciliation Engine).
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 12, 0, 0);

  AdaptiveQuestionCandidate buildCandidate({
    required NormalizedQuestion question,
    double priority = 0.5,
    double weakness = 0.5,
    int exposures = 0,
    DateTime? lastExposed,
    double recency = 1.0,
    double diffFit = 0.8,
    double quality = 1.0,
    double selectionScore = 0.75,
    bool eligible = true,
  }) {
    return AdaptiveQuestionCandidate(
      question: question,
      historicalPriority: priority,
      learnerWeakness: weakness,
      exposureCount: exposures,
      lastExposedAt: lastExposed,
      recencyScore: recency,
      difficultyFit: diffFit,
      sourceQualityScore: quality,
      selectionScore: selectionScore,
      isEligible: eligible,
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
    String? learnerId = 'learner_aspirant_2026',
    required List<NormalizedQuestion> questions,
    PracticeSessionMode mode = PracticeSessionMode.standard,
    int sectionSize = 5,
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
      sessionMode: mode,
      sectionSize: sectionSize,
      estimatedSecondsPerQuestion: 60,
    );

    const orchestrator = AdaptivePracticeSessionOrchestrator();
    return orchestrator.orchestrateSession(
      selectionResult: selectionResult,
      config: config,
      orchestratedAt: fixedDate,
    );
  }

  group('P38 Adaptive Learning State Reconciliation Integration Pipeline', () {
    test(
        '1. Full E2E Pipeline (P30 -> P29 -> P31 -> P32 -> P23 -> P33 -> P34 -> P35 -> P36 -> P37 -> P38)',
        () {
      // ----------------------------------------------------------------------
      // STAGE 1: P29/P30 Multi-Exam Normalization
      // ----------------------------------------------------------------------
      final rawBatch = <RawQuestionInput>[];
      int qCounter = 0;

      for (int year = 2020; year <= 2024; year++) {
        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'History',
          topic: 'Modern History of Bihar',
          questionText: 'BPSC 1857 Revolt in Bihar question $qCounter in $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          difficulty: 'Medium',
          objectiveIds: const ['obj_bihar_hist'],
          source: PyqSourceReference.official(
              examId: 'bpsc', year: year, paper: 'GS1'),
        ));

        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'History',
          topic: 'Indian National Movement',
          questionText:
              'BPSC Non-Cooperation Movement question $qCounter in $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'B',
          difficulty: 'Hard',
          objectiveIds: const ['obj_modern_hist'],
          source: PyqSourceReference.official(
              examId: 'bpsc', year: year, paper: 'GS1'),
        ));

        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'Science',
          topic: 'General Science Physics',
          questionText: 'BPSC Physics question $qCounter in $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'C',
          difficulty: 'Easy',
          objectiveIds: const ['obj_physics'],
          source: PyqSourceReference.official(
              examId: 'bpsc', year: year, paper: 'GS1'),
        ));
      }

      final p29Service = MultiExamPyqIntelligenceService();
      final ingestionResult = p29Service.ingestRawQuestions(rawBatch);
      final normalizedBatch = ingestionResult.uniqueQuestions;

      expect(normalizedBatch.length, equals(15));

      // ----------------------------------------------------------------------
      // STAGE 2: P31 Multi-Exam Historical PYQ Intelligence
      // ----------------------------------------------------------------------
      const p31Engine = PyqHistoricalIntelligenceEngine();
      final bpscIntelligence = p31Engine.buildExamProfile(
        normalizedBatch,
        examId: 'bpsc',
        frameworkObjectiveIds: const [
          'obj_bihar_hist',
          'obj_modern_hist',
          'obj_physics',
        ],
      );

      // ----------------------------------------------------------------------
      // STAGE 3: P23 Learner Weak Spot Diagnoses & Progress
      // ----------------------------------------------------------------------
      final weakSpotProfile = WeakSpotProfile(
        learnerId: 'learner_aspirant_bpsc_2026',
        totalEvaluatedObjectives: 2,
        evaluatedWithSufficientEvidence: 2,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_bihar_hist',
            attemptCount: 10,
            correctCount: 2,
          ),
        ],
      );

      final initialProgressList = [
        LearnerProgress(
          learnerId: 'learner_aspirant_bpsc_2026',
          objectiveId: 'obj_bihar_hist',
          status: LearnerObjectiveStatus.inProgress,
          attemptCount: 10,
          correctCount: 2,
          lastAttemptAt: fixedDate,
        ),
        LearnerProgress(
          learnerId: 'learner_aspirant_bpsc_2026',
          objectiveId: 'obj_modern_hist',
          status: LearnerObjectiveStatus.achieved,
          attemptCount: 10,
          correctCount: 9,
          lastAttemptAt: fixedDate,
          achievedAt: fixedDate,
        ),
      ];

      // ----------------------------------------------------------------------
      // STAGE 4: P32 PYQ Learning Priority Engine
      // ----------------------------------------------------------------------
      final p32Engine = PyqLearningPriorityEngine();
      final p32PriorityProfile = p32Engine.evaluateFromExamProfile(
        examProfile: bpscIntelligence,
        weakSpotProfile: weakSpotProfile,
        progressList: initialProgressList,
        evaluatedAt: fixedDate,
      );

      // ----------------------------------------------------------------------
      // STAGE 5: P33 Adaptive Question Selection
      // ----------------------------------------------------------------------
      const p33Service = AdaptiveQuestionSelectionService();
      final selectionResult = p33Service.selectQuestions(
        corpus: normalizedBatch,
        config: AdaptiveQuestionSelectionConfig(
          examId: 'bpsc',
          targetQuestionCount: 5,
        ),
        pyqPriorityProfile: p32PriorityProfile,
        weakSpotProfile: weakSpotProfile,
        progressList: initialProgressList,
        selectedAt: fixedDate,
      );

      // ----------------------------------------------------------------------
      // STAGE 6: P34 Adaptive Practice Session Orchestration
      // ----------------------------------------------------------------------
      const sessionOrchestrator = AdaptivePracticeSessionOrchestrator();
      final sessionSpec = sessionOrchestrator.orchestrateSession(
        selectionResult: selectionResult,
        config: AdaptivePracticeSessionConfig(
          examId: 'bpsc',
          learnerId: 'learner_aspirant_bpsc_2026',
          sessionMode: PracticeSessionMode.remedialPractice,
          sectionSize: 3,
          estimatedSecondsPerQuestion: 60,
        ),
        orchestratedAt: fixedDate,
      );

      // ----------------------------------------------------------------------
      // STAGE 7: P35 Adaptive Practice Session Execution
      // ----------------------------------------------------------------------
      const executionEngine = AdaptivePracticeExecutionEngine();
      final initialState = executionEngine.initializeSession(
        spec: sessionSpec,
        feedbackPolicy: PracticeFeedbackPolicy.immediate,
      );

      var currentState = executionEngine
          .startSession(state: initialState, startedAt: fixedDate)
          .valueOrThrow;

      for (int i = 0; i < 5; i++) {
        final q = currentState.currentQuestion!;
        final answerToSubmit = q.officialAnswer.correctOptionKeys.first;

        currentState = executionEngine
            .submitAnswer(
              state: currentState,
              questionId: q.id,
              answer: answerToSubmit,
              submittedAt: fixedDate.add(Duration(seconds: (i + 1) * 20)),
            )
            .valueOrThrow;
      }

      // ----------------------------------------------------------------------
      // STAGE 8: P36 Adaptive Practice Outcome Consolidation
      // ----------------------------------------------------------------------
      const outcomeConsolidator = PracticeOutcomeConsolidator();
      final outcome = outcomeConsolidator
          .consolidate(
            state: currentState,
            consolidatedAt: fixedDate.add(const Duration(seconds: 180)),
          )
          .valueOrThrow;

      // ----------------------------------------------------------------------
      // STAGE 9: P37 Adaptive Learning Evidence Feedback Loop & Proposal
      // ----------------------------------------------------------------------
      const updateProposer = LearningStateUpdateProposer();
      final proposal = updateProposer
          .proposeUpdate(
            outcome: outcome,
            proposedAt: fixedDate.add(const Duration(seconds: 200)),
          )
          .valueOrThrow;

      // ----------------------------------------------------------------------
      // STAGE 10: P38 Adaptive Learning State Reconciliation Engine
      // ----------------------------------------------------------------------
      final authoritativeLearnerState =
          AuthoritativeLearnerState.fromProgressList(
        learnerId: 'learner_aspirant_bpsc_2026',
        examId: 'bpsc',
        progressList: initialProgressList,
        lastUpdatedAt: fixedDate,
      );

      const stateReconciler = AdaptiveLearningStateReconciler();
      final reconciliationResult = stateReconciler.reconcile(
        authoritativeState: authoritativeLearnerState,
        proposal: proposal,
        reconciledAt: fixedDate.add(const Duration(seconds: 250)),
      );

      expect(reconciliationResult.isSuccess, isTrue);
      final reconciledProposal = reconciliationResult.valueOrThrow;

      expect(reconciledProposal.reconciliationId,
          equals('rec_${sessionSpec.sessionId}_bpsc'));
      expect(
          reconciledProposal.learnerId, equals('learner_aspirant_bpsc_2026'));
      expect(reconciledProposal.examId, equals('bpsc'));
      expect(reconciledProposal.overallDecision,
          equals(ReconciliationDecision.merged));
      expect(reconciledProposal.hasStateChanges, isTrue);

      // Verify objective progress merged correctly
      final mergedProgress = reconciledProposal.reconciledProgress;
      expect(mergedProgress.containsKey('obj_bihar_hist'), isTrue);
      expect(mergedProgress.containsKey('obj_modern_hist'), isTrue);

      // Total attempts for obj_bihar_hist increased from prior 10
      expect(mergedProgress['obj_bihar_hist']!.attemptCount, greaterThan(10));

      // Processed sessions includes sessionSpec.sessionId
      expect(
          reconciledProposal.processedSessionIds
              .contains(sessionSpec.sessionId),
          isTrue);

      // Provenance accurately linked
      expect(reconciledProposal.provenance.sessionId,
          equals(sessionSpec.sessionId));
      expect(reconciledProposal.provenance.proposalId,
          equals(proposal.proposalId));
      expect(reconciledProposal.provenance.sourceProposalFingerprint,
          equals(proposal.fingerprint));
      expect(reconciledProposal.provenance.baseStateFingerprint,
          equals(authoritativeLearnerState.stateFingerprint));
      expect(reconciledProposal.fingerprint, hasLength(64));
    });

    test(
        '2. Multi-Exam Isolation: UPSC and BPSC states and proposals reconcile independently',
        () {
      final stateUpsc = AuthoritativeLearnerState.empty(
        learnerId: 'aspirant_multi',
        examId: 'upsc',
        createdAt: fixedDate,
      );
      final stateBpsc = AuthoritativeLearnerState.empty(
        learnerId: 'aspirant_multi',
        examId: 'bpsc',
        createdAt: fixedDate,
      );

      final qUpsc = NormalizedQuestion(
        id: 'q_upsc_test_01',
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Preamble',
        normalizedText: 'UPSC Preamble question',
        originalText: 'UPSC Preamble question',
        options: const [
          Option(key: 'A', text: 'Opt A', isCorrect: true),
          Option(key: 'B', text: 'Opt B', isCorrect: false),
        ],
        officialAnswer:
            const Answer(correctOptionKeys: ['A'], officialAnswerSource: 'Key'),
        source: PyqSourceReference.official(
            examId: 'upsc', year: 2024, paper: 'GS1'),
        objectiveIds: const ['obj_upsc_polity'],
      );

      final qBpsc = NormalizedQuestion(
        id: 'q_bpsc_test_01',
        examId: 'bpsc',
        year: 2024,
        paper: 'GS1',
        subject: 'History',
        topic: 'Bihar History',
        normalizedText: 'BPSC History question',
        originalText: 'BPSC History question',
        options: const [
          Option(key: 'A', text: 'Opt A', isCorrect: true),
          Option(key: 'B', text: 'Opt B', isCorrect: false),
        ],
        officialAnswer:
            const Answer(correctOptionKeys: ['A'], officialAnswerSource: 'Key'),
        source: PyqSourceReference.official(
            examId: 'bpsc', year: 2024, paper: 'GS1'),
        objectiveIds: const ['obj_bpsc_hist'],
      );

      final specUpsc = buildSpec(
          examId: 'upsc', learnerId: 'aspirant_multi', questions: [qUpsc]);
      final specBpsc = buildSpec(
          examId: 'bpsc', learnerId: 'aspirant_multi', questions: [qBpsc]);

      const engine = AdaptivePracticeExecutionEngine();
      const consolidator = PracticeOutcomeConsolidator();
      const proposer = LearningStateUpdateProposer();
      const reconciler = AdaptiveLearningStateReconciler();

      var execUpsc = engine
          .startSession(
              state: engine.initializeSession(spec: specUpsc),
              startedAt: fixedDate)
          .valueOrThrow;
      execUpsc = engine
          .submitAnswer(
              state: execUpsc,
              questionId: 'q_upsc_test_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      var execBpsc = engine
          .startSession(
              state: engine.initializeSession(spec: specBpsc),
              startedAt: fixedDate)
          .valueOrThrow;
      execBpsc = engine
          .submitAnswer(
              state: execBpsc,
              questionId: 'q_bpsc_test_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final propUpsc = proposer
          .proposeUpdate(
              outcome: consolidator.consolidate(state: execUpsc).valueOrThrow)
          .valueOrThrow;
      final propBpsc = proposer
          .proposeUpdate(
              outcome: consolidator.consolidate(state: execBpsc).valueOrThrow)
          .valueOrThrow;

      final rUpsc = reconciler
          .reconcile(authoritativeState: stateUpsc, proposal: propUpsc)
          .valueOrThrow;
      final rBpsc = reconciler
          .reconcile(authoritativeState: stateBpsc, proposal: propBpsc)
          .valueOrThrow;

      expect(rUpsc.examId, equals('upsc'));
      expect(rBpsc.examId, equals('bpsc'));
      expect(rUpsc.fingerprint, isNot(equals(rBpsc.fingerprint)));
      expect(rUpsc.reconciledProgress.containsKey('obj_upsc_polity'), isTrue);
      expect(rBpsc.reconciledProgress.containsKey('obj_bpsc_hist'), isTrue);

      // Cross-exam reconciliation attempt fails
      final crossResult = reconciler.reconcile(
          authoritativeState: stateUpsc, proposal: propBpsc);
      expect(crossResult.isFailure, isTrue);
      expect(crossResult.error?.code,
          equals(ReconciliationErrorCode.examMismatch));
    });

    test(
        '3. Sequential Idempotency: Reconciling twice produces duplicate no-op without state drift',
        () {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_idem',
        examId: 'upsc',
        progressMap: {
          'obj_fr': LearnerProgress(
            learnerId: 'learner_idem',
            objectiveId: 'obj_fr',
            attemptCount: 5,
            correctCount: 4,
          ),
        },
        lastUpdatedAt: fixedDate,
      );

      final q = NormalizedQuestion(
        id: 'q_idem_01',
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        normalizedText: 'FR question',
        originalText: 'FR question',
        options: const [Option(key: 'A', text: 'A', isCorrect: true)],
        officialAnswer:
            const Answer(correctOptionKeys: ['A'], officialAnswerSource: 'Key'),
        source: PyqSourceReference.official(
            examId: 'upsc', year: 2024, paper: 'GS1'),
        objectiveIds: const ['obj_fr'],
      );

      final spec =
          buildSpec(examId: 'upsc', learnerId: 'learner_idem', questions: [q]);
      const engine = AdaptivePracticeExecutionEngine();
      const consolidator = PracticeOutcomeConsolidator();
      const proposer = LearningStateUpdateProposer();
      const reconciler = AdaptiveLearningStateReconciler();

      var exec = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;
      exec = engine
          .submitAnswer(
              state: exec,
              questionId: 'q_idem_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 15)))
          .valueOrThrow;

      final prop = proposer
          .proposeUpdate(
              outcome: consolidator.consolidate(state: exec).valueOrThrow)
          .valueOrThrow;

      // 1st run
      final r1 = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;
      expect(r1.overallDecision, equals(ReconciliationDecision.merged));
      expect(r1.reconciledProgress['obj_fr']!.attemptCount, equals(6)); // 5 + 1

      // Intermediate authoritative state
      final intermediateState = AuthoritativeLearnerState(
        learnerId: r1.learnerId,
        examId: r1.examId,
        progressMap: r1.reconciledProgress,
        processedSessionIds: r1.processedSessionIds,
        lastUpdatedAt: r1.reconciledAt,
      );

      // 2nd run
      final r2 = reconciler
          .reconcile(authoritativeState: intermediateState, proposal: prop)
          .valueOrThrow;
      expect(r2.overallDecision, equals(ReconciliationDecision.duplicate));
      expect(r2.hasStateChanges, isFalse);
      expect(r2.reconciledProgress['obj_fr']!.attemptCount,
          equals(6)); // Remains 6, no double counting!
    });

    test(
        '4. Conflicting Historical Progress Reconciliation: Preserves achieved status',
        () {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_conflict',
        examId: 'upsc',
        progressMap: {
          'obj_mastered': LearnerProgress(
            learnerId: 'learner_conflict',
            objectiveId: 'obj_mastered',
            attemptCount: 10,
            correctCount: 10,
            status: LearnerObjectiveStatus.achieved,
            achievedAt: fixedDate,
          ),
        },
        lastUpdatedAt: fixedDate,
      );

      // Learner gets 3 wrong in practice
      final q = NormalizedQuestion(
        id: 'q_wrong_01',
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Mastered Topic',
        normalizedText: 'Mastered question',
        originalText: 'Mastered question',
        options: const [
          Option(key: 'A', text: 'A', isCorrect: true),
          Option(key: 'B', text: 'B', isCorrect: false),
        ],
        officialAnswer:
            const Answer(correctOptionKeys: ['A'], officialAnswerSource: 'Key'),
        source: PyqSourceReference.official(
            examId: 'upsc', year: 2024, paper: 'GS1'),
        objectiveIds: const ['obj_mastered'],
      );

      final spec = buildSpec(
          examId: 'upsc', learnerId: 'learner_conflict', questions: [q]);
      const engine = AdaptivePracticeExecutionEngine();
      const consolidator = PracticeOutcomeConsolidator();
      const proposer = LearningStateUpdateProposer();
      const reconciler = AdaptiveLearningStateReconciler();

      var exec = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;
      exec = engine
          .submitAnswer(
              state: exec,
              questionId: 'q_wrong_01',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 15)))
          .valueOrThrow;

      final prop = proposer
          .proposeUpdate(
              outcome: consolidator.consolidate(state: exec).valueOrThrow)
          .valueOrThrow;
      final reconciled = reconciler
          .reconcile(authoritativeState: state, proposal: prop)
          .valueOrThrow;

      // Status remains achieved despite wrong practice answer
      final progress = reconciled.reconciledProgress['obj_mastered']!;
      expect(progress.status, equals(LearnerObjectiveStatus.achieved));
      expect(progress.attemptCount, equals(11));
      expect(progress.correctCount, equals(10));
    });

    test(
        '5. Deterministic Pipeline Replay: 10 consecutive full pipeline executions produce identical JSON and SHA-256',
        () {
      final q = NormalizedQuestion(
        id: 'q_det_replay_p38',
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        subject: 'Environment',
        topic: 'Ecology',
        normalizedText: 'Ecology question',
        originalText: 'Ecology question',
        options: const [Option(key: 'A', text: 'A', isCorrect: true)],
        officialAnswer:
            const Answer(correctOptionKeys: ['A'], officialAnswerSource: 'Key'),
        source: PyqSourceReference.official(
            examId: 'upsc', year: 2024, paper: 'GS1'),
        objectiveIds: const ['obj_ecology'],
      );

      final spec = buildSpec(examId: 'upsc', questions: [q]);
      const engine = AdaptivePracticeExecutionEngine();
      const consolidator = PracticeOutcomeConsolidator();
      const proposer = LearningStateUpdateProposer();
      const reconciler = AdaptiveLearningStateReconciler();

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_aspirant_2026',
        examId: 'upsc',
        createdAt: fixedDate,
      );

      String? baselineJson;
      String? baselineFp;

      for (int run = 0; run < 10; run++) {
        var exec = engine
            .startSession(
                state: engine.initializeSession(spec: spec),
                startedAt: fixedDate)
            .valueOrThrow;
        exec = engine
            .submitAnswer(
                state: exec,
                questionId: 'q_det_replay_p38',
                answer: 'A',
                submittedAt: fixedDate.add(const Duration(seconds: 10)))
            .valueOrThrow;

        final outcome = consolidator.consolidate(state: exec).valueOrThrow;
        final proposal = proposer
            .proposeUpdate(outcome: outcome, proposedAt: fixedDate)
            .valueOrThrow;
        final reconciled = reconciler
            .reconcile(
              authoritativeState: state,
              proposal: proposal,
              reconciledAt: fixedDate,
            )
            .valueOrThrow;

        final currentJson = jsonEncode(reconciled.toJson());

        if (run == 0) {
          baselineJson = currentJson;
          baselineFp = reconciled.fingerprint;
        } else {
          expect(currentJson, equals(baselineJson));
          expect(reconciled.fingerprint, equals(baselineFp));
        }
      }
    });
  });
}
