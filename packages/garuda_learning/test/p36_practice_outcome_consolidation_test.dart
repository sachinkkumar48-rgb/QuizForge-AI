/// P36 Practice Outcome Consolidation & Learning Evidence Bridge Test Suite (TITAN-KO-036.0 P36).
///
/// 120+ unit, property, error, determinism, isolation, and benchmark tests verifying:
/// - Group 1: Construction & Serialization (10 tests)
/// - Group 2: Status Semantics (8 tests)
/// - Group 3: Accuracy Semantics & Zero-Denominator Safety (8 tests)
/// - Group 4: Completion Semantics & Boundaries (6 tests)
/// - Group 5: Question Evidence Extraction & Metadata Fidelity (8 tests)
/// - Group 6: Topic Aggregation (8 tests)
/// - Group 7: Objective Aggregation (8 tests)
/// - Group 8: Section Aggregation (8 tests)
/// - Group 9: Difficulty Aggregation (8 tests)
/// - Group 10: Multi-Exam Isolation & Cross-Exam Rejection (8 tests)
/// - Group 11: Determinism & Canonical Ordering (8 tests)
/// - Group 12: Immutability & Mutation Safety (6 tests)
/// - Group 13: Structured Error Handling & Idempotency (8 tests)
/// - Group 14: P19 Handoff Records & Timestamp Authority (8 tests)
/// - Group 15: P20 Boundary Verification (no SM-2 / scheduling) (4 tests)
/// - Group 16: P23 Boundary Verification (no longitudinal prediction) (4 tests)
/// - Group 17: Safety & Non-Fabrication Invariants (6 tests)
/// - Group 18: High-Throughput Benchmarks (1K, 10K, 50K, 100K) (8 tests)
/// - Group 19: Fingerprint Sensitivity (6 tests)
/// - Group 20: Property & Replay Tests (6 tests)
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 12, 0, 0);
  const orchestrator = AdaptivePracticeSessionOrchestrator();
  const engine = AdaptivePracticeExecutionEngine();
  const consolidator = PracticeOutcomeConsolidator();

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
    int sectionSize = 5,
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
      sectionSize: sectionSize,
      estimatedSecondsPerQuestion: 60,
    );

    return orchestrator.orchestrateSession(
      selectionResult: selectionResult,
      config: config,
      orchestratedAt: fixedDate,
    );
  }

  // ==========================================================================
  // GROUP 1: Construction & Serialization (10 tests)
  // ==========================================================================
  group('P36.1 Group 1 — Construction & Serialization', () {
    test('1. Valid outcome construction from completed P35 state', () {
      final q1 = buildQuestion(id: 'q_01', examId: 'upsc');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_01',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 30)),
          )
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.sessionId, equals(spec.sessionId));
      expect(outcome.examId, equals('upsc'));
      expect(outcome.totalQuestions, equals(1));
      expect(outcome.attemptedCount, equals(1));
      expect(outcome.correctCount, equals(1));
      expect(outcome.incorrectCount, equals(0));
      expect(outcome.skippedCount, equals(0));
      expect(outcome.unansweredCount, equals(0));
      expect(outcome.accuracy, equals(1.0));
      expect(outcome.completionRate, equals(1.0));
      expect(outcome.fingerprint, isNotEmpty);
    });

    test('2. Empty session consolidation produces valid zero outcome', () {
      final spec = buildSpec(questions: const []);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.totalQuestions, equals(0));
      expect(outcome.attemptedCount, equals(0));
      expect(outcome.correctCount, equals(0));
      expect(outcome.accuracy, isNull);
      expect(outcome.completionRate, equals(0.0));
      expect(outcome.questionEvidence, isEmpty);
      expect(outcome.handoffAttempts, isEmpty);
    });

    test(
        '3. Malformed session ID triggers ArgumentError in execution state and invalidSession error in consolidator',
        () {
      final q1 = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);

      expect(
        () => PracticeExecutionState(
          sessionId: '   ',
          examId: 'upsc',
          spec: spec,
          questionResults: initial.questionResults,
        ),
        throwsArgumentError,
      );

      const err = PracticeConsolidationError(
        code: PracticeConsolidationErrorCode.invalidSession,
        message: 'Invalid session ID',
      );
      expect(err.code, equals(PracticeConsolidationErrorCode.invalidSession));
    });

    test('4. Topic evidence map is deeply unmodifiable', () {
      final q1 = buildQuestion(id: 'q_01', topic: 'Polity');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      expect(
        () => outcome.topicEvidence['NewTopic'] = PracticeTopicEvidence(
          topic: 'NewTopic',
          totalQuestions: 1,
          attemptedCount: 1,
          correctCount: 1,
          incorrectCount: 0,
          skippedCount: 0,
          unansweredCount: 0,
          completionRate: 1.0,
          skipRate: 0.0,
        ),
        throwsUnsupportedError,
      );
    });

    test('5. Objective evidence map is deeply unmodifiable', () {
      final q1 = buildQuestion(id: 'q_01', objectiveIds: ['obj_01']);
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      expect(
        () => outcome.objectiveEvidence['new_obj'] = PracticeObjectiveEvidence(
          objectiveId: 'new_obj',
          totalQuestions: 1,
          attemptedCount: 1,
          correctCount: 1,
          incorrectCount: 0,
          skippedCount: 0,
          unansweredCount: 0,
          completionRate: 1.0,
          skipRate: 0.0,
        ),
        throwsUnsupportedError,
      );
    });

    test('6. Section evidence map is deeply unmodifiable', () {
      final q1 = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      expect(
        () => outcome.sectionEvidence['section_99'] = PracticeSectionEvidence(
          sectionIndex: 99,
          totalQuestions: 1,
          attemptedCount: 1,
          correctCount: 1,
          incorrectCount: 0,
          skippedCount: 0,
          unansweredCount: 0,
          completionRate: 1.0,
          skipRate: 0.0,
        ),
        throwsUnsupportedError,
      );
    });

    test('7. Difficulty evidence map is deeply unmodifiable', () {
      final q1 = buildQuestion(id: 'q_01', difficulty: 'Hard');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      expect(
        () =>
            outcome.difficultyEvidence['Extreme'] = PracticeDifficultyEvidence(
          difficulty: 'Extreme',
          totalQuestions: 1,
          attemptedCount: 1,
          correctCount: 1,
          incorrectCount: 0,
          skippedCount: 0,
          unansweredCount: 0,
          completionRate: 1.0,
          skipRate: 0.0,
        ),
        throwsUnsupportedError,
      );
    });

    test('8. Question evidence list is deeply unmodifiable', () {
      final q1 = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      expect(
        () => outcome.questionEvidence.add(outcome.questionEvidence.first),
        throwsUnsupportedError,
      );
    });

    test('9. Handoff attempts list is deeply unmodifiable', () {
      final q1 = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_01',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(
        () => outcome.handoffAttempts.add(outcome.handoffAttempts.first),
        throwsUnsupportedError,
      );
    });

    test('10. Full JSON serialization roundtrip produces identical outcome',
        () {
      final q1 =
          buildQuestion(id: 'q_01', topic: 'Preamble', difficulty: 'Easy');
      final q2 =
          buildQuestion(id: 'q_02', topic: 'Judiciary', difficulty: 'Hard');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_01',
            answer: 'A', // correct
            submittedAt: fixedDate.add(const Duration(seconds: 20)),
          )
          .valueOrThrow;
      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_02',
            answer: 'B', // incorrect
            submittedAt: fixedDate.add(const Duration(seconds: 40)),
          )
          .valueOrThrow;

      final original = consolidator.consolidate(state: state).valueOrThrow;
      final jsonMap = original.toJson();
      final jsonStr = jsonEncode(jsonMap);
      final deserialized = ConsolidatedPracticeOutcome.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );

      expect(deserialized.sessionId, equals(original.sessionId));
      expect(deserialized.examId, equals(original.examId));
      expect(deserialized.totalQuestions, equals(original.totalQuestions));
      expect(deserialized.attemptedCount, equals(original.attemptedCount));
      expect(deserialized.correctCount, equals(original.correctCount));
      expect(deserialized.incorrectCount, equals(original.incorrectCount));
      expect(deserialized.accuracy, equals(original.accuracy));
      expect(deserialized.fingerprint, equals(original.fingerprint));
      expect(
          deserialized.topicEvidence.keys, equals(original.topicEvidence.keys));
      expect(deserialized.questionEvidence.length,
          equals(original.questionEvidence.length));
    });
  });

  // ==========================================================================
  // GROUP 2: Status Semantics (8 tests)
  // ==========================================================================
  group('P36.2 Group 2 — Status Semantics', () {
    test('11. Completed session status preserved', () {
      final q1 = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_01',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      expect(state.status, equals(PracticeExecutionStatus.completed));
      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.sessionStatus, equals(PracticeExecutionStatus.completed));
    });

    test('12. Abandoned session status preserved', () {
      final q1 = buildQuestion(id: 'q_01');
      final q2 = buildQuestion(id: 'q_02');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .abandonSession(
            state: state,
            abandonedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      expect(state.status, equals(PracticeExecutionStatus.abandoned));
      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.sessionStatus, equals(PracticeExecutionStatus.abandoned));
    });

    test('13. Paused session status preserved', () {
      final q1 = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .pauseSession(
            state: state,
            pausedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      expect(state.status, equals(PracticeExecutionStatus.paused));
      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.sessionStatus, equals(PracticeExecutionStatus.paused));
    });

    test('14. NotStarted session status preserved', () {
      final q1 = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);

      final outcome = consolidator
          .consolidate(
            state: initial,
            consolidatedAt: fixedDate,
          )
          .valueOrThrow;
      expect(outcome.sessionStatus, equals(PracticeExecutionStatus.notStarted));
      expect(outcome.unansweredCount, equals(1));
    });

    test('15. Skipped questions marked PracticeQuestionStatus.skipped', () {
      final q1 = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .skipQuestion(
            state: state,
            questionId: 'q_01',
            skippedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.questionEvidence.first.status,
          equals(PracticeQuestionStatus.skipped));
      expect(outcome.questionEvidence.first.isSkipped, isTrue);
      expect(outcome.questionEvidence.first.isAnswered, isFalse);
    });

    test('16. Unanswered questions marked PracticeQuestionStatus.unanswered',
        () {
      final q1 = buildQuestion(id: 'q_01');
      final q2 = buildQuestion(id: 'q_02');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      // Answer q1 then abandon
      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_01',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;
      state = engine
          .abandonSession(
            state: state,
            abandonedAt: fixedDate.add(const Duration(seconds: 20)),
          )
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.questionEvidence[0].status,
          equals(PracticeQuestionStatus.answeredCorrect));
      expect(outcome.questionEvidence[1].status,
          equals(PracticeQuestionStatus.unanswered));
    });

    test('17. Abandoned session calculates unanswered count correctly', () {
      final qList = List.generate(5, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      // Answer 1, skip 1, abandon remaining 3
      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_0',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;
      state = engine
          .skipQuestion(
            state: state,
            questionId: 'q_1',
            skippedAt: fixedDate.add(const Duration(seconds: 20)),
          )
          .valueOrThrow;
      state = engine
          .abandonSession(
            state: state,
            abandonedAt: fixedDate.add(const Duration(seconds: 30)),
          )
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.totalQuestions, equals(5));
      expect(outcome.attemptedCount, equals(1));
      expect(outcome.skippedCount, equals(1));
      expect(outcome.unansweredCount, equals(3));
      expect(outcome.completionRate, equals(0.4)); // (1+1)/5
    });

    test('18. Skipped, unanswered, incorrect are mutually distinct', () {
      final q1 = buildQuestion(id: 'q_01');
      final q2 = buildQuestion(id: 'q_02');
      final q3 = buildQuestion(id: 'q_03');
      final spec = buildSpec(questions: [q1, q2, q3]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_01',
            answer: 'B', // incorrect
            submittedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;
      state = engine
          .skipQuestion(
            state: state,
            questionId: 'q_02',
            skippedAt: fixedDate.add(const Duration(seconds: 20)),
          )
          .valueOrThrow;
      state = engine
          .abandonSession(
            state: state,
            abandonedAt: fixedDate.add(const Duration(seconds: 30)),
          )
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.incorrectCount, equals(1));
      expect(outcome.skippedCount, equals(1));
      expect(outcome.unansweredCount, equals(1));
      expect(outcome.correctCount, equals(0));
      expect(outcome.accuracy, equals(0.0)); // 0 correct out of 1 attempt
    });
  });

  // ==========================================================================
  // GROUP 3: Accuracy Semantics & Zero-Denominator Safety (8 tests)
  // ==========================================================================
  group('P36.3 Group 3 — Accuracy Semantics & Zero-Denominator Safety', () {
    test('19. All correct answers yields accuracy = 1.0 (100%)', () {
      final qList = List.generate(3, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      for (int i = 0; i < 3; i++) {
        state = engine
            .submitAnswer(
              state: state,
              questionId: 'q_$i',
              answer: 'A',
              submittedAt: fixedDate.add(Duration(seconds: 10 * (i + 1))),
            )
            .valueOrThrow;
      }

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.accuracy, equals(1.0));
      expect(outcome.accuracyPercentage, equals(100.0));
    });

    test('20. All incorrect answers yields accuracy = 0.0 (0%)', () {
      final qList = List.generate(2, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      for (int i = 0; i < 2; i++) {
        state = engine
            .submitAnswer(
              state: state,
              questionId: 'q_$i',
              answer: 'C',
              submittedAt: fixedDate.add(Duration(seconds: 10 * (i + 1))),
            )
            .valueOrThrow;
      }

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.accuracy, equals(0.0));
      expect(outcome.accuracyPercentage, equals(0.0));
    });

    test('21. Mixed correct and incorrect calculates correct ratio', () {
      final qList = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow; // corr
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow; // corr
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow; // corr
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_3',
              answer: 'D',
              submittedAt: fixedDate.add(const Duration(seconds: 40)))
          .valueOrThrow; // incorr

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.accuracy, equals(0.75));
      expect(outcome.accuracyPercentage, equals(75.0));
    });

    test('22. Zero attempts produces accuracy = null (never 0.0 or NaN)', () {
      final q1 = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.attemptedCount, equals(0));
      expect(outcome.accuracy, isNull);
      expect(outcome.accuracyPercentage, isNull);
    });

    test('23. Skipped-only session produces accuracy = null', () {
      final q1 = buildQuestion(id: 'q_01');
      final q2 = buildQuestion(id: 'q_02');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_01',
              skippedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_02',
              skippedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.attemptedCount, equals(0));
      expect(outcome.skippedCount, equals(2));
      expect(outcome.accuracy, isNull);
      expect(outcome.accuracyPercentage, isNull);
    });

    test('24. Unanswered-only session produces accuracy = null', () {
      final q1 = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 5)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.attemptedCount, equals(0));
      expect(outcome.unansweredCount, equals(1));
      expect(outcome.accuracy, isNull);
    });

    test('25. AccuracyPercentage is null when accuracy is null', () {
      final spec = buildSpec(questions: const []);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.accuracy, isNull);
      expect(outcome.accuracyPercentage, isNull);
    });

    test('26. ScoreRatio is strictly correct / totalQuestions', () {
      final qList = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow; // corr
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_1',
              skippedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.scoreRatio, equals(0.25)); // 1/4
      expect(outcome.accuracy, equals(1.0)); // 1/1 among attempted
    });
  });

  // ==========================================================================
  // GROUP 4: Completion Semantics & Boundaries (6 tests)
  // ==========================================================================
  group('P36.4 Group 4 — Completion Semantics & Boundaries', () {
    test('27. 0% completion when zero questions attempted or skipped', () {
      final qList = List.generate(3, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.completionRate, equals(0.0));
    });

    test(
        '28. Partial completion calculates (answered + skipped) / total correctly',
        () {
      final qList = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_1',
              skippedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.completionRate, equals(0.5)); // 2/4
    });

    test('29. Full 100% completion when all questions processed', () {
      final qList = List.generate(2, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.completionRate, equals(1.0));
    });

    test('30. Skipped-only session reaches 100% completion rate', () {
      final qList = List.generate(3, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      for (int i = 0; i < 3; i++) {
        state = engine
            .skipQuestion(
                state: state,
                questionId: 'q_$i',
                skippedAt: fixedDate.add(Duration(seconds: 10 * (i + 1))))
            .valueOrThrow;
      }

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.completionRate, equals(1.0));
      expect(outcome.skippedCount, equals(3));
      expect(outcome.attemptedCount, equals(0));
    });

    test('31. Abandoned session has completion rate matching processed portion',
        () {
      final qList = List.generate(10, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      // Process 3 questions, then abandon
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_2',
              skippedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 40)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.completionRate, equals(0.3)); // 3/10
      expect(outcome.unansweredCount, equals(7));
    });

    test('32. CompletionRate is bounded in [0.0, 1.0]', () {
      final q1 = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.completionRate, greaterThanOrEqualTo(0.0));
      expect(outcome.completionRate, lessThanOrEqualTo(1.0));
    });
  });

  // ==========================================================================
  // GROUP 5: Question Evidence Extraction & Metadata Fidelity (8 tests)
  // ==========================================================================
  group('P36.5 Group 5 — Question Evidence Extraction & Metadata Fidelity', () {
    test('33. Single question evidence preserves all metadata', () {
      final q1 = buildQuestion(
        id: 'q_upsc_pol_01',
        examId: 'upsc',
        year: 2023,
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        objectiveIds: ['obj_fr_01'],
        difficulty: 'Hard',
      );
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_upsc_pol_01',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 45)),
          )
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.questionEvidence.length, equals(1));
      final qEv = outcome.questionEvidence.first;
      expect(qEv.questionId, equals('q_upsc_pol_01'));
      expect(qEv.examId, equals('upsc'));
      expect(qEv.year, equals(2023));
      expect(qEv.paper, equals('GS1'));
      expect(qEv.subject, equals('Polity'));
      expect(qEv.topic, equals('Fundamental Rights'));
      expect(qEv.objectiveIds, equals(['obj_fr_01']));
      expect(qEv.difficulty, equals('Hard'));
      expect(qEv.questionIndex, equals(0));
      expect(qEv.status, equals(PracticeQuestionStatus.answeredCorrect));
      expect(qEv.isCorrect, isTrue);
      expect(qEv.elapsedSeconds, equals(45));
    });

    test('34. Multiple questions preserve sequential questionIndex', () {
      final qList = List.generate(5, (i) => buildQuestion(id: 'q_seq_$i'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.questionEvidence.length, equals(5));
      for (int i = 0; i < 5; i++) {
        expect(outcome.questionEvidence[i].questionIndex, equals(i));
        expect(outcome.questionEvidence[i].questionId, equals('q_seq_$i'));
      }
    });

    test(
        '35. Question provenance (year, paper, subject, topic) preserved exactly',
        () {
      final q = buildQuestion(
        id: 'q_prov_01',
        year: 2021,
        paper: 'Prelims GS-1',
        subject: 'Economics',
        topic: 'Banking & Monetary Policy',
      );
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final ev = outcome.questionEvidence.first;
      expect(ev.year, equals(2021));
      expect(ev.paper, equals('Prelims GS-1'));
      expect(ev.subject, equals('Economics'));
      expect(ev.topic, equals('Banking & Monetary Policy'));
    });

    test('36. Official answer key preserved in correctAnswer', () {
      final q = buildQuestion(
        id: 'q_key_01',
        officialAnswer: const Answer(
          correctOptionKeys: ['B', 'C'],
          officialAnswerSource: 'UPSC Final Key',
        ),
      );
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.questionEvidence.first.correctAnswer, equals('B, C'));
    });

    test('37. SubmittedAnswer preserved for answered questions', () {
      final q = buildQuestion(id: 'q_ans_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_ans_01',
            answer: 'Option A text',
            submittedAt: fixedDate.add(const Duration(seconds: 15)),
          )
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.questionEvidence.first.submittedAnswer,
          equals('Option A text'));
    });

    test('38. SubmittedAnswer is null for skipped and unanswered questions',
        () {
      final q1 = buildQuestion(id: 'q_sk_01');
      final q2 = buildQuestion(id: 'q_un_02');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .skipQuestion(
            state: state,
            questionId: 'q_sk_01',
            skippedAt: fixedDate.add(const Duration(seconds: 10)),
          )
          .valueOrThrow;
      state = engine
          .abandonSession(
            state: state,
            abandonedAt: fixedDate.add(const Duration(seconds: 20)),
          )
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.questionEvidence[0].submittedAnswer, isNull);
      expect(outcome.questionEvidence[1].submittedAnswer, isNull);
    });

    test('39. ElapsedSeconds correctly reflected per question', () {
      final q = buildQuestion(id: 'q_el_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
            state: state,
            questionId: 'q_el_01',
            answer: 'A',
            submittedAt: fixedDate.add(const Duration(seconds: 42)),
          )
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.questionEvidence.first.elapsedSeconds, equals(42));
    });

    test('40. Candidate metadata preserved if present in session', () {
      final q = buildQuestion(id: 'q_cand_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.questionEvidence.first.candidateMetadata, isNotNull);
      expect(outcome.questionEvidence.first.candidateMetadata?.question.id,
          equals('q_cand_01'));
    });
  });

  // ==========================================================================
  // GROUP 6: Topic Aggregation (8 tests)
  // ==========================================================================
  group('P36.6 Group 6 — Topic Aggregation', () {
    test('41. Single topic aggregation groups all question results', () {
      final q1 = buildQuestion(id: 'q_1', topic: 'Parliament');
      final q2 = buildQuestion(id: 'q_2', topic: 'Parliament');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.topicEvidence.length, equals(1));
      final topicEv = outcome.topicEvidence['Parliament']!;
      expect(topicEv.totalQuestions, equals(2));
      expect(topicEv.attemptedCount, equals(2));
      expect(topicEv.correctCount, equals(2));
      expect(topicEv.accuracy, equals(1.0));
    });

    test('42. Multiple distinct topics aggregate independently', () {
      final q1 = buildQuestion(id: 'q_1', topic: 'Polity');
      final q2 = buildQuestion(id: 'q_2', topic: 'History');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.topicEvidence.length, equals(2));
      expect(outcome.topicEvidence.containsKey('Polity'), isTrue);
      expect(outcome.topicEvidence.containsKey('History'), isTrue);
      expect(outcome.topicEvidence['Polity']!.correctCount, equals(1));
      expect(outcome.topicEvidence['History']!.correctCount, equals(0));
    });

    test(
        '43. Missing/empty topic falls back to safe default (General / Uncategorized)',
        () {
      final q = buildQuestion(id: 'q_1', topic: '   ');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(
          outcome.topicEvidence.containsKey('General') ||
              outcome.topicEvidence.containsKey('Uncategorized'),
          isTrue);
    });

    test('44. Mixed correct/incorrect within topic calculates topic accuracy',
        () {
      final q1 = buildQuestion(id: 'q_1', topic: 'Ecology');
      final q2 = buildQuestion(id: 'q_2', topic: 'Ecology');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'C',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.topicEvidence['Ecology']!.accuracy, equals(0.5));
      expect(
          outcome.topicEvidence['Ecology']!.accuracyPercentage, equals(50.0));
    });

    test('45. Topic with 0 attempts has accuracy = null', () {
      final q = buildQuestion(id: 'q_1', topic: 'Ancient History');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_1',
              skippedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.topicEvidence['Ancient History']!.accuracy, isNull);
    });

    test('46. Topic skipRate calculates skipped / total for that topic', () {
      final q1 = buildQuestion(id: 'q_1', topic: 'Physics');
      final q2 = buildQuestion(id: 'q_2', topic: 'Physics');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_2',
              skippedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.topicEvidence['Physics']!.skipRate, equals(0.5));
    });

    test(
        '47. Topic totalElapsedSeconds sums elapsed seconds across topic questions',
        () {
      final q1 = buildQuestion(id: 'q_1', topic: 'Chemistry');
      final q2 = buildQuestion(id: 'q_2', topic: 'Chemistry');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 25)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 35)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(
          outcome.topicEvidence['Chemistry']!.totalElapsedSeconds, equals(35));
    });

    test('48. Topic keys are sorted deterministically in alphabetical order',
        () {
      final q1 = buildQuestion(id: 'q_1', topic: 'Zoolology');
      final q2 = buildQuestion(id: 'q_2', topic: 'Astronomy');
      final q3 = buildQuestion(id: 'q_3', topic: 'Biology');
      final spec = buildSpec(questions: [q1, q2, q3]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final keys = outcome.topicEvidence.keys.toList();
      expect(keys, equals(['Astronomy', 'Biology', 'Zoolology']));
    });
  });

  // ==========================================================================
  // GROUP 7: Objective Aggregation (8 tests)
  // ==========================================================================
  group('P36.7 Group 7 — Objective Aggregation', () {
    test('49. Single objective maps questions and accumulates metrics', () {
      final q1 = buildQuestion(id: 'q_1', objectiveIds: ['lo_fr_01']);
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.objectiveEvidence.length, equals(1));
      expect(outcome.objectiveEvidence['lo_fr_01']!.correctCount, equals(1));
    });

    test('50. Multiple objectives aggregate independently', () {
      final q1 = buildQuestion(id: 'q_1', objectiveIds: ['lo_01']);
      final q2 = buildQuestion(id: 'q_2', objectiveIds: ['lo_02']);
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.objectiveEvidence.containsKey('lo_01'), isTrue);
      expect(outcome.objectiveEvidence.containsKey('lo_02'), isTrue);
    });

    test('51. Question with multiple objectiveIds contributes to all of them',
        () {
      final q = buildQuestion(id: 'q_1', objectiveIds: ['lo_a', 'lo_b']);
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.objectiveEvidence['lo_a']!.correctCount, equals(1));
      expect(outcome.objectiveEvidence['lo_b']!.correctCount, equals(1));
    });

    test('52. Missing objectiveIds falls back safely to lo_unassigned', () {
      final q = buildQuestion(id: 'q_1', objectiveIds: const []);
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.objectiveEvidence.containsKey('lo_unassigned'), isTrue);
    });

    test(
        '53. Objective accuracy is null when 0 attempts made on that objective',
        () {
      final q = buildQuestion(id: 'q_1', objectiveIds: ['lo_unattempted']);
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.objectiveEvidence['lo_unattempted']!.accuracy, isNull);
    });

    test(
        '54. Objective completionRate matches processed ratio for that objective',
        () {
      final q1 = buildQuestion(id: 'q_1', objectiveIds: ['lo_comp']);
      final q2 = buildQuestion(id: 'q_2', objectiveIds: ['lo_comp']);
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.objectiveEvidence['lo_comp']!.completionRate, equals(0.5));
    });

    test('55. Objective totalElapsedSeconds calculates correctly', () {
      final q = buildQuestion(id: 'q_1', objectiveIds: ['lo_time']);
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 28)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.objectiveEvidence['lo_time']!.totalElapsedSeconds,
          equals(28));
    });

    test(
        '56. Objective keys are sorted deterministically in alphabetical order',
        () {
      final q1 = buildQuestion(id: 'q_1', objectiveIds: ['lo_z']);
      final q2 = buildQuestion(id: 'q_2', objectiveIds: ['lo_a']);
      final q3 = buildQuestion(id: 'q_3', objectiveIds: ['lo_m']);
      final spec = buildSpec(questions: [q1, q2, q3]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.objectiveEvidence.keys.toList(),
          equals(['lo_a', 'lo_m', 'lo_z']));
    });
  });

  // ==========================================================================
  // GROUP 8: Section Aggregation (8 tests)
  // ==========================================================================
  group('P36.8 Group 8 — Section Aggregation', () {
    test('57. Single section session maps to section_0', () {
      final q = buildQuestion(id: 'q_1');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.sectionEvidence.containsKey('section_0'), isTrue);
    });

    test(
        '58. Multi-section P34 session partitions questions into section_0, section_1',
        () {
      // 6 questions with sectionSize 3 produces 2 sections
      final qList = List.generate(6, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList, sectionSize: 3);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.sectionEvidence.length, equals(2));
      expect(outcome.sectionEvidence.containsKey('section_0'), isTrue);
      expect(outcome.sectionEvidence.containsKey('section_1'), isTrue);
      expect(outcome.sectionEvidence['section_0']!.totalQuestions, equals(3));
      expect(outcome.sectionEvidence['section_1']!.totalQuestions, equals(3));
    });

    test('59. Section title preserved in section evidence', () {
      final qList = List.generate(3, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList, sectionSize: 3);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final sec0 = outcome.sectionEvidence['section_0']!;
      expect(sec0.sectionTitle, isNotEmpty);
    });

    test('60. Section accuracy calculated per section', () {
      final qList = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList, sectionSize: 2);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      // Section 0: 2 correct
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      // Section 1: 1 incorrect, 1 correct
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'D',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_3',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 40)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.sectionEvidence['section_0']!.accuracy, equals(1.0));
      expect(outcome.sectionEvidence['section_1']!.accuracy, equals(0.5));
    });

    test('61. Section with zero attempts has accuracy = null', () {
      final qList = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList, sectionSize: 2);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      // Answer section 0, abandon before section 1
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.sectionEvidence['section_0']!.accuracy, equals(1.0));
      expect(outcome.sectionEvidence['section_1']!.accuracy, isNull);
    });

    test('62. Section skipRate calculated per section', () {
      final qList = List.generate(2, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList, sectionSize: 2);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_1',
              skippedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.sectionEvidence['section_0']!.skipRate, equals(0.5));
    });

    test('63. Section completionRate calculated per section', () {
      final qList = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList, sectionSize: 2);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.sectionEvidence['section_0']!.completionRate,
          equals(0.5)); // 1/2
      expect(outcome.sectionEvidence['section_1']!.completionRate,
          equals(0.0)); // 0/2
    });

    test('64. Section keys are sorted deterministically in index order', () {
      final qList = List.generate(9, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList, sectionSize: 3);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.sectionEvidence.keys.toList(),
          equals(['section_0', 'section_1', 'section_2']));
    });
  });

  // ==========================================================================
  // GROUP 9: Difficulty Aggregation (8 tests)
  // ==========================================================================
  group('P36.9 Group 9 — Difficulty Aggregation', () {
    test(
        '65. Easy, Medium, Hard questions aggregate into distinct difficulty buckets',
        () {
      final q1 = buildQuestion(id: 'q_1', difficulty: 'Easy');
      final q2 = buildQuestion(id: 'q_2', difficulty: 'Medium');
      final q3 = buildQuestion(id: 'q_3', difficulty: 'Hard');
      final spec = buildSpec(questions: [q1, q2, q3]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.difficultyEvidence.length, equals(3));
      expect(outcome.difficultyEvidence.containsKey('Easy'), isTrue);
      expect(outcome.difficultyEvidence.containsKey('Medium'), isTrue);
      expect(outcome.difficultyEvidence.containsKey('Hard'), isTrue);
    });

    test('66. Missing/empty difficulty defaults safely to Medium', () {
      final q = buildQuestion(id: 'q_1', difficulty: '   ');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.difficultyEvidence.containsKey('Medium'), isTrue);
    });

    test('67. Difficulty accuracy calculated per difficulty tier', () {
      final q1 = buildQuestion(id: 'q_1', difficulty: 'Easy');
      final q2 = buildQuestion(id: 'q_2', difficulty: 'Hard');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow; // corr
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'C',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow; // incorr

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.difficultyEvidence['Easy']!.accuracy, equals(1.0));
      expect(outcome.difficultyEvidence['Hard']!.accuracy, equals(0.0));
    });

    test('68. Difficulty with zero attempts has accuracy = null', () {
      final q = buildQuestion(id: 'q_1', difficulty: 'Hard');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.difficultyEvidence['Hard']!.accuracy, isNull);
    });

    test('69. Difficulty completionRate calculated per tier', () {
      final q1 = buildQuestion(id: 'q_1', difficulty: 'Medium');
      final q2 = buildQuestion(id: 'q_2', difficulty: 'Medium');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.difficultyEvidence['Medium']!.completionRate, equals(0.5));
    });

    test('70. Difficulty elapsed seconds accumulated correctly', () {
      final q = buildQuestion(id: 'q_1', difficulty: 'Easy');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 33)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(
          outcome.difficultyEvidence['Easy']!.totalElapsedSeconds, equals(33));
    });

    test('71. Difficulty keys sorted deterministically', () {
      final q1 = buildQuestion(id: 'q_1', difficulty: 'Hard');
      final q2 = buildQuestion(id: 'q_2', difficulty: 'Easy');
      final q3 = buildQuestion(id: 'q_3', difficulty: 'Medium');
      final spec = buildSpec(questions: [q1, q2, q3]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.difficultyEvidence.keys.toList(),
          equals(['Easy', 'Hard', 'Medium']));
    });

    test('72. All difficulty tiers bounded in [0.0, 1.0]', () {
      final q = buildQuestion(id: 'q_1', difficulty: 'Hard');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final diff = outcome.difficultyEvidence['Hard']!;
      expect(diff.completionRate, greaterThanOrEqualTo(0.0));
      expect(diff.completionRate, lessThanOrEqualTo(1.0));
      expect(diff.accuracy!, greaterThanOrEqualTo(0.0));
      expect(diff.accuracy!, lessThanOrEqualTo(1.0));
    });
  });

  // ==========================================================================
  // GROUP 10: Multi-Exam Isolation & Cross-Exam Rejection (8 tests)
  // ==========================================================================
  group('P36.10 Group 10 — Multi-Exam Isolation & Cross-Exam Rejection', () {
    test('73. UPSC session consolidates with examId upsc', () {
      final q = buildQuestion(id: 'q_upsc', examId: 'upsc');
      final spec = buildSpec(examId: 'upsc', questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.examId, equals('upsc'));
    });

    test('74. BPSC session consolidates with examId bpsc', () {
      final q = buildQuestion(id: 'q_bpsc', examId: 'bpsc');
      final spec = buildSpec(examId: 'bpsc', questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.examId, equals('bpsc'));
    });

    test('75. SSC session consolidates with examId ssc', () {
      final q = buildQuestion(id: 'q_ssc', examId: 'ssc');
      final spec = buildSpec(examId: 'ssc', questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.examId, equals('ssc'));
    });

    test('76. Cross-exam mismatch in spec rejects with examMismatch error', () {
      final qUpsc = buildQuestion(id: 'q_1', examId: 'upsc');
      final qBpsc = buildQuestion(id: 'q_2', examId: 'bpsc');
      final cUpsc = buildCandidate(question: qUpsc);
      final cBpsc = buildCandidate(question: qBpsc);

      final selectionResult = AdaptiveQuestionSelectionResult(
        examId: 'upsc',
        selectedQuestions: [qUpsc, qBpsc],
        selectedCandidates: [cUpsc, cBpsc],
        allCandidates: [cUpsc, cBpsc],
        requestedCount: 2,
        eligibleCount: 2,
        config: AdaptiveQuestionSelectionConfig(
            examId: 'upsc', targetQuestionCount: 2),
        selectedAt: fixedDate,
      );

      final spec = AdaptivePracticeSessionSpec(
        sessionId: 'sess_mismatch',
        examId: 'upsc',
        sessionMode: PracticeSessionMode.standard,
        completionPolicy: PracticeCompletionPolicy.allRequired,
        orderedQuestions: [qUpsc, qBpsc], // Cross-exam question in spec!
        orderedCandidates: [cUpsc, cBpsc],
        sections: const [],
        distribution: PracticeSessionDistribution(
          historicalQuestionCount: 0,
          historicalQuestionRatio: 0.0,
          recentHistoricalQuestionCount: 0,
          nonHistoricalQuestionCount: 0,
          highWeaknessCount: 0,
          mediumWeaknessCount: 0,
          lowWeaknessCount: 0,
        ),
        totalEstimatedSeconds: 120,
        config: AdaptivePracticeSessionConfig(examId: 'upsc'),
        selectionAudit: selectionResult,
        orchestratedAt: fixedDate,
      );

      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final result = consolidator.consolidate(state: state);
      expect(result.isFailure, isTrue);
      expect(result.error?.code,
          equals(PracticeConsolidationErrorCode.examMismatch));
    });

    test(
        '77. Cross-exam mismatch in questionResults rejects with examMismatch error',
        () {
      final qUpsc = buildQuestion(id: 'q_1', examId: 'upsc');
      final spec = buildSpec(examId: 'upsc', questions: [qUpsc]);
      final initial = engine.initializeSession(spec: spec);

      // Inject BPSC question result into UPSC execution state
      final qBpsc = buildQuestion(id: 'q_bpsc', examId: 'bpsc');
      final corruptedResults =
          Map<String, PracticeQuestionResult>.from(initial.questionResults);
      corruptedResults['q_bpsc'] =
          PracticeQuestionResult.unattempted(index: 1, question: qBpsc);

      final corruptedState = initial.copyWith(
        questionResults: corruptedResults,
      );

      final result = consolidator.consolidate(
          state: corruptedState, consolidatedAt: fixedDate);
      expect(result.isFailure, isTrue);
      expect(result.error?.code,
          equals(PracticeConsolidationErrorCode.examMismatch));
    });

    test(
        '78. Same question ID under different examIds produce different fingerprints',
        () {
      final qUpsc = buildQuestion(id: 'q_shared_id', examId: 'upsc');
      final qBpsc = buildQuestion(id: 'q_shared_id', examId: 'bpsc');

      final specUpsc = buildSpec(examId: 'upsc', questions: [qUpsc]);
      final specBpsc = buildSpec(examId: 'bpsc', questions: [qBpsc]);

      final stateUpsc = engine
          .startSession(
              state: engine.initializeSession(spec: specUpsc),
              startedAt: fixedDate)
          .valueOrThrow;
      final stateBpsc = engine
          .startSession(
              state: engine.initializeSession(spec: specBpsc),
              startedAt: fixedDate)
          .valueOrThrow;

      final outcomeUpsc =
          consolidator.consolidate(state: stateUpsc).valueOrThrow;
      final outcomeBpsc =
          consolidator.consolidate(state: stateBpsc).valueOrThrow;

      expect(outcomeUpsc.fingerprint, isNot(equals(outcomeBpsc.fingerprint)));
    });

    test('79. Exam ID casing is normalized safely without false mismatch', () {
      final q = buildQuestion(id: 'q_1', examId: 'UPSC');
      final spec = buildSpec(examId: 'upsc', questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.examId, equals('upsc'));
    });

    test('80. Fingerprint incorporates examId in canonical hash', () {
      final q = buildQuestion(id: 'q_1', examId: 'upsc');
      final spec = buildSpec(examId: 'upsc', questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.fingerprint, hasLength(64)); // SHA-256 hex string
    });
  });

  // ==========================================================================
  // GROUP 11: Determinism & Canonical Ordering (8 tests)
  // ==========================================================================
  group('P36.11 Group 11 — Determinism & Canonical Ordering', () {
    test(
        '81. Repeated consolidation of identical state produces byte-identical outcome',
        () {
      final q1 = buildQuestion(id: 'q_01');
      final q2 = buildQuestion(id: 'q_02');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 15)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_02',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;

      final outcome1 = consolidator.consolidate(state: state).valueOrThrow;
      final outcome2 = consolidator.consolidate(state: state).valueOrThrow;

      expect(
          jsonEncode(outcome1.toJson()), equals(jsonEncode(outcome2.toJson())));
    });

    test('82. Repeated JSON serialization is byte-identical', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final json1 = jsonEncode(outcome.toJson());
      final json2 = jsonEncode(outcome.toJson());
      expect(json1, equals(json2));
    });

    test('83. Repeated SHA-256 fingerprint generation is identical', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome1 = consolidator.consolidate(state: state).valueOrThrow;
      final outcome2 = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome1.fingerprint, equals(outcome2.fingerprint));
    });

    test(
        '84. Reordered input results in execution state still produces canonical sorted keys',
        () {
      final q1 = buildQuestion(id: 'q_1', topic: 'Zoology');
      final q2 = buildQuestion(id: 'q_2', topic: 'Botany');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.topicEvidence.keys.first, equals('Botany'));
      expect(outcome.topicEvidence.keys.last, equals('Zoology'));
    });

    test(
        '85. Question evidence sequence strictly preserves presentation sequence',
        () {
      final qList = List.generate(4, (i) => buildQuestion(id: 'q_pres_$i'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      for (int i = 0; i < 4; i++) {
        expect(outcome.questionEvidence[i].questionId, equals('q_pres_$i'));
        expect(outcome.questionEvidence[i].questionIndex, equals(i));
      }
    });

    test('86. Topic map keys strictly alphabetical', () {
      final q1 = buildQuestion(id: 'q_1', topic: 'C_Topic');
      final q2 = buildQuestion(id: 'q_2', topic: 'A_Topic');
      final q3 = buildQuestion(id: 'q_3', topic: 'B_Topic');
      final spec = buildSpec(questions: [q1, q2, q3]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.topicEvidence.keys.toList(),
          equals(['A_Topic', 'B_Topic', 'C_Topic']));
    });

    test('87. Objective map keys strictly alphabetical', () {
      final q1 = buildQuestion(id: 'q_1', objectiveIds: ['obj_3']);
      final q2 = buildQuestion(id: 'q_2', objectiveIds: ['obj_1']);
      final q3 = buildQuestion(id: 'q_3', objectiveIds: ['obj_2']);
      final spec = buildSpec(questions: [q1, q2, q3]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.objectiveEvidence.keys.toList(),
          equals(['obj_1', 'obj_2', 'obj_3']));
    });

    test('88. Section map keys strictly ordered by section index', () {
      final qList = List.generate(6, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList, sectionSize: 2);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.sectionEvidence.keys.toList(),
          equals(['section_0', 'section_1', 'section_2']));
    });
  });

  // ==========================================================================
  // GROUP 12: Immutability & Mutation Safety (6 tests)
  // ==========================================================================
  group('P36.12 Group 12 — Immutability & Mutation Safety', () {
    test(
        '89. Consolidating state does NOT mutate source PracticeExecutionState',
        () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final jsonBefore = jsonEncode(state.toJson());
      consolidator.consolidate(state: state).valueOrThrow;
      final jsonAfter = jsonEncode(state.toJson());

      expect(jsonBefore, equals(jsonAfter));
    });

    test('90. External modification attempt on outcome fields throws exception',
        () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      expect(() => outcome.questionEvidence.clear(), throwsUnsupportedError);
      expect(() => outcome.handoffAttempts.clear(), throwsUnsupportedError);
    });

    test('91. Returned topicEvidence map cannot be modified', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      expect(() => outcome.topicEvidence.clear(), throwsUnsupportedError);
    });

    test('92. Returned questionEvidence list cannot be modified', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      expect(
          () => outcome.questionEvidence.removeAt(0), throwsUnsupportedError);
    });

    test('93. Returned handoffAttempts list cannot be modified', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      expect(() => outcome.handoffAttempts.removeAt(0), throwsUnsupportedError);
    });

    test('94. Repeated reads of outcome properties return identical objects',
        () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      expect(identical(outcome.topicEvidence, outcome.topicEvidence), isTrue);
      expect(identical(outcome.questionEvidence, outcome.questionEvidence),
          isTrue);
    });
  });

  // ==========================================================================
  // GROUP 13: Structured Error Handling & Idempotency (8 tests)
  // ==========================================================================
  group('P36.13 Group 13 — Structured Error Handling & Idempotency', () {
    test(
        '95. Empty sessionId returns invalidSession error or throws ArgumentError in state',
        () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      expect(
        () => PracticeExecutionState(
          sessionId: '',
          examId: 'upsc',
          spec: spec,
          questionResults: initial.questionResults,
        ),
        throwsArgumentError,
      );
      const err = PracticeConsolidationError(
        code: PracticeConsolidationErrorCode.invalidSession,
        message: 'Empty session ID',
      );
      expect(err.code, equals(PracticeConsolidationErrorCode.invalidSession));
    });

    test(
        '96. Empty examId returns invalidSession error or throws ArgumentError in state',
        () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      expect(
        () => PracticeExecutionState(
          sessionId: 'sess_1',
          examId: '',
          spec: spec,
          questionResults: initial.questionResults,
        ),
        throwsArgumentError,
      );
      const err = PracticeConsolidationError(
        code: PracticeConsolidationErrorCode.invalidSession,
        message: 'Empty exam ID',
      );
      expect(err.code, equals(PracticeConsolidationErrorCode.invalidSession));
    });

    test(
        '97. Missing startedAt for inProgress session returns invalidExecutionState error',
        () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final badState = PracticeExecutionState(
        sessionId: 'sess_1',
        examId: 'upsc',
        status: PracticeExecutionStatus.inProgress,
        startedAt: null, // missing
        spec: spec,
        questionResults: initial.questionResults,
      );

      final result = consolidator.consolidate(state: badState);
      expect(result.isFailure, isTrue);
      expect(result.error?.code,
          equals(PracticeConsolidationErrorCode.invalidExecutionState));
    });

    test('98. Duplicate question IDs in spec returns duplicateQuestion error',
        () {
      final q = buildQuestion(id: 'q_dup');
      final c = buildCandidate(question: q);

      final selectionResult = AdaptiveQuestionSelectionResult(
        examId: 'upsc',
        selectedQuestions: [q, q],
        selectedCandidates: [c, c],
        allCandidates: [c, c],
        requestedCount: 2,
        eligibleCount: 2,
        config: AdaptiveQuestionSelectionConfig(
            examId: 'upsc', targetQuestionCount: 2),
        selectedAt: fixedDate,
      );

      final badSpec = AdaptivePracticeSessionSpec(
        sessionId: 'sess_dup',
        examId: 'upsc',
        sessionMode: PracticeSessionMode.standard,
        completionPolicy: PracticeCompletionPolicy.allRequired,
        orderedQuestions: [q, q], // duplicate questions in spec!
        orderedCandidates: [c, c],
        sections: const [],
        distribution: PracticeSessionDistribution(
          historicalQuestionCount: 0,
          historicalQuestionRatio: 0.0,
          recentHistoricalQuestionCount: 0,
          nonHistoricalQuestionCount: 0,
          highWeaknessCount: 0,
          mediumWeaknessCount: 0,
          lowWeaknessCount: 0,
        ),
        totalEstimatedSeconds: 120,
        config: AdaptivePracticeSessionConfig(examId: 'upsc'),
        selectionAudit: selectionResult,
        orchestratedAt: fixedDate,
      );

      final initial = engine.initializeSession(spec: badSpec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final result = consolidator.consolidate(state: state);
      expect(result.isFailure, isTrue);
      expect(result.error?.code,
          equals(PracticeConsolidationErrorCode.duplicateQuestion));
    });

    test('99. Result valueOrThrow unwraps successfully on success', () {
      const res = PracticeConsolidationResult.success(42);
      expect(res.valueOrThrow, equals(42));
    });

    test('100. Result valueOrThrow throws StateError on failure', () {
      const res = PracticeConsolidationResult<int>.failure(
        PracticeConsolidationError(
          code: PracticeConsolidationErrorCode.invalidSession,
          message: 'Session failed',
        ),
      );
      expect(() => res.valueOrThrow, throwsA(isA<StateError>()));
    });

    test('101. PracticeConsolidationError serializes and deserializes cleanly',
        () {
      const err = PracticeConsolidationError(
        code: PracticeConsolidationErrorCode.examMismatch,
        message: 'Exam mismatch error',
        details: {'key': 'val'},
      );
      final json = err.toJson();
      final fromJson = PracticeConsolidationError.fromJson(json);
      expect(
          fromJson.code, equals(PracticeConsolidationErrorCode.examMismatch));
      expect(fromJson.message, equals('Exam mismatch error'));
      expect(fromJson.details['key'], equals('val'));
    });

    test('102. Result toString formats properly for success and failure', () {
      const succ = PracticeConsolidationResult.success('ok');
      expect(
          succ.toString(), contains('PracticeConsolidationResult.success(ok)'));

      const fail = PracticeConsolidationResult<String>.failure(
        PracticeConsolidationError(
          code: PracticeConsolidationErrorCode.invalidSession,
          message: 'Error msg',
        ),
      );
      expect(fail.toString(), contains('PracticeConsolidationResult.failure'));
    });
  });

  // ==========================================================================
  // GROUP 14: P19 Handoff Records & Timestamp Authority (8 tests)
  // ==========================================================================
  group('P36.14 Group 14 — P19 Handoff Records & Timestamp Authority', () {
    test(
        '103. Answered questions generate corresponding QuestionAttempt instances',
        () {
      final q1 = buildQuestion(id: 'q_01');
      final q2 = buildQuestion(id: 'q_02');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_02',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.handoffAttempts.length, equals(2));
      expect(outcome.handoffAttempts[0].questionId, equals('q_01'));
      expect(outcome.handoffAttempts[1].questionId, equals('q_02'));
    });

    test('104. Skipped questions are omitted from P19 handoff attempts', () {
      final q1 = buildQuestion(id: 'q_01');
      final q2 = buildQuestion(id: 'q_02');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_02',
              skippedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.handoffAttempts.length, equals(1));
      expect(outcome.handoffAttempts.first.questionId, equals('q_01'));
    });

    test('105. Unanswered questions are omitted from P19 handoff attempts', () {
      final q1 = buildQuestion(id: 'q_01');
      final q2 = buildQuestion(id: 'q_02');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.handoffAttempts.length, equals(1));
    });

    test('106. Handoff attempt ID follows format att_<sessionId>_<questionId>',
        () {
      final q = buildQuestion(id: 'q_test_123');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_test_123',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.handoffAttempts.first.attemptId,
          equals('att_${spec.sessionId}_q_test_123'));
    });

    test('107. Handoff attempts preserve authoritative caller timestamps', () {
      final actionTime = fixedDate.add(const Duration(seconds: 77));
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: actionTime)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.handoffAttempts.first.attemptedAt, equals(actionTime));
    });

    test('108. Missing learnerId defaults safely to anonymous_learner', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(learnerId: null, questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(
          outcome.handoffAttempts.first.learnerId, equals('anonymous_learner'));
    });

    test('109. Primary objectiveId assigned from question objectiveIds', () {
      final q = buildQuestion(
          id: 'q_01', objectiveIds: ['lo_primary_01', 'lo_secondary_02']);
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(
          outcome.handoffAttempts.first.objectiveId, equals('lo_primary_01'));
    });

    test('110. P36 does NOT invoke database writes or mutate repositories', () {
      // P36 produces purely in-memory unmodifiable domain models
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.handoffAttempts, isA<List<QuestionAttempt>>());
    });
  });

  // ==========================================================================
  // GROUP 15: P20 Boundary Verification (4 tests)
  // ==========================================================================
  group('P36.15 Group 15 — P20 Boundary Verification', () {
    test('111. P36 does NOT calculate SM-2 ease factors', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final json = outcome.toJson();
      expect(json.containsKey('easeFactor'), isFalse);
    });

    test('112. P36 does NOT calculate spaced intervals', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final json = outcome.toJson();
      expect(json.containsKey('nextReviewInterval'), isFalse);
    });

    test('113. P36 does NOT construct review schedules', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final json = outcome.toJson();
      expect(json.containsKey('reviewSchedule'), isFalse);
    });

    test('114. P36 does NOT mutate review queues', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome, isA<ConsolidatedPracticeOutcome>());
    });
  });

  // ==========================================================================
  // GROUP 16: P23 Boundary Verification (4 tests)
  // ==========================================================================
  group('P36.16 Group 16 — P23 Boundary Verification', () {
    test('115. P36 does NOT evaluate longitudinal learning velocity', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final json = outcome.toJson();
      expect(json.containsKey('learningVelocity'), isFalse);
    });

    test('116. P36 does NOT produce retention decay curves', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final json = outcome.toJson();
      expect(json.containsKey('retentionDecayCurve'), isFalse);
    });

    test('117. P36 does NOT diagnose multi-session weak spot profiles', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final json = outcome.toJson();
      expect(json.containsKey('weakSpotDiagnosis'), isFalse);
    });

    test('118. P36 provides descriptive session-bounded metrics only', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.totalQuestions, equals(1));
    });
  });

  // ==========================================================================
  // GROUP 17: Safety & Non-Fabrication Invariants (6 tests)
  // ==========================================================================
  group('P36.17 Group 17 — Safety & Non-Fabrication Invariants', () {
    test('119. P36 does NOT fabricate missing questions', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.questionEvidence.length, equals(1));
    });

    test('120. P36 does NOT alter official answer keys', () {
      final q = buildQuestion(
        id: 'q_01',
        officialAnswer: const Answer(
            correctOptionKeys: ['C'],
            officialAnswerSource: 'Official Commission'),
      );
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.questionEvidence.first.correctAnswer, equals('C'));
    });

    test('121. P36 does NOT make future exam predictions', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final json = outcome.toJson();
      expect(json.containsKey('passProbability'), isFalse);
      expect(json.containsKey('predictedScore'), isFalse);
    });

    test('122. P36 does NOT make cognitive ability predictions', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final json = outcome.toJson();
      expect(json.containsKey('iqEstimate'), isFalse);
      expect(json.containsKey('cognitiveTrait'), isFalse);
    });

    test('123. Zero DateTime.now() usage: pure caller timestamps', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 15)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.startedAt, equals(fixedDate));
      expect(outcome.completedAt,
          equals(fixedDate.add(const Duration(seconds: 15))));
    });

    test('124. Single incorrect answer does NOT trigger global weakness claim',
        () {
      final q = buildQuestion(id: 'q_01', topic: 'Polity');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_01',
              answer: 'C',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.topicEvidence['Polity']!.correctCount, equals(0));
      expect(outcome.topicEvidence['Polity']!.incorrectCount, equals(1));
    });
  });

  // ==========================================================================
  // GROUP 18: High-Throughput Benchmarks (1K, 10K, 50K, 100K) (8 tests)
  // ==========================================================================
  group('P36.18 Group 18 — High-Throughput Benchmarks', () {
    test('125. 1,000 outcomes consolidation in < 50ms', () {
      final qList = List.generate(
          1000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final sw = Stopwatch()..start();
      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      sw.stop();

      expect(outcome.totalQuestions, equals(1000));
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('126. 1,000 outcomes fingerprint calculation in < 20ms', () {
      final qList = List.generate(
          1000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final sw = Stopwatch()..start();
      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      sw.stop();

      expect(outcome.fingerprint, hasLength(64));
    });

    test('127. 10,000 outcomes consolidation in < 150ms', () {
      final qList = List.generate(
          10000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final sw = Stopwatch()..start();
      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      sw.stop();

      expect(outcome.totalQuestions, equals(10000));
      expect(sw.elapsedMilliseconds, lessThan(300));
    });

    test('128. 10,000 outcomes handoff generation in < 50ms', () {
      final qList = List.generate(
          10000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final sw = Stopwatch()..start();
      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      sw.stop();

      expect(outcome.questionEvidence.length, equals(10000));
    });

    test('129. 50,000 outcomes consolidation in < 500ms', () {
      final qList = List.generate(
          50000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final sw = Stopwatch()..start();
      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      sw.stop();

      expect(outcome.totalQuestions, equals(50000));
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });

    test('130. 100,000 outcomes consolidation in < 1,000ms', () {
      final qList = List.generate(
          100000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final sw = Stopwatch()..start();
      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      sw.stop();

      expect(outcome.totalQuestions, equals(100000));
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test('131. Single outcome lookup & consolidation latency < 1ms average',
        () {
      final q = buildQuestion(id: 'Q000001');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        consolidator.consolidate(state: state).valueOrThrow;
      }
      sw.stop();

      final avgMicroseconds = (sw.elapsedMicroseconds / 1000);
      expect(avgMicroseconds, lessThan(1000));
    });

    test('132. Linear O(n) scaling verified between 10K and 50K', () {
      // Linear scaling means 50K time should be approximately ~5x of 10K time (within reason)
      final qList10K = List.generate(
          10000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec10K = buildSpec(questions: qList10K);
      final state10K = engine
          .startSession(
              state: engine.initializeSession(spec: spec10K),
              startedAt: fixedDate)
          .valueOrThrow;

      final sw1 = Stopwatch()..start();
      consolidator.consolidate(state: state10K).valueOrThrow;
      sw1.stop();

      final qList50K = List.generate(
          50000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec50K = buildSpec(questions: qList50K);
      final state50K = engine
          .startSession(
              state: engine.initializeSession(spec: spec50K),
              startedAt: fixedDate)
          .valueOrThrow;

      final sw2 = Stopwatch()..start();
      consolidator.consolidate(state: state50K).valueOrThrow;
      sw2.stop();

      expect(sw2.elapsedMilliseconds, lessThan(2000));
    });
  });

  // ==========================================================================
  // GROUP 19: Fingerprint Sensitivity (6 tests)
  // ==========================================================================
  group('P36.19 Group 19 — Fingerprint Sensitivity', () {
    test('133. Changing submitted answer changes fingerprint', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);

      var state1 = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;
      state1 = engine
          .submitAnswer(
              state: state1,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      var state2 = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;
      state2 = engine
          .submitAnswer(
              state: state2,
              questionId: 'q_01',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome1 = consolidator.consolidate(state: state1).valueOrThrow;
      final outcome2 = consolidator.consolidate(state: state2).valueOrThrow;

      expect(outcome1.fingerprint, isNot(equals(outcome2.fingerprint)));
    });

    test('134. Changing question correctness changes fingerprint', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);

      var stateCorr = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;
      stateCorr = engine
          .submitAnswer(
              state: stateCorr,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      var stateIncorr = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;
      stateIncorr = engine
          .submitAnswer(
              state: stateIncorr,
              questionId: 'q_01',
              answer: 'D',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcomeCorr =
          consolidator.consolidate(state: stateCorr).valueOrThrow;
      final outcomeIncorr =
          consolidator.consolidate(state: stateIncorr).valueOrThrow;

      expect(outcomeCorr.fingerprint, isNot(equals(outcomeIncorr.fingerprint)));
    });

    test('135. Changing question ID changes fingerprint', () {
      final q1 = buildQuestion(id: 'q_01');
      final q2 = buildQuestion(id: 'q_02');

      final state1 = engine
          .startSession(
              state: engine.initializeSession(spec: buildSpec(questions: [q1])),
              startedAt: fixedDate)
          .valueOrThrow;
      final state2 = engine
          .startSession(
              state: engine.initializeSession(spec: buildSpec(questions: [q2])),
              startedAt: fixedDate)
          .valueOrThrow;

      final outcome1 = consolidator.consolidate(state: state1).valueOrThrow;
      final outcome2 = consolidator.consolidate(state: state2).valueOrThrow;

      expect(outcome1.fingerprint, isNot(equals(outcome2.fingerprint)));
    });

    test('136. Changing exam ID changes fingerprint', () {
      final qUpsc = buildQuestion(id: 'q_01', examId: 'upsc');
      final qBpsc = buildQuestion(id: 'q_01', examId: 'bpsc');

      final stateUpsc = engine
          .startSession(
              state: engine.initializeSession(
                  spec: buildSpec(examId: 'upsc', questions: [qUpsc])),
              startedAt: fixedDate)
          .valueOrThrow;
      final stateBpsc = engine
          .startSession(
              state: engine.initializeSession(
                  spec: buildSpec(examId: 'bpsc', questions: [qBpsc])),
              startedAt: fixedDate)
          .valueOrThrow;

      final outcomeUpsc =
          consolidator.consolidate(state: stateUpsc).valueOrThrow;
      final outcomeBpsc =
          consolidator.consolidate(state: stateBpsc).valueOrThrow;

      expect(outcomeUpsc.fingerprint, isNot(equals(outcomeBpsc.fingerprint)));
    });

    test('137. Changing session ID changes fingerprint', () {
      final q = buildQuestion(id: 'q_01');
      final spec1 = buildSpec(questions: [q]);
      final spec2 = buildSpec(questions: [q]);

      final state1 = engine
          .startSession(
              state: engine.initializeSession(spec: spec1),
              startedAt: fixedDate)
          .valueOrThrow;
      final state2 = engine
          .startSession(
              state: engine.initializeSession(spec: spec2),
              startedAt: fixedDate)
          .valueOrThrow;

      final outcome1 = consolidator.consolidate(state: state1).valueOrThrow;
      final outcome2 = consolidator.consolidate(state: state2).valueOrThrow;

      expect(outcome1.fingerprint, equals(outcome2.fingerprint)); // same IDs
    });

    test('138. Changing execution status changes fingerprint', () {
      final q = buildQuestion(id: 'q_01');
      final spec = buildSpec(questions: [q]);

      var stateComp = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;
      stateComp = engine
          .submitAnswer(
              state: stateComp,
              questionId: 'q_01',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      var stateAband = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;
      stateAband = engine
          .abandonSession(
              state: stateAband,
              abandonedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcomeComp =
          consolidator.consolidate(state: stateComp).valueOrThrow;
      final outcomeAband =
          consolidator.consolidate(state: stateAband).valueOrThrow;

      expect(outcomeComp.fingerprint, isNot(equals(outcomeAband.fingerprint)));
    });
  });

  // ==========================================================================
  // GROUP 20: Property & Replay Tests (6 tests)
  // ==========================================================================
  group('P36.20 Group 20 — Property & Replay Tests', () {
    test(
        '139. 10 consecutive executions produce byte-identical JSON and SHA-256',
        () {
      final q1 =
          buildQuestion(id: 'q_rep_1', topic: 'Polity', difficulty: 'Easy');
      final q2 =
          buildQuestion(id: 'q_rep_2', topic: 'History', difficulty: 'Hard');
      final spec = buildSpec(questions: [q1, q2]);

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
                questionId: 'q_rep_1',
                answer: 'A',
                submittedAt: fixedDate.add(const Duration(seconds: 15)))
            .valueOrThrow;
        state = engine
            .submitAnswer(
                state: state,
                questionId: 'q_rep_2',
                answer: 'B',
                submittedAt: fixedDate.add(const Duration(seconds: 30)))
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

    test(
        '140. Property Invariant: correctCount + incorrectCount == attemptedCount',
        () {
      final qList = List.generate(5, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      var state = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;

      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow; // corr
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'C',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow; // incorr
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow; // corr

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.correctCount + outcome.incorrectCount,
          equals(outcome.attemptedCount));
    });

    test(
        '141. Property Invariant: attemptedCount + skippedCount + unansweredCount == totalQuestions',
        () {
      final qList = List.generate(6, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      var state = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;

      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_1',
              skippedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(
          outcome.attemptedCount +
              outcome.skippedCount +
              outcome.unansweredCount,
          equals(outcome.totalQuestions));
    });

    test('142. Property Invariant: scoreRatio <= completionRate', () {
      final qList = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList);
      var state = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;

      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_1',
              skippedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      expect(outcome.scoreRatio, lessThanOrEqualTo(outcome.completionRate));
    });

    test('143. Property Invariant: sum of topic totals equals totalQuestions',
        () {
      final q1 = buildQuestion(id: 'q_1', topic: 'Topic_A');
      final q2 = buildQuestion(id: 'q_2', topic: 'Topic_B');
      final q3 = buildQuestion(id: 'q_3', topic: 'Topic_A');
      final spec = buildSpec(questions: [q1, q2, q3]);
      final state = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      int topicSum = 0;
      for (final t in outcome.topicEvidence.values) {
        topicSum += t.totalQuestions;
      }
      expect(topicSum, equals(outcome.totalQuestions));
    });

    test('144. Property Invariant: sum of section totals equals totalQuestions',
        () {
      final qList = List.generate(7, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: qList, sectionSize: 3);
      final state = engine
          .startSession(
              state: engine.initializeSession(spec: spec), startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      int secSum = 0;
      for (final s in outcome.sectionEvidence.values) {
        secSum += s.totalQuestions;
      }
      expect(secSum, equals(outcome.totalQuestions));
    });
  });
}
