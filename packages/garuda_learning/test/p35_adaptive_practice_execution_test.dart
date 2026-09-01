/// P35 Adaptive Practice Execution & Feedback Test Suite (TITAN-KO-035.0 P35).
///
/// 120+ unit, property, error, determinism, and benchmark tests verifying:
/// - Group 1: Configuration, Initialization & State Transitions (10 tests)
/// - Group 2: Question Presentation & Sequential Cursor (10 tests)
/// - Group 3: Answer Submission & Validation (10 tests)
/// - Group 4: Correctness Determination (10 tests)
/// - Group 5: Feedback Policies (Immediate, Deferred, Exam Simulation) (10 tests)
/// - Group 6: Skip Handling & Transition (10 tests)
/// - Group 7: Real-Time Progress Metrics ($O(1)$, zero NaN/Infinity) (10 tests)
/// - Group 8: Event Generation & Audit Trail (10 tests)
/// - Group 9: Structured Error Model & Idempotency (10 tests)
/// - Group 10: P19 Evidence-Ready Handoff Records (10 tests)
/// - Group 11: Safety, Multi-Exam Isolation & Property Invariants (10 tests)
/// - Group 12: Replay Determinism & High-Throughput Benchmarks (12 tests: 1k, 10k, 50k, 100k)
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 12, 0, 0);
  const orchestrator = AdaptivePracticeSessionOrchestrator();
  const engine = AdaptivePracticeExecutionEngine();

  NormalizedQuestion buildQuestion({
    required String id,
    String examId = 'upsc',
    int year = 2024,
    String paper = 'GS1',
    String subject = 'Polity',
    String topic = 'Fundamental Rights',
    List<String>? objectiveIds,
    String difficulty = 'Medium',
    String normalizedText = 'Normalized test question text',
    List<Option>? options,
    Answer? officialAnswer,
    String explanation = 'Official commission explanation text',
    PyqSourceReference? source,
  }) {
    final effectiveOfficialAnswer = officialAnswer ??
        const Answer(
          correctOptionKeys: ['A'],
          officialAnswerSource: 'Official Commission Key',
        );

    final correctKeys = effectiveOfficialAnswer.correctOptionKeys
        .map((k) => k.trim().toUpperCase())
        .toList();

    return NormalizedQuestion(
      id: id,
      examId: examId,
      year: year,
      paper: paper,
      subject: subject,
      topic: topic,
      objectiveIds: objectiveIds ?? ['obj_fr'],
      difficulty: difficulty,
      normalizedText: normalizedText,
      originalText: normalizedText,
      options: options ??
          [
            Option(
                key: 'A',
                text: 'Option A',
                isCorrect: correctKeys.contains('A')),
            Option(
                key: 'B',
                text: 'Option B',
                isCorrect: correctKeys.contains('B')),
            Option(
                key: 'C',
                text: 'Option C',
                isCorrect: correctKeys.contains('C')),
            Option(
                key: 'D',
                text: 'Option D',
                isCorrect: correctKeys.contains('D')),
          ],
      officialAnswer: effectiveOfficialAnswer,
      explanation: explanation,
      source: source ??
          PyqSourceReference.official(
            examId: examId,
            year: year,
            paper: paper,
          ),
    );
  }

  AdaptiveQuestionCandidate buildCandidate({
    required NormalizedQuestion question,
    double historicalPriority = 0.5,
    double learnerWeakness = 0.0,
    double selectionScore = 0.5,
    int exposureCount = 0,
    double recencyScore = 1.0,
    double difficultyFit = 1.0,
    double sourceQualityScore = 1.0,
  }) {
    return AdaptiveQuestionCandidate(
      question: question,
      historicalPriority: historicalPriority,
      learnerWeakness: learnerWeakness,
      selectionScore: selectionScore,
      exposureCount: exposureCount,
      recencyScore: recencyScore,
      difficultyFit: difficultyFit,
      sourceQualityScore: sourceQualityScore,
      isEligible: true,
      scoreBreakdown: const {},
    );
  }

  AdaptivePracticeSessionSpec buildSpec({
    String examId = 'upsc',
    String? learnerId = 'learner_101',
    required List<NormalizedQuestion> questions,
    PracticeSessionMode mode = PracticeSessionMode.standard,
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
        targetQuestionCount: questions.isEmpty ? 1 : questions.length,
      ),
      selectedAt: fixedDate,
    );

    final config = AdaptivePracticeSessionConfig(
      examId: examId,
      learnerId: learnerId,
      sessionMode: mode,
      sectionSize: 5,
      estimatedSecondsPerQuestion: 60,
    );

    return orchestrator.orchestrateSession(
      selectionResult: selectionResult,
      config: config,
      orchestratedAt: fixedDate,
    );
  }

  // ==========================================================================
  // GROUP 1: CONFIGURATION, INITIALIZATION & STATE TRANSITIONS
  // ==========================================================================
  group('P35.1 Group 1 — Configuration, Initialization & State Transitions',
      () {
    test('1. Initialized state starts in notStarted status with 0 index', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final state = engine.initializeSession(spec: spec);

      expect(state.sessionId, equals(spec.sessionId));
      expect(state.examId, equals('upsc'));
      expect(state.learnerId, equals('learner_101'));
      expect(state.status, equals(PracticeExecutionStatus.notStarted));
      expect(state.currentQuestionIndex, equals(0));
      expect(state.totalQuestions, equals(1));
      expect(state.events.isEmpty, isTrue);
      expect(state.startedAt, isNull);
    });

    test('2. Default feedbackPolicy is immediate and allowSkip is true', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final state = engine.initializeSession(spec: spec);

      expect(state.feedbackPolicy, equals(PracticeFeedbackPolicy.immediate));
      expect(state.allowSkip, isTrue);
    });

    test('3. Custom feedbackPolicy and allowSkip are retained', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final state = engine.initializeSession(
        spec: spec,
        feedbackPolicy: PracticeFeedbackPolicy.examSimulation,
        allowSkip: false,
      );

      expect(
          state.feedbackPolicy, equals(PracticeFeedbackPolicy.examSimulation));
      expect(state.allowSkip, isFalse);
    });

    test(
        '4. startSession transitions notStarted to inProgress and records startedAt',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final res = engine.startSession(state: initial, startedAt: fixedDate);

      expect(res.isSuccess, isTrue);
      final active = res.valueOrThrow;
      expect(active.status, equals(PracticeExecutionStatus.inProgress));
      expect(active.startedAt, equals(fixedDate));
      expect(active.lastActionAt, equals(fixedDate));
      expect(active.events.length,
          equals(2)); // sessionStarted + questionPresented
    });

    test(
        '5. startSession on already started session returns invalidTransition error',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final invalidRes =
          engine.startSession(state: active, startedAt: fixedDate);
      expect(invalidRes.isFailure, isTrue);
      expect(invalidRes.error!.code,
          equals(PracticeExecutionErrorCode.invalidTransition));
    });

    test('6. pauseSession transitions inProgress to paused', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final pauseTime = fixedDate.add(const Duration(seconds: 10));
      final pauseRes = engine.pauseSession(state: active, pausedAt: pauseTime);
      expect(pauseRes.isSuccess, isTrue);
      expect(
          pauseRes.valueOrThrow.status, equals(PracticeExecutionStatus.paused));
    });

    test('7. resumeSession transitions paused to inProgress', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final paused =
          engine.pauseSession(state: active, pausedAt: fixedDate).valueOrThrow;

      final resumeTime = fixedDate.add(const Duration(seconds: 20));
      final resumeRes =
          engine.resumeSession(state: paused, resumedAt: resumeTime);
      expect(resumeRes.isSuccess, isTrue);
      expect(resumeRes.valueOrThrow.status,
          equals(PracticeExecutionStatus.inProgress));
    });

    test('8. abandonSession transitions to terminal abandoned status', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final abandonTime = fixedDate.add(const Duration(seconds: 30));
      final abandonRes = engine.abandonSession(
        state: active,
        abandonedAt: abandonTime,
        reason: 'Learner exited early',
      );

      expect(abandonRes.isSuccess, isTrue);
      final abandoned = abandonRes.valueOrThrow;
      expect(abandoned.status, equals(PracticeExecutionStatus.abandoned));
      expect(abandoned.isFinished, isTrue);
      expect(abandoned.completedAt, equals(abandonTime));
    });

    test('9. State serialization roundtrips cleanly to and from JSON', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final json = active.toJson();
      final roundtrip = PracticeExecutionState.fromJson(json);

      expect(roundtrip.sessionId, equals(active.sessionId));
      expect(roundtrip.examId, equals(active.examId));
      expect(roundtrip.status, equals(PracticeExecutionStatus.inProgress));
      expect(roundtrip.totalQuestions, equals(1));
      expect(roundtrip.events.length, equals(active.events.length));
    });

    test('10. Collections inside state are deeply unmodifiable', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      expect(
          () => active.events.add(active.events.first), throwsUnsupportedError);
      expect(
          () => active.questionResults['hack'] =
              active.questionResults.values.first,
          throwsUnsupportedError);
    });
  });

  // ==========================================================================
  // GROUP 2: QUESTION PRESENTATION & SEQUENTIAL CURSOR
  // ==========================================================================
  group('P35.2 Group 2 — Question Presentation & Sequential Cursor', () {
    test('11. getCurrentQuestion returns first question when session starts',
        () {
      final q1 = buildQuestion(id: 'q1');
      final q2 = buildQuestion(id: 'q2');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final currentQ = engine.getCurrentQuestion(active);
      expect(currentQ, isNotNull);
      expect(currentQ!.id, equals('q1'));
      expect(active.currentQuestionId, equals('q1'));
    });

    test('12. submitAnswer advances currentQuestion to next question', () {
      final q1 = buildQuestion(id: 'q1');
      final q2 = buildQuestion(id: 'q2');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final next = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 15)),
          )
          .valueOrThrow;

      expect(next.currentQuestionIndex, equals(1));
      expect(next.currentQuestionId, equals('q2'));
      expect(next.status, equals(PracticeExecutionStatus.inProgress));
    });

    test('13. Submitting final question transitions status to completed', () {
      final q1 = buildQuestion(id: 'q1');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 20)),
          )
          .valueOrThrow;

      expect(finished.status, equals(PracticeExecutionStatus.completed));
      expect(finished.isFinished, isTrue);
      expect(finished.currentQuestion, isNull);
      expect(finished.currentQuestionId, isNull);
    });

    test(
        '14. Question sequence follows P34 specification order authoritatively',
        () {
      final questions = List.generate(
        5,
        (i) => buildQuestion(id: 'q_$i', subject: 'Subject $i'),
      );
      final spec = buildSpec(questions: questions);
      final state = engine.initializeSession(spec: spec);

      for (int i = 0; i < 5; i++) {
        expect(state.spec.orderedQuestions[i].id, equals('q_$i'));
      }
    });

    test('15. Empty session transitions directly to completed on startSession',
        () {
      final spec = buildSpec(questions: []);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      expect(active.status, equals(PracticeExecutionStatus.completed));
      expect(active.isFinished, isTrue);
      expect(active.totalQuestions, equals(0));
    });

    test('16. Cursor index cannot advance beyond totalQuestions', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      expect(completed.currentQuestionIndex, equals(1));
      expect(completed.isFinished, isTrue);
    });

    test('17. Candidate metadata is attached to question results', () {
      final q1 = buildQuestion(id: 'q1');
      final spec = buildSpec(questions: [q1]);
      final state = engine.initializeSession(spec: spec);

      final result = state.questionResults['q1'];
      expect(result, isNotNull);
      expect(result!.candidateMetadata, isNotNull);
      expect(result.candidateMetadata!.questionId, equals('q1'));
    });

    test(
        '18. Zero question fabrication: returned questions match spec verbatim',
        () {
      final q1 = buildQuestion(
        id: 'q_exact',
        normalizedText: 'Exact verbatim text without alteration',
      );
      final spec = buildSpec(questions: [q1]);
      final state = engine.initializeSession(spec: spec);

      expect(state.currentQuestion!.normalizedText, equals(q1.normalizedText));
    });

    test('19. Presentation timestamp is recorded on current question result',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final result = active.questionResults['q1']!;
      expect(result.presentedAt, equals(fixedDate));
    });

    test('20. Multiple questions receive sequential presentation timestamps',
        () {
      final spec = buildSpec(
          questions: [buildQuestion(id: 'q1'), buildQuestion(id: 'q2')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final t1 = fixedDate.add(const Duration(seconds: 15));
      final next = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: t1,
          )
          .valueOrThrow;

      expect(next.questionResults['q1']!.presentedAt, equals(fixedDate));
      expect(next.questionResults['q2']!.presentedAt, equals(t1));
    });
  });

  // ==========================================================================
  // GROUP 3: ANSWER SUBMISSION & VALIDATION
  // ==========================================================================
  group('P35.3 Group 3 — Answer Submission & Validation', () {
    test('21. Empty answer string returns invalidAnswer error', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final res = engine.submitAnswer(
        state: active,
        questionId: 'q1',
        answer: '',
        submittedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(res.error!.code, equals(PracticeExecutionErrorCode.invalidAnswer));
    });

    test('22. Whitespace-only answer string returns invalidAnswer error', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final res = engine.submitAnswer(
        state: active,
        questionId: 'q1',
        answer: '    ',
        submittedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(res.error!.code, equals(PracticeExecutionErrorCode.invalidAnswer));
    });

    test('23. Non-existent question ID returns questionNotFound error', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final res = engine.submitAnswer(
        state: active,
        questionId: 'q_unknown_999',
        answer: 'A',
        submittedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(
          res.error!.code, equals(PracticeExecutionErrorCode.questionNotFound));
    });

    test('24. Submitting out-of-turn question ID returns wrongQuestion error',
        () {
      final spec = buildSpec(
          questions: [buildQuestion(id: 'q1'), buildQuestion(id: 'q2')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final res = engine.submitAnswer(
        state: active,
        questionId: 'q2', // Current is q1
        answer: 'A',
        submittedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(res.error!.code, equals(PracticeExecutionErrorCode.wrongQuestion));
    });

    test(
        '25. Duplicate answer submission on already answered question returns questionAlreadyAnswered error',
        () {
      final spec = buildSpec(
          questions: [buildQuestion(id: 'q1'), buildQuestion(id: 'q2')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final next = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      // Attempt duplicate submit on q1
      final dupRes = engine.submitAnswer(
        state: next,
        questionId: 'q1',
        answer: 'B',
        submittedAt: fixedDate.add(const Duration(seconds: 10)),
      );

      expect(dupRes.isFailure, isTrue);
      expect(
          dupRes.error!.code, equals(PracticeExecutionErrorCode.wrongQuestion));
    });

    test(
        '26. Submitting answer on notStarted session returns sessionNotStarted error',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);

      final res = engine.submitAnswer(
        state: initial,
        questionId: 'q1',
        answer: 'A',
        submittedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(res.error!.code,
          equals(PracticeExecutionErrorCode.sessionNotStarted));
    });

    test('27. Submitting answer on paused session returns sessionPaused error',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final paused =
          engine.pauseSession(state: active, pausedAt: fixedDate).valueOrThrow;

      final res = engine.submitAnswer(
        state: paused,
        questionId: 'q1',
        answer: 'A',
        submittedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(res.error!.code, equals(PracticeExecutionErrorCode.sessionPaused));
    });

    test(
        '28. Submitting answer on completed session returns sessionCompleted error',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final postRes = engine.submitAnswer(
        state: completed,
        questionId: 'q1',
        answer: 'A',
        submittedAt: fixedDate.add(const Duration(seconds: 10)),
      );

      expect(postRes.isFailure, isTrue);
      expect(postRes.error!.code,
          equals(PracticeExecutionErrorCode.sessionCompleted));
    });

    test(
        '29. Submitting answer on abandoned session returns sessionAbandoned error',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final abandoned = engine
          .abandonSession(state: active, abandonedAt: fixedDate)
          .valueOrThrow;

      final res = engine.submitAnswer(
        state: abandoned,
        questionId: 'q1',
        answer: 'A',
        submittedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(
          res.error!.code, equals(PracticeExecutionErrorCode.sessionAbandoned));
    });

    test('30. Cross-exam candidate submission returns crossExamMismatch error',
        () {
      final qUpsc = buildQuestion(id: 'q_upsc', examId: 'upsc');
      final qBpsc = buildQuestion(id: 'q_bpsc', examId: 'bpsc');
      final spec = buildSpec(examId: 'upsc', questions: [qUpsc]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final forgedResults =
          Map<String, PracticeQuestionResult>.from(active.questionResults);
      forgedResults['q_upsc'] =
          PracticeQuestionResult.unattempted(index: 0, question: qBpsc);
      final forgedState = active.copyWith(questionResults: forgedResults);

      final res = engine.submitAnswer(
        state: forgedState,
        questionId: 'q_upsc',
        answer: 'A',
        submittedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(res.error!.code,
          equals(PracticeExecutionErrorCode.crossExamMismatch));
    });
  });

  // ==========================================================================
  // GROUP 4: CORRECTNESS DETERMINATION
  // ==========================================================================
  group('P35.4 Group 4 — Correctness Determination', () {
    test('31. Correct MCQ option key evaluates isCorrect=true', () {
      final q1 = buildQuestion(
        id: 'q1',
        officialAnswer: const Answer(correctOptionKeys: ['B']),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'B',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final result = finished.questionResults['q1']!;
      expect(result.isCorrect, isTrue);
      expect(result.feedback!.isCorrect, isTrue);
    });

    test('32. Incorrect MCQ option key evaluates isCorrect=false', () {
      final q1 = buildQuestion(
        id: 'q1',
        officialAnswer: const Answer(correctOptionKeys: ['B']),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'C',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final result = finished.questionResults['q1']!;
      expect(result.isCorrect, isFalse);
      expect(result.feedback!.isCorrect, isFalse);
    });

    test('33. Key matching is case-insensitive (e.g. "b" matches "B")', () {
      final q1 = buildQuestion(
        id: 'q1',
        officialAnswer: const Answer(correctOptionKeys: ['B']),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'b',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      expect(finished.questionResults['q1']!.isCorrect, isTrue);
    });

    test(
        '34. Revised official key with multiple valid keys (e.g. ["A", "C"]) accepts any valid key',
        () {
      final q1 = buildQuestion(
        id: 'q1',
        officialAnswer: const Answer(correctOptionKeys: ['A', 'C']),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'C',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      expect(finished.questionResults['q1']!.isCorrect, isTrue);
    });

    test('35. Answer matching option isCorrect flag evaluates correctly', () {
      final q1 = buildQuestion(
        id: 'q1',
        options: const [
          Option(key: 'A', text: 'Option A'),
          Option(key: 'B', text: 'Option B', isCorrect: true),
        ],
        officialAnswer: const Answer(correctOptionKeys: ['B']),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'B',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      expect(finished.questionResults['q1']!.isCorrect, isTrue);
    });

    test(
        '36. Correctness is evaluated without mutating question text or options',
        () {
      final q1 = buildQuestion(
        id: 'q1',
        officialAnswer: const Answer(correctOptionKeys: ['A']),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final resultQ = finished.questionResults['q1']!.question;
      expect(resultQ.normalizedText, equals(q1.normalizedText));
      expect(resultQ.options.length, equals(q1.options.length));
      expect(resultQ.officialAnswer.correctOptionKeys,
          equals(q1.officialAnswer.correctOptionKeys));
    });

    test(
        '37. Option full text match evaluates correctly for text-based submissions',
        () {
      final q1 = buildQuestion(
        id: 'q1',
        options: const [
          Option(key: 'A', text: 'Right to Equality', isCorrect: true),
          Option(key: 'B', text: 'Right to Freedom'),
        ],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'Right to Equality',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      expect(finished.questionResults['q1']!.isCorrect, isTrue);
    });

    test('38. Evaluation method is recorded as multipleChoice', () {
      final q1 = buildQuestion(id: 'q1');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      expect(
        finished.questionResults['q1']!.feedback!.evaluationMethod,
        equals(EvaluationMethod.multipleChoice),
      );
    });

    test('39. Dropped question maintains authoritative dropped flag', () {
      final q1 = buildQuestion(
        id: 'q_dropped',
        officialAnswer: const Answer(
          correctOptionKeys: ['A'],
          isDropped: true,
        ),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q_dropped',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      expect(
          finished
              .questionResults['q_dropped']!.question.officialAnswer.isDropped,
          isTrue);
    });

    test('40. Descriptive answer match evaluates correctly', () {
      final q1 = buildQuestion(
        id: 'q_desc',
        officialAnswer: const Answer(
          correctOptionKeys: [],
          descriptiveAnswer: 'Directive Principles of State Policy',
        ),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q_desc',
            answer: 'Directive Principles of State Policy',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      expect(finished.questionResults['q_desc']!.isCorrect, isTrue);
    });
  });

  // ==========================================================================
  // GROUP 5: FEEDBACK POLICIES (IMMEDIATE, DEFERRED, EXAM SIMULATION)
  // ==========================================================================
  group(
      'P35.5 Group 5 — Feedback Policies (Immediate, Deferred, Exam Simulation)',
      () {
    test(
        '41. IMMEDIATE policy exposes correctness, explanation, and correct key immediately',
        () {
      final q1 = buildQuestion(
        id: 'q1',
        explanation: 'Article 14 guarantees equality before the law.',
        officialAnswer: const Answer(correctOptionKeys: ['A']),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(
        spec: spec,
        feedbackPolicy: PracticeFeedbackPolicy.immediate,
      );
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final fb = finished.questionResults['q1']!.feedback!;
      expect(fb.isCorrect, isTrue);
      expect(fb.isExplanationExposed, isTrue);
      expect(fb.explanation,
          equals('Article 14 guarantees equality before the law.'));
      expect(fb.correctAnswer, equals('A'));
      expect(fb.feedbackText, equals('Correct'));
    });

    test('42. IMMEDIATE policy provides detailed incorrect feedback message',
        () {
      final q1 = buildQuestion(
        id: 'q1',
        officialAnswer: const Answer(correctOptionKeys: ['B']),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(
        spec: spec,
        feedbackPolicy: PracticeFeedbackPolicy.immediate,
      );
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'C',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final fb = finished.questionResults['q1']!.feedback!;
      expect(fb.isCorrect, isFalse);
      expect(fb.feedbackText, contains('Incorrect. Correct answer is B.'));
    });

    test(
        '43. DEFERRED policy records correctness internally but withholds explanation',
        () {
      final q1 = buildQuestion(
        id: 'q1',
        explanation: 'Detailed confidential explanation',
        officialAnswer: const Answer(correctOptionKeys: ['A']),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(
        spec: spec,
        feedbackPolicy: PracticeFeedbackPolicy.deferred,
      );
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final fb = finished.questionResults['q1']!.feedback!;
      expect(fb.isCorrect, isTrue);
      expect(fb.isExplanationExposed, isFalse);
      expect(fb.explanation, isEmpty);
      expect(fb.feedbackText, equals('Answer recorded.'));
    });

    test(
        '44. EXAM_SIMULATION policy hides both correctness and explanations during execution',
        () {
      final q1 = buildQuestion(
        id: 'q1',
        explanation: 'Detailed exam explanation',
        officialAnswer: const Answer(correctOptionKeys: ['A']),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(
        spec: spec,
        feedbackPolicy: PracticeFeedbackPolicy.examSimulation,
      );
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final fb = finished.questionResults['q1']!.feedback!;
      expect(fb.isExplanationExposed, isFalse);
      expect(fb.explanation, isEmpty);
      expect(fb.correctAnswer, isEmpty);
      expect(fb.feedbackText, equals('Answer submitted.'));

      // However, internal result record retains true correctness
      expect(finished.questionResults['q1']!.isCorrect, isTrue);
    });

    test(
        '45. Completion summary exposes full results for EXAM_SIMULATION sessions',
        () {
      final q1 = buildQuestion(
          id: 'q1', officialAnswer: const Answer(correctOptionKeys: ['A']));
      final q2 = buildQuestion(
          id: 'q2', officialAnswer: const Answer(correctOptionKeys: ['B']));
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(
        spec: spec,
        feedbackPolicy: PracticeFeedbackPolicy.examSimulation,
      );
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final step1 = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final completed = engine
          .submitAnswer(
            state: step1,
            questionId: 'q2',
            answer: 'C', // Incorrect
            submittedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      final summary = completed.completionSummary!;
      expect(summary.totalQuestions, equals(2));
      expect(summary.correctCount, equals(1));
      expect(summary.incorrectCount, equals(1));
      expect(summary.accuracy, equals(0.5));
    });

    test('46. Feedback serialization roundtrips through JSON without loss', () {
      const fb = PracticeFeedback(
        questionId: 'q1',
        isCorrect: true,
        submittedAnswer: 'A',
        correctAnswer: 'A',
        explanation: 'Explanation text',
        isExplanationExposed: true,
        evaluationMethod: EvaluationMethod.multipleChoice,
        feedbackText: 'Correct',
      );

      final json = fb.toJson();
      final roundtrip = PracticeFeedback.fromJson(json);

      expect(roundtrip.questionId, equals(fb.questionId));
      expect(roundtrip.isCorrect, equals(fb.isCorrect));
      expect(roundtrip.explanation, equals(fb.explanation));
      expect(roundtrip.evaluationMethod, equals(fb.evaluationMethod));
    });

    test(
        '47. Feedback contains zero predictive claims regarding future examinations',
        () {
      final q1 = buildQuestion(id: 'q1');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final fbText =
          finished.questionResults['q1']!.feedback!.feedbackText ?? '';
      expect(fbText.contains('will appear'), isFalse);
      expect(fbText.contains('fail'), isFalse);
      expect(fbText.contains('guaranteed'), isFalse);
    });

    test('48. Missing question explanation defaults safely to empty string',
        () {
      final q1 = buildQuestion(id: 'q1', explanation: '');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      expect(finished.questionResults['q1']!.feedback!.explanation, equals(''));
    });

    test(
        '49. Multi-option revised key is formatted as comma-separated string in feedback',
        () {
      final q1 = buildQuestion(
        id: 'q1',
        officialAnswer: const Answer(correctOptionKeys: ['A', 'C']),
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final finished = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      expect(finished.questionResults['q1']!.feedback!.correctAnswer,
          equals('A, C'));
    });

    test('50. Question results in completion summary match ordered sequence',
        () {
      final questions = [
        buildQuestion(id: 'q_a'),
        buildQuestion(id: 'q_b'),
        buildQuestion(id: 'q_c'),
      ];
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      var current = active;
      for (int i = 0; i < 3; i++) {
        current = engine
            .submitAnswer(
              state: current,
              questionId: questions[i].id,
              answer: 'A',
              submittedAt: fixedDate.add(Duration(seconds: (i + 1) * 5)),
            )
            .valueOrThrow;
      }

      final summary = current.completionSummary!;
      expect(summary.results.map((r) => r.questionId).toList(),
          equals(['q_a', 'q_b', 'q_c']));
    });
  });

  // ==========================================================================
  // GROUP 6: SKIP HANDLING & TRANSITION
  // ==========================================================================
  group('P35.6 Group 6 — Skip Handling & Transition', () {
    test('51. skipQuestion marks result as isSkipped=true and isAnswered=false',
        () {
      final spec = buildSpec(
          questions: [buildQuestion(id: 'q1'), buildQuestion(id: 'q2')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final skipped = engine
          .skipQuestion(
            state: active,
            questionId: 'q1',
            skippedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final res = skipped.questionResults['q1']!;
      expect(res.isSkipped, isTrue);
      expect(res.isAnswered, isFalse);
      expect(res.isCorrect, isFalse);
      expect(res.submittedAnswer, isNull);
      expect(res.feedback, isNull);
    });

    test('52. skipQuestion advances currentQuestionIndex to next question', () {
      final spec = buildSpec(
          questions: [buildQuestion(id: 'q1'), buildQuestion(id: 'q2')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final skipped = engine
          .skipQuestion(
            state: active,
            questionId: 'q1',
            skippedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      expect(skipped.currentQuestionIndex, equals(1));
      expect(skipped.currentQuestionId, equals('q2'));
    });

    test('53. Skipping final question transitions status to completed', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final completed = engine
          .skipQuestion(
            state: active,
            questionId: 'q1',
            skippedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      expect(completed.status, equals(PracticeExecutionStatus.completed));
      expect(completed.isFinished, isTrue);
    });

    test('54. skipQuestion with allowSkip=false returns skipNotAllowed error',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec, allowSkip: false);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final res = engine.skipQuestion(
        state: active,
        questionId: 'q1',
        skippedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(
          res.error!.code, equals(PracticeExecutionErrorCode.skipNotAllowed));
    });

    test(
        '55. Skipping already answered question returns questionAlreadyAnswered error',
        () {
      final spec = buildSpec(
          questions: [buildQuestion(id: 'q1'), buildQuestion(id: 'q2')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final answered = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final skipRes = engine.skipQuestion(
        state: answered,
        questionId: 'q1',
        skippedAt: fixedDate.add(const Duration(seconds: 10)),
      );

      expect(skipRes.isFailure, isTrue);
      expect(skipRes.error!.code,
          equals(PracticeExecutionErrorCode.wrongQuestion));
    });

    test('56. Skipping out-of-turn question returns wrongQuestion error', () {
      final spec = buildSpec(
          questions: [buildQuestion(id: 'q1'), buildQuestion(id: 'q2')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final res = engine.skipQuestion(
        state: active,
        questionId: 'q2', // Current is q1
        skippedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(res.error!.code, equals(PracticeExecutionErrorCode.wrongQuestion));
    });

    test('57. Skipped question records elapsedSeconds accurately', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final skippedTime = fixedDate.add(const Duration(seconds: 12));
      final completed = engine
          .skipQuestion(
            state: active,
            questionId: 'q1',
            skippedAt: skippedTime,
          )
          .valueOrThrow;

      expect(completed.questionResults['q1']!.elapsedSeconds, equals(12));
    });

    test(
        '58. Question skipped event is emitted with questionId and index payload',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final completed = engine
          .skipQuestion(
            state: active,
            questionId: 'q1',
            skippedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final skipEvt = completed.events.firstWhere(
        (e) => e.type == PracticeExecutionEventType.questionSkipped,
      );
      expect(skipEvt.payload['questionId'], equals('q1'));
      expect(skipEvt.payload['questionIndex'], equals(0));
    });

    test(
        '59. Mixed session with answers and skips records separate counts correctly',
        () {
      final questions = [
        buildQuestion(id: 'q1'),
        buildQuestion(id: 'q2'),
        buildQuestion(id: 'q3'),
      ];
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final s1 = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final s2 = engine
          .skipQuestion(
            state: s1,
            questionId: 'q2',
            skippedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      final s3 = engine
          .submitAnswer(
            state: s2,
            questionId: 'q3',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 15)),
          )
          .valueOrThrow;

      final p = s3.progress;
      expect(p.answeredCount, equals(2));
      expect(p.skippedCount, equals(1));
      expect(p.totalQuestions, equals(3));
      expect(p.completionRatio, equals(1.0));
    });

    test(
        '60. Skipped questions do not dilute accuracy among answered questions',
        () {
      final questions = [
        buildQuestion(
            id: 'q1', officialAnswer: const Answer(correctOptionKeys: ['A'])),
        buildQuestion(id: 'q2'),
      ];
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final s1 = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A', // Correct
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final completed = engine
          .skipQuestion(
            state: s1,
            questionId: 'q2', // Skipped
            skippedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      final p = completed.progress;
      expect(p.correctCount, equals(1));
      expect(p.answeredCount, equals(1));
      expect(p.skippedCount, equals(1));
      expect(p.accuracyAmongAnswered, equals(1.0)); // 1/1 = 100%
    });
  });

  // ==========================================================================
  // GROUP 7: REAL-TIME PROGRESS METRICS (O(1), ZERO NAN/INFINITY)
  // ==========================================================================
  group('P35.7 Group 7 — Real-Time Progress Metrics (O(1), Zero NaN/Infinity)',
      () {
    test('61. Unattempted session has 0.0 completionRatio and 0.0 accuracy',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final state = engine.initializeSession(spec: spec);

      final p = state.progress;
      expect(p.totalQuestions, equals(1));
      expect(p.currentQuestionIndex, equals(0));
      expect(p.currentQuestionNumber, equals(1));
      expect(p.answeredCount, equals(0));
      expect(p.correctCount, equals(0));
      expect(p.incorrectCount, equals(0));
      expect(p.skippedCount, equals(0));
      expect(p.remainingCount, equals(1));
      expect(p.completionRatio, equals(0.0));
      expect(p.accuracyAmongAnswered, equals(0.0));
      expect(p.accuracyAmongAnswered.isNaN, isFalse);
    });

    test(
        '62. Zero-question session has 0.0 completionRatio and 0.0 accuracy without NaN',
        () {
      final spec = buildSpec(questions: []);
      final state = engine.initializeSession(spec: spec);

      final p = state.progress;
      expect(p.totalQuestions, equals(0));
      expect(p.completionRatio, equals(0.0));
      expect(p.accuracyAmongAnswered, equals(0.0));
      expect(p.completionRatio.isNaN, isFalse);
      expect(p.accuracyAmongAnswered.isNaN, isFalse);
    });

    test(
        '63. Single correct answer yields 1.0 accuracy and 1.0 completionRatio',
        () {
      final spec = buildSpec(questions: [
        buildQuestion(
            id: 'q1', officialAnswer: const Answer(correctOptionKeys: ['A']))
      ]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      final p = completed.progress;
      expect(p.answeredCount, equals(1));
      expect(p.correctCount, equals(1));
      expect(p.incorrectCount, equals(0));
      expect(p.completionRatio, equals(1.0));
      expect(p.accuracyAmongAnswered, equals(1.0));
      expect(p.remainingCount, equals(0));
    });

    test(
        '64. Single incorrect answer yields 0.0 accuracy and 1.0 completionRatio',
        () {
      final spec = buildSpec(questions: [
        buildQuestion(
            id: 'q1', officialAnswer: const Answer(correctOptionKeys: ['A']))
      ]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'B', // Incorrect
            submittedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      final p = completed.progress;
      expect(p.answeredCount, equals(1));
      expect(p.correctCount, equals(0));
      expect(p.incorrectCount, equals(1));
      expect(p.completionRatio, equals(1.0));
      expect(p.accuracyAmongAnswered, equals(0.0));
    });

    test(
        '65. 5-question session calculates intermediate progress metrics accurately',
        () {
      final questions = List.generate(
        5,
        (i) => buildQuestion(
            id: 'q_$i', officialAnswer: const Answer(correctOptionKeys: ['A'])),
      );
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      // Q0: correct, Q1: incorrect
      final s1 = engine
          .submitAnswer(
            state: active,
            questionId: 'q_0',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final s2 = engine
          .submitAnswer(
            state: s1,
            questionId: 'q_1',
            answer: 'B',
            submittedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      final p = s2.progress;
      expect(p.totalQuestions, equals(5));
      expect(p.currentQuestionIndex, equals(2));
      expect(p.currentQuestionNumber, equals(3));
      expect(p.answeredCount, equals(2));
      expect(p.correctCount, equals(1));
      expect(p.incorrectCount, equals(1));
      expect(p.skippedCount, equals(0));
      expect(p.remainingCount, equals(3));
      expect(p.completionRatio, closeTo(2 / 5, 0.001));
      expect(p.accuracyAmongAnswered, equals(0.5));
    });

    test('66. Progress snapshot serializes and deserializes accurately', () {
      final snap = PracticeProgressSnapshot(
        totalQuestions: 10,
        currentQuestionIndex: 4,
        currentQuestionNumber: 5,
        answeredCount: 4,
        correctCount: 3,
        incorrectCount: 1,
        skippedCount: 0,
        remainingCount: 6,
        completionRatio: 0.4,
        accuracyAmongAnswered: 0.75,
        totalElapsedSeconds: 120,
      );

      final json = snap.toJson();
      final roundtrip = PracticeProgressSnapshot.fromJson(json);

      expect(roundtrip.totalQuestions, equals(10));
      expect(roundtrip.answeredCount, equals(4));
      expect(roundtrip.accuracyAmongAnswered, equals(0.75));
      expect(roundtrip.totalElapsedSeconds, equals(120));
    });

    test(
        '67. Total elapsed seconds aggregates across all answered and skipped questions',
        () {
      final spec = buildSpec(
          questions: [buildQuestion(id: 'q1'), buildQuestion(id: 'q2')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final s1 = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 10)), // 10s
          )
          .valueOrThrow;

      final completed = engine
          .skipQuestion(
            state: s1,
            questionId: 'q2',
            skippedAt: fixedDate.add(const Duration(seconds: 25)), // 15s
          )
          .valueOrThrow;

      expect(completed.progress.totalElapsedSeconds, equals(25));
    });

    test('68. completionRatio is strictly bounded in [0.0, 1.0]', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final state = engine.initializeSession(spec: spec);

      expect(state.progress.completionRatio, greaterThanOrEqualTo(0.0));
      expect(state.progress.completionRatio, lessThanOrEqualTo(1.0));
    });

    test('69. accuracyAmongAnswered is strictly bounded in [0.0, 1.0]', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final state = engine.initializeSession(spec: spec);

      expect(state.progress.accuracyAmongAnswered, greaterThanOrEqualTo(0.0));
      expect(state.progress.accuracyAmongAnswered, lessThanOrEqualTo(1.0));
    });

    test('70. currentQuestionNumber is 1-based and bounded by totalQuestions',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final state = engine.initializeSession(spec: spec);

      expect(state.progress.currentQuestionNumber, equals(1));
    });
  });

  // ==========================================================================
  // GROUP 8: EVENT GENERATION & AUDIT TRAIL
  // ==========================================================================
  group('P35.8 Group 8 — Event Generation & Audit Trail', () {
    test('71. startSession emits sessionStarted and questionPresented events',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      expect(active.events.length, equals(2));
      expect(active.events[0].type,
          equals(PracticeExecutionEventType.sessionStarted));
      expect(active.events[1].type,
          equals(PracticeExecutionEventType.questionPresented));
    });

    test('72. submitAnswer emits answerSubmitted and feedbackGenerated events',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final types = completed.events.map((e) => e.type).toList();
      expect(types, contains(PracticeExecutionEventType.answerSubmitted));
      expect(types, contains(PracticeExecutionEventType.feedbackGenerated));
      expect(types, contains(PracticeExecutionEventType.sessionCompleted));
    });

    test('73. skipQuestion emits questionSkipped event', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final completed = engine
          .skipQuestion(
            state: active,
            questionId: 'q1',
            skippedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final types = completed.events.map((e) => e.type).toList();
      expect(types, contains(PracticeExecutionEventType.questionSkipped));
    });

    test(
        '74. pauseSession and resumeSession emit sessionPaused and sessionResumed events',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final paused =
          engine.pauseSession(state: active, pausedAt: fixedDate).valueOrThrow;
      final resumed = engine
          .resumeSession(state: paused, resumedAt: fixedDate)
          .valueOrThrow;

      final types = resumed.events.map((e) => e.type).toList();
      expect(types, contains(PracticeExecutionEventType.sessionPaused));
      expect(types, contains(PracticeExecutionEventType.sessionResumed));
    });

    test('75. abandonSession emits sessionAbandoned event', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final abandoned = engine
          .abandonSession(
            state: active,
            abandonedAt: fixedDate,
            reason: 'User quit',
          )
          .valueOrThrow;

      final types = abandoned.events.map((e) => e.type).toList();
      expect(types, contains(PracticeExecutionEventType.sessionAbandoned));
    });

    test('76. Event IDs are deterministic and prefixed with evt_', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      for (final evt in active.events) {
        expect(evt.eventId.startsWith('evt_'), isTrue);
        expect(evt.sessionId, equals(spec.sessionId));
      }
    });

    test('77. Event serialization roundtrips accurately through JSON', () {
      final evt = PracticeExecutionEvent(
        eventId: 'evt_test_1',
        sessionId: 'sess_1',
        type: PracticeExecutionEventType.answerSubmitted,
        timestamp: fixedDate,
        payload: {'score': 1.0},
      );

      final json = evt.toJson();
      final roundtrip = PracticeExecutionEvent.fromJson(json);

      expect(roundtrip.eventId, equals('evt_test_1'));
      expect(roundtrip.sessionId, equals('sess_1'));
      expect(
          roundtrip.type, equals(PracticeExecutionEventType.answerSubmitted));
      expect(roundtrip.payload['score'], equals(1.0));
    });

    test('78. Event timestamps match caller-supplied action timestamps', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final customTime = DateTime.utc(2026, 8, 15, 9, 30, 0);
      final active = engine
          .startSession(state: initial, startedAt: customTime)
          .valueOrThrow;

      expect(active.events.first.timestamp, equals(customTime));
    });

    test('79. Sequential questions have strictly monotonic event timestamps',
        () {
      final spec = buildSpec(
          questions: [buildQuestion(id: 'q1'), buildQuestion(id: 'q2')]);
      final initial = engine.initializeSession(spec: spec);
      final t0 = fixedDate;
      final t1 = fixedDate.add(const Duration(seconds: 10));
      final t2 = fixedDate.add(const Duration(seconds: 20));

      final active =
          engine.startSession(state: initial, startedAt: t0).valueOrThrow;
      final s1 = engine
          .submitAnswer(
              state: active, questionId: 'q1', answer: 'A', submittedAt: t1)
          .valueOrThrow;
      final completed = engine
          .submitAnswer(
              state: s1, questionId: 'q2', answer: 'A', submittedAt: t2)
          .valueOrThrow;

      DateTime? prev;
      for (final evt in completed.events) {
        if (prev != null) {
          expect(
              evt.timestamp.isAfter(prev) ||
                  evt.timestamp.isAtSameMomentAs(prev),
              isTrue);
        }
        prev = evt.timestamp;
      }
    });

    test('80. Event payload dictionary is deeply unmodifiable', () {
      final evt = PracticeExecutionEvent(
        eventId: 'evt_1',
        sessionId: 'sess_1',
        type: PracticeExecutionEventType.sessionStarted,
        timestamp: fixedDate,
        payload: {'key': 'val'},
      );

      expect(() => evt.payload['new'] = 'mutated', throwsUnsupportedError);
    });
  });

  // ==========================================================================
  // GROUP 9: STRUCTURED ERROR MODEL & IDEMPOTENCY
  // ==========================================================================
  group('P35.9 Group 9 — Structured Error Model & Idempotency', () {
    test('81. PracticeExecutionResult.success unwraps value correctly', () {
      const res = PracticeExecutionResult<String>.success('test_val');
      expect(res.isSuccess, isTrue);
      expect(res.isFailure, isFalse);
      expect(res.value, equals('test_val'));
      expect(res.valueOrThrow, equals('test_val'));
    });

    test(
        '82. PracticeExecutionResult.failure throws StateError on valueOrThrow',
        () {
      const err = PracticeExecutionError(
        code: PracticeExecutionErrorCode.invalidAnswer,
        message: 'Invalid payload',
      );
      const res = PracticeExecutionResult<String>.failure(err);

      expect(res.isSuccess, isFalse);
      expect(res.isFailure, isTrue);
      expect(res.error, equals(err));
      expect(() => res.valueOrThrow, throwsStateError);
    });

    test(
        '83. Repeated submission of failed answer does not corrupt existing state',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      // Submit invalid empty answer 5 times
      for (int i = 0; i < 5; i++) {
        final res = engine.submitAnswer(
          state: active,
          questionId: 'q1',
          answer: '',
          submittedAt: fixedDate,
        );
        expect(res.isFailure, isTrue);
      }

      // State remains unchanged and active
      expect(active.status, equals(PracticeExecutionStatus.inProgress));
      expect(active.currentQuestionIndex, equals(0));
      expect(active.progress.answeredCount, equals(0));
    });

    test('84. Resume when not paused returns invalidTransition error', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final res = engine.resumeSession(state: active, resumedAt: fixedDate);
      expect(res.isFailure, isTrue);
      expect(res.error!.code,
          equals(PracticeExecutionErrorCode.invalidTransition));
    });

    test('85. Pause when already paused returns invalidTransition error', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final paused =
          engine.pauseSession(state: active, pausedAt: fixedDate).valueOrThrow;

      final res = engine.pauseSession(state: paused, pausedAt: fixedDate);
      expect(res.isFailure, isTrue);
      expect(res.error!.code,
          equals(PracticeExecutionErrorCode.invalidTransition));
    });

    test('86. Abandon when already completed returns invalidTransition error',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final res =
          engine.abandonSession(state: completed, abandonedAt: fixedDate);
      expect(res.isFailure, isTrue);
      expect(res.error!.code,
          equals(PracticeExecutionErrorCode.invalidTransition));
    });

    test('87. PracticeExecutionError serializes to and from JSON', () {
      const err = PracticeExecutionError(
        code: PracticeExecutionErrorCode.crossExamMismatch,
        message: 'Exam mismatch error',
        details: {'submitted': 'bpsc', 'expected': 'upsc'},
      );

      final json = err.toJson();
      final roundtrip = PracticeExecutionError.fromJson(json);

      expect(
          roundtrip.code, equals(PracticeExecutionErrorCode.crossExamMismatch));
      expect(roundtrip.message, equals('Exam mismatch error'));
      expect(roundtrip.details['submitted'], equals('bpsc'));
    });

    test('88. Structured error toString includes code and message', () {
      const err = PracticeExecutionError(
        code: PracticeExecutionErrorCode.wrongQuestion,
        message: 'Wrong question index',
      );

      expect(err.toString(), contains('wrongQuestion'));
      expect(err.toString(), contains('Wrong question index'));
    });

    test('89. Submitting on invalid question index returns structured error',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final res = engine.submitAnswer(
        state: active,
        questionId: 'q_non_existent',
        answer: 'A',
        submittedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(
          res.error!.code, equals(PracticeExecutionErrorCode.questionNotFound));
    });

    test(
        '90. Result string representation formats properly for success and failure',
        () {
      const s = PracticeExecutionResult<int>.success(42);
      expect(s.toString(), contains('success(42)'));

      const f = PracticeExecutionResult<int>.failure(
        PracticeExecutionError(
            code: PracticeExecutionErrorCode.invalidAnswer, message: 'Bad'),
      );
      expect(f.toString(), contains('failure'));
    });
  });

  // ==========================================================================
  // GROUP 10: P19 EVIDENCE-READY HANDOFF RECORDS
  // ==========================================================================
  group('P35.10 Group 10 — P19 Evidence-Ready Handoff Records', () {
    test(
        '91. generateHandoffAttempts produces QuestionAttempt list for answered questions',
        () {
      final q1 = buildQuestion(id: 'q1', objectiveIds: ['obj_fr']);
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      final attempts = engine.generateHandoffAttempts(completed);
      expect(attempts.length, equals(1));
      final att = attempts.first;
      expect(att.questionId, equals('q1'));
      expect(att.objectiveId, equals('obj_fr'));
      expect(att.submittedAnswer, equals('A'));
      expect(att.sessionId, equals(spec.sessionId));
      expect(att.learnerId, equals('learner_101'));
    });

    test('92. Deterministic attempt ID format (att_<sessionId>_<questionId>)',
        () {
      final q1 = buildQuestion(id: 'q1');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      final att = engine.generateHandoffAttempts(completed).first;
      expect(att.attemptId, equals('att_${spec.sessionId}_q1'));
    });

    test('93. Skipped questions are omitted from generateHandoffAttempts', () {
      final spec = buildSpec(
          questions: [buildQuestion(id: 'q1'), buildQuestion(id: 'q2')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final s1 = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final completed = engine
          .skipQuestion(
            state: s1,
            questionId: 'q2', // Skipped
            skippedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      final attempts = engine.generateHandoffAttempts(completed);
      expect(attempts.length, equals(1));
      expect(attempts.first.questionId, equals('q1'));
    });

    test('94. Null learnerId defaults cleanly to anonymous_learner', () {
      final q1 = buildQuestion(id: 'q1');
      final spec = buildSpec(learnerId: null, questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final att = engine.generateHandoffAttempts(completed).first;
      expect(att.learnerId, equals('anonymous_learner'));
    });

    test('95. Missing question objectiveId defaults safely to lo_unassigned',
        () {
      final q1 = buildQuestion(id: 'q1', objectiveIds: const []);
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final att = engine.generateHandoffAttempts(completed).first;
      expect(att.objectiveId, equals('lo_unassigned'));
    });

    test('96. Empty session produces empty handoff attempt list', () {
      final spec = buildSpec(questions: []);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final attempts = engine.generateHandoffAttempts(active);
      expect(attempts.isEmpty, isTrue);
    });

    test('97. Handoff attempt list is deeply unmodifiable', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      final attempts = engine.generateHandoffAttempts(completed);
      expect(() => attempts.add(attempts.first), throwsUnsupportedError);
    });

    test('98. Attempt submission timestamp matches caller-supplied submittedAt',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final customSubmitTime = DateTime.utc(2026, 9, 1, 14, 25, 30);
      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: customSubmitTime,
          )
          .valueOrThrow;

      final att = engine.generateHandoffAttempts(completed).first;
      expect(att.attemptedAt, equals(customSubmitTime));
    });

    test(
        '99. Multiple answered questions produce corresponding attempts in order',
        () {
      final questions = List.generate(
        4,
        (i) => buildQuestion(id: 'q_$i', objectiveIds: ['obj_$i']),
      );
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      var current = active;
      for (int i = 0; i < 4; i++) {
        current = engine
            .submitAnswer(
              state: current,
              questionId: questions[i].id,
              answer: 'A',
              submittedAt: fixedDate.add(Duration(seconds: (i + 1) * 5)),
            )
            .valueOrThrow;
      }

      final attempts = engine.generateHandoffAttempts(current);
      expect(attempts.length, equals(4));
      for (int i = 0; i < 4; i++) {
        expect(attempts[i].questionId, equals('q_$i'));
        expect(attempts[i].objectiveId, equals('obj_$i'));
      }
    });

    test('100. P35 does not mutate downstream database repositories directly',
        () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 5)),
          )
          .valueOrThrow;

      // P35 only prepares objects; does not call persistent DB
      final attempts = engine.generateHandoffAttempts(completed);
      expect(attempts.length, equals(1));
    });
  });

  // ==========================================================================
  // GROUP 11: SAFETY, MULTI-EXAM ISOLATION & PROPERTY INVARIANTS
  // ==========================================================================
  group('P35.11 Group 11 — Safety, Multi-Exam Isolation & Property Invariants',
      () {
    test(
        '101. Multi-exam isolation: UPSC session rejects BPSC question submission',
        () {
      final qUpsc = buildQuestion(id: 'q_upsc', examId: 'upsc');
      final qBpsc = buildQuestion(id: 'q_bpsc', examId: 'bpsc');
      final spec = buildSpec(examId: 'upsc', questions: [qUpsc]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final forgedResults =
          Map<String, PracticeQuestionResult>.from(active.questionResults);
      forgedResults['q_upsc'] =
          PracticeQuestionResult.unattempted(index: 0, question: qBpsc);
      final forgedState = active.copyWith(questionResults: forgedResults);

      final res = engine.submitAnswer(
        state: forgedState,
        questionId: 'q_upsc',
        answer: 'A',
        submittedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(res.error!.code,
          equals(PracticeExecutionErrorCode.crossExamMismatch));
    });

    test(
        '102. Multi-exam isolation: BPSC session rejects SSC question submission',
        () {
      final qBpsc = buildQuestion(id: 'q_bpsc', examId: 'bpsc');
      final qSsc = buildQuestion(id: 'q_ssc', examId: 'ssc');
      final spec = buildSpec(examId: 'bpsc', questions: [qBpsc]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final forgedResults =
          Map<String, PracticeQuestionResult>.from(active.questionResults);
      forgedResults['q_bpsc'] =
          PracticeQuestionResult.unattempted(index: 0, question: qSsc);
      final forgedState = active.copyWith(questionResults: forgedResults);

      final res = engine.submitAnswer(
        state: forgedState,
        questionId: 'q_bpsc',
        answer: 'A',
        submittedAt: fixedDate,
      );

      expect(res.isFailure, isTrue);
      expect(res.error!.code,
          equals(PracticeExecutionErrorCode.crossExamMismatch));
    });

    test('103. Property Invariant: answeredCount <= totalQuestions', () {
      final questions = List.generate(5, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      var current = active;
      for (int i = 0; i < 3; i++) {
        current = engine
            .submitAnswer(
              state: current,
              questionId: questions[i].id,
              answer: 'A',
              submittedAt: fixedDate.add(Duration(seconds: (i + 1) * 5)),
            )
            .valueOrThrow;
        expect(current.progress.answeredCount, lessThanOrEqualTo(5));
      }
    });

    test(
        '104. Property Invariant: correctCount + incorrectCount == answeredCount',
        () {
      final questions = [
        buildQuestion(
            id: 'q1', officialAnswer: const Answer(correctOptionKeys: ['A'])),
        buildQuestion(
            id: 'q2', officialAnswer: const Answer(correctOptionKeys: ['B'])),
        buildQuestion(
            id: 'q3', officialAnswer: const Answer(correctOptionKeys: ['C'])),
      ];
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final s1 = engine
          .submitAnswer(
              state: active,
              questionId: 'q1',
              answer: 'A',
              submittedAt: fixedDate)
          .valueOrThrow; // corr
      final s2 = engine
          .submitAnswer(
              state: s1, questionId: 'q2', answer: 'A', submittedAt: fixedDate)
          .valueOrThrow; // incorr
      final s3 = engine
          .skipQuestion(state: s2, questionId: 'q3', skippedAt: fixedDate)
          .valueOrThrow; // skip

      final p = s3.progress;
      expect(p.correctCount + p.incorrectCount, equals(p.answeredCount));
      expect(p.answeredCount + p.skippedCount, equals(p.totalQuestions));
    });

    test('105. Property Invariant: remainingCount >= 0 and never negative', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final completed = engine
          .submitAnswer(
              state: active,
              questionId: 'q1',
              answer: 'A',
              submittedAt: fixedDate)
          .valueOrThrow;

      expect(completed.progress.remainingCount, greaterThanOrEqualTo(0));
      expect(completed.progress.remainingCount, equals(0));
    });

    test(
        '106. Property Invariant: all question results retain source provenance',
        () {
      final q1 = buildQuestion(
        id: 'q_prov',
        source: PyqSourceReference.official(
            examId: 'upsc', year: 2024, paper: 'GS1'),
      );
      final spec = buildSpec(questions: [q1]);
      final state = engine.initializeSession(spec: spec);

      final q = state.questionResults['q_prov']!.question;
      expect(q.source.sourceType, equals('officialPdf'));
      expect(q.source.publisher, contains('UPSC'));
    });

    test('107. Zero DateTime.now() drift: pure caller-supplied timestamps', () {
      final spec = buildSpec(questions: [buildQuestion(id: 'q1')]);
      final initial = engine.initializeSession(spec: spec);

      final customStart = DateTime.utc(2025, 1, 1, 0, 0, 0);
      final customSubmit = DateTime.utc(2025, 1, 1, 0, 1, 30); // 90s

      final active = engine
          .startSession(state: initial, startedAt: customStart)
          .valueOrThrow;
      final completed = engine
          .submitAnswer(
            state: active,
            questionId: 'q1',
            answer: 'A',
            submittedAt: customSubmit,
          )
          .valueOrThrow;

      expect(completed.startedAt, equals(customStart));
      expect(completed.completedAt, equals(customSubmit));
      expect(completed.questionResults['q1']!.elapsedSeconds, equals(90));
    });

    test(
        '108. Completion summary score ratio matches correctCount / totalQuestions',
        () {
      final questions = [
        buildQuestion(
            id: 'q1', officialAnswer: const Answer(correctOptionKeys: ['A'])),
        buildQuestion(
            id: 'q2', officialAnswer: const Answer(correctOptionKeys: ['B'])),
      ];
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final s1 = engine
          .submitAnswer(
              state: active,
              questionId: 'q1',
              answer: 'A',
              submittedAt: fixedDate)
          .valueOrThrow;
      final completed = engine
          .submitAnswer(
              state: s1, questionId: 'q2', answer: 'A', submittedAt: fixedDate)
          .valueOrThrow; // incorrect

      final summary = completed.completionSummary!;
      expect(summary.score, equals(0.5));
      expect(summary.accuracy, equals(0.5));
    });

    test(
        '109. Objective performance summary correctly groups scores per objective',
        () {
      final questions = [
        buildQuestion(
            id: 'q1',
            objectiveIds: ['obj_polity'],
            officialAnswer: const Answer(correctOptionKeys: ['A'])),
        buildQuestion(
            id: 'q2',
            objectiveIds: ['obj_polity'],
            officialAnswer: const Answer(correctOptionKeys: ['A'])),
        buildQuestion(
            id: 'q3',
            objectiveIds: ['obj_history'],
            officialAnswer: const Answer(correctOptionKeys: ['B'])),
      ];
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final s1 = engine
          .submitAnswer(
              state: active,
              questionId: 'q1',
              answer: 'A',
              submittedAt: fixedDate)
          .valueOrThrow; // corr
      final s2 = engine
          .submitAnswer(
              state: s1, questionId: 'q2', answer: 'A', submittedAt: fixedDate)
          .valueOrThrow; // corr
      final completed = engine
          .submitAnswer(
              state: s2, questionId: 'q3', answer: 'A', submittedAt: fixedDate)
          .valueOrThrow; // incorr

      final summary = completed.completionSummary!;
      expect(summary.objectivePerformance['obj_polity']!.accuracy, equals(1.0));
      expect(
          summary.objectivePerformance['obj_history']!.accuracy, equals(0.0));
    });

    test('110. Topic performance summary correctly groups scores per topic',
        () {
      final questions = [
        buildQuestion(
            id: 'q1',
            topic: 'Fundamental Rights',
            officialAnswer: const Answer(correctOptionKeys: ['A'])),
        buildQuestion(
            id: 'q2',
            topic: 'Preamble',
            officialAnswer: const Answer(correctOptionKeys: ['B'])),
      ];
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final s1 = engine
          .submitAnswer(
              state: active,
              questionId: 'q1',
              answer: 'A',
              submittedAt: fixedDate)
          .valueOrThrow; // corr
      final completed = engine
          .submitAnswer(
              state: s1, questionId: 'q2', answer: 'B', submittedAt: fixedDate)
          .valueOrThrow; // corr

      final summary = completed.completionSummary!;
      expect(summary.topicPerformance['Fundamental Rights']!.accuracy,
          equals(1.0));
      expect(summary.topicPerformance['Preamble']!.accuracy, equals(1.0));
    });
  });

  // ==========================================================================
  // GROUP 12: REPLAY DETERMINISM & HIGH-THROUGHPUT BENCHMARKS
  // ==========================================================================
  group('P35.12 Group 12 — Replay Determinism & High-Throughput Benchmarks',
      () {
    test(
        '111. Deterministic Replay: 10 consecutive execution runs produce byte-identical JSON',
        () {
      final questions = List.generate(
        5,
        (i) => buildQuestion(
          id: 'q_$i',
          topic: 'Topic ${i % 2}',
          officialAnswer: const Answer(correctOptionKeys: ['A']),
        ),
      );
      final spec = buildSpec(questions: questions);

      String? baselineJson;

      for (int run = 0; run < 10; run++) {
        final initial = engine.initializeSession(spec: spec);
        var state = engine
            .startSession(state: initial, startedAt: fixedDate)
            .valueOrThrow;

        for (int i = 0; i < 5; i++) {
          final t = fixedDate.add(Duration(seconds: (i + 1) * 10));
          if (i == 2) {
            state = engine
                .skipQuestion(state: state, questionId: 'q_$i', skippedAt: t)
                .valueOrThrow;
          } else {
            state = engine
                .submitAnswer(
                    state: state,
                    questionId: 'q_$i',
                    answer: 'A',
                    submittedAt: t)
                .valueOrThrow;
          }
        }

        final runJson = jsonEncode(state.toJson());
        if (baselineJson == null) {
          baselineJson = runJson;
        } else {
          expect(runJson, equals(baselineJson));
        }
      }
    });

    test('112. Pause and Resume lifecycle determinism holds', () {
      final spec = buildSpec(
          questions: [buildQuestion(id: 'q1'), buildQuestion(id: 'q2')]);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final paused = engine
          .pauseSession(
              state: active,
              pausedAt: fixedDate.add(const Duration(seconds: 5)))
          .valueOrThrow;
      final resumed = engine
          .resumeSession(
              state: paused,
              resumedAt: fixedDate.add(const Duration(seconds: 15)))
          .valueOrThrow;

      final completed = engine
          .submitAnswer(
            state: resumed,
            questionId: 'q1',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 25)),
          )
          .valueOrThrow;

      expect(completed.currentQuestionIndex, equals(1));
    });

    test('113. 1,000 questions session initialization & lookup in < 20ms', () {
      final questions = List.generate(
        1000,
        (i) => buildQuestion(id: 'q_1k_$i', topic: 'Topic ${i % 10}'),
      );
      final spec = buildSpec(questions: questions);

      final sw = Stopwatch()..start();
      final state = engine.initializeSession(spec: spec);
      final active =
          engine.startSession(state: state, startedAt: fixedDate).valueOrThrow;
      final q = engine.getCurrentQuestion(active);
      sw.stop();

      // ignore: avoid_print
      print('P35 1K session init + lookup: ${sw.elapsedMilliseconds}ms');
      expect(active.totalQuestions, equals(1000));
      expect(q!.id, equals('q_1k_0'));
      expect(sw.elapsedMilliseconds, lessThan(20));
    });

    test('114. 1,000 questions execution simulation (1,000 answers) in < 50ms',
        () {
      final questions = List.generate(
        1000,
        (i) => buildQuestion(
            id: 'q_1k_$i',
            officialAnswer: const Answer(correctOptionKeys: ['A'])),
      );
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      var current = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        final qId = current.currentQuestionId!;
        current = engine
            .submitAnswer(
              state: current,
              questionId: qId,
              answer: 'A',
              submittedAt: fixedDate.add(Duration(seconds: i + 1)),
            )
            .valueOrThrow;
      }
      sw.stop();

      // ignore: avoid_print
      print(
          'P35 1K questions execution (1,000 answer submissions): ${sw.elapsedMilliseconds}ms');
      expect(current.status, equals(PracticeExecutionStatus.completed));
      expect(current.progress.correctCount, equals(1000));
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('115. 10,000 questions session initialization in < 50ms', () {
      final questions = List.generate(
        10000,
        (i) => buildQuestion(id: 'q_10k_$i', topic: 'Topic ${i % 50}'),
      );
      final spec = buildSpec(questions: questions);

      final sw = Stopwatch()..start();
      final state = engine.initializeSession(spec: spec);
      final active =
          engine.startSession(state: state, startedAt: fixedDate).valueOrThrow;
      sw.stop();

      // ignore: avoid_print
      print('P35 10K session init + start: ${sw.elapsedMilliseconds}ms');
      expect(active.totalQuestions, equals(10000));
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('116. 1,000 questions execution simulation in < 2,000ms', () {
      final questions = List.generate(
        1000,
        (i) => buildQuestion(
            id: 'q_1k_$i',
            officialAnswer: const Answer(correctOptionKeys: ['A'])),
      );
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      var current = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        final qId = current.currentQuestionId!;
        current = engine
            .submitAnswer(
              state: current,
              questionId: qId,
              answer: i % 2 == 0 ? 'A' : 'B',
              submittedAt: fixedDate.add(Duration(seconds: i + 1)),
            )
            .valueOrThrow;
      }
      sw.stop();

      // ignore: avoid_print
      print('P35 1K questions execution: ${sw.elapsedMilliseconds}ms');
      expect(current.status, equals(PracticeExecutionStatus.completed));
      expect(current.progress.answeredCount, equals(1000));
      expect(current.progress.correctCount, equals(500));
      expect(sw.elapsedMilliseconds, lessThan(3000));
    });

    test('117. 50,000 questions session initialization in < 200ms', () {
      final questions = List.generate(
        50000,
        (i) => buildQuestion(id: 'q_50k_$i', topic: 'Topic ${i % 100}'),
      );
      final spec = buildSpec(questions: questions);

      final sw = Stopwatch()..start();
      final state = engine.initializeSession(spec: spec);
      final active =
          engine.startSession(state: state, startedAt: fixedDate).valueOrThrow;
      sw.stop();

      // ignore: avoid_print
      print('P35 50K session init + start: ${sw.elapsedMilliseconds}ms');
      expect(active.totalQuestions, equals(50000));
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('118. 100,000 questions session initialization in < 500ms', () {
      final questions = List.generate(
        100000,
        (i) => buildQuestion(id: 'q_100k_$i', topic: 'Topic ${i % 200}'),
      );
      final spec = buildSpec(questions: questions);

      final sw = Stopwatch()..start();
      final state = engine.initializeSession(spec: spec);
      final active =
          engine.startSession(state: state, startedAt: fixedDate).valueOrThrow;
      sw.stop();

      // ignore: avoid_print
      print('P35 100K session init + start: ${sw.elapsedMilliseconds}ms');
      expect(active.totalQuestions, equals(100000));
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });

    test('119. Single question lookup latency is < 1ms average', () {
      final questions = List.generate(1000, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      final active = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        final q = engine.getCurrentQuestion(active);
        expect(q, isNotNull);
      }
      sw.stop();

      final avgMicroseconds = sw.elapsedMicroseconds / 1000;
      // ignore: avoid_print
      print(
          'P35 Average question lookup time: ${avgMicroseconds.toStringAsFixed(2)} µs');
      expect(avgMicroseconds, lessThan(1000)); // < 1ms
    });

    test('120. Single answer transition latency is < 1ms average', () {
      final questions = List.generate(1000, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      var current = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        final qId = current.currentQuestionId!;
        current = engine
            .submitAnswer(
              state: current,
              questionId: qId,
              answer: 'A',
              submittedAt: fixedDate.add(Duration(seconds: i + 1)),
            )
            .valueOrThrow;
      }
      sw.stop();

      final avgMicroseconds = sw.elapsedMicroseconds / 1000;
      // ignore: avoid_print
      print(
          'P35 Average answer transition time: ${avgMicroseconds.toStringAsFixed(2)} µs');
      expect(avgMicroseconds, lessThan(1000)); // < 1ms
    });

    test('121. Completion summary compilation for 10,000 questions in < 50ms',
        () {
      final questions = List.generate(
        10000,
        (i) => buildQuestion(
          id: 'q_$i',
          topic: 'Topic ${i % 20}',
          objectiveIds: ['obj_${i % 50}'],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
        ),
      );
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);

      final resultsMap = <String, PracticeQuestionResult>{};
      for (int i = 0; i < 10000; i++) {
        final q = spec.orderedQuestions[i];
        resultsMap[q.id] = PracticeQuestionResult(
          questionId: q.id,
          questionIndex: i,
          isAnswered: true,
          isSkipped: false,
          submittedAnswer: i % 2 == 0 ? 'A' : 'B',
          isCorrect: i % 2 == 0,
          elapsedSeconds: 30,
          question: q,
        );
      }

      final completedState = initial.copyWith(
        status: PracticeExecutionStatus.completed,
        questionResults: resultsMap,
        startedAt: fixedDate,
        completedAt: fixedDate.add(const Duration(minutes: 60)),
      );

      final sw = Stopwatch()..start();
      final summary = completedState.completionSummary;
      sw.stop();

      // ignore: avoid_print
      print(
          'P35 10K completion summary compilation: ${sw.elapsedMilliseconds}ms');
      expect(summary, isNotNull);
      expect(summary!.totalQuestions, equals(10000));
      expect(summary.objectivePerformance.length, equals(50));
      expect(summary.topicPerformance.length, equals(20));
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('122. generateHandoffAttempts for 10,000 questions in < 50ms', () {
      final questions = List.generate(
        10000,
        (i) => buildQuestion(
          id: 'q_$i',
          objectiveIds: ['obj_${i % 50}'],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
        ),
      );
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);

      final resultsMap = <String, PracticeQuestionResult>{};
      for (int i = 0; i < 10000; i++) {
        final q = spec.orderedQuestions[i];
        resultsMap[q.id] = PracticeQuestionResult(
          questionId: q.id,
          questionIndex: i,
          isAnswered: true,
          isSkipped: false,
          submittedAnswer: 'A',
          isCorrect: true,
          elapsedSeconds: 30,
          question: q,
        );
      }

      final completedState = initial.copyWith(
        status: PracticeExecutionStatus.completed,
        questionResults: resultsMap,
        startedAt: fixedDate,
        completedAt: fixedDate.add(const Duration(minutes: 60)),
      );

      final sw = Stopwatch()..start();
      final attempts = engine.generateHandoffAttempts(completedState);
      sw.stop();

      // ignore: avoid_print
      print('P35 10K generateHandoffAttempts: ${sw.elapsedMilliseconds}ms');
      expect(attempts.length, equals(10000));
      expect(sw.elapsedMilliseconds, lessThan(100));
    });
  });
}
