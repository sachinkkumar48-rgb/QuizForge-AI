import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

// ============================================================================
// FIXTURE HELPERS
// ============================================================================

NormalizedQuestion _makeQuestion({
  required String examId,
  required int year,
  String paper = 'GS1',
  String subject = 'Polity',
  String topic = 'Fundamental Rights',
  String language = 'en',
  List<String> objectiveIds = const ['obj_pol_fr'],
  int questionNumber = 1,
}) {
  final src = PyqSourceReference.official(
    examId: examId,
    year: year,
    paper: paper,
  );
  final id = DeterministicQuestionId.generate(
    examId: examId,
    year: year,
    paper: paper,
    normalizedQuestionText: '$examId $year $paper $topic $questionNumber',
    language: language,
    questionNumber: questionNumber,
  );
  return NormalizedQuestion(
    id: id,
    examId: examId,
    year: year,
    paper: paper,
    subject: subject,
    topic: topic,
    questionNumber: questionNumber,
    normalizedText: '$examId $year $paper $topic $questionNumber',
    originalText: '$examId $year $paper $topic $questionNumber',
    options: const [
      Option(key: 'A', text: 'Option A'),
      Option(key: 'B', text: 'Option B'),
      Option(key: 'C', text: 'Option C'),
      Option(key: 'D', text: 'Option D'),
    ],
    officialAnswer: const Answer(correctOptionKeys: ['A']),
    language: language,
    source: src,
    objectiveIds: objectiveIds,
  );
}

