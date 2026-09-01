/// P35 Adaptive Practice Execution Integration Test Suite (TITAN-KO-035.0 P35).
///
/// Full pipeline integration test verifying end-to-end execution:
/// P30 (Acquisition) -> P29 (Normalization) -> P31 (Historical Intelligence)
/// -> P32 (Adaptive Priority) -> P23 (Learner State) -> P33 (Question Selection)
/// -> P34 (Practice Session Orchestrator) -> P35 (Adaptive Practice Execution Engine)
/// -> P19 (Learning Session & Question Attempt Evidence Handoff).
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 12, 0, 0);

  group('P35 Adaptive Practice Execution Mega Integration Pipeline', () {
    test(
        '1. Full E2E Pipeline (P30 -> P29 -> P31 -> P32 -> P23 -> P33 -> P34 -> P35 -> P19)',
        () {
      // ----------------------------------------------------------------------
      // STAGE 1: P29/P30 Multi-Exam Normalization
      // ----------------------------------------------------------------------
      final rawBatch = <RawQuestionInput>[];
      int qCounter = 0;

      // Create BPSC questions
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
      // STAGE 5: P33 Adaptive Question Selection Engine
      // ----------------------------------------------------------------------
      const p33Service = AdaptiveQuestionSelectionService();
      final selectionConfig = AdaptiveQuestionSelectionConfig(
        examId: 'bpsc',
        targetQuestionCount: 5,
        maxQuestionsPerTopic: 3,
        maxQuestionsPerYear: 3,
        excludePreviouslySeen: false,
      );

      final selectionResult = p33Service.selectQuestions(
        corpus: normalizedBatch,
        config: selectionConfig,
        pyqPriorityProfile: p32PriorityProfile,
        weakSpotProfile: weakSpotProfile,
        progressList: progressList,
        selectedAt: fixedDate,
      );

      expect(selectionResult.selectedCount, equals(5));

      // ----------------------------------------------------------------------
      // STAGE 6: P34 Adaptive Practice Session Orchestrator
      // ----------------------------------------------------------------------
      const orchestrator = AdaptivePracticeSessionOrchestrator();
      final sessionConfig = AdaptivePracticeSessionConfig(
        examId: 'bpsc',
        learnerId: 'learner_aspirant_bpsc_2026',
        sessionMode: PracticeSessionMode.standard,
        sectionSize: 3,
        estimatedSecondsPerQuestion: 60,
      );

      final sessionSpec = orchestrator.orchestrateSession(
        selectionResult: selectionResult,
        config: sessionConfig,
        orchestratedAt: fixedDate,
      );

      expect(sessionSpec.totalQuestions, equals(5));

      // ----------------------------------------------------------------------
      // STAGE 7: P35 Adaptive Practice Execution Engine
      // ----------------------------------------------------------------------
      const executionEngine = AdaptivePracticeExecutionEngine();
      final initialState = executionEngine.initializeSession(
        spec: sessionSpec,
        feedbackPolicy: PracticeFeedbackPolicy.immediate,
      );

      expect(initialState.status, equals(PracticeExecutionStatus.notStarted));
      expect(initialState.currentQuestionIndex, equals(0));

      final activeRes = executionEngine.startSession(
        state: initialState,
        startedAt: fixedDate,
      );
      expect(activeRes.isSuccess, isTrue);
      var currentState = activeRes.valueOrThrow;
      expect(currentState.status, equals(PracticeExecutionStatus.inProgress));

      // Execute all 5 questions
      for (int i = 0; i < 5; i++) {
        final q = currentState.currentQuestion!;
        final correctKey = q.officialAnswer.correctOptionKeys.first;
        final isCorrect = i != 1; // Question 1 is answered incorrectly
        final submittedAnswer = isCorrect ? correctKey : 'Z';
        final submitTime = fixedDate.add(Duration(seconds: (i + 1) * 20));

        final subRes = executionEngine.submitAnswer(
          state: currentState,
          questionId: q.id,
          answer: submittedAnswer,
          submittedAt: submitTime,
        );

        expect(subRes.isSuccess, isTrue);
        currentState = subRes.valueOrThrow;

        final r = currentState.questionResults[q.id]!;
        expect(r.isAnswered, isTrue);
        expect(r.isCorrect, equals(isCorrect));
        expect(r.feedback!.isExplanationExposed, isTrue);
      }

      // Final session metrics
      expect(currentState.status, equals(PracticeExecutionStatus.completed));
      expect(currentState.isFinished, isTrue);

      final summary = currentState.completionSummary!;
      expect(summary.totalQuestions, equals(5));
      expect(summary.answeredCount, equals(5));
      expect(summary.correctCount, equals(4));
      expect(summary.incorrectCount, equals(1));
      expect(summary.score, equals(0.8));
      expect(summary.accuracy, equals(0.8));

      // ----------------------------------------------------------------------
      // STAGE 8: P19 QuestionAttempt Evidence Handoff
      // ----------------------------------------------------------------------
      final attempts = executionEngine.generateHandoffAttempts(currentState);
      expect(attempts.length, equals(5));

      for (int i = 0; i < 5; i++) {
        final att = attempts[i];
        expect(att.sessionId, equals(sessionSpec.sessionId));
        expect(att.learnerId, equals('learner_aspirant_bpsc_2026'));
        expect(
            att.attemptId.startsWith('att_${sessionSpec.sessionId}_'), isTrue);
      }
    });

    test(
        '2. Exam Simulation Mode: withholds feedback during session and reveals summary at completion',
        () {
      final rawBatch = <RawQuestionInput>[
        RawQuestionInput(
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          questionNumber: 1,
          subject: 'Polity',
          topic: 'Preamble',
          questionText: 'Preamble of the Indian Constitution question',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          objectiveIds: const ['lo_preamble'],
          source: PyqSourceReference.official(
              examId: 'upsc', year: 2024, paper: 'GS1'),
        ),
        RawQuestionInput(
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          questionNumber: 2,
          subject: 'Polity',
          topic: 'Citizenship',
          questionText: 'Citizenship provisions in Constitution',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'B',
          objectiveIds: const ['lo_citizenship'],
          source: PyqSourceReference.official(
              examId: 'upsc', year: 2024, paper: 'GS1'),
        ),
      ];

      final normalizedBatch = MultiExamPyqIntelligenceService()
          .ingestRawQuestions(rawBatch)
          .uniqueQuestions;

      final candidates = normalizedBatch
          .map((q) => AdaptiveQuestionCandidate(
                question: q,
                historicalPriority: 0.7,
                learnerWeakness: 0.3,
                selectionScore: 0.7,
                exposureCount: 0,
                recencyScore: 1.0,
                difficultyFit: 1.0,
                sourceQualityScore: 1.0,
                isEligible: true,
                scoreBreakdown: const {},
              ))
          .toList();

      final selectionResult = AdaptiveQuestionSelectionResult(
        examId: 'upsc',
        selectedQuestions: normalizedBatch,
        selectedCandidates: candidates,
        allCandidates: candidates,
        requestedCount: 2,
        eligibleCount: 2,
        config: AdaptiveQuestionSelectionConfig(
          examId: 'upsc',
          targetQuestionCount: 2,
        ),
        selectedAt: fixedDate,
      );

      const orchestrator = AdaptivePracticeSessionOrchestrator();
      final spec = orchestrator.orchestrateSession(
        selectionResult: selectionResult,
        config: AdaptivePracticeSessionConfig(
          examId: 'upsc',
          sessionMode: PracticeSessionMode.pyqFocused,
        ),
        orchestratedAt: fixedDate,
      );

      const engine = AdaptivePracticeExecutionEngine();
      final initial = engine.initializeSession(
        spec: spec,
        feedbackPolicy: PracticeFeedbackPolicy.examSimulation,
      );

      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      // Question 1 answer
      state = engine
          .submitAnswer(
            state: state,
            questionId: state.currentQuestionId!,
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 30)),
          )
          .valueOrThrow;

      final fb1 = state.questionResults[normalizedBatch[0].id]!.feedback!;
      expect(fb1.isExplanationExposed, isFalse);
      expect(fb1.explanation, isEmpty);

      // Question 2 answer
      state = engine
          .submitAnswer(
            state: state,
            questionId: state.currentQuestionId!,
            answer: 'C', // Incorrect
            submittedAt: fixedDate.add(const Duration(seconds: 60)),
          )
          .valueOrThrow;

      expect(state.status, equals(PracticeExecutionStatus.completed));

      final summary = state.completionSummary!;
      expect(summary.correctCount, equals(1));
      expect(summary.incorrectCount, equals(1));
      expect(summary.accuracy, equals(0.5));
    });

    test(
        '3. Deterministic Pipeline Replay: Identical JSON output across repeated runs',
        () {
      final rawBatch = [
        RawQuestionInput(
          examId: 'upsc',
          year: 2024,
          paper: 'GS1',
          questionNumber: 1,
          subject: 'Geography',
          topic: 'Geomorphology',
          questionText: 'Plate tectonics question',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          objectiveIds: const ['lo_geo_01'],
          source: PyqSourceReference.official(
              examId: 'upsc', year: 2024, paper: 'GS1'),
        ),
      ];

      final normalizedBatch = MultiExamPyqIntelligenceService()
          .ingestRawQuestions(rawBatch)
          .uniqueQuestions;

      final candidates = normalizedBatch
          .map((q) => AdaptiveQuestionCandidate(
                question: q,
                historicalPriority: 0.5,
                learnerWeakness: 0.0,
                selectionScore: 0.5,
                exposureCount: 0,
                recencyScore: 1.0,
                difficultyFit: 1.0,
                sourceQualityScore: 1.0,
                isEligible: true,
                scoreBreakdown: const {},
              ))
          .toList();

      final selectionResult = AdaptiveQuestionSelectionResult(
        examId: 'upsc',
        selectedQuestions: normalizedBatch,
        selectedCandidates: candidates,
        allCandidates: candidates,
        requestedCount: 1,
        eligibleCount: 1,
        config: AdaptiveQuestionSelectionConfig(
          examId: 'upsc',
          targetQuestionCount: 1,
        ),
        selectedAt: fixedDate,
      );

      const orchestrator = AdaptivePracticeSessionOrchestrator();
      final spec = orchestrator.orchestrateSession(
        selectionResult: selectionResult,
        config: AdaptivePracticeSessionConfig(
          examId: 'upsc',
          sessionMode: PracticeSessionMode.standard,
        ),
        orchestratedAt: fixedDate,
      );

      const engine = AdaptivePracticeExecutionEngine();

      String? run1Json;
      String? run2Json;

      for (int run = 0; run < 2; run++) {
        final initial = engine.initializeSession(spec: spec);
        var state = engine
            .startSession(state: initial, startedAt: fixedDate)
            .valueOrThrow;

        state = engine
            .submitAnswer(
              state: state,
              questionId: state.currentQuestionId!,
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 15)),
            )
            .valueOrThrow;

        final jsonStr = jsonEncode(state.toJson());
        if (run == 0) {
          run1Json = jsonStr;
        } else {
          run2Json = jsonStr;
        }
      }

      expect(run1Json, equals(run2Json));
    });
  });
}
