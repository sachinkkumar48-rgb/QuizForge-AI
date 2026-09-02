/// P36 Adaptive Practice Outcome Consolidation Integration Test Suite (TITAN-KO-036.0 P36).
///
/// Full pipeline integration test verifying end-to-end outcome consolidation:
/// P30 (Acquisition) -> P29 (Normalization) -> P31 (Historical Intelligence)
/// -> P32 (Adaptive Priority) -> P23 (Learner State) -> P33 (Question Selection)
/// -> P34 (Practice Session Orchestrator) -> P35 (Adaptive Practice Execution Engine)
/// -> P36 (Outcome Consolidation & Evidence Bridge) -> P19 (Evidence-Ready Attempt Persistence Handoff).
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

  group('P36 Adaptive Practice Outcome Consolidation Integration Pipeline', () {
    test(
        '1. Full E2E Pipeline (P30 -> P29 -> P31 -> P32 -> P23 -> P33 -> P34 -> P35 -> P36 -> P19)',
        () {
      // ----------------------------------------------------------------------
      // STAGE 1: P29/P30 Multi-Exam Normalization
      // ----------------------------------------------------------------------
      final rawBatch = <RawQuestionInput>[];
      int qCounter = 0;

      // Create BPSC questions across multiple topics and objectives
      for (int year = 2020; year <= 2024; year++) {
        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'History',
          topic: 'Modern History of Bihar',
          questionText:
              'BPSC 1857 Revolt in Bihar Veer Kunwar Singh question $qCounter in $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          difficulty: 'Medium',
          objectiveIds: const ['obj_bihar_hist'],
          source: PyqSourceReference.official(
            examId: 'bpsc',
            year: year,
            paper: 'GS1',
          ),
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
              'BPSC Non-Cooperation Movement in Bihar question $qCounter in $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'B',
          difficulty: 'Hard',
          objectiveIds: const ['obj_modern_hist'],
          source: PyqSourceReference.official(
            examId: 'bpsc',
            year: year,
            paper: 'GS1',
          ),
        ));

        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'Science',
          topic: 'General Science Physics',
          questionText:
              'BPSC Newton laws of motion optics question $qCounter in $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'C',
          difficulty: 'Easy',
          objectiveIds: const ['obj_physics'],
          source: PyqSourceReference.official(
            examId: 'bpsc',
            year: year,
            paper: 'GS1',
          ),
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

      expect(bpscIntelligence.examId, equals('bpsc'));
      expect(bpscIntelligence.questionCount, equals(15));

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
            correctCount: 2, // 20% accuracy -> deficiency 0.80
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

      expect(p32PriorityProfile.examId, equals('bpsc'));

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

      expect(selectionResult.selectedCount, equals(5));

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

      expect(sessionSpec.totalQuestions, equals(5));

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

      // Submit answers for 5 questions (4 correct, 1 incorrect)
      for (int i = 0; i < 5; i++) {
        final q = currentState.currentQuestion!;
        final answerToSubmit = (i == 2)
            ? 'Z' // Intentionally wrong answer for question index 2
            : q.officialAnswer.correctOptionKeys.first;

        final answerTime = fixedDate.add(Duration(seconds: (i + 1) * 30));
        currentState = executionEngine
            .submitAnswer(
              state: currentState,
              questionId: q.id,
              answer: answerToSubmit,
              submittedAt: answerTime,
            )
            .valueOrThrow;
      }

      expect(currentState.status, equals(PracticeExecutionStatus.completed));

      // ----------------------------------------------------------------------
      // STAGE 8: P36 Adaptive Practice Outcome Consolidation & Evidence Bridge
      // ----------------------------------------------------------------------
      const outcomeConsolidator = PracticeOutcomeConsolidator();
      final outcomeResult = outcomeConsolidator.consolidate(
        state: currentState,
        consolidatedAt: fixedDate.add(const Duration(seconds: 180)),
      );

      expect(outcomeResult.isSuccess, isTrue);
      final outcome = outcomeResult.valueOrThrow;

      expect(outcome.sessionId, equals(sessionSpec.sessionId));
      expect(outcome.examId, equals('bpsc'));
      expect(outcome.learnerId, equals('learner_aspirant_bpsc_2026'));
      expect(outcome.sessionStatus, equals(PracticeExecutionStatus.completed));
      expect(outcome.totalQuestions, equals(5));
      expect(outcome.attemptedCount, equals(5));
      expect(outcome.correctCount, equals(4));
      expect(outcome.incorrectCount, equals(1));
      expect(outcome.skippedCount, equals(0));
      expect(outcome.unansweredCount, equals(0));
      expect(outcome.completionRate, equals(1.0));
      expect(outcome.accuracy, equals(0.8));
      expect(outcome.accuracyPercentage, equals(80.0));
      expect(outcome.scoreRatio, equals(0.8));
      expect(outcome.fingerprint, hasLength(64));

      // Dimensional evidence verification
      expect(outcome.topicEvidence.isNotEmpty, isTrue);
      expect(outcome.objectiveEvidence.isNotEmpty, isTrue);
      expect(outcome.sectionEvidence.length,
          equals(2)); // 5 questions with sectionSize 3 -> 2 sections
      expect(outcome.difficultyEvidence.isNotEmpty, isTrue);
      expect(outcome.questionEvidence.length, equals(5));

      // ----------------------------------------------------------------------
      // STAGE 9: P19 Handoff Verification
      // ----------------------------------------------------------------------
      expect(outcome.handoffAttempts.length, equals(5));
      for (final att in outcome.handoffAttempts) {
        expect(att.sessionId, equals(sessionSpec.sessionId));
        expect(att.learnerId, equals('learner_aspirant_bpsc_2026'));
        expect(
            att.attemptId.startsWith('att_${sessionSpec.sessionId}_'), isTrue);
        expect(att.submittedAnswer, isNotEmpty);
      }
    });

    test(
        '2. Multi-Exam Isolation: UPSC and BPSC outcomes consolidate independently',
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

      // Consolidate both
      final outcomeUpsc =
          p36Consolidator.consolidate(state: stateUpsc).valueOrThrow;
      final outcomeBpsc =
          p36Consolidator.consolidate(state: stateBpsc).valueOrThrow;

      expect(outcomeUpsc.examId, equals('upsc'));
      expect(outcomeBpsc.examId, equals('bpsc'));
      expect(outcomeUpsc.fingerprint, isNot(equals(outcomeBpsc.fingerprint)));
      expect(
          outcomeUpsc.topicEvidence.containsKey('Fundamental Rights'), isTrue);
      expect(outcomeBpsc.topicEvidence.containsKey('Bihar Modern History'),
          isTrue);
    });

    test(
        '3. Exam Simulation Mode: withholds feedback during execution and reveals full consolidation at finish',
        () {
      final q1 = NormalizedQuestion(
        id: 'q_sim_01',
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Preamble',
        normalizedText: 'Preamble question',
        originalText: 'Preamble question',
        options: const [
          Option(key: 'A', text: 'Opt A', isCorrect: true),
          Option(key: 'B', text: 'Opt B', isCorrect: false),
        ],
        officialAnswer: const Answer(
            correctOptionKeys: ['A'], officialAnswerSource: 'UPSC Official'),
        explanation: 'Official detailed explanation',
        source: PyqSourceReference.official(
            examId: 'upsc', year: 2024, paper: 'GS1'),
      );

      final spec = buildSpec(
          examId: 'upsc',
          questions: [q1],
          mode: PracticeSessionMode.pyqFocused);

      const engine = AdaptivePracticeExecutionEngine();
      final initial = engine.initializeSession(
        spec: spec,
        feedbackPolicy: PracticeFeedbackPolicy.examSimulation,
      );

      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_sim_01',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 30)),
          )
          .valueOrThrow;

      const consolidator = PracticeOutcomeConsolidator();
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      expect(outcome.feedbackSummary.policy,
          equals(PracticeFeedbackPolicy.examSimulation));
      expect(outcome.feedbackSummary.totalFeedbackGenerated, equals(1));
      expect(outcome.feedbackSummary.explanationsWithheldCount, equals(1));
      expect(outcome.accuracy, equals(1.0));
      expect(outcome.handoffAttempts.length, equals(1));
    });

    test(
        '4. Abandoned Session Partial Consolidation: calculates accurate partial metrics and unanswered questions',
        () {
      final questions = List.generate(
        5,
        (i) => NormalizedQuestion(
          id: 'q_aband_$i',
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          subject: 'Economy',
          topic: 'Inflation',
          normalizedText: 'Inflation question $i',
          originalText: 'Inflation question $i',
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

      final spec = buildSpec(examId: 'upsc', questions: questions);

      const engine = AdaptivePracticeExecutionEngine();
      var state = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;

      // Answer 1, skip 1, abandon remaining 3
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_aband_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_aband_1',
              skippedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;

      const consolidator = PracticeOutcomeConsolidator();
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      expect(outcome.sessionStatus, equals(PracticeExecutionStatus.abandoned));
      expect(outcome.totalQuestions, equals(5));
      expect(outcome.attemptedCount, equals(1));
      expect(outcome.correctCount, equals(1));
      expect(outcome.skippedCount, equals(1));
      expect(outcome.unansweredCount, equals(3));
      expect(outcome.completionRate, equals(0.4)); // (1+1)/5 = 40%
      expect(outcome.accuracy, equals(1.0)); // 1/1 attempted
      expect(
          outcome.handoffAttempts.length, equals(1)); // only answered question
    });

    test(
        '5. Deterministic Pipeline Replay: 10 consecutive full executions produce identical JSON and SHA-256',
        () {
      final q = NormalizedQuestion(
        id: 'q_det_replay_01',
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        subject: 'Geography',
        topic: 'Geomorphology',
        normalizedText: 'Plate tectonics question',
        originalText: 'Plate tectonics question',
        options: const [
          Option(key: 'A', text: 'Opt A', isCorrect: true),
          Option(key: 'B', text: 'Opt B', isCorrect: false),
        ],
        officialAnswer: const Answer(
            correctOptionKeys: ['A'], officialAnswerSource: 'UPSC Key'),
        source: PyqSourceReference.official(
            examId: 'upsc', year: 2024, paper: 'GS1'),
      );

      final spec = buildSpec(examId: 'upsc', questions: [q]);

      const engine = AdaptivePracticeExecutionEngine();
      const consolidator = PracticeOutcomeConsolidator();

      String? baselineJson;
      String? baselineFingerprint;

      for (int run = 0; run < 10; run++) {
        var state = engine
            .startSession(
                state: engine.initializeSession(spec: spec),
                startedAt: fixedDate)
            .valueOrThrow;
        state = engine
            .submitAnswer(
              state: state,
              questionId: 'q_det_replay_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 20)),
            )
            .valueOrThrow;

        final outcome = consolidator.consolidate(state: state).valueOrThrow;
        final currentJson = jsonEncode(outcome.toJson());

        if (run == 0) {
          baselineJson = currentJson;
          baselineFingerprint = outcome.fingerprint;
        } else {
          expect(currentJson, equals(baselineJson));
          expect(outcome.fingerprint, equals(baselineFingerprint));
        }
      }
    });
  });
}
