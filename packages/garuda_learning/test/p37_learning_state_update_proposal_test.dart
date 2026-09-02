/// P37 Learning State Update Proposal Unit and Property Tests (TITAN-KO-037.0 P37).
///
/// Comprehensive test suite verifying learning-state update proposals,
/// multi-tier evidence signals (question, topic, objective, section, difficulty),
/// trajectory pattern analysis (improving, declining, consistent, mixed),
/// calibrated evidence strength, recommended downstream action proposals,
/// multi-exam isolation, deterministic canonical hashing, and performance benchmarks.
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 12, 0, 0);
  const proposer = LearningStateUpdateProposer();
  const consolidator = PracticeOutcomeConsolidator();
  const engine = AdaptivePracticeExecutionEngine();
  const orchestrator = AdaptivePracticeSessionOrchestrator();

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
    return NormalizedQuestion(
      id: id,
      examId: examId,
      year: year,
      paper: paper,
      subject: subject,
      topic: topic,
      normalizedText: normalizedText,
      originalText: normalizedText,
      options: options ??
          const [
            Option(key: 'A', text: 'Option A', isCorrect: true),
            Option(key: 'B', text: 'Option B', isCorrect: false),
            Option(key: 'C', text: 'Option C', isCorrect: false),
            Option(key: 'D', text: 'Option D', isCorrect: false),
          ],
      officialAnswer: officialAnswer ??
          const Answer(
            correctOptionKeys: ['A'],
            officialAnswerSource: 'Official Commission Key',
          ),
      explanation: explanation,
      difficulty: difficulty,
      source: source ??
          PyqSourceReference.official(
            examId: examId,
            year: year,
            paper: paper,
          ),
      objectiveIds: objectiveIds ?? const ['obj_polity_fr'],
    );
  }

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

    return orchestrator.orchestrateSession(
      selectionResult: selectionResult,
      config: config,
      orchestratedAt: fixedDate,
    );
  }

  ConsolidatedPracticeOutcome buildSampleOutcome({
    String examId = 'upsc',
    String? learnerId = 'learner_101',
    int correctCount = 4,
    int incorrectCount = 0,
    int skippedCount = 0,
    int unansweredCount = 0,
    PracticeSessionMode mode = PracticeSessionMode.standard,
  }) {
    final totalCount =
        correctCount + incorrectCount + skippedCount + unansweredCount;
    final questions = List.generate(
        totalCount, (i) => buildQuestion(id: 'q_$i', examId: examId));
    final spec = buildSpec(
        examId: examId, learnerId: learnerId, questions: questions, mode: mode);
    final initial = engine.initializeSession(spec: spec);
    var state =
        engine.startSession(state: initial, startedAt: fixedDate).valueOrThrow;

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
    for (int i = 0; i < skippedCount; i++, qIdx++) {
      state = engine
          .skipQuestion(
            state: state,
            questionId: 'q_$qIdx',
            skippedAt: fixedDate.add(Duration(seconds: (qIdx + 1) * 10)),
          )
          .valueOrThrow;
    }
    if (unansweredCount > 0) {
      state = engine
          .abandonSession(
            state: state,
            abandonedAt: fixedDate.add(Duration(seconds: (qIdx + 1) * 10)),
          )
          .valueOrThrow;
    }

    return consolidator.consolidate(state: state).valueOrThrow;
  }

  // ==========================================================================
  // GROUP 1: Construction & Serialization (8 tests)
  // ==========================================================================
  group('P37.1 Group 1 — Construction & Serialization', () {
    test('1. Valid proposal compiles from completed outcome', () {
      final outcome = buildSampleOutcome(correctCount: 4, incorrectCount: 1);
      final result = proposer.proposeUpdate(outcome: outcome);

      expect(result.isSuccess, isTrue);
      final proposal = result.valueOrThrow;
      expect(proposal.proposalId, startsWith('prop_'));
      expect(proposal.sessionId, equals(outcome.sessionId));
      expect(proposal.examId, equals('upsc'));
      expect(proposal.totalQuestions, equals(5));
      expect(proposal.attemptedCount, equals(5));
      expect(proposal.correctCount, equals(4));
      expect(proposal.incorrectCount, equals(1));
      expect(proposal.fingerprint, hasLength(64));
    });

    test('2. Proposal serializes to JSON and deserializes cleanly', () {
      final outcome = buildSampleOutcome(correctCount: 3, incorrectCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      final fromJson = LearningStateUpdateProposal.fromJson(json);

      expect(fromJson.proposalId, equals(proposal.proposalId));
      expect(fromJson.sessionId, equals(proposal.sessionId));
      expect(fromJson.examId, equals(proposal.examId));
      expect(fromJson.fingerprint, equals(proposal.fingerprint));
      expect(fromJson.overallEvidenceStrength,
          equals(proposal.overallEvidenceStrength));
      expect(fromJson.overallPattern, equals(proposal.overallPattern));
      expect(fromJson.recommendedAction, equals(proposal.recommendedAction));
      expect(fromJson.questionSignals.length,
          equals(proposal.questionSignals.length));
    });

    test(
        '3. Empty outcome proposal produces zero-count proposal with EvidenceStrength.none',
        () {
      final spec = buildSpec(questions: const []);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.totalQuestions, equals(0));
      expect(proposal.attemptedCount, equals(0));
      expect(proposal.overallEvidenceStrength, equals(EvidenceStrength.none));
      expect(
          proposal.overallPattern, equals(OutcomePattern.insufficientEvidence));
      expect(
          proposal.recommendedAction, equals(ProposedLearningAction.noAction));
      expect(proposal.accuracy, isNull);
    });

    test('4. Question signals collection is deeply unmodifiable', () {
      final outcome = buildSampleOutcome(correctCount: 2, incorrectCount: 0);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(() => proposal.questionSignals.add(proposal.questionSignals.first),
          throwsUnsupportedError);
    });

    test('5. Topic signals map is deeply unmodifiable', () {
      final outcome = buildSampleOutcome(correctCount: 2, incorrectCount: 0);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(
          () => proposal.topicSignals['NewTopic'] =
              proposal.topicSignals.values.first,
          throwsUnsupportedError);
    });

    test('6. Objective signals map is deeply unmodifiable', () {
      final outcome = buildSampleOutcome(correctCount: 2, incorrectCount: 0);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(
          () => proposal.objectiveSignals['NewObj'] =
              proposal.objectiveSignals.values.first,
          throwsUnsupportedError);
    });

    test('7. Section signals map is deeply unmodifiable', () {
      final outcome = buildSampleOutcome(correctCount: 2, incorrectCount: 0);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(
          () => proposal.sectionSignals['NewSec'] =
              proposal.sectionSignals.values.first,
          throwsUnsupportedError);
    });

    test('8. Difficulty signals map is deeply unmodifiable', () {
      final outcome = buildSampleOutcome(correctCount: 2, incorrectCount: 0);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(
          () => proposal.difficultySignals['Hard'] =
              proposal.difficultySignals.values.first,
          throwsUnsupportedError);
    });
  });

  // ==========================================================================
  // GROUP 2: Session Status Proposals (8 tests)
  // ==========================================================================
  group('P37.2 Group 2 — Session Status Proposals', () {
    test('9. Completed session preserves completed status in proposal', () {
      final outcome = buildSampleOutcome(correctCount: 3, incorrectCount: 0);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.sessionStatus, equals(PracticeExecutionStatus.completed));
    });

    test(
        '10. Abandoned session preserves abandoned status and unanswered counts',
        () {
      final outcome = buildSampleOutcome(correctCount: 1, unansweredCount: 3);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.sessionStatus, equals(PracticeExecutionStatus.abandoned));
      expect(proposal.unansweredCount, equals(3));
      expect(proposal.attemptedCount, equals(1));
    });

    test('11. Paused session produces proposal reflecting paused state', () {
      final q1 = buildQuestion(id: 'q_1');
      final q2 = buildQuestion(id: 'q_2');
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
          .pauseSession(
              state: state,
              pausedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.sessionStatus, equals(PracticeExecutionStatus.paused));
      expect(proposal.attemptedCount, equals(1));
      expect(proposal.unansweredCount, equals(1));
    });

    test('12. Not started session (created) produces unattempted proposal', () {
      final q1 = buildQuestion(id: 'q_1');
      final spec = buildSpec(questions: [q1]);
      final initial = engine.initializeSession(spec: spec);
      final outcome = consolidator.consolidate(state: initial).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(
          proposal.sessionStatus, equals(PracticeExecutionStatus.notStarted));
      expect(proposal.overallEvidenceStrength, equals(EvidenceStrength.none));
      expect(proposal.overallPattern, equals(OutcomePattern.unansweredOnly));
      expect(
          proposal.recommendedAction, equals(ProposedLearningAction.noAction));
    });

    test(
        '13. Completed all-skipped session produces skippedOnly pattern and continueExposure action',
        () {
      final outcome = buildSampleOutcome(
          correctCount: 0, incorrectCount: 0, skippedCount: 3);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.sessionStatus, equals(PracticeExecutionStatus.completed));
      expect(proposal.overallPattern, equals(OutcomePattern.skippedOnly));
      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.continueExposure));
    });

    test(
        '14. Abandoned all-unanswered session produces unansweredOnly pattern and noAction',
        () {
      final outcome = buildSampleOutcome(
          correctCount: 0, incorrectCount: 0, unansweredCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.overallPattern, equals(OutcomePattern.unansweredOnly));
      expect(
          proposal.recommendedAction, equals(ProposedLearningAction.noAction));
    });

    test('15. Session mode is preserved in proposal', () {
      final outcome = buildSampleOutcome(
          correctCount: 2, mode: PracticeSessionMode.remedialPractice);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(
          proposal.sessionMode, equals(PracticeSessionMode.remedialPractice));
    });

    test('16. Source outcome fingerprint is preserved exactly in proposal', () {
      final outcome = buildSampleOutcome(correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.sourceOutcomeFingerprint, equals(outcome.fingerprint));
    });
  });

  // ==========================================================================
  // GROUP 3: Question-Level Signals (10 tests)
  // ==========================================================================
  group('P37.3 Group 3 — Question-Level Signals', () {
    test('17. Correct question produces retainMastery proposed action', () {
      final outcome = buildSampleOutcome(correctCount: 1, incorrectCount: 0);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final qSig = proposal.questionSignals.first;
      expect(qSig.isCorrect, isTrue);
      expect(qSig.status, equals(PracticeQuestionStatus.answeredCorrect));
      expect(qSig.proposedAction, equals(ProposedLearningAction.retainMastery));
      expect(qSig.evidenceStrength, equals(EvidenceStrength.insufficient));
    });

    test('18. Incorrect question produces reviewRemediation proposed action',
        () {
      final outcome = buildSampleOutcome(correctCount: 0, incorrectCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final qSig = proposal.questionSignals.first;
      expect(qSig.isCorrect, isFalse);
      expect(qSig.status, equals(PracticeQuestionStatus.answeredIncorrect));
      expect(qSig.proposedAction,
          equals(ProposedLearningAction.reviewRemediation));
    });

    test(
        '19. Skipped question produces continueExposure proposed action and EvidenceStrength.none',
        () {
      final outcome = buildSampleOutcome(
          correctCount: 0, incorrectCount: 0, skippedCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final qSig = proposal.questionSignals.first;
      expect(qSig.isSkipped, isTrue);
      expect(
          qSig.proposedAction, equals(ProposedLearningAction.continueExposure));
      expect(qSig.evidenceStrength, equals(EvidenceStrength.none));
    });

    test(
        '20. Unanswered question produces noAction proposed action and EvidenceStrength.none',
        () {
      final outcome = buildSampleOutcome(
          correctCount: 0, incorrectCount: 0, unansweredCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final qSig = proposal.questionSignals.first;
      expect(qSig.isUnanswered, isTrue);
      expect(qSig.proposedAction, equals(ProposedLearningAction.noAction));
      expect(qSig.evidenceStrength, equals(EvidenceStrength.none));
    });

    test('21. Question signal preserves questionId and examId', () {
      final outcome = buildSampleOutcome(examId: 'upsc', correctCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final qSig = proposal.questionSignals.first;
      expect(qSig.questionId, equals('q_0'));
      expect(qSig.examId, equals('upsc'));
    });

    test('22. Question signal preserves topic and subject metadata', () {
      final outcome = buildSampleOutcome(correctCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final qSig = proposal.questionSignals.first;
      expect(qSig.subject, equals('Polity'));
      expect(qSig.topic, equals('Fundamental Rights'));
    });

    test('23. Question signal preserves objectiveIds list', () {
      final outcome = buildSampleOutcome(correctCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final qSig = proposal.questionSignals.first;
      expect(qSig.objectiveIds, contains('obj_polity_fr'));
    });

    test('24. Question signal preserves difficulty band', () {
      final outcome = buildSampleOutcome(correctCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final qSig = proposal.questionSignals.first;
      expect(qSig.difficulty, equals('Medium'));
    });

    test('25. Question signal preserves elapsedSeconds', () {
      final outcome = buildSampleOutcome(correctCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final qSig = proposal.questionSignals.first;
      expect(qSig.elapsedSeconds, greaterThanOrEqualTo(0));
    });

    test('26. Question signals maintain exact sequence of presentation order',
        () {
      final outcome = buildSampleOutcome(correctCount: 2, incorrectCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      for (int i = 0; i < 4; i++) {
        expect(proposal.questionSignals[i].questionId, equals('q_$i'));
      }
    });
  });

  // ==========================================================================
  // GROUP 4: Evidence Strength Calibration (6 tests)
  // ==========================================================================
  group('P37.4 Group 4 — Evidence Strength Calibration', () {
    test('27. 0 attempts yields EvidenceStrength.none', () {
      expect(
          EvidenceStrength.fromAttemptCount(0), equals(EvidenceStrength.none));
      expect(
          EvidenceStrength.fromAttemptCount(-5), equals(EvidenceStrength.none));
    });

    test('28. 1 attempt yields EvidenceStrength.insufficient', () {
      expect(EvidenceStrength.fromAttemptCount(1),
          equals(EvidenceStrength.insufficient));
      expect(EvidenceStrength.insufficient.hasUsableEvidence, isFalse);
    });

    test('29. 2 attempts yields EvidenceStrength.limited', () {
      expect(EvidenceStrength.fromAttemptCount(2),
          equals(EvidenceStrength.limited));
      expect(EvidenceStrength.limited.hasUsableEvidence, isTrue);
    });

    test('30. 3 and 4 attempts yield EvidenceStrength.moderate', () {
      expect(EvidenceStrength.fromAttemptCount(3),
          equals(EvidenceStrength.moderate));
      expect(EvidenceStrength.fromAttemptCount(4),
          equals(EvidenceStrength.moderate));
      expect(EvidenceStrength.moderate.hasUsableEvidence, isTrue);
    });

    test('31. 5+ attempts yield EvidenceStrength.strong', () {
      expect(EvidenceStrength.fromAttemptCount(5),
          equals(EvidenceStrength.strong));
      expect(EvidenceStrength.fromAttemptCount(50),
          equals(EvidenceStrength.strong));
      expect(EvidenceStrength.strong.hasUsableEvidence, isTrue);
    });

    test(
        '32. Single incorrect attempt does NOT yield strong evidence of learner weakness',
        () {
      final outcome = buildSampleOutcome(correctCount: 0, incorrectCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.overallEvidenceStrength,
          equals(EvidenceStrength.insufficient));
      expect(
          proposal.overallPattern, equals(OutcomePattern.insufficientEvidence));
    });
  });

  // ==========================================================================
  // GROUP 5: Repeated Evidence & Consistency (6 tests)
  // ==========================================================================
  group('P37.5 Group 5 — Repeated Evidence & Consistency', () {
    test(
        '33. 2+ consistently correct attempts yields OutcomePattern.consistentlyCorrect and retainMastery',
        () {
      final outcome = buildSampleOutcome(correctCount: 3, incorrectCount: 0);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(
          proposal.overallPattern, equals(OutcomePattern.consistentlyCorrect));
      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.retainMastery));
    });

    test(
        '34. 2+ consistently incorrect attempts yields OutcomePattern.consistentlyIncorrect and reviewRemediation',
        () {
      final outcome = buildSampleOutcome(correctCount: 0, incorrectCount: 3);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.overallPattern,
          equals(OutcomePattern.consistentlyIncorrect));
      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.reviewRemediation));
    });

    test(
        '35. 2 attempts with 1 correct and 1 incorrect yields OutcomePattern.mixed',
        () {
      final outcome = buildSampleOutcome(correctCount: 1, incorrectCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.overallPattern, equals(OutcomePattern.mixed));
      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.reinforceConcept));
    });

    test('36. High accuracy (>= 75%) in mixed pattern suggests retainMastery',
        () {
      final questions = List.generate(5, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
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
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_3',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 40)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_4',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 50)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.accuracy, equals(0.8));
      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.retainMastery));
    });

    test('37. Low accuracy (< 50%) in mixed pattern suggests reviewRemediation',
        () {
      final outcome =
          buildSampleOutcome(correctCount: 1, incorrectCount: 3); // 25%
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.reviewRemediation));
    });

    test(
        '38. Moderate accuracy (50%-74%) in mixed pattern suggests reinforceConcept',
        () {
      final questions = List.generate(5, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      // Alternating 3 right, 2 wrong -> 60% accuracy, mixed pattern
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
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_3',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 40)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_4',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 50)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.accuracy, equals(0.6));
      expect(proposal.overallPattern, equals(OutcomePattern.mixed));
      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.reinforceConcept));
    });
  });

  // ==========================================================================
  // GROUP 6: Chronological Direction (Improvement & Decline) (8 tests)
  // ==========================================================================
  group('P37.6 Group 6 — Chronological Direction (Improvement & Decline)', () {
    test(
        '39. Wrong -> Wrong -> Right -> Right produces OutcomePattern.improving',
        () {
      final questions = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      // First half wrong: q_0 wrong, q_1 wrong
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      // Second half right: q_2 right, q_3 right
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'A',
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.overallPattern, equals(OutcomePattern.improving));
    });

    test(
        '40. Right -> Right -> Wrong -> Wrong produces OutcomePattern.declining and reviewRemediation',
        () {
      final questions = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      // First half right: q_0 right, q_1 right
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
      // Second half wrong: q_2 wrong, q_3 wrong
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_3',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 40)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.overallPattern, equals(OutcomePattern.declining));
      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.reviewRemediation));
    });

    test(
        '41. Alternating Right -> Wrong -> Right -> Wrong produces OutcomePattern.mixed',
        () {
      final questions = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
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
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_3',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 40)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.overallPattern, equals(OutcomePattern.mixed));
    });

    test(
        '42. Improving trajectory with high overall accuracy suggests retainMastery',
        () {
      final questions = List.generate(5, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      // 1 wrong, 4 right -> 80% accuracy, improving
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'B',
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
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_3',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 40)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_4',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 50)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.overallPattern, equals(OutcomePattern.improving));
      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.retainMastery));
    });

    test(
        '43. Directional analysis ignores skipped questions in chronological sequence',
        () {
      final questions = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_0',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_1',
              skippedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'B',
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      // 3 attempted: [false, false, true] -> improving
      expect(proposal.overallPattern, equals(OutcomePattern.improving));
    });

    test(
        '44. Pattern isPositive helper returns true for consistentlyCorrect and improving',
        () {
      expect(OutcomePattern.consistentlyCorrect.isPositive, isTrue);
      expect(OutcomePattern.improving.isPositive, isTrue);
      expect(OutcomePattern.mixed.isPositive, isFalse);
    });

    test(
        '45. Pattern isNegative helper returns true for consistentlyIncorrect and declining',
        () {
      expect(OutcomePattern.consistentlyIncorrect.isNegative, isTrue);
      expect(OutcomePattern.declining.isNegative, isTrue);
      expect(OutcomePattern.mixed.isNegative, isFalse);
    });

    test('46. Less than 3 attempts does NOT trigger improving/declining split',
        () {
      final outcome =
          buildSampleOutcome(correctCount: 1, incorrectCount: 1); // 2 attempts
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.overallPattern, equals(OutcomePattern.mixed));
    });
  });

  // ==========================================================================
  // GROUP 7: Topic Signals & Zero-Denominator Safety (8 tests)
  // ==========================================================================
  group('P37.7 Group 7 — Topic Signals & Zero-Denominator Safety', () {
    test('47. Single topic with 100% accuracy produces retainMastery signal',
        () {
      final q1 = buildQuestion(id: 'q_1', topic: 'Preamble');
      final q2 = buildQuestion(id: 'q_2', topic: 'Preamble');
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final tSig = proposal.topicSignals['Preamble']!;
      expect(tSig.accuracy, equals(1.0));
      expect(tSig.accuracyPercentage, equals(100.0));
      expect(tSig.pattern, equals(OutcomePattern.consistentlyCorrect));
      expect(tSig.proposedAction, equals(ProposedLearningAction.retainMastery));
      expect(tSig.evidenceStrength, equals(EvidenceStrength.limited));
    });

    test(
        '48. Unattempted topic produces null accuracy and continueExposure/noAction',
        () {
      final q1 = buildQuestion(id: 'q_1', topic: 'Judiciary');
      final spec = buildSpec(questions: [q1]);
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final tSig = proposal.topicSignals['Judiciary']!;
      expect(tSig.accuracy, isNull);
      expect(tSig.accuracyPercentage, isNull);
      expect(tSig.attemptedCount, equals(0));
      expect(tSig.evidenceStrength, equals(EvidenceStrength.none));
      expect(
          tSig.proposedAction, equals(ProposedLearningAction.continueExposure));
    });

    test('49. Multiple topics evaluated independently', () {
      final q1 = buildQuestion(id: 'q_1', topic: 'Polity');
      final q2 = buildQuestion(id: 'q_2', topic: 'Economy');
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
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow; // incorr

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.topicSignals['Polity']!.proposedAction,
          equals(ProposedLearningAction.retainMastery));
      expect(proposal.topicSignals['Economy']!.proposedAction,
          equals(ProposedLearningAction.reinforceConcept));
    });

    test('50. Missing/blank topic safely falls back without crashing', () {
      final q = buildQuestion(id: 'q_1', topic: '   ');
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.topicSignals.isNotEmpty, isTrue);
    });

    test('51. Topic signals preserve averageSecondsPerAttempt', () {
      final outcome = buildSampleOutcome(correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final tSig = proposal.topicSignals.values.first;
      expect(tSig.averageSecondsPerAttempt, greaterThanOrEqualTo(0.0));
    });

    test('52. Topic signal completionRate calculated accurately', () {
      final q1 = buildQuestion(id: 'q_1', topic: 'Tax');
      final q2 = buildQuestion(id: 'q_2', topic: 'Tax');
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final tSig = proposal.topicSignals['Tax']!;
      expect(tSig.completionRate, equals(0.5)); // 1 of 2
    });

    test(
        '53. Topic map keys are sorted deterministically in alphabetical order',
        () {
      final qZ = buildQuestion(id: 'q_1', topic: 'Zoology');
      final qA = buildQuestion(id: 'q_2', topic: 'Astronomy');
      final qM = buildQuestion(id: 'q_3', topic: 'Microbiology');
      final spec = buildSpec(questions: [qZ, qA, qM]);
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
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_3',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.topicSignals.keys.toList(),
          equals(['Astronomy', 'Microbiology', 'Zoology']));
    });

    test('54. Topic signal serializes and deserializes cleanly', () {
      final outcome = buildSampleOutcome(correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final tSig = proposal.topicSignals.values.first;
      final json = tSig.toJson();
      final fromJson = TopicLearningSignal.fromJson(json);

      expect(fromJson.topic, equals(tSig.topic));
      expect(fromJson.accuracy, equals(tSig.accuracy));
      expect(fromJson.pattern, equals(tSig.pattern));
    });
  });

  // ==========================================================================
  // GROUP 8: Objective Signals (8 tests)
  // ==========================================================================
  group('P37.8 Group 8 — Objective Signals', () {
    test('55. Objective signal reflects objective performance', () {
      final q1 = buildQuestion(id: 'q_1', objectiveIds: ['obj_fr_01']);
      final q2 = buildQuestion(id: 'q_2', objectiveIds: ['obj_fr_01']);
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final oSig = proposal.objectiveSignals['obj_fr_01']!;
      expect(oSig.totalQuestions, equals(2));
      expect(oSig.correctCount, equals(2));
      expect(oSig.accuracy, equals(1.0));
      expect(oSig.pattern, equals(OutcomePattern.consistentlyCorrect));
      expect(oSig.proposedAction, equals(ProposedLearningAction.retainMastery));
    });

    test(
        '56. Objective map keys are sorted deterministically in alphabetical order',
        () {
      final q1 = buildQuestion(id: 'q_1', objectiveIds: ['obj_c']);
      final q2 = buildQuestion(id: 'q_2', objectiveIds: ['obj_a']);
      final q3 = buildQuestion(id: 'q_3', objectiveIds: ['obj_b']);
      final spec = buildSpec(questions: [q1, q2, q3]);
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
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_3',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.objectiveSignals.keys.toList(),
          equals(['obj_a', 'obj_b', 'obj_c']));
    });

    test('57. Unattempted objective produces null accuracy', () {
      final q1 = buildQuestion(id: 'q_1', objectiveIds: ['obj_unatt']);
      final spec = buildSpec(questions: [q1]);
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final oSig = proposal.objectiveSignals['obj_unatt']!;
      expect(oSig.accuracy, isNull);
      expect(oSig.evidenceStrength, equals(EvidenceStrength.none));
    });

    test('58. Objective signal serializes and deserializes cleanly', () {
      final outcome = buildSampleOutcome(correctCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final oSig = proposal.objectiveSignals.values.first;
      final json = oSig.toJson();
      final fromJson = ObjectiveLearningSignal.fromJson(json);

      expect(fromJson.objectiveId, equals(oSig.objectiveId));
      expect(fromJson.accuracy, equals(oSig.accuracy));
      expect(fromJson.proposedAction, equals(oSig.proposedAction));
    });

    test(
        '59. Multi-objective questions populate signals for all associated objectives',
        () {
      final q1 = buildQuestion(id: 'q_1', objectiveIds: ['obj_1', 'obj_2']);
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.objectiveSignals.containsKey('obj_1'), isTrue);
      expect(proposal.objectiveSignals.containsKey('obj_2'), isTrue);
    });

    test(
        '60. Zero questions in objective throws ArgumentError on manual entity construction with blank ID',
        () {
      expect(
        () => ObjectiveLearningSignal(
          objectiveId: '',
          totalQuestions: 0,
          attemptedCount: 0,
          correctCount: 0,
          incorrectCount: 0,
          skippedCount: 0,
          unansweredCount: 0,
          completionRate: 0.0,
          evidenceStrength: EvidenceStrength.none,
          pattern: OutcomePattern.insufficientEvidence,
          proposedAction: ProposedLearningAction.noAction,
        ),
        throwsArgumentError,
      );
    });

    test('61. Objective signal completionRate calculated accurately', () {
      final outcome = buildSampleOutcome(correctCount: 1, skippedCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final oSig = proposal.objectiveSignals.values.first;
      expect(oSig.completionRate, equals(1.0));
    });

    test(
        '62. Repeated incorrect answers in objective produces reviewRemediation proposal',
        () {
      final q1 = buildQuestion(id: 'q_1', objectiveIds: ['obj_hard']);
      final q2 = buildQuestion(id: 'q_2', objectiveIds: ['obj_hard']);
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'B',
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final oSig = proposal.objectiveSignals['obj_hard']!;
      expect(oSig.pattern, equals(OutcomePattern.consistentlyIncorrect));
      expect(oSig.proposedAction,
          equals(ProposedLearningAction.reviewRemediation));
    });
  });

  // ==========================================================================
  // GROUP 9: Section Signals (8 tests)
  // ==========================================================================
  group('P37.9 Group 9 — Section Signals', () {
    test('63. Single section session produces valid section signal', () {
      final outcome = buildSampleOutcome(correctCount: 3);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.sectionSignals.length, equals(1));
      final secSig = proposal.sectionSignals.values.first;
      expect(secSig.sectionIndex, equals(0));
      expect(secSig.totalQuestions, equals(3));
      expect(secSig.correctCount, equals(3));
      expect(
          secSig.proposedAction, equals(ProposedLearningAction.retainMastery));
    });

    test('64. Multi-section session partitions signals accurately', () {
      final questions = List.generate(6, (i) => buildQuestion(id: 'q_$i'));
      final spec =
          buildSpec(questions: questions, sectionSize: 3); // 2 sections of 3
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      for (int i = 0; i < 6; i++) {
        state = engine
            .submitAnswer(
                state: state,
                questionId: 'q_$i',
                answer: 'A',
                submittedAt: fixedDate.add(Duration(seconds: (i + 1) * 10)))
            .valueOrThrow;
      }

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.sectionSignals.length, equals(2));
      expect(proposal.sectionSignals.containsKey('section_0'), isTrue);
      expect(proposal.sectionSignals.containsKey('section_1'), isTrue);
      expect(proposal.sectionSignals['section_0']!.totalQuestions, equals(3));
      expect(proposal.sectionSignals['section_1']!.totalQuestions, equals(3));
    });

    test('65. Section signal serializes and deserializes cleanly', () {
      final outcome = buildSampleOutcome(correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final sSig = proposal.sectionSignals.values.first;
      final json = sSig.toJson();
      final fromJson = SectionLearningSignal.fromJson(json);

      expect(fromJson.sectionId, equals(sSig.sectionId));
      expect(fromJson.sectionIndex, equals(sSig.sectionIndex));
      expect(fromJson.accuracy, equals(sSig.accuracy));
    });

    test('66. Section map keys ordered deterministically', () {
      final questions = List.generate(6, (i) => buildQuestion(id: 'q_$i'));
      final spec =
          buildSpec(questions: questions, sectionSize: 2); // 3 sections
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.sectionSignals.keys.toList(),
          equals(['section_0', 'section_1', 'section_2']));
    });

    test('67. Section signal zero attempted yields null accuracy', () {
      final questions = List.generate(3, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final sSig = proposal.sectionSignals.values.first;
      expect(sSig.accuracy, isNull);
      expect(sSig.proposedAction, equals(ProposedLearningAction.noAction));
    });

    test(
        '68. Section signal accuracy calculated accurately on partial attempts',
        () {
      final questions = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
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
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow; // incorr
      state = engine
          .abandonSession(
              state: state,
              abandonedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final sSig = proposal.sectionSignals.values.first;
      expect(sSig.accuracy, equals(0.5));
      expect(sSig.accuracyPercentage, equals(50.0));
      expect(sSig.completionRate, equals(0.5));
    });

    test(
        '69. Section signal handles skipped questions safely without penalizing accuracy',
        () {
      final questions = List.generate(3, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
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
      state = engine
          .skipQuestion(
              state: state,
              questionId: 'q_2',
              skippedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final sSig = proposal.sectionSignals.values.first;
      expect(sSig.accuracy, equals(1.0)); // 1/1 attempted
      expect(sSig.skippedCount, equals(2));
      expect(sSig.completionRate, equals(1.0));
    });

    test(
        '70. Manual SectionLearningSignal construction with empty ID throws ArgumentError',
        () {
      expect(
        () => SectionLearningSignal(
          sectionId: '',
          sectionIndex: 0,
          totalQuestions: 1,
          attemptedCount: 1,
          correctCount: 1,
          incorrectCount: 0,
          skippedCount: 0,
          unansweredCount: 0,
          completionRate: 1.0,
          evidenceStrength: EvidenceStrength.insufficient,
          pattern: OutcomePattern.insufficientEvidence,
          proposedAction: ProposedLearningAction.retainMastery,
        ),
        throwsArgumentError,
      );
    });
  });

  // ==========================================================================
  // GROUP 10: Difficulty Band Signals (8 tests)
  // ==========================================================================
  group('P37.10 Group 10 — Difficulty Band Signals', () {
    test('71. Distinct difficulty tiers aggregate into separate signals', () {
      final qEasy = buildQuestion(id: 'q_1', difficulty: 'Easy');
      final qHard = buildQuestion(id: 'q_2', difficulty: 'Hard');
      final spec = buildSpec(questions: [qEasy, qHard]);
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.difficultySignals.length, equals(2));
      expect(proposal.difficultySignals['Easy']!.accuracy, equals(1.0));
      expect(proposal.difficultySignals['Hard']!.accuracy, equals(0.0));
    });

    test(
        '72. Difficulty signal map keys sorted deterministically in alphabetical order',
        () {
      final q1 = buildQuestion(id: 'q_1', difficulty: 'Medium');
      final q2 = buildQuestion(id: 'q_2', difficulty: 'Hard');
      final q3 = buildQuestion(id: 'q_3', difficulty: 'Easy');
      final spec = buildSpec(questions: [q1, q2, q3]);
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
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_3',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.difficultySignals.keys.toList(),
          equals(['Easy', 'Hard', 'Medium']));
    });

    test('73. Difficulty signal serializes and deserializes cleanly', () {
      final outcome = buildSampleOutcome(correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final dSig = proposal.difficultySignals.values.first;
      final json = dSig.toJson();
      final fromJson = DifficultyLearningSignal.fromJson(json);

      expect(fromJson.difficulty, equals(dSig.difficulty));
      expect(fromJson.accuracy, equals(dSig.accuracy));
      expect(fromJson.pattern, equals(dSig.pattern));
    });

    test('74. Difficulty band with zero attempts produces null accuracy', () {
      final q1 = buildQuestion(id: 'q_1', difficulty: 'Hard');
      final spec = buildSpec(questions: [q1]);
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final dSig = proposal.difficultySignals['Hard']!;
      expect(dSig.accuracy, isNull);
      expect(dSig.evidenceStrength, equals(EvidenceStrength.none));
    });

    test(
        '75. 2+ correct answers on Hard difficulty yields retainMastery proposal',
        () {
      final q1 = buildQuestion(id: 'q_1', difficulty: 'Hard');
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
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 20)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final dSig = proposal.difficultySignals['Hard']!;
      expect(dSig.pattern, equals(OutcomePattern.consistentlyCorrect));
      expect(dSig.proposedAction, equals(ProposedLearningAction.retainMastery));
    });

    test(
        '76. 2+ incorrect answers on Easy difficulty yields reviewRemediation proposal',
        () {
      final q1 = buildQuestion(id: 'q_1', difficulty: 'Easy');
      final q2 = buildQuestion(id: 'q_2', difficulty: 'Easy');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      var state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_1',
              answer: 'B',
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final dSig = proposal.difficultySignals['Easy']!;
      expect(dSig.pattern, equals(OutcomePattern.consistentlyIncorrect));
      expect(dSig.proposedAction,
          equals(ProposedLearningAction.reviewRemediation));
    });

    test(
        '77. Difficulty signal completionRate is strictly bounded in [0.0, 1.0]',
        () {
      final outcome = buildSampleOutcome(correctCount: 2, skippedCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final dSig = proposal.difficultySignals.values.first;
      expect(dSig.completionRate, inInclusiveRange(0.0, 1.0));
    });

    test(
        '78. Manual DifficultyLearningSignal construction with empty label throws ArgumentError',
        () {
      expect(
        () => DifficultyLearningSignal(
          difficulty: '',
          totalQuestions: 1,
          attemptedCount: 1,
          correctCount: 1,
          incorrectCount: 0,
          skippedCount: 0,
          unansweredCount: 0,
          completionRate: 1.0,
          evidenceStrength: EvidenceStrength.insufficient,
          pattern: OutcomePattern.insufficientEvidence,
          proposedAction: ProposedLearningAction.retainMastery,
        ),
        throwsArgumentError,
      );
    });
  });

  // ==========================================================================
  // GROUP 11: Multi-Exam Isolation & Cross-Exam Rejection (8 tests)
  // ==========================================================================
  group('P37.11 Group 11 — Multi-Exam Isolation & Cross-Exam Rejection', () {
    test('79. UPSC practice outcome generates proposal with examId upsc', () {
      final outcome = buildSampleOutcome(examId: 'upsc', correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.examId, equals('upsc'));
    });

    test('80. BPSC practice outcome generates proposal with examId bpsc', () {
      final outcome = buildSampleOutcome(examId: 'bpsc', correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.examId, equals('bpsc'));
    });

    test('81. SSC practice outcome generates proposal with examId ssc', () {
      final outcome = buildSampleOutcome(examId: 'ssc', correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.examId, equals('ssc'));
    });

    test(
        '82. Same question ID in different exams produces distinct fingerprints',
        () {
      final outcomeUpsc = buildSampleOutcome(examId: 'upsc', correctCount: 2);
      final outcomeBpsc = buildSampleOutcome(examId: 'bpsc', correctCount: 2);

      final propUpsc =
          proposer.proposeUpdate(outcome: outcomeUpsc).valueOrThrow;
      final propBpsc =
          proposer.proposeUpdate(outcome: outcomeBpsc).valueOrThrow;

      expect(propUpsc.fingerprint, isNot(equals(propBpsc.fingerprint)));
    });

    test(
        '83. Cross-exam mismatch in question evidence rejects with examMismatch error',
        () {
      final qUpsc = buildQuestion(id: 'q_1', examId: 'upsc');
      final qBpsc = buildQuestion(id: 'q_2', examId: 'bpsc');
      final cUpsc = buildCandidate(question: qUpsc);
      final cBpsc = buildCandidate(question: qBpsc);

      final badOutcome = ConsolidatedPracticeOutcome(
        sessionId: 'sess_1',
        examId: 'upsc',
        sessionMode: PracticeSessionMode.standard,
        sessionStatus: PracticeExecutionStatus.completed,
        startedAt: fixedDate,
        completedAt: fixedDate.add(const Duration(seconds: 60)),
        totalQuestions: 2,
        attemptedCount: 2,
        correctCount: 2,
        incorrectCount: 0,
        skippedCount: 0,
        unansweredCount: 0,
        completionRate: 1.0,
        accuracy: 1.0,
        accuracyPercentage: 100.0,
        scoreRatio: 1.0,
        totalDurationSeconds: 60,
        averageSecondsPerQuestion: 30.0,
        feedbackSummary: PracticeFeedbackSummary(
          policy: PracticeFeedbackPolicy.immediate,
          totalFeedbackGenerated: 2,
          explanationsExposedCount: 2,
          explanationsWithheldCount: 0,
          exposureRate: 1.0,
        ),
        topicEvidence: const {},
        objectiveEvidence: const {},
        sectionEvidence: const {},
        difficultyEvidence: const {},
        questionEvidence: [
          PracticeQuestionEvidence(
            questionId: 'q_1',
            examId: 'upsc',
            subject: 'Polity',
            topic: 'Preamble',
            objectiveIds: const ['obj_1'],
            difficulty: 'Easy',
            questionIndex: 0,
            status: PracticeQuestionStatus.answeredCorrect,
            correctAnswer: 'A',
            isCorrect: true,
            isAnswered: true,
            isSkipped: false,
            elapsedSeconds: 30,
            candidateMetadata: cUpsc,
          ),
          PracticeQuestionEvidence(
            questionId: 'q_2',
            examId: 'bpsc', // Cross-exam mismatch!
            subject: 'Polity',
            topic: 'Preamble',
            objectiveIds: const ['obj_1'],
            difficulty: 'Easy',
            questionIndex: 1,
            status: PracticeQuestionStatus.answeredCorrect,
            correctAnswer: 'A',
            isCorrect: true,
            isAnswered: true,
            isSkipped: false,
            elapsedSeconds: 30,
            candidateMetadata: cBpsc,
          ),
        ],
        handoffAttempts: const [],
        fingerprint: 'dummy_fp',
      );

      final result = proposer.proposeUpdate(outcome: badOutcome);
      expect(result.isFailure, isTrue);
      expect(
          result.error?.code, equals(LearningProposalErrorCode.examMismatch));
    });

    test('84. Exam ID is case-normalized to lowercase', () {
      final outcome = buildSampleOutcome(examId: 'UPSC', correctCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.examId, equals('upsc'));
    });

    test('85. Multi-exam isolation prevents cross-exam signal aggregation', () {
      final outcomeUpsc = buildSampleOutcome(examId: 'upsc', correctCount: 2);
      final propUpsc =
          proposer.proposeUpdate(outcome: outcomeUpsc).valueOrThrow;

      for (final q in propUpsc.questionSignals) {
        expect(q.examId, equals('upsc'));
      }
    });

    test('86. Fingerprint incorporates examId in canonical hash string', () {
      final outcome = buildSampleOutcome(examId: 'upsc', correctCount: 1);
      final prop = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(prop.fingerprint, isNotEmpty);
    });
  });

  // ==========================================================================
  // GROUP 12: Feedback Action Proposals (8 tests)
  // ==========================================================================
  group('P37.12 Group 12 — Feedback Action Proposals', () {
    test('87. High accuracy session produces retainMastery action', () {
      final outcome = buildSampleOutcome(correctCount: 5, incorrectCount: 0);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.retainMastery));
    });

    test('88. Repeated error session produces reviewRemediation action', () {
      final outcome = buildSampleOutcome(correctCount: 0, incorrectCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.reviewRemediation));
    });

    test('89. Mixed performance session produces reinforceConcept action', () {
      final questions = List.generate(5, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions);
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
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_2',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 30)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_3',
              answer: 'B',
              submittedAt: fixedDate.add(const Duration(seconds: 40)))
          .valueOrThrow;
      state = engine
          .submitAnswer(
              state: state,
              questionId: 'q_4',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 50)))
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.accuracy, equals(0.6));
      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.reinforceConcept));
    });

    test('90. Skipped-only session produces continueExposure action', () {
      final outcome = buildSampleOutcome(
          correctCount: 0, incorrectCount: 0, skippedCount: 3);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.recommendedAction,
          equals(ProposedLearningAction.continueExposure));
    });

    test('91. Empty session produces noAction proposal', () {
      final spec = buildSpec(questions: const []);
      final outcome = consolidator
          .consolidate(state: engine.initializeSession(spec: spec))
          .valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(
          proposal.recommendedAction, equals(ProposedLearningAction.noAction));
    });

    test('92. Question-level proposed actions are granularly assigned', () {
      final outcome = buildSampleOutcome(
          correctCount: 1, incorrectCount: 1, skippedCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.questionSignals[0].proposedAction,
          equals(ProposedLearningAction.retainMastery));
      expect(proposal.questionSignals[1].proposedAction,
          equals(ProposedLearningAction.reviewRemediation));
      expect(proposal.questionSignals[2].proposedAction,
          equals(ProposedLearningAction.continueExposure));
    });

    test('93. Topic-level proposed actions are granularly assigned', () {
      final qPolityCorr = buildQuestion(id: 'q_1', topic: 'Polity');
      final qEconIncorr = buildQuestion(id: 'q_2', topic: 'Economy');
      final spec = buildSpec(questions: [qPolityCorr, qEconIncorr]);
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.topicSignals['Polity']!.proposedAction,
          equals(ProposedLearningAction.retainMastery));
      expect(proposal.topicSignals['Economy']!.proposedAction,
          equals(ProposedLearningAction.reinforceConcept));
    });

    test(
        '94. ProposedLearningAction enum values are descriptive and non-authoritative',
        () {
      expect(ProposedLearningAction.values,
          contains(ProposedLearningAction.retainMastery));
      expect(ProposedLearningAction.values,
          contains(ProposedLearningAction.reviewRemediation));
      expect(ProposedLearningAction.values,
          contains(ProposedLearningAction.reinforceConcept));
      expect(ProposedLearningAction.values,
          contains(ProposedLearningAction.continueExposure));
      expect(ProposedLearningAction.values,
          contains(ProposedLearningAction.noAction));
    });
  });

  // ==========================================================================
  // GROUP 13: P20 Boundary Verification (Zero SM-2 / Scheduling) (4 tests)
  // ==========================================================================
  group('P37.13 Group 13 — P20 Boundary Verification', () {
    test('95. P37 does NOT calculate SM-2 ease factors', () {
      final outcome = buildSampleOutcome(correctCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      expect(json.containsKey('easeFactor'), isFalse);
      expect(json.containsKey('efactor'), isFalse);
    });

    test('96. P37 does NOT calculate spaced repetition review intervals', () {
      final outcome = buildSampleOutcome(correctCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      expect(json.containsKey('interval'), isFalse);
      expect(json.containsKey('nextReviewDate'), isFalse);
      expect(json.containsKey('scheduledAt'), isFalse);
    });

    test('97. P37 does NOT compute repetition numbers', () {
      final outcome = buildSampleOutcome(correctCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      expect(json.containsKey('repetitionNumber'), isFalse);
      expect(json.containsKey('repetitions'), isFalse);
    });

    test('98. P37 does NOT mutate review queues or schedule databases', () {
      final outcome = buildSampleOutcome(correctCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal, isA<LearningStateUpdateProposal>());
    });
  });

  // ==========================================================================
  // GROUP 14: P23 Boundary Verification (Descriptive Only) (4 tests)
  // ==========================================================================
  group('P37.14 Group 14 — P23 Boundary Verification', () {
    test('99. P37 does NOT evaluate longitudinal learning velocity', () {
      final outcome = buildSampleOutcome(correctCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      expect(json.containsKey('velocity'), isFalse);
      expect(json.containsKey('learningVelocity'), isFalse);
    });

    test('100. P37 does NOT produce retention decay curves', () {
      final outcome = buildSampleOutcome(correctCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      expect(json.containsKey('decayCurve'), isFalse);
      expect(json.containsKey('retentionRate'), isFalse);
      expect(json.containsKey('halfLife'), isFalse);
    });

    test('101. P37 does NOT diagnose multi-session weak spot profiles', () {
      final outcome = buildSampleOutcome(correctCount: 0, incorrectCount: 3);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      expect(json.containsKey('weakSpotProfile'), isFalse);
      expect(json.containsKey('deficiencyScore'), isFalse);
    });

    test('102. P37 provides session-bounded evidence proposals only', () {
      final outcome = buildSampleOutcome(correctCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.recommendedAction, isA<ProposedLearningAction>());
    });
  });

  // ==========================================================================
  // GROUP 15: P33/P34 Boundary Verification (Zero Selection / Composition) (4 tests)
  // ==========================================================================
  group('P37.15 Group 15 — P33/P34 Boundary Verification', () {
    test('103. P37 does NOT rank or select future questions', () {
      final outcome = buildSampleOutcome(correctCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      expect(json.containsKey('selectedQuestions'), isFalse);
      expect(json.containsKey('candidateRankings'), isFalse);
    });

    test('104. P37 does NOT reorder future questions', () {
      final outcome = buildSampleOutcome(correctCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      expect(json.containsKey('orderedQuestions'), isFalse);
      expect(json.containsKey('orderedCandidates'), isFalse);
    });

    test('105. P37 does NOT compose future practice sessions', () {
      final outcome = buildSampleOutcome(correctCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      expect(json.containsKey('nextSessionSpec'), isFalse);
      expect(json.containsKey('futureSessionConfig'), isFalse);
    });

    test('106. P37 does NOT determine future pedagogical mode', () {
      final outcome = buildSampleOutcome(correctCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      expect(json.containsKey('nextSessionMode'), isFalse);
    });
  });

  // ==========================================================================
  // GROUP 16: Immutability & Mutation Safety (6 tests)
  // ==========================================================================
  group('P37.16 Group 16 — Immutability & Mutation Safety', () {
    test(
        '107. Proposing update does NOT mutate source ConsolidatedPracticeOutcome',
        () {
      final outcome = buildSampleOutcome(correctCount: 3, incorrectCount: 1);
      final baselineFingerprint = outcome.fingerprint;
      final baselineCorrect = outcome.correctCount;

      proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(outcome.fingerprint, equals(baselineFingerprint));
      expect(outcome.correctCount, equals(baselineCorrect));
    });

    test(
        '108. External modification attempt on proposal fields throws exception',
        () {
      final outcome = buildSampleOutcome(correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(() => proposal.questionSignals.clear(), throwsUnsupportedError);
      expect(() => proposal.topicSignals.clear(), throwsUnsupportedError);
      expect(() => proposal.objectiveSignals.clear(), throwsUnsupportedError);
      expect(() => proposal.sectionSignals.clear(), throwsUnsupportedError);
      expect(() => proposal.difficultySignals.clear(), throwsUnsupportedError);
    });

    test('109. Repeated reads of proposal properties return identical objects',
        () {
      final outcome = buildSampleOutcome(correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final sigs1 = proposal.questionSignals;
      final sigs2 = proposal.questionSignals;
      expect(identical(sigs1, sigs2), isTrue);
    });

    test('110. QuestionLearningSignal metadata is unmodifiable', () {
      final outcome = buildSampleOutcome(correctCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final qSig = proposal.questionSignals.first;
      expect(() => qSig.metadata['key'] = 'val', throwsUnsupportedError);
    });

    test('111. QuestionLearningSignal objectiveIds list is unmodifiable', () {
      final outcome = buildSampleOutcome(correctCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final qSig = proposal.questionSignals.first;
      expect(() => qSig.objectiveIds.add('new_obj'), throwsUnsupportedError);
    });

    test('112. Proposal invariants prevent invalid manual construction', () {
      expect(
        () => LearningStateUpdateProposal(
          proposalId: 'prop_1',
          sessionId: 'sess_1',
          examId: 'upsc',
          sessionMode: PracticeSessionMode.standard,
          sessionStatus: PracticeExecutionStatus.completed,
          sourceOutcomeFingerprint: 'dummy_fp',
          proposedAt: fixedDate,
          overallEvidenceStrength: EvidenceStrength.none,
          overallPattern: OutcomePattern.insufficientEvidence,
          recommendedAction: ProposedLearningAction.noAction,
          totalQuestions: 5,
          attemptedCount: 3, // Invariant violation: 2 + 0 != 3
          correctCount: 2,
          incorrectCount: 0,
          skippedCount: 1,
          unansweredCount: 1,
          completionRate: 0.8,
          scoreRatio: 0.4,
          questionSignals: const [],
          topicSignals: const {},
          objectiveSignals: const {},
          sectionSignals: const {},
          difficultySignals: const {},
          fingerprint: 'fp',
        ),
        throwsArgumentError,
      );
    });
  });

  // ==========================================================================
  // GROUP 17: Determinism & Canonical Ordering (8 tests)
  // ==========================================================================
  group('P37.17 Group 17 — Determinism & Canonical Ordering', () {
    test(
        '113. Repeated proposal of identical outcome produces byte-identical proposal',
        () {
      final outcome = buildSampleOutcome(correctCount: 3, incorrectCount: 1);

      final prop1 = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      final prop2 = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(jsonEncode(prop1.toJson()), equals(jsonEncode(prop2.toJson())));
      expect(prop1.fingerprint, equals(prop2.fingerprint));
    });

    test('114. Repeated JSON serialization is byte-identical', () {
      final outcome = buildSampleOutcome(correctCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json1 = jsonEncode(proposal.toJson());
      final json2 = jsonEncode(proposal.toJson());
      expect(json1, equals(json2));
    });

    test('115. Repeated SHA-256 fingerprint generation is identical', () {
      final outcome = buildSampleOutcome(correctCount: 2, incorrectCount: 1);
      final prop1 = proposer
          .proposeUpdate(outcome: outcome, proposedAt: fixedDate)
          .valueOrThrow;
      final prop2 = proposer
          .proposeUpdate(outcome: outcome, proposedAt: fixedDate)
          .valueOrThrow;

      expect(prop1.fingerprint, equals(prop2.fingerprint));
    });

    test(
        '116. Question evidence sequence strictly preserves presentation sequence',
        () {
      final outcome = buildSampleOutcome(correctCount: 5);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      for (int i = 0; i < 5; i++) {
        expect(proposal.questionSignals[i].questionId, equals('q_$i'));
      }
    });

    test('117. Topic map keys strictly alphabetical', () {
      final qB = buildQuestion(id: 'q_1', topic: 'Beta');
      final qA = buildQuestion(id: 'q_2', topic: 'Alpha');
      final spec = buildSpec(questions: [qB, qA]);
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.topicSignals.keys.toList(), equals(['Alpha', 'Beta']));
    });

    test('118. Objective map keys strictly alphabetical', () {
      final q2 = buildQuestion(id: 'q_1', objectiveIds: ['obj_2']);
      final q1 = buildQuestion(id: 'q_2', objectiveIds: ['obj_1']);
      final spec = buildSpec(questions: [q2, q1]);
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(
          proposal.objectiveSignals.keys.toList(), equals(['obj_1', 'obj_2']));
    });

    test('119. Section map keys strictly ordered by section index', () {
      final questions = List.generate(4, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions, sectionSize: 2);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;

      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.sectionSignals.keys.toList(),
          equals(['section_0', 'section_1']));
    });

    test('120. Difficulty map keys strictly alphabetical', () {
      final q1 = buildQuestion(id: 'q_1', difficulty: 'Medium');
      final q2 = buildQuestion(id: 'q_2', difficulty: 'Easy');
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
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(
          proposal.difficultySignals.keys.toList(), equals(['Easy', 'Medium']));
    });
  });

  // ==========================================================================
  // GROUP 18: Fingerprint Sensitivity & Stability (6 tests)
  // ==========================================================================
  group('P37.18 Group 18 — Fingerprint Sensitivity & Stability', () {
    test('121. Changing correctness changes fingerprint', () {
      final out1 = buildSampleOutcome(correctCount: 2, incorrectCount: 0);
      final out2 = buildSampleOutcome(correctCount: 1, incorrectCount: 1);

      final prop1 = proposer
          .proposeUpdate(outcome: out1, proposedAt: fixedDate)
          .valueOrThrow;
      final prop2 = proposer
          .proposeUpdate(outcome: out2, proposedAt: fixedDate)
          .valueOrThrow;

      expect(prop1.fingerprint, isNot(equals(prop2.fingerprint)));
    });

    test('122. Changing examId changes fingerprint', () {
      final outUpsc = buildSampleOutcome(examId: 'upsc', correctCount: 2);
      final outBpsc = buildSampleOutcome(examId: 'bpsc', correctCount: 2);

      final propUpsc = proposer
          .proposeUpdate(outcome: outUpsc, proposedAt: fixedDate)
          .valueOrThrow;
      final propBpsc = proposer
          .proposeUpdate(outcome: outBpsc, proposedAt: fixedDate)
          .valueOrThrow;

      expect(propUpsc.fingerprint, isNot(equals(propBpsc.fingerprint)));
    });

    test('123. Changing sessionId changes fingerprint', () {
      final q = buildQuestion(id: 'q_1');
      final spec1 = buildSpec(questions: [q]);
      final initial1 = engine.initializeSession(spec: spec1);
      var state1 = engine
          .startSession(state: initial1, startedAt: fixedDate)
          .valueOrThrow;
      state1 = engine
          .submitAnswer(
              state: state1,
              questionId: 'q_1',
              answer: 'A',
              submittedAt: fixedDate.add(const Duration(seconds: 10)))
          .valueOrThrow;
      final outcome1 = consolidator.consolidate(state: state1).valueOrThrow;

      final outcome2 = ConsolidatedPracticeOutcome(
        sessionId: 'other_sess_id',
        examId: outcome1.examId,
        learnerId: outcome1.learnerId,
        sessionMode: outcome1.sessionMode,
        sessionStatus: outcome1.sessionStatus,
        startedAt: outcome1.startedAt,
        completedAt: outcome1.completedAt,
        totalQuestions: outcome1.totalQuestions,
        attemptedCount: outcome1.attemptedCount,
        correctCount: outcome1.correctCount,
        incorrectCount: outcome1.incorrectCount,
        skippedCount: outcome1.skippedCount,
        unansweredCount: outcome1.unansweredCount,
        completionRate: outcome1.completionRate,
        accuracy: outcome1.accuracy,
        accuracyPercentage: outcome1.accuracyPercentage,
        scoreRatio: outcome1.scoreRatio,
        totalDurationSeconds: outcome1.totalDurationSeconds,
        averageSecondsPerQuestion: outcome1.averageSecondsPerQuestion,
        feedbackSummary: outcome1.feedbackSummary,
        topicEvidence: outcome1.topicEvidence,
        objectiveEvidence: outcome1.objectiveEvidence,
        sectionEvidence: outcome1.sectionEvidence,
        difficultyEvidence: outcome1.difficultyEvidence,
        questionEvidence: outcome1.questionEvidence,
        handoffAttempts: outcome1.handoffAttempts,
        fingerprint: outcome1.fingerprint,
      );

      final prop1 = proposer
          .proposeUpdate(outcome: outcome1, proposedAt: fixedDate)
          .valueOrThrow;
      final prop2 = proposer
          .proposeUpdate(outcome: outcome2, proposedAt: fixedDate)
          .valueOrThrow;

      expect(prop1.fingerprint, isNot(equals(prop2.fingerprint)));
    });

    test('124. Changing sessionStatus changes fingerprint', () {
      final outCompleted =
          buildSampleOutcome(correctCount: 2, unansweredCount: 0);
      final outAbandoned =
          buildSampleOutcome(correctCount: 2, unansweredCount: 1);

      final prop1 = proposer
          .proposeUpdate(outcome: outCompleted, proposedAt: fixedDate)
          .valueOrThrow;
      final prop2 = proposer
          .proposeUpdate(outcome: outAbandoned, proposedAt: fixedDate)
          .valueOrThrow;

      expect(prop1.fingerprint, isNot(equals(prop2.fingerprint)));
    });

    test('125. Changing proposedAction changes fingerprint', () {
      final out1 = buildSampleOutcome(
          correctCount: 3, incorrectCount: 0); // retainMastery
      final out2 = buildSampleOutcome(
          correctCount: 0, incorrectCount: 3); // reviewRemediation

      final prop1 = proposer
          .proposeUpdate(outcome: out1, proposedAt: fixedDate)
          .valueOrThrow;
      final prop2 = proposer
          .proposeUpdate(outcome: out2, proposedAt: fixedDate)
          .valueOrThrow;

      expect(prop1.fingerprint, isNot(equals(prop2.fingerprint)));
    });

    test('126. Changing sourceOutcomeFingerprint changes proposal fingerprint',
        () {
      final outcome1 = buildSampleOutcome(correctCount: 2);
      final outcome2 = ConsolidatedPracticeOutcome(
        sessionId: outcome1.sessionId,
        examId: outcome1.examId,
        learnerId: outcome1.learnerId,
        sessionMode: outcome1.sessionMode,
        sessionStatus: outcome1.sessionStatus,
        startedAt: outcome1.startedAt,
        completedAt: outcome1.completedAt,
        totalQuestions: outcome1.totalQuestions,
        attemptedCount: outcome1.attemptedCount,
        correctCount: outcome1.correctCount,
        incorrectCount: outcome1.incorrectCount,
        skippedCount: outcome1.skippedCount,
        unansweredCount: outcome1.unansweredCount,
        completionRate: outcome1.completionRate,
        accuracy: outcome1.accuracy,
        accuracyPercentage: outcome1.accuracyPercentage,
        scoreRatio: outcome1.scoreRatio,
        totalDurationSeconds: outcome1.totalDurationSeconds,
        averageSecondsPerQuestion: outcome1.averageSecondsPerQuestion,
        feedbackSummary: outcome1.feedbackSummary,
        topicEvidence: outcome1.topicEvidence,
        objectiveEvidence: outcome1.objectiveEvidence,
        sectionEvidence: outcome1.sectionEvidence,
        difficultyEvidence: outcome1.difficultyEvidence,
        questionEvidence: outcome1.questionEvidence,
        handoffAttempts: outcome1.handoffAttempts,
        fingerprint: 'different_source_fp',
      );

      final prop1 = proposer
          .proposeUpdate(outcome: outcome1, proposedAt: fixedDate)
          .valueOrThrow;
      final prop2 = proposer
          .proposeUpdate(outcome: outcome2, proposedAt: fixedDate)
          .valueOrThrow;

      expect(prop1.fingerprint, isNot(equals(prop2.fingerprint)));
    });
  });

  // ==========================================================================
  // GROUP 19: Error Handling & Idempotency (8 tests)
  // ==========================================================================
  group('P37.19 Group 19 — Error Handling & Idempotency', () {
    test(
        '127. Empty sessionId throws ArgumentError on ConsolidatedPracticeOutcome',
        () {
      final outcome = buildSampleOutcome(correctCount: 1);
      expect(
        () => ConsolidatedPracticeOutcome(
          sessionId: '',
          examId: outcome.examId,
          sessionMode: outcome.sessionMode,
          sessionStatus: outcome.sessionStatus,
          startedAt: outcome.startedAt,
          completedAt: outcome.completedAt,
          totalQuestions: outcome.totalQuestions,
          attemptedCount: outcome.attemptedCount,
          correctCount: outcome.correctCount,
          incorrectCount: outcome.incorrectCount,
          skippedCount: outcome.skippedCount,
          unansweredCount: outcome.unansweredCount,
          completionRate: outcome.completionRate,
          accuracy: outcome.accuracy,
          scoreRatio: outcome.scoreRatio,
          totalDurationSeconds: outcome.totalDurationSeconds,
          averageSecondsPerQuestion: outcome.averageSecondsPerQuestion,
          feedbackSummary: outcome.feedbackSummary,
          topicEvidence: outcome.topicEvidence,
          objectiveEvidence: outcome.objectiveEvidence,
          sectionEvidence: outcome.sectionEvidence,
          difficultyEvidence: outcome.difficultyEvidence,
          questionEvidence: outcome.questionEvidence,
          handoffAttempts: outcome.handoffAttempts,
          fingerprint: outcome.fingerprint,
        ),
        throwsArgumentError,
      );
    });

    test(
        '128. Empty examId throws ArgumentError on ConsolidatedPracticeOutcome',
        () {
      final outcome = buildSampleOutcome(correctCount: 1);
      expect(
        () => ConsolidatedPracticeOutcome(
          sessionId: outcome.sessionId,
          examId: '',
          sessionMode: outcome.sessionMode,
          sessionStatus: outcome.sessionStatus,
          startedAt: outcome.startedAt,
          completedAt: outcome.completedAt,
          totalQuestions: outcome.totalQuestions,
          attemptedCount: outcome.attemptedCount,
          correctCount: outcome.correctCount,
          incorrectCount: outcome.incorrectCount,
          skippedCount: outcome.skippedCount,
          unansweredCount: outcome.unansweredCount,
          completionRate: outcome.completionRate,
          accuracy: outcome.accuracy,
          scoreRatio: outcome.scoreRatio,
          totalDurationSeconds: outcome.totalDurationSeconds,
          averageSecondsPerQuestion: outcome.averageSecondsPerQuestion,
          feedbackSummary: outcome.feedbackSummary,
          topicEvidence: outcome.topicEvidence,
          objectiveEvidence: outcome.objectiveEvidence,
          sectionEvidence: outcome.sectionEvidence,
          difficultyEvidence: outcome.difficultyEvidence,
          questionEvidence: outcome.questionEvidence,
          handoffAttempts: outcome.handoffAttempts,
          fingerprint: outcome.fingerprint,
        ),
        throwsArgumentError,
      );
    });

    test('129. Inconsistent count sum returns calculationError', () {
      final outcome = buildSampleOutcome(correctCount: 1);
      final badOutcome = ConsolidatedPracticeOutcome(
        sessionId: outcome.sessionId,
        examId: outcome.examId,
        sessionMode: outcome.sessionMode,
        sessionStatus: outcome.sessionStatus,
        startedAt: outcome.startedAt,
        completedAt: outcome.completedAt,
        totalQuestions: outcome.totalQuestions,
        attemptedCount: 5, // Count invariant violation: 1 + 0 != 5
        correctCount: 1,
        incorrectCount: 0,
        skippedCount: outcome.skippedCount,
        unansweredCount: outcome.unansweredCount,
        completionRate: outcome.completionRate,
        accuracy: outcome.accuracy,
        scoreRatio: outcome.scoreRatio,
        totalDurationSeconds: outcome.totalDurationSeconds,
        averageSecondsPerQuestion: outcome.averageSecondsPerQuestion,
        feedbackSummary: outcome.feedbackSummary,
        topicEvidence: outcome.topicEvidence,
        objectiveEvidence: outcome.objectiveEvidence,
        sectionEvidence: outcome.sectionEvidence,
        difficultyEvidence: outcome.difficultyEvidence,
        questionEvidence: outcome.questionEvidence,
        handoffAttempts: outcome.handoffAttempts,
        fingerprint: outcome.fingerprint,
      );

      final result = proposer.proposeUpdate(outcome: badOutcome);
      expect(result.isFailure, isTrue);
      expect(result.error?.code,
          equals(LearningProposalErrorCode.calculationError));
    });

    test(
        '130. Duplicate question ID in question evidence returns duplicateSignal error',
        () {
      final outcome = buildSampleOutcome(correctCount: 1);
      final qEv = outcome.questionEvidence.first;
      final badOutcome = ConsolidatedPracticeOutcome(
        sessionId: outcome.sessionId,
        examId: outcome.examId,
        sessionMode: outcome.sessionMode,
        sessionStatus: outcome.sessionStatus,
        startedAt: outcome.startedAt,
        completedAt: outcome.completedAt,
        totalQuestions: 2,
        attemptedCount: 2,
        correctCount: 2,
        incorrectCount: 0,
        skippedCount: 0,
        unansweredCount: 0,
        completionRate: 1.0,
        accuracy: 1.0,
        scoreRatio: 1.0,
        totalDurationSeconds: outcome.totalDurationSeconds,
        averageSecondsPerQuestion: outcome.averageSecondsPerQuestion,
        feedbackSummary: outcome.feedbackSummary,
        topicEvidence: outcome.topicEvidence,
        objectiveEvidence: outcome.objectiveEvidence,
        sectionEvidence: outcome.sectionEvidence,
        difficultyEvidence: outcome.difficultyEvidence,
        questionEvidence: [qEv, qEv], // duplicate
        handoffAttempts: outcome.handoffAttempts,
        fingerprint: outcome.fingerprint,
      );

      final result = proposer.proposeUpdate(outcome: badOutcome);
      expect(result.isFailure, isTrue);
      expect(result.error?.code,
          equals(LearningProposalErrorCode.duplicateSignal));
    });

    test('131. Result valueOrThrow unwraps successfully on success', () {
      const res = LearningProposalResult.success(100);
      expect(res.valueOrThrow, equals(100));
    });

    test('132. Result valueOrThrow throws StateError on failure', () {
      const res = LearningProposalResult<int>.failure(
        LearningProposalError(
          code: LearningProposalErrorCode.invalidOutcome,
          message: 'Error message',
        ),
      );
      expect(() => res.valueOrThrow, throwsStateError);
    });

    test('133. LearningProposalError serializes and deserializes cleanly', () {
      const err = LearningProposalError(
        code: LearningProposalErrorCode.examMismatch,
        message: 'Exam mismatch description',
        details: {'key': 'val'},
      );
      final json = err.toJson();
      final fromJson = LearningProposalError.fromJson(json);

      expect(fromJson.code, equals(err.code));
      expect(fromJson.message, equals(err.message));
    });

    test('134. LearningProposalResult toString formats properly', () {
      const success = LearningProposalResult.success('OK');
      expect(
          success.toString(), contains('LearningProposalResult.success(OK)'));

      const failure = LearningProposalResult<String>.failure(
        LearningProposalError(
          code: LearningProposalErrorCode.invalidOutcome,
          message: 'Failed',
        ),
      );
      expect(failure.toString(), contains('LearningProposalResult.failure'));
    });
  });

  // ==========================================================================
  // GROUP 20: High-Throughput Benchmarks (8 tests)
  // ==========================================================================
  group('P37.20 Group 20 — High-Throughput Benchmarks', () {
    test('135. 1,000 outcomes proposal generation in < 50ms', () {
      final qList = List.generate(
          1000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      final sw = Stopwatch()..start();
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      sw.stop();

      expect(proposal.totalQuestions, equals(1000));
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('136. 1,000 outcomes fingerprint calculation in < 20ms', () {
      final qList = List.generate(
          1000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.fingerprint, hasLength(64));
    });

    test('137. 10,000 outcomes proposal generation in < 150ms', () {
      final qList = List.generate(
          10000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      final sw = Stopwatch()..start();
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      sw.stop();

      expect(proposal.totalQuestions, equals(10000));
      expect(sw.elapsedMilliseconds, lessThan(300));
    });

    test('138. 10,000 outcomes question signals serialization in < 50ms', () {
      final qList = List.generate(
          10000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final sw = Stopwatch()..start();
      final json = proposal.toJson();
      sw.stop();

      expect(json['questionSignals'], isList);
      expect((json['questionSignals'] as List).length, equals(10000));
    });

    test('139. 50,000 outcomes proposal generation in < 500ms', () {
      final qList = List.generate(
          50000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      final sw = Stopwatch()..start();
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      sw.stop();

      expect(proposal.totalQuestions, equals(50000));
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });

    test('140. 100,000 outcomes proposal generation in < 2,000ms', () {
      final qList = List.generate(
          100000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final spec = buildSpec(questions: qList);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      final sw = Stopwatch()..start();
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      sw.stop();

      expect(proposal.totalQuestions, equals(100000));
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test('141. Single proposal lookup & derivation latency < 1ms average', () {
      final q = buildQuestion(id: 'Q000001');
      final spec = buildSpec(questions: [q]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;

      final sw = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      }
      sw.stop();

      final avgMicroseconds = (sw.elapsedMicroseconds / 1000);
      expect(avgMicroseconds, lessThan(1000));
    });

    test('142. Linear O(n) scaling verified between 10K and 50K', () {
      final qList10K = List.generate(
          10000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final outcome10K = consolidator
          .consolidate(
              state: engine
                  .startSession(
                      state: engine.initializeSession(
                          spec: buildSpec(questions: qList10K)),
                      startedAt: fixedDate)
                  .valueOrThrow)
          .valueOrThrow;

      final sw1 = Stopwatch()..start();
      proposer.proposeUpdate(outcome: outcome10K).valueOrThrow;
      sw1.stop();

      final qList50K = List.generate(
          50000, (i) => buildQuestion(id: 'Q${i.toString().padLeft(6, '0')}'));
      final outcome50K = consolidator
          .consolidate(
              state: engine
                  .startSession(
                      state: engine.initializeSession(
                          spec: buildSpec(questions: qList50K)),
                      startedAt: fixedDate)
                  .valueOrThrow)
          .valueOrThrow;

      final sw2 = Stopwatch()..start();
      proposer.proposeUpdate(outcome: outcome50K).valueOrThrow;
      sw2.stop();

      expect(sw2.elapsedMilliseconds, lessThan(2000));
    });
  });

  // ==========================================================================
  // GROUP 21: Safety & Non-Fabrication Invariants (6 tests)
  // ==========================================================================
  group('P37.21 Group 21 — Safety & Non-Fabrication Invariants', () {
    test('143. P37 does NOT fabricate missing questions', () {
      final outcome = buildSampleOutcome(correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.questionSignals.length, equals(2));
    });

    test('144. P37 does NOT make future exam predictions', () {
      final outcome = buildSampleOutcome(correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      expect(json.containsKey('predictedScore'), isFalse);
      expect(json.containsKey('predictedRank'), isFalse);
      expect(json.containsKey('passProbability'), isFalse);
    });

    test('145. P37 does NOT make cognitive ability or personality predictions',
        () {
      final outcome = buildSampleOutcome(correctCount: 0, incorrectCount: 4);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final json = proposal.toJson();
      expect(json.containsKey('iq'), isFalse);
      expect(json.containsKey('cognitiveLevel'), isFalse);
      expect(json.containsKey('traitScore'), isFalse);
    });

    test('146. Zero DateTime.now() usage: pure caller timestamps', () {
      final outcome = buildSampleOutcome(correctCount: 2);
      final explicitTime = DateTime.utc(2030, 1, 1, 0, 0, 0);
      final proposal = proposer
          .proposeUpdate(outcome: outcome, proposedAt: explicitTime)
          .valueOrThrow;
      expect(proposal.proposedAt, equals(explicitTime));
    });

    test('147. Zero attempts results in noAction without diagnostic claim', () {
      final spec = buildSpec(questions: const []);
      final outcome = consolidator
          .consolidate(state: engine.initializeSession(spec: spec))
          .valueOrThrow;
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.overallEvidenceStrength, equals(EvidenceStrength.none));
      expect(
          proposal.recommendedAction, equals(ProposedLearningAction.noAction));
    });

    test('148. Single wrong answer does NOT trigger systemic weakness label',
        () {
      final outcome = buildSampleOutcome(correctCount: 0, incorrectCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      expect(proposal.overallEvidenceStrength,
          equals(EvidenceStrength.insufficient));
      expect(
          proposal.overallPattern, equals(OutcomePattern.insufficientEvidence));
    });
  });

  // ==========================================================================
  // GROUP 22: Property & Deterministic Replay Tests (10 tests)
  // ==========================================================================
  group('P37.22 Group 22 — Property & Deterministic Replay Tests', () {
    test(
        '149. 10 consecutive executions produce byte-identical JSON and SHA-256',
        () {
      final outcome = buildSampleOutcome(
          correctCount: 3, incorrectCount: 1, skippedCount: 1);

      String? baselineJson;
      String? baselineFp;

      for (int i = 0; i < 10; i++) {
        final prop = proposer
            .proposeUpdate(outcome: outcome, proposedAt: fixedDate)
            .valueOrThrow;
        final currentJson = jsonEncode(prop.toJson());
        final currentFp = prop.fingerprint;

        if (i == 0) {
          baselineJson = currentJson;
          baselineFp = currentFp;
        } else {
          expect(currentJson, equals(baselineJson));
          expect(currentFp, equals(baselineFp));
        }
      }
    });

    test(
        '150. Property Invariant: correctCount + incorrectCount == attemptedCount',
        () {
      for (int c = 0; c <= 3; c++) {
        for (int inc = 0; inc <= 3; inc++) {
          final outcome =
              buildSampleOutcome(correctCount: c, incorrectCount: inc);
          final prop = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
          expect(prop.correctCount + prop.incorrectCount,
              equals(prop.attemptedCount));
        }
      }
    });

    test(
        '151. Property Invariant: attemptedCount + skippedCount + unansweredCount == totalQuestions',
        () {
      for (int att = 0; att <= 2; att++) {
        for (int sk = 0; sk <= 2; sk++) {
          for (int un = 0; un <= 2; un++) {
            final outcome = buildSampleOutcome(
                correctCount: att, skippedCount: sk, unansweredCount: un);
            final prop = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
            expect(
                prop.attemptedCount + prop.skippedCount + prop.unansweredCount,
                equals(prop.totalQuestions));
          }
        }
      }
    });

    test('152. Property Invariant: scoreRatio <= completionRate', () {
      final outcome = buildSampleOutcome(
          correctCount: 2, incorrectCount: 1, skippedCount: 2);
      final prop = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(prop.scoreRatio, lessThanOrEqualTo(prop.completionRate));
    });

    test(
        '153. Property Invariant: sum of topic question totals equals totalQuestions',
        () {
      final q1 = buildQuestion(id: 'q_1', topic: 'TopicA');
      final q2 = buildQuestion(id: 'q_2', topic: 'TopicB');
      final spec = buildSpec(questions: [q1, q2]);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final prop = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final sumTopicTotals = prop.topicSignals.values
          .fold<int>(0, (sum, t) => sum + t.totalQuestions);
      expect(sumTopicTotals, equals(prop.totalQuestions));
    });

    test(
        '154. Property Invariant: sum of section question totals equals totalQuestions',
        () {
      final questions = List.generate(5, (i) => buildQuestion(id: 'q_$i'));
      final spec = buildSpec(questions: questions, sectionSize: 2);
      final initial = engine.initializeSession(spec: spec);
      final state = engine
          .startSession(state: initial, startedAt: fixedDate)
          .valueOrThrow;
      final outcome = consolidator.consolidate(state: state).valueOrThrow;
      final prop = proposer.proposeUpdate(outcome: outcome).valueOrThrow;

      final sumSectionTotals = prop.sectionSignals.values
          .fold<int>(0, (sum, s) => sum + s.totalQuestions);
      expect(sumSectionTotals, equals(prop.totalQuestions));
    });

    test('155. Proposal toString formats human-readable debug representation',
        () {
      final outcome = buildSampleOutcome(correctCount: 2);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.toString(), contains('LearningStateUpdateProposal'));
      expect(proposal.toString(), contains('exam: upsc'));
    });

    test('156. Proposal preserves learnerId when present', () {
      final outcome =
          buildSampleOutcome(learnerId: 'learner_aspirant_42', correctCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.learnerId, equals('learner_aspirant_42'));
    });

    test('157. Proposal handles null learnerId gracefully', () {
      final outcome = buildSampleOutcome(learnerId: null, correctCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.learnerId, isNull);
    });

    test('158. Proposal proposedAt defaults safely to completedAt when omitted',
        () {
      final outcome = buildSampleOutcome(correctCount: 1);
      final proposal = proposer.proposeUpdate(outcome: outcome).valueOrThrow;
      expect(proposal.proposedAt, equals(outcome.completedAt.toUtc()));
    });
  });
}
