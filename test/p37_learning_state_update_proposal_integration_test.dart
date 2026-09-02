/// P37 Learning State Update Proposal Integration Test Suite (TITAN-KO-037.0 P37).
///
/// Full pipeline integration test verifying end-to-end evidence feedback loop:
/// P30 (Acquisition) -> P29 (Normalization) -> P31 (Historical Intelligence)
/// -> P32 (Adaptive Priority) -> P23 (Learner State) -> P33 (Question Selection)
/// -> P34 (Practice Session Orchestrator) -> P35 (Adaptive Practice Execution Engine)
/// -> P36 (Outcome Consolidation & Evidence Bridge) -> P37 (Learning-State Update Proposal).
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

  group('P37 Learning-State Update Proposal Integration Pipeline', () {
    test(
        '1. Full E2E Pipeline (P30 -> P29 -> P31 -> P32 -> P23 -> P33 -> P34 -> P35 -> P36 -> P37)',
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
      // STAGE 3: P23 Learner Weak Spot Diagnoses
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

      final progressList = [
        LearnerProgress(
          learnerId: 'learner_aspirant_bpsc_2026',
          objectiveId: 'obj_modern_hist',
          status: LearnerObjectiveStatus.achieved,
          attemptCount: 10,
          correctCount: 9,
          lastAttemptAt: fixedDate,
        ),
      ];

      // ----------------------------------------------------------------------
      // STAGE 4: P32 PYQ Learning Priority Engine
      // ----------------------------------------------------------------------
      final p32Engine = PyqLearningPriorityEngine();
      final p32PriorityProfile = p32Engine.evaluateFromExamProfile(
        examProfile: bpscIntelligence,
        weakSpotProfile: weakSpotProfile,
        progressList: progressList,
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
        progressList: progressList,
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
        final answerToSubmit = (i == 0)
            ? 'Z' // First answer wrong
            : q.officialAnswer.correctOptionKeys.first; // remaining 4 correct

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
      final proposalResult = updateProposer.proposeUpdate(
        outcome: outcome,
        proposedAt: fixedDate.add(const Duration(seconds: 200)),
      );

      expect(proposalResult.isSuccess, isTrue);
      final proposal = proposalResult.valueOrThrow;

      expect(proposal.proposalId, equals('prop_${sessionSpec.sessionId}_bpsc'));
      expect(proposal.sessionId, equals(sessionSpec.sessionId));
      expect(proposal.examId, equals('bpsc'));
      expect(proposal.learnerId, equals('learner_aspirant_bpsc_2026'));
      expect(proposal.sessionStatus, equals(PracticeExecutionStatus.completed));
      expect(proposal.totalQuestions, equals(5));
      expect(proposal.attemptedCount, equals(5));
      expect(proposal.correctCount, equals(4));
      expect(proposal.incorrectCount, equals(1));
      expect(proposal.accuracy, equals(0.8));
      expect(proposal.overallEvidenceStrength,
          equals(EvidenceStrength.strong)); // 5 attempts -> strong
      expect(proposal.overallPattern,
          equals(OutcomePattern.improving)); // wrong then 4 right -> improving
      expect(
          proposal.recommendedAction,
          equals(ProposedLearningAction
              .retainMastery)); // 80% improving -> retainMastery
      expect(proposal.questionSignals.length, equals(5));
      expect(proposal.topicSignals.isNotEmpty, isTrue);
      expect(proposal.objectiveSignals.isNotEmpty, isTrue);
      expect(proposal.sectionSignals.length, equals(2));
      expect(proposal.difficultySignals.isNotEmpty, isTrue);
      expect(proposal.fingerprint, hasLength(64));
    });

    test(
        '2. Multi-Exam Isolation: UPSC and BPSC generate independent proposals and distinct fingerprints',
        () {
      final qUpsc = NormalizedQuestion(
        id: 'q_upsc_polity_01',
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        normalizedText: 'UPSC Fundamental Rights question',
        originalText: 'UPSC Fundamental Rights question',
        options: const [
          Option(key: 'A', text: 'Opt A', isCorrect: true),
          Option(key: 'B', text: 'Opt B', isCorrect: false),
        ],
        officialAnswer: const Answer(
            correctOptionKeys: ['A'], officialAnswerSource: 'UPSC Key'),
        source: PyqSourceReference.official(
            examId: 'upsc', year: 2024, paper: 'GS1'),
      );

      final qBpsc = NormalizedQuestion(
        id: 'q_bpsc_history_01',
        examId: 'bpsc',
        year: 2024,
        paper: 'GS1',
        subject: 'History',
        topic: 'Bihar Modern History',
        normalizedText: 'BPSC Modern History question',
        originalText: 'BPSC Modern History question',
        options: const [
          Option(key: 'A', text: 'Opt A', isCorrect: true),
          Option(key: 'B', text: 'Opt B', isCorrect: false),
        ],
        officialAnswer: const Answer(
            correctOptionKeys: ['A'], officialAnswerSource: 'BPSC Key'),
        source: PyqSourceReference.official(
            examId: 'bpsc', year: 2024, paper: 'GS1'),
      );

      final specUpsc = buildSpec(examId: 'upsc', questions: [qUpsc]);
      final specBpsc = buildSpec(examId: 'bpsc', questions: [qBpsc]);

      const p35Engine = AdaptivePracticeExecutionEngine();
      const p36Consolidator = PracticeOutcomeConsolidator();
      const p37Proposer = LearningStateUpdateProposer();

      var stateUpsc = p35Engine
          .startSession(
              state: p35Engine.initializeSession(spec: specUpsc),
              startedAt: fixedDate)
          .valueOrThrow;
      stateUpsc = p35Engine
          .submitAnswer(
              state: stateUpsc,
              questionId: 'q_upsc_polity_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 15)))
          .valueOrThrow;

      var stateBpsc = p35Engine
          .startSession(
              state: p35Engine.initializeSession(spec: specBpsc),
              startedAt: fixedDate)
          .valueOrThrow;
      stateBpsc = p35Engine
          .submitAnswer(
              state: stateBpsc,
              questionId: 'q_bpsc_history_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 15)))
          .valueOrThrow;

      final outcomeUpsc =
          p36Consolidator.consolidate(state: stateUpsc).valueOrThrow;
      final outcomeBpsc =
          p36Consolidator.consolidate(state: stateBpsc).valueOrThrow;

      final propUpsc = p37Proposer
          .proposeUpdate(outcome: outcomeUpsc, proposedAt: fixedDate)
          .valueOrThrow;
      final propBpsc = p37Proposer
          .proposeUpdate(outcome: outcomeBpsc, proposedAt: fixedDate)
          .valueOrThrow;

      expect(propUpsc.examId, equals('upsc'));
      expect(propBpsc.examId, equals('bpsc'));
      expect(propUpsc.fingerprint, isNot(equals(propBpsc.fingerprint)));
      expect(propUpsc.topicSignals.containsKey('Fundamental Rights'), isTrue);
      expect(propBpsc.topicSignals.containsKey('Bihar Modern History'), isTrue);
    });

    test(
        '3. Directional Trajectory Analysis: Improving session vs Declining session generate justified distinct proposals',
        () {
      final questionsImproving = List.generate(
        4,
        (i) => NormalizedQuestion(
          id: 'q_imp_$i',
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Parliament',
          normalizedText: 'Parliament question $i',
          originalText: 'Parliament question $i',
          options: const [
            Option(key: 'A', text: 'Opt A', isCorrect: true),
            Option(key: 'B', text: 'Opt B', isCorrect: false),
          ],
          officialAnswer: const Answer(
              correctOptionKeys: ['A'], officialAnswerSource: 'UPSC Key'),
          source: PyqSourceReference.official(
              examId: 'upsc', year: 2024, paper: 'GS1'),
        ),
      );

      final questionsDeclining = List.generate(
        4,
        (i) => NormalizedQuestion(
          id: 'q_dec_$i',
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Parliament',
          normalizedText: 'Parliament question $i',
          originalText: 'Parliament question $i',
          options: const [
            Option(key: 'A', text: 'Opt A', isCorrect: true),
            Option(key: 'B', text: 'Opt B', isCorrect: false),
          ],
          officialAnswer: const Answer(
              correctOptionKeys: ['A'], officialAnswerSource: 'UPSC Key'),
          source: PyqSourceReference.official(
              examId: 'upsc', year: 2024, paper: 'GS1'),
        ),
      );

      const p35Engine = AdaptivePracticeExecutionEngine();
      const p36Consolidator = PracticeOutcomeConsolidator();
      const p37Proposer = LearningStateUpdateProposer();

      // Improving: wrong, wrong, right, right
      var stateImp = p35Engine
          .startSession(
              state: p35Engine.initializeSession(
                  spec: buildSpec(questions: questionsImproving)),
              startedAt: fixedDate)
          .valueOrThrow;
      stateImp = p35Engine
          .submitAnswer(
              state: stateImp,
              questionId: 'q_imp_0',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      stateImp = p35Engine
          .submitAnswer(
              state: stateImp,
              questionId: 'q_imp_1',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      stateImp = p35Engine
          .submitAnswer(
              state: stateImp,
              questionId: 'q_imp_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;
      stateImp = p35Engine
          .submitAnswer(
              state: stateImp,
              questionId: 'q_imp_3',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 40)))
          .valueOrThrow;

      // Declining: right, right, wrong, wrong
      var stateDec = p35Engine
          .startSession(
              state: p35Engine.initializeSession(
                  spec: buildSpec(questions: questionsDeclining)),
              startedAt: fixedDate)
          .valueOrThrow;
      stateDec = p35Engine
          .submitAnswer(
              state: stateDec,
              questionId: 'q_dec_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      stateDec = p35Engine
          .submitAnswer(
              state: stateDec,
              questionId: 'q_dec_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      stateDec = p35Engine
          .submitAnswer(
              state: stateDec,
              questionId: 'q_dec_2',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;
      stateDec = p35Engine
          .submitAnswer(
              state: stateDec,
              questionId: 'q_dec_3',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 40)))
          .valueOrThrow;

      final propImp = p37Proposer
          .proposeUpdate(
              outcome:
                  p36Consolidator.consolidate(state: stateImp).valueOrThrow)
          .valueOrThrow;
      final propDec = p37Proposer
          .proposeUpdate(
              outcome:
                  p36Consolidator.consolidate(state: stateDec).valueOrThrow)
          .valueOrThrow;

      expect(propImp.overallPattern, equals(OutcomePattern.improving));
      expect(propDec.overallPattern, equals(OutcomePattern.declining));
      expect(propDec.recommendedAction,
          equals(ProposedLearningAction.reviewRemediation));
    });

    test(
        '4. Abandoned Session Partial Proposal: compiles partial evidence without penalizing unanswered questions',
        () {
      final questions = List.generate(
        5,
        (i) => NormalizedQuestion(
          id: 'q_aband_p37_$i',
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Economy',
          topic: 'Fiscal Policy',
          normalizedText: 'Fiscal Policy question $i',
          originalText: 'Fiscal Policy question $i',
          options: const [
            Option(key: 'A', text: 'Opt A', isCorrect: true),
            Option(key: 'B', text: 'Opt B', isCorrect: false),
          ],
          officialAnswer: const Answer(
              correctOptionKeys: ['A'], officialAnswerSource: 'UPSC Key'),
          source: PyqSourceReference.official(
              examId: 'upsc', year: 2024, paper: 'GS1'),
        ),
      );

      final spec = buildSpec(questions: questions);
      const engine = AdaptivePracticeExecutionEngine();
      var state = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;

      // Answer 1, skip 1, abandon remaining 3
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_aband_p37_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_aband_p37_1',
              skippedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;

      const consolidator = PracticeOutcomeConsolidator();
      const proposer = LearningStateUpdateProposer();

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.sessionStatus, equals(PracticeExecutionStatus.abandoned));
      expect(proposal.totalQuestions, equals(5));
      expect(proposal.attemptedCount, equals(1));
      expect(proposal.correctCount, equals(1));
      expect(proposal.skippedCount, equals(1));
      expect(proposal.unansweredCount, equals(3));
      expect(proposal.accuracy, equals(1.0)); // 1/1 attempted
      expect(proposal.completionRate, equals(0.4)); // 2/5
      expect(proposal.questionSignals[0].proposedAction,
          equals(ProposedLearningAction.retainMastery));
      expect(proposal.questionSignals[1].proposedAction,
          equals(ProposedLearningAction.continueExposure));
      expect(proposal.questionSignals[2].proposedAction,
          equals(ProposedLearningAction.noAction));
    });

    test(
        '5. Deterministic Pipeline Replay: 10 consecutive full pipeline executions produce identical JSON and SHA-256',
        () {
      final q = NormalizedQuestion(
        id: 'q_det_p37_replay',
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        subject: 'Environment',
        topic: 'Biodiversity',
        normalizedText: 'Biodiversity conservation question',
        originalText: 'Biodiversity conservation question',
        options: const [
          Option(key: 'A', text: 'Opt A', isCorrect: true),
          Option(key: 'B', text: 'Opt B', isCorrect: false),
        ],
        officialAnswer: const Answer(
            correctOptionKeys: ['A'], officialAnswerSource: 'UPSC Key'),
        source: PyqSourceReference.official(
            examId: 'upsc', year: 2024, paper: 'GS1'),
      );

      final spec = buildSpec(questions: [q]);
      const engine = AdaptivePracticeExecutionEngine();
      const consolidator = PracticeOutcomeConsolidator();
      const proposer = LearningStateUpdateProposer();

      String? baselineJson;
      String? baselineFp;

      for (int run = 0; run < 10; run++) {
        var state = engine
            .startSession(
                state: engine.initializeSession(spec: spec),
                startedAt: fixedDate)
            .valueOrThrow;
        state = engine
            .submitAnswer(
              state: state,
              questionId: 'q_det_p37_replay',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 25)),
            )
            .valueOrThrow;

        final outcome = consolidator.consolidate(state: state).valueOrThrow;
        final proposal = proposer
            .proposeUpdate(outcome: outcome, proposedAt: fixedDate)
            .valueOrThrow;
        final currentJson = jsonEncode(proposal.toJson());

        if (run == 0) {
          baselineJson = currentJson;
          baselineFp = proposal.fingerprint;
        } else {
          expect(currentJson, equals(baselineJson));
          expect(proposal.fingerprint, equals(baselineFp));
        }
      }
    });
  });
}