void main() {
  final engine = PyqLearningPriorityEngine();

  group('P32.1 Historical-Only Matrix', () {
    test('1. Empty PYQ corpus produces safe zero-historical profile', () {
      final profile = engine.evaluateFromQuestions(
        questions: const [],
        examId: 'upsc',
      );

      expect(profile.examId, 'upsc');
      expect(profile.sufficientEvidence, isFalse);
      expect(profile.corpusQuestionCount, 0);
      expect(profile.objectiveSignals, isEmpty);
      expect(profile.topicSignals, isEmpty);
      expect(profile.subjectSignals, isEmpty);

      // Querying an objective returns zero-historical fallback
      final sig = profile.getObjectiveSignal('obj_pol_fr');
      expect(sig.level, PrioritySignalLevel.none);
      expect(sig.historicalQuestionCount, 0);
      expect(sig.historicalShare, 0.0);
      expect(sig.priorityScore, 0.0);
      expect(sig.rationale.rationaleCode, 'NO_HISTORICAL_EVIDENCE');
    });

    test(
        '2. Single question corpus exposes insufficient evidence and scales confidence',
        () {
      final q = _makeQuestion(examId: 'upsc', year: 2024);
      final profile = engine.evaluateFromQuestions(
        questions: [q],
        examId: 'upsc',
      );

      expect(profile.sufficientEvidence, isFalse);
      expect(profile.corpusQuestionCount, 1);
      final sig = profile.getObjectiveSignal('obj_pol_fr');
      expect(sig.historicalQuestionCount, 1);
      expect(sig.hasSufficientHistoricalEvidence, isFalse);
      // Gating factor: 1 / 5 = 0.20
      expect(sig.evidenceConfidence, closeTo(0.20, 0.001));
      expect(sig.priorityScore, inInclusiveRange(0.0, 1.0));
      expect(sig.priorityScore, greaterThan(0.0));
    });

    test(
        '3. Sparse corpus (< threshold) reduces confidence without zeroing count',
        () {
      final questions = List.generate(
        3,
        (i) => _makeQuestion(
            examId: 'upsc', year: 2022 + i, questionNumber: i + 1),
      );
      final profile = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
      );

      expect(profile.sufficientEvidence, isFalse);
      final sig = profile.getObjectiveSignal('obj_pol_fr');
      expect(sig.historicalQuestionCount, 3);
      expect(sig.evidenceConfidence, closeTo(0.60, 0.001));
      expect(sig.hasSufficientHistoricalEvidence, isFalse);
    });

    test('4. Sufficient corpus (>= threshold) unlocks full confidence (1.0)',
        () {
      final questions = List.generate(
        10,
        (i) => _makeQuestion(
            examId: 'upsc', year: 2020 + (i % 5), questionNumber: i + 1),
      );
      final profile = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
      );

      expect(profile.sufficientEvidence, isTrue);
      final sig = profile.getObjectiveSignal('obj_pol_fr');
      expect(sig.historicalQuestionCount, 10);
      expect(sig.evidenceConfidence, 1.0);
      expect(sig.hasSufficientHistoricalEvidence, isTrue);
    });

    test('5. High recurrence and recent activity boost historical components',
        () {
      // 10 questions across 5 years, all in recent 3 years
      final questions = <NormalizedQuestion>[];
      for (int year = 2021; year <= 2025; year++) {
        questions.add(_makeQuestion(
          examId: 'upsc',
          year: year,
          topic: 'Fundamental Rights',
          objectiveIds: ['obj_pol_fr'],
          questionNumber: 1,
        ));
        questions.add(_makeQuestion(
          examId: 'upsc',
          year: year,
          topic: 'Fundamental Rights',
          objectiveIds: ['obj_pol_fr'],
          questionNumber: 2,
        ));
      }

      final profile = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
        recentWindowYears: 3,
      );

      final sig = profile.getObjectiveSignal('obj_pol_fr');
      expect(sig.recurrenceCount, 5);
      expect(sig.yearsObserved, 5);
      expect(sig.recentHistoricalShare, 1.0);
      expect(sig.priorityScore, greaterThan(0.40));
      expect(sig.rationale.recurrenceContribution, greaterThan(0.0));
      expect(sig.rationale.recencyContribution, greaterThan(0.0));
    });
  });

  group('P32.2 Learner Evidence Matrix', () {
    test('6. Strong learner (high accuracy) has zero weakness contribution',
        () {
      final questions = List.generate(
        10,
        (i) => _makeQuestion(
            examId: 'upsc', year: 2020 + (i % 5), questionNumber: i + 1),
      );

      final weakSpotProfile = WeakSpotProfile(
        learnerId: 'learner_1',
        totalEvaluatedObjectives: 1,
        evaluatedWithSufficientEvidence: 1,
        weakObjectives: const [], // No weak spots because accuracy is high
        evaluatedAt: DateTime.utc(2026, 1, 1),
      );

      final progress = LearnerProgress(
        learnerId: 'learner_1',
        objectiveId: 'obj_pol_fr',
        attemptCount: 10,
        correctCount: 10, // 100% accuracy
        status: LearnerObjectiveStatus.achieved,
      );

      final profile = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
        weakSpotProfile: weakSpotProfile,
        progressList: [progress],
      );

      final sig = profile.getObjectiveSignal('obj_pol_fr');
      expect(sig.currentWeakness, 0.0);
      expect(sig.rationale.learnerWeaknessContribution, 0.0);
      expect(sig.rationale.hasSufficientLearnerEvidence, isTrue);
    });

    test('7. Weak learner (low accuracy) has high weakness contribution', () {
      final questions = List.generate(
        10,
        (i) => _makeQuestion(
            examId: 'upsc', year: 2020 + (i % 5), questionNumber: i + 1),
      );

      final weakSpotProfile = WeakSpotProfile(
        learnerId: 'learner_1',
        totalEvaluatedObjectives: 1,
        evaluatedWithSufficientEvidence: 1,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_pol_fr',
            attemptCount: 10,
            correctCount: 2, // 20% accuracy -> deficiency 0.80
            observedAccuracy: 0.20,
            deficiencyScore: 0.80,
          ),
        ],
        evaluatedAt: DateTime.utc(2026, 1, 1),
      );

      final profile = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
        weakSpotProfile: weakSpotProfile,
      );

      final sig = profile.getObjectiveSignal('obj_pol_fr');
      expect(sig.currentWeakness, 0.80);
      expect(sig.rationale.learnerWeaknessContribution,
          closeTo(0.40 * 0.80, 0.01));
      expect(sig.rationale.hasSufficientLearnerEvidence, isTrue);
    });

    test(
        '8. Zero learner evidence strictly yields zero weakness (unattempted != weak)',
        () {
      final questions = List.generate(
        10,
        (i) => _makeQuestion(
            examId: 'upsc', year: 2020 + (i % 5), questionNumber: i + 1),
      );

      final profile = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
        // Zero learner evidence passed
      );

      final sig = profile.getObjectiveSignal('obj_pol_fr');
      expect(sig.learnerEvidenceCount, 0);
      expect(sig.learnerAccuracy, isNull);
      expect(sig.currentWeakness, 0.0);
      expect(sig.rationale.learnerWeaknessContribution, 0.0);
      expect(sig.rationale.hasSufficientLearnerEvidence, isFalse);
    });

    test(
        '9. Sparse learner evidence (< minimumLearnerAttempts) strictly yields zero weakness',
        () {
      final questions = List.generate(
        10,
        (i) => _makeQuestion(
            examId: 'upsc', year: 2020 + (i % 5), questionNumber: i + 1),
      );

      // Only 2 attempts (less than default threshold 5)
      final progress = LearnerProgress(
        learnerId: 'learner_1',
        objectiveId: 'obj_pol_fr',
        attemptCount: 2,
        correctCount: 0, // 0% accuracy, but evidence is sparse!
        status: LearnerObjectiveStatus.inProgress,
      );

      final profile = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
        progressList: [progress],
      );

      final sig = profile.getObjectiveSignal('obj_pol_fr');
      expect(sig.learnerEvidenceCount, 2);
      expect(sig.currentWeakness, 0.0);
      expect(sig.rationale.learnerWeaknessContribution, 0.0);
      expect(sig.rationale.hasSufficientLearnerEvidence, isFalse);
    });
  });

  group('P32.3 Combined Matrix & Relative Prioritization', () {
    test('10. High PYQ + weak learner ranks highest', () {
      final qList = <NormalizedQuestion>[];
      // 8 questions for obj_a (High PYQ)
      for (int i = 0; i < 8; i++) {
        qList.add(_makeQuestion(
          examId: 'upsc',
          year: 2020 + (i % 4),
          topic: 'Topic A',
          objectiveIds: ['obj_a'],
          questionNumber: i + 1,
        ));
      }
      // 2 questions for obj_b (Low PYQ)
      for (int i = 0; i < 2; i++) {
        qList.add(_makeQuestion(
          examId: 'upsc',
          year: 2023 + i,
          topic: 'Topic B',
          objectiveIds: ['obj_b'],
          questionNumber: i + 10,
        ));
      }

      final weakProfile = WeakSpotProfile(
        learnerId: 'learner_1',
        totalEvaluatedObjectives: 2,
        evaluatedWithSufficientEvidence: 2,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_a',
            attemptCount: 6,
            correctCount: 1,
            observedAccuracy: 0.167,
            deficiencyScore: 0.833,
          ),
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_b',
            attemptCount: 6,
            correctCount: 1,
            observedAccuracy: 0.167,
            deficiencyScore: 0.833,
          ),
        ],
        evaluatedAt: DateTime.utc(2026, 1, 1),
      );

      final profile = engine.evaluateFromQuestions(
        questions: qList,
        examId: 'upsc',
        weakSpotProfile: weakProfile,
      );

      final sigA = profile.getObjectiveSignal('obj_a');
      final sigB = profile.getObjectiveSignal('obj_b');

      expect(sigA.priorityScore, greaterThan(sigB.priorityScore));
      expect(profile.objectiveSignals.first.objectiveId, 'obj_a');
    });

    test(
        '11. High PYQ does not make strong learner outrank genuinely weak learner',
        () {
      final qList = <NormalizedQuestion>[];
      // 9 questions for obj_high_pyq
      for (int i = 0; i < 9; i++) {
        qList.add(_makeQuestion(
          examId: 'upsc',
          year: 2020 + (i % 5),
          topic: 'Topic High',
          objectiveIds: ['obj_high'],
          questionNumber: i + 1,
        ));
      }
      // 1 question for obj_low_pyq
      qList.add(_makeQuestion(
        examId: 'upsc',
        year: 2024,
        topic: 'Topic Low',
        objectiveIds: ['obj_low'],
        questionNumber: 10,
      ));

      // Learner is 100% mastery on obj_high, but 0% on obj_low
      final weakProfile = WeakSpotProfile(
        learnerId: 'learner_1',
        totalEvaluatedObjectives: 2,
        evaluatedWithSufficientEvidence: 2,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_low',
            attemptCount: 5,
            correctCount: 0,
            observedAccuracy: 0.0,
            deficiencyScore: 1.0,
          ),
        ],
        evaluatedAt: DateTime.utc(2026, 1, 1),
      );

      final progressHigh = LearnerProgress(
        learnerId: 'learner_1',
        objectiveId: 'obj_high',
        attemptCount: 10,
        correctCount: 10,
        status: LearnerObjectiveStatus.achieved,
      );

      final profile = engine.evaluateFromQuestions(
        questions: qList,
        examId: 'upsc',
        weakSpotProfile: weakProfile,
        progressList: [progressHigh],
      );

      final sigHigh = profile.getObjectiveSignal('obj_high');
      final sigLow = profile.getObjectiveSignal('obj_low');

      expect(sigHigh.currentWeakness, 0.0);
      expect(sigLow.currentWeakness, 1.0);
      // Learner weakness weight is 0.40, which ensures genuinely weak spots receive high priority
      expect(
          sigLow.rationale.learnerWeaknessContribution, closeTo(0.40, 0.001));
    });
  });

  group('P32.4 Fallback Hierarchy', () {
    test('12. Fallback hierarchy: objective -> topic -> subject -> none', () {
      final questions = [
        _makeQuestion(
          examId: 'upsc',
          year: 2024,
          subject: 'Polity',
          topic: 'Preamble',
          objectiveIds: ['obj_preamble'],
          questionNumber: 1,
        ),
        _makeQuestion(
          examId: 'upsc',
          year: 2024,
          subject: 'Polity',
          topic: 'Judiciary',
          objectiveIds: const [], // unmapped objective
          questionNumber: 2,
        ),
      ];

      final profile = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
      );

      // Level 1: Objective level
      final sigObj = profile.getObjectiveSignal('obj_preamble');
      expect(sigObj.level, PrioritySignalLevel.objective);
      expect(sigObj.rationale.fallbackLevel, PrioritySignalLevel.objective);

      // Level 2: Topic level fallback
      final sigTopic = profile.getObjectiveSignal(
        'obj_unmapped_judiciary',
        topic: 'Judiciary',
      );
      expect(sigTopic.level, PrioritySignalLevel.topicFallback);
      expect(
          sigTopic.rationale.fallbackLevel, PrioritySignalLevel.topicFallback);
      expect(sigTopic.historicalQuestionCount, 1);

      // Level 3: Subject level fallback
      final sigSubj = profile.getObjectiveSignal(
        'obj_unmapped_polity',
        topic: 'NonExistentTopic',
        subject: 'Polity',
      );
      expect(sigSubj.level, PrioritySignalLevel.subjectFallback);
      expect(
          sigSubj.rationale.fallbackLevel, PrioritySignalLevel.subjectFallback);
      expect(sigSubj.historicalQuestionCount, 2);

      // Level 4: No historical signal
      final sigNone = profile.getObjectiveSignal(
        'obj_completely_unknown',
        topic: 'UnknownTopic',
        subject: 'UnknownSubject',
      );
      expect(sigNone.level, PrioritySignalLevel.none);
      expect(sigNone.rationale.fallbackLevel, PrioritySignalLevel.none);
      expect(sigNone.historicalQuestionCount, 0);
      expect(sigNone.priorityScore, 0.0);
    });
  });

  group('P32.5 Configuration & Boundary Safety', () {
    test('13. Valid configuration normalizes weights and enforces invariants',
        () {
      final customConfig = PyqLearningPriorityConfig(
        historicalWeight: 10.0,
        recurrenceWeight: 10.0,
        recencyWeight: 10.0,
        weaknessWeight: 10.0,
      );

      expect(customConfig.normalizedHistoricalWeight, closeTo(0.25, 0.001));
      expect(customConfig.normalizedRecurrenceWeight, closeTo(0.25, 0.001));
      expect(customConfig.normalizedRecencyWeight, closeTo(0.25, 0.001));
      expect(customConfig.normalizedWeaknessWeight, closeTo(0.25, 0.001));
    });

    test('14. Invalid configuration throws ArgumentError', () {
      expect(
        () => PyqLearningPriorityConfig(minimumHistoricalQuestions: 0),
        throwsArgumentError,
      );
      expect(
        () => PyqLearningPriorityConfig(minimumYears: 0),
        throwsArgumentError,
      );
      expect(
        () => PyqLearningPriorityConfig(minimumLearnerAttempts: 0),
        throwsArgumentError,
      );
      expect(
        () => PyqLearningPriorityConfig(historicalWeight: -1.0),
        throwsArgumentError,
      );
      expect(
        () => PyqLearningPriorityConfig(
          historicalWeight: 0.0,
          recurrenceWeight: 0.0,
          recencyWeight: 0.0,
          weaknessWeight: 0.0,
        ),
        throwsArgumentError,
      );
      expect(
        () => PyqLearningPriorityConfig(historicalWeight: double.nan),
        throwsArgumentError,
      );
      expect(
        () => PyqLearningPriorityConfig(historicalWeight: double.infinity),
        throwsArgumentError,
      );
    });

    test(
        '15. Priority scores are strictly bounded in [0.0, 1.0] without NaN or Infinity',
        () {
      final questions = List.generate(
        100,
        (i) => _makeQuestion(
            examId: 'upsc', year: 2000 + (i % 25), questionNumber: i + 1),
      );

      final profile = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
      );

      for (final sig in profile.objectiveSignals) {
        expect(sig.priorityScore, inInclusiveRange(0.0, 1.0));
        expect(sig.priorityScore.isNaN, isFalse);
        expect(sig.priorityScore.isInfinite, isFalse);
      }
      for (final sig in profile.topicSignals) {
        expect(sig.priorityScore, inInclusiveRange(0.0, 1.0));
      }
      for (final sig in profile.subjectSignals) {
        expect(sig.priorityScore, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('P32.6 Determinism & Replay Invariant', () {
    test('16. Repeated evaluation produces identical JSON serialization', () {
      final questions = List.generate(
        20,
        (i) => _makeQuestion(
          examId: 'upsc',
          year: 2020 + (i % 5),
          topic: i.isEven ? 'Rights' : 'Duties',
          objectiveIds: [i.isEven ? 'obj_rights' : 'obj_duties'],
          questionNumber: i + 1,
        ),
      );

      final evalTimestamp = DateTime.utc(2026, 8, 30, 12, 0, 0);

      final profile1 = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
        evaluatedAt: evalTimestamp,
      );

      final profile2 = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
        evaluatedAt: evalTimestamp,
      );

      final json1 = jsonEncode(profile1.toJson());
      final json2 = jsonEncode(profile2.toJson());

      expect(json1, equals(json2));
    });
  });

  group('P32.7 High-Throughput Performance Benchmarks', () {
    test('17. 10,000 questions benchmark completes efficiently', () {
      final questions = List.generate(
        10000,
        (i) => _makeQuestion(
          examId: 'upsc',
          year: 2000 + (i % 25),
          subject: 'Subject_${i % 10}',
          topic: 'Topic_${i % 50}',
          objectiveIds: ['obj_${i % 100}'],
          questionNumber: i + 1,
        ),
      );

      final sw = Stopwatch()..start();
      final profile = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
      );
      sw.stop();

      // ignore: avoid_print
      print(
          'P32 10K questions priority evaluation completed in: ${sw.elapsedMilliseconds}ms');
      expect(profile.corpusQuestionCount, 10000);
      expect(profile.objectiveSignals, isNotEmpty);
      expect(sw.elapsedMilliseconds, lessThan(5000));
    });

    test('18. 50,000 questions benchmark completes efficiently', () {
      final questions = List.generate(
        50000,
        (i) => _makeQuestion(
          examId: 'upsc',
          year: 2000 + (i % 25),
          subject: 'Subject_${i % 10}',
          topic: 'Topic_${i % 50}',
          objectiveIds: ['obj_${i % 100}'],
          questionNumber: i + 1,
        ),
      );

      final sw = Stopwatch()..start();
      final profile = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
      );
      sw.stop();

      // ignore: avoid_print
      print(
          'P32 50K questions priority evaluation completed in: ${sw.elapsedMilliseconds}ms');
      expect(profile.corpusQuestionCount, 50000);
      expect(sw.elapsedMilliseconds, lessThan(10000));
    });

    test('19. 100,000 questions benchmark completes efficiently', () {
      final questions = List.generate(
        100000,
        (i) => _makeQuestion(
          examId: 'upsc',
          year: 2000 + (i % 25),
          subject: 'Subject_${i % 10}',
          topic: 'Topic_${i % 50}',
          objectiveIds: ['obj_${i % 100}'],
          questionNumber: i + 1,
        ),
      );

      final sw = Stopwatch()..start();
      final profile = engine.evaluateFromQuestions(
        questions: questions,
        examId: 'upsc',
      );
      sw.stop();

      // ignore: avoid_print
      print(
          'P32 100K questions priority evaluation completed in: ${sw.elapsedMilliseconds}ms');
      expect(profile.corpusQuestionCount, 100000);
      expect(sw.elapsedMilliseconds, lessThan(15000));
    });
  });
}
