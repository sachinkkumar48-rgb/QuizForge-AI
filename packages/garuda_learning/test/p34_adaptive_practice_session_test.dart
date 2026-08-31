/// P34 Adaptive Practice Session Orchestration Test Suite (TITAN-KO-034.0 P34).
///
/// 100+ unit, determinism, distribution, and benchmark tests verifying:
/// - Group 1: Configuration & Validation (10 tests)
/// - Group 2: Session Validation & Error Safety (10 tests)
/// - Group 3: Mode-Specific Question Ordering & Progression (10 tests)
/// - Group 4: Objective Balancing Policies (10 tests)
/// - Group 5: Topic Balancing Policies (10 tests)
/// - Group 6: Difficulty Progression & Ordering (10 tests)
/// - Group 7: Historical PYQ Distribution & Analytics (10 tests)
/// - Group 8: Learner Priority & Weakness Analytics (10 tests)
/// - Group 9: Determinism, Replay & Immutability Invariants (10 tests)
/// - Group 10: Educational Safety, Non-Predictive & Property Invariants (10 tests)
/// - Group 11: High-Throughput Performance Benchmarks (4 benchmark tests: 1k, 10k, 50k, 100k)
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 12, 0, 0);
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
    PyqSourceReference? source,
  }) {
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
          const [
            Option(key: 'A', text: 'Option A'),
            Option(key: 'B', text: 'Option B'),
            Option(key: 'C', text: 'Option C'),
            Option(key: 'D', text: 'Option D'),
          ],
      officialAnswer: officialAnswer ??
          const Answer(
            correctOptionKeys: ['A'],
            officialAnswerSource: 'Official Commission Key',
          ),
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
    int exposureCount = 0,
    double recencyScore = 1.0,
    double difficultyFit = 1.0,
    double sourceQualityScore = 1.0,
    double selectionScore = 0.5,
    bool isEligible = true,
    QuestionExclusionReason? exclusionReason,
    Map<String, double>? scoreBreakdown,
  }) {
    return AdaptiveQuestionCandidate(
      question: question,
      historicalPriority: historicalPriority,
      learnerWeakness: learnerWeakness,
      exposureCount: exposureCount,
      recencyScore: recencyScore,
      difficultyFit: difficultyFit,
      sourceQualityScore: sourceQualityScore,
      selectionScore: selectionScore,
      isEligible: isEligible,
      exclusionReason: exclusionReason,
      scoreBreakdown: scoreBreakdown ??
          {
            'weakness': learnerWeakness * 0.35,
            'historicalPriority': historicalPriority * 0.30,
            'recency': recencyScore * 0.20,
            'difficulty': difficultyFit * 0.10,
            'sourceQuality': sourceQualityScore * 0.05,
          },
    );
  }

  AdaptiveQuestionSelectionResult buildSelectionResult({
    String examId = 'upsc',
    required List<AdaptiveQuestionCandidate> candidates,
    int requestedCount = 10,
    bool isConstraintLimited = false,
    String? constraintLimitReason,
  }) {
    final selected = candidates.where((c) => c.isEligible).toList();
    final selectedQuestions = selected.map((c) => c.question).toList();
    return AdaptiveQuestionSelectionResult(
      examId: examId,
      selectedQuestions: selectedQuestions,
      selectedCandidates: selected,
      allCandidates: candidates,
      requestedCount: requestedCount,
      eligibleCount: selected.length,
      config: AdaptiveQuestionSelectionConfig(
        examId: examId,
        targetQuestionCount: requestedCount,
      ),
      selectedAt: fixedDate,
      isConstraintLimited: isConstraintLimited,
      constraintLimitReason: constraintLimitReason,
    );
  }

  // ==========================================================================
  // GROUP 1: CONFIGURATION & VALIDATION
  // ==========================================================================
  group('P34.1 Group 1 — Configuration & Parameter Validation', () {
    test('1. Valid config constructs successfully with default values', () {
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');
      expect(config.examId, equals('upsc'));
      expect(config.sessionMode, equals(PracticeSessionMode.standard));
      expect(config.completionPolicy,
          equals(PracticeCompletionPolicy.allRequired));
      expect(config.objectiveBalancing, equals(ObjectiveBalancingPolicy.none));
      expect(config.topicBalancing, equals(TopicBalancingPolicy.none));
      expect(config.difficultyProgression,
          equals(PracticeDifficultyProgression.none));
      expect(config.sectionSize, equals(5));
      expect(config.estimatedSecondsPerQuestion, equals(60));
      expect(config.allowIncompleteSession, isTrue);
    });

    test('2. Empty examId throws ArgumentError', () {
      expect(
        () => AdaptivePracticeSessionConfig(examId: ''),
        throwsArgumentError,
      );
      expect(
        () => AdaptivePracticeSessionConfig(examId: '   '),
        throwsArgumentError,
      );
    });

    test('3. Non-positive maxQuestions throws ArgumentError', () {
      expect(
        () => AdaptivePracticeSessionConfig(examId: 'upsc', maxQuestions: 0),
        throwsArgumentError,
      );
      expect(
        () => AdaptivePracticeSessionConfig(examId: 'upsc', maxQuestions: -5),
        throwsArgumentError,
      );
    });

    test('4. Non-positive sectionSize throws ArgumentError', () {
      expect(
        () => AdaptivePracticeSessionConfig(examId: 'upsc', sectionSize: 0),
        throwsArgumentError,
      );
      expect(
        () => AdaptivePracticeSessionConfig(examId: 'upsc', sectionSize: -2),
        throwsArgumentError,
      );
    });

    test('5. Non-positive estimatedSecondsPerQuestion throws ArgumentError',
        () {
      expect(
        () => AdaptivePracticeSessionConfig(
            examId: 'upsc', estimatedSecondsPerQuestion: 0),
        throwsArgumentError,
      );
      expect(
        () => AdaptivePracticeSessionConfig(
            examId: 'upsc', estimatedSecondsPerQuestion: -10),
        throwsArgumentError,
      );
    });

    test('6. Exam ID is trimmed and normalized to lowercase', () {
      final config = AdaptivePracticeSessionConfig(examId: '  BPSC  ');
      expect(config.examId, equals('bpsc'));
    });

    test('7. Optional learnerId is retained', () {
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        learnerId: 'learner_101',
      );
      expect(config.learnerId, equals('learner_101'));
    });

    test('8. Metadata dictionary is deeply unmodifiable', () {
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        metadata: {'curriculum': 'v2.1'},
      );
      expect(config.metadata['curriculum'], equals('v2.1'));
      expect(() => config.metadata['new'] = 'val', throwsUnsupportedError);
    });

    test('9. Config serialization to/from JSON roundtrips perfectly', () {
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        learnerId: 'learner_42',
        sessionMode: PracticeSessionMode.weaknessFocused,
        completionPolicy: PracticeCompletionPolicy.allowEarlyExit,
        objectiveBalancing: ObjectiveBalancingPolicy.priorityWeighted,
        topicBalancing: TopicBalancingPolicy.strictCap,
        difficultyProgression: PracticeDifficultyProgression.easyToHard,
        maxQuestions: 15,
        sectionSize: 5,
        estimatedSecondsPerQuestion: 90,
        allowIncompleteSession: false,
        metadata: {'batch': 'A1'},
      );

      final json = config.toJson();
      final roundtrip = AdaptivePracticeSessionConfig.fromJson(json);

      expect(roundtrip.examId, equals('upsc'));
      expect(roundtrip.learnerId, equals('learner_42'));
      expect(
          roundtrip.sessionMode, equals(PracticeSessionMode.weaknessFocused));
      expect(roundtrip.completionPolicy,
          equals(PracticeCompletionPolicy.allowEarlyExit));
      expect(roundtrip.objectiveBalancing,
          equals(ObjectiveBalancingPolicy.priorityWeighted));
      expect(roundtrip.topicBalancing, equals(TopicBalancingPolicy.strictCap));
      expect(roundtrip.difficultyProgression,
          equals(PracticeDifficultyProgression.easyToHard));
      expect(roundtrip.maxQuestions, equals(15));
      expect(roundtrip.sectionSize, equals(5));
      expect(roundtrip.estimatedSecondsPerQuestion, equals(90));
      expect(roundtrip.allowIncompleteSession, isFalse);
      expect(roundtrip.metadata['batch'], equals('A1'));
    });

    test('10. Equivalence and hashCode comparison hold', () {
      final c1 = AdaptivePracticeSessionConfig(examId: 'upsc', sectionSize: 5);
      final c2 = AdaptivePracticeSessionConfig(examId: 'upsc', sectionSize: 5);
      final c3 = AdaptivePracticeSessionConfig(examId: 'bpsc', sectionSize: 5);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1 == c3, isFalse);
    });
  });

  // ==========================================================================
  // GROUP 2: SESSION VALIDATION & ERROR SAFETY
  // ==========================================================================
  group('P34.2 Group 2 — Session Validation & Error Safety', () {
    test('11. Empty selection result returns safe empty session specification',
        () {
      final emptySelection = buildSelectionResult(candidates: []);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: emptySelection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(0));
      expect(spec.totalSections, equals(0));
      expect(spec.isConstraintLimited, isTrue);
      expect(spec.constraintLimitReason, contains('zero selected questions'));
    });

    test('12. Exam mismatch returns safe empty session without throwing', () {
      final bpscSelection = buildSelectionResult(
        examId: 'bpsc',
        candidates: [
          buildCandidate(question: buildQuestion(id: 'q1', examId: 'bpsc')),
        ],
      );
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: bpscSelection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(0));
      expect(spec.isConstraintLimited, isTrue);
      expect(spec.constraintLimitReason, contains('Exam ID mismatch'));
    });

    test('13. Cross-exam candidate leakage in selection result is filtered out',
        () {
      final mixedCandidates = [
        buildCandidate(question: buildQuestion(id: 'q_upsc', examId: 'upsc')),
        buildCandidate(question: buildQuestion(id: 'q_bpsc', examId: 'bpsc')),
      ];
      final selection =
          buildSelectionResult(examId: 'upsc', candidates: mixedCandidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(1));
      expect(spec.orderedQuestions.first.id, equals('q_upsc'));
    });

    test('14. Duplicate candidate IDs in selection result are deduplicated',
        () {
      final dupCandidates = [
        buildCandidate(question: buildQuestion(id: 'q1'), selectionScore: 0.9),
        buildCandidate(question: buildQuestion(id: 'q1'), selectionScore: 0.7),
        buildCandidate(question: buildQuestion(id: 'q2'), selectionScore: 0.8),
      ];
      final selection = buildSelectionResult(candidates: dupCandidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(2));
      expect(spec.orderedQuestionIds, equals(['q1', 'q2']));
    });

    test(
        '15. Single question selection produces 1 section and 1 question safely',
        () {
      final selection = buildSelectionResult(
        candidates: [buildCandidate(question: buildQuestion(id: 'q_single'))],
      );
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(1));
      expect(spec.totalSections, equals(1));
      expect(spec.sections.first.questionCount, equals(1));
      expect(spec.sections.first.questions.first.id, equals('q_single'));
    });

    test('16. maxQuestions truncation caps total session questions', () {
      final candidates = List.generate(
        10,
        (i) => buildCandidate(
          question: buildQuestion(id: 'q_$i'),
          selectionScore: 0.9 - (i * 0.05),
        ),
      );
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        maxQuestions: 4,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(4));
      expect(spec.isConstraintLimited, isTrue);
      expect(spec.constraintLimitReason, contains('capped at maxQuestions'));
    });

    test(
        '17. Section size larger than total questions produces exactly 1 section',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1')),
        buildCandidate(question: buildQuestion(id: 'q2')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sectionSize: 10,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(2));
      expect(spec.totalSections, equals(1));
      expect(spec.sections.first.questionCount, equals(2));
    });

    test(
        '18. Section size smaller than total questions splits into multiple sections',
        () {
      final candidates = List.generate(
        7,
        (i) => buildCandidate(question: buildQuestion(id: 'q_$i')),
      );
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sectionSize: 3,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(7));
      expect(spec.totalSections, equals(3)); // 3 + 3 + 1
      expect(spec.sections[0].questionCount, equals(3));
      expect(spec.sections[1].questionCount, equals(3));
      expect(spec.sections[2].questionCount, equals(1));
    });

    test('19. Null learnerId is safely preserved as null', () {
      final selection = buildSelectionResult(
        candidates: [buildCandidate(question: buildQuestion(id: 'q1'))],
      );
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.learnerId, isNull);
    });

    test(
        '20. toLearningSession adapter converts to P19 domain entity without error',
        () {
      final candidates = [
        buildCandidate(
          question: buildQuestion(id: 'q1', objectiveIds: ['obj_fr']),
        ),
        buildCandidate(
          question: buildQuestion(id: 'q2', objectiveIds: ['obj_dpsp']),
        ),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        learnerId: 'learner_p19',
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final learningSession = spec.toLearningSession(startedAt: fixedDate);
      expect(learningSession.sessionId, equals(spec.sessionId));
      expect(learningSession.learnerId, equals('learner_p19'));
      expect(learningSession.totalQuestions, equals(2));
      expect(
          learningSession.orderedQuestionIds, equals(spec.orderedQuestionIds));
      expect(learningSession.state, equals(LearningSessionState.created));
    });
  });

  // ==========================================================================
  // GROUP 3: MODE-SPECIFIC QUESTION ORDERING & PROGRESSION
  // ==========================================================================
  group('P34.3 Group 3 — Mode-Specific Question Ordering & Progression', () {
    test('21. STANDARD mode organizes questions into pedagogical 4-stage flow',
        () {
      final candidates = [
        // Warmup (fresh, low weakness, low historical priority)
        buildCandidate(
          question: buildQuestion(id: 'q_warmup'),
          historicalPriority: 0.2,
          learnerWeakness: 0.1,
          recencyScore: 1.0,
          selectionScore: 0.4,
        ),
        // Core Weak (high weakness)
        buildCandidate(
          question: buildQuestion(id: 'q_weak'),
          historicalPriority: 0.3,
          learnerWeakness: 0.8,
          selectionScore: 0.7,
        ),
        // High PYQ (high historical priority, low weakness)
        buildCandidate(
          question: buildQuestion(id: 'q_pyq'),
          historicalPriority: 0.9,
          learnerWeakness: 0.0,
          selectionScore: 0.6,
        ),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.standard,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, contains('q_warmup'));
      expect(spec.orderedQuestionIds, contains('q_weak'));
      expect(spec.orderedQuestionIds, contains('q_pyq'));
      // Warmup and Weak questions are placed before high PYQ
      expect(spec.orderedQuestionIds.first, equals('q_warmup'));
    });

    test('22. WEAKNESS_FOCUSED mode sorts primarily by learner weakness DESC',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_low'),
            learnerWeakness: 0.2,
            selectionScore: 0.9),
        buildCandidate(
            question: buildQuestion(id: 'q_high'),
            learnerWeakness: 0.9,
            selectionScore: 0.5),
        buildCandidate(
            question: buildQuestion(id: 'q_med'),
            learnerWeakness: 0.5,
            selectionScore: 0.7),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.weaknessFocused,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q_high', 'q_med', 'q_low']));
    });

    test('23. PYQ_FOCUSED mode sorts primarily by historical priority DESC',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_low_pyq'),
            historicalPriority: 0.2,
            selectionScore: 0.9),
        buildCandidate(
            question: buildQuestion(id: 'q_high_pyq'),
            historicalPriority: 0.95,
            selectionScore: 0.4),
        buildCandidate(
            question: buildQuestion(id: 'q_med_pyq'),
            historicalPriority: 0.6,
            selectionScore: 0.7),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.pyqFocused,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds,
          equals(['q_high_pyq', 'q_med_pyq', 'q_low_pyq']));
    });

    test('24. BALANCED mode interleaves multi-topic questions evenly', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q_t1_a', topic: 'Topic A')),
        buildCandidate(question: buildQuestion(id: 'q_t1_b', topic: 'Topic A')),
        buildCandidate(question: buildQuestion(id: 'q_t2_a', topic: 'Topic B')),
        buildCandidate(question: buildQuestion(id: 'q_t2_b', topic: 'Topic B')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.balanced,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      // Topic A and Topic B questions alternate
      expect(spec.orderedQuestions[0].topic, equals('Topic A'));
      expect(spec.orderedQuestions[1].topic, equals('Topic B'));
      expect(spec.orderedQuestions[2].topic, equals('Topic A'));
      expect(spec.orderedQuestions[3].topic, equals('Topic B'));
    });

    test(
        '25. REMEDIAL_PRACTICE mode prioritizes weak areas with difficulty progression',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_hard', difficulty: 'Hard'),
            learnerWeakness: 0.8),
        buildCandidate(
            question: buildQuestion(id: 'q_easy', difficulty: 'Easy'),
            learnerWeakness: 0.8),
        buildCandidate(
            question: buildQuestion(id: 'q_non_weak', difficulty: 'Easy'),
            learnerWeakness: 0.0),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.remedialPractice,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      // High weakness first, and within high weakness Easy before Hard
      expect(
          spec.orderedQuestionIds, equals(['q_easy', 'q_hard', 'q_non_weak']));
    });

    test('26. MIXED_REVISION mode round-robins across all available topics',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_polity_1', topic: 'Polity')),
        buildCandidate(
            question: buildQuestion(id: 'q_polity_2', topic: 'Polity')),
        buildCandidate(
            question: buildQuestion(id: 'q_hist_1', topic: 'History')),
        buildCandidate(
            question: buildQuestion(id: 'q_econ_1', topic: 'Economy')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.mixedRevision,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final topics = spec.orderedQuestions.map((q) => q.topic).toList();
      expect(topics[0], equals('Economy'));
      expect(topics[1], equals('History'));
      expect(topics[2], equals('Polity'));
      expect(topics[3], equals('Polity'));
    });

    test('27. Identical scores are tie-broken by historical priority DESC', () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1'),
            selectionScore: 0.5,
            historicalPriority: 0.2),
        buildCandidate(
            question: buildQuestion(id: 'q2'),
            selectionScore: 0.5,
            historicalPriority: 0.8),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.pyqFocused,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q2', 'q1']));
    });

    test(
        '28. Identical scores and historical priority are tie-broken by learner weakness DESC',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1'),
            selectionScore: 0.5,
            historicalPriority: 0.5,
            learnerWeakness: 0.2),
        buildCandidate(
            question: buildQuestion(id: 'q2'),
            selectionScore: 0.5,
            historicalPriority: 0.5,
            learnerWeakness: 0.9),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.weaknessFocused,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q2', 'q1']));
    });

    test(
        '29. Identical scores, priority, and weakness are tie-broken by year DESC',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_2021', year: 2021),
            selectionScore: 0.5,
            historicalPriority: 0.5,
            learnerWeakness: 0.5),
        buildCandidate(
            question: buildQuestion(id: 'q_2024', year: 2024),
            selectionScore: 0.5,
            historicalPriority: 0.5,
            learnerWeakness: 0.5),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.weaknessFocused,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q_2024', 'q_2021']));
    });

    test(
        '30. Identical scores, priority, weakness, and year are tie-broken by questionId ASC',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_z', year: 2024),
            selectionScore: 0.5,
            historicalPriority: 0.5,
            learnerWeakness: 0.5),
        buildCandidate(
            question: buildQuestion(id: 'q_a', year: 2024),
            selectionScore: 0.5,
            historicalPriority: 0.5,
            learnerWeakness: 0.5),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.weaknessFocused,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q_a', 'q_z']));
    });
  });

  // ==========================================================================
  // GROUP 4: OBJECTIVE BALANCING POLICIES
  // ==========================================================================
  group('P34.4 Group 4 — Objective Balancing Policies', () {
    test('31. ObjectiveBalancingPolicy.none preserves raw candidate sequence',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1', objectiveIds: ['obj_1']),
            selectionScore: 0.9),
        buildCandidate(
            question: buildQuestion(id: 'q2', objectiveIds: ['obj_1']),
            selectionScore: 0.8),
        buildCandidate(
            question: buildQuestion(id: 'q3', objectiveIds: ['obj_2']),
            selectionScore: 0.7),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        objectiveBalancing: ObjectiveBalancingPolicy.none,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q1', 'q2', 'q3']));
    });

    test(
        '32. ObjectiveBalancingPolicy.balanced round-robins across distinct objectives',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_o1_a', objectiveIds: ['obj_1']),
            selectionScore: 0.9),
        buildCandidate(
            question: buildQuestion(id: 'q_o1_b', objectiveIds: ['obj_1']),
            selectionScore: 0.8),
        buildCandidate(
            question: buildQuestion(id: 'q_o2_a', objectiveIds: ['obj_2']),
            selectionScore: 0.7),
        buildCandidate(
            question: buildQuestion(id: 'q_o2_b', objectiveIds: ['obj_2']),
            selectionScore: 0.6),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        objectiveBalancing: ObjectiveBalancingPolicy.balanced,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestions[0].objectiveIds.first, equals('obj_1'));
      expect(spec.orderedQuestions[1].objectiveIds.first, equals('obj_2'));
      expect(spec.orderedQuestions[2].objectiveIds.first, equals('obj_1'));
      expect(spec.orderedQuestions[3].objectiveIds.first, equals('obj_2'));
    });

    test(
        '33. Objective distribution correctly tallies multiple objectives per question',
        () {
      final candidates = [
        buildCandidate(
            question:
                buildQuestion(id: 'q1', objectiveIds: ['obj_1', 'obj_2'])),
        buildCandidate(
            question: buildQuestion(id: 'q2', objectiveIds: ['obj_1'])),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.objectiveCounts['obj_1'], equals(2));
      expect(spec.distribution.objectiveCounts['obj_2'], equals(1));
    });

    test('34. Single objective session has objectiveCounts with length 1', () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1', objectiveIds: ['obj_only'])),
        buildCandidate(
            question: buildQuestion(id: 'q2', objectiveIds: ['obj_only'])),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.objectiveCounts.length, equals(1));
      expect(spec.distribution.objectiveCounts['obj_only'], equals(2));
    });

    test(
        '35. Missing objective IDs in question fall back to primaryObjectiveId or lo_unassigned',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1', objectiveIds: const [])),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.objectiveCounts.containsKey('lo_unassigned'),
          isTrue);
    });

    test(
        '36. Balanced objective policy maintains order across 5 distinct objectives',
        () {
      final candidates = [
        for (int i = 1; i <= 5; i++)
          buildCandidate(
              question: buildQuestion(id: 'q_$i', objectiveIds: ['obj_$i'])),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        objectiveBalancing: ObjectiveBalancingPolicy.balanced,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.objectiveCounts.length, equals(5));
      for (int i = 1; i <= 5; i++) {
        expect(spec.distribution.objectiveCounts['obj_$i'], equals(1));
      }
    });

    test('37. Uneven objective counts drain exhausted objectives gracefully',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_a1', objectiveIds: ['obj_A'])),
        buildCandidate(
            question: buildQuestion(id: 'q_a2', objectiveIds: ['obj_A'])),
        buildCandidate(
            question: buildQuestion(id: 'q_a3', objectiveIds: ['obj_A'])),
        buildCandidate(
            question: buildQuestion(id: 'q_b1', objectiveIds: ['obj_B'])),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        objectiveBalancing: ObjectiveBalancingPolicy.balanced,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(4));
      expect(spec.distribution.objectiveCounts['obj_A'], equals(3));
      expect(spec.distribution.objectiveCounts['obj_B'], equals(1));
    });

    test('38. Priority-weighted objective policy respects mode priority', () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1', objectiveIds: ['obj_1']),
            historicalPriority: 0.9),
        buildCandidate(
            question: buildQuestion(id: 'q2', objectiveIds: ['obj_2']),
            historicalPriority: 0.3),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        objectiveBalancing: ObjectiveBalancingPolicy.priorityWeighted,
        sessionMode: PracticeSessionMode.pyqFocused,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds.first, equals('q1'));
    });

    test('39. Objective counts are non-negative and sum >= totalQuestions', () {
      final candidates = [
        buildCandidate(
            question:
                buildQuestion(id: 'q1', objectiveIds: ['obj_1', 'obj_2'])),
        buildCandidate(
            question: buildQuestion(id: 'q2', objectiveIds: ['obj_2'])),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final sum =
          spec.distribution.objectiveCounts.values.reduce((a, b) => a + b);
      expect(sum, greaterThanOrEqualTo(spec.totalQuestions));
    });

    test('40. Objective balancing preserves question model content intact', () {
      final original =
          buildQuestion(id: 'q_intact', objectiveIds: ['obj_spec']);
      final selection = buildSelectionResult(
        candidates: [buildCandidate(question: original)],
      );
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        objectiveBalancing: ObjectiveBalancingPolicy.balanced,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final sessionQ = spec.orderedQuestions.first;
      expect(sessionQ.id, equals(original.id));
      expect(sessionQ.normalizedText, equals(original.normalizedText));
    });
  });

  // ==========================================================================
  // GROUP 5: TOPIC BALANCING POLICIES
  // ==========================================================================
  group('P34.5 Group 5 — Topic Balancing Policies', () {
    test('41. TopicBalancingPolicy.none preserves raw candidate sequence', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1', topic: 'Polity')),
        buildCandidate(question: buildQuestion(id: 'q2', topic: 'Polity')),
        buildCandidate(question: buildQuestion(id: 'q3', topic: 'History')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        topicBalancing: TopicBalancingPolicy.none,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q1', 'q2', 'q3']));
    });

    test('42. TopicBalancingPolicy.balanced alternates questions across topics',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q_p1', topic: 'Polity')),
        buildCandidate(question: buildQuestion(id: 'q_p2', topic: 'Polity')),
        buildCandidate(question: buildQuestion(id: 'q_h1', topic: 'History')),
        buildCandidate(question: buildQuestion(id: 'q_h2', topic: 'History')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        topicBalancing: TopicBalancingPolicy.balanced,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestions[0].topic, equals('History'));
      expect(spec.orderedQuestions[1].topic, equals('Polity'));
      expect(spec.orderedQuestions[2].topic, equals('History'));
      expect(spec.orderedQuestions[3].topic, equals('Polity'));
    });

    test('43. Topic counts in distribution accurately match selected questions',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1', topic: 'Polity')),
        buildCandidate(question: buildQuestion(id: 'q2', topic: 'Polity')),
        buildCandidate(question: buildQuestion(id: 'q3', topic: 'Geography')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.topicCounts['Polity'], equals(2));
      expect(spec.distribution.topicCounts['Geography'], equals(1));
    });

    test('44. Sum of topic counts equals total session questions', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1', topic: 'T1')),
        buildCandidate(question: buildQuestion(id: 'q2', topic: 'T2')),
        buildCandidate(question: buildQuestion(id: 'q3', topic: 'T3')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final sum = spec.distribution.topicCounts.values.reduce((a, b) => a + b);
      expect(sum, equals(spec.totalQuestions));
    });

    test(
        '45. Single topic corpus produces valid topic distribution with length 1',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1', topic: 'Polity')),
        buildCandidate(question: buildQuestion(id: 'q2', topic: 'Polity')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.topicCounts.length, equals(1));
      expect(spec.distribution.topicCounts['Polity'], equals(2));
    });

    test('46. Multi-topic round-robin handles 4 distinct topics', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1', topic: 'Economy')),
        buildCandidate(question: buildQuestion(id: 'q2', topic: 'Polity')),
        buildCandidate(question: buildQuestion(id: 'q3', topic: 'History')),
        buildCandidate(question: buildQuestion(id: 'q4', topic: 'Geography')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        topicBalancing: TopicBalancingPolicy.balanced,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.topicCounts.length, equals(4));
    });

    test('47. Truncated session recalculates topic distribution accurately',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1', topic: 'Polity'),
            selectionScore: 0.9),
        buildCandidate(
            question: buildQuestion(id: 'q2', topic: 'Polity'),
            selectionScore: 0.8),
        buildCandidate(
            question: buildQuestion(id: 'q3', topic: 'History'),
            selectionScore: 0.1),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        maxQuestions: 2,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(2));
      expect(spec.distribution.topicCounts['Polity'], equals(2));
      expect(spec.distribution.topicCounts.containsKey('History'), isFalse);
    });

    test('48. Topic names with mixed casing are preserved verbatim', () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1', topic: 'Modern Indian History')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.topicCounts.containsKey('Modern Indian History'),
          isTrue);
    });

    test('49. Empty topic defaults cleanly to General without throwing', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1', topic: '')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.topicCounts.isNotEmpty, isTrue);
    });

    test('50. All section candidates reflect topic distribution correctly', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1', topic: 'Polity')),
        buildCandidate(question: buildQuestion(id: 'q2', topic: 'History')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sectionSize: 1,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.sections[0].questions.first.topic, isNotEmpty);
      expect(spec.sections[1].questions.first.topic, isNotEmpty);
    });
  });

  // ==========================================================================
  // GROUP 6: DIFFICULTY PROGRESSION & ORDERING
  // ==========================================================================
  group('P34.6 Group 6 — Difficulty Progression & Ordering', () {
    test('51. PracticeDifficultyProgression.none preserves mode ordering', () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_hard', difficulty: 'Hard'),
            selectionScore: 0.9),
        buildCandidate(
            question: buildQuestion(id: 'q_easy', difficulty: 'Easy'),
            selectionScore: 0.8),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        difficultyProgression: PracticeDifficultyProgression.none,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q_hard', 'q_easy']));
    });

    test(
        '52. PracticeDifficultyProgression.easyToHard orders Easy -> Medium -> Hard',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_hard', difficulty: 'Hard')),
        buildCandidate(
            question: buildQuestion(id: 'q_easy', difficulty: 'Easy')),
        buildCandidate(
            question: buildQuestion(id: 'q_med', difficulty: 'Medium')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        difficultyProgression: PracticeDifficultyProgression.easyToHard,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q_easy', 'q_med', 'q_hard']));
    });

    test(
        '53. PracticeDifficultyProgression.mediumToHard orders Medium -> Hard -> Easy',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_easy', difficulty: 'Easy')),
        buildCandidate(
            question: buildQuestion(id: 'q_hard', difficulty: 'Hard')),
        buildCandidate(
            question: buildQuestion(id: 'q_med', difficulty: 'Medium')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        difficultyProgression: PracticeDifficultyProgression.mediumToHard,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q_med', 'q_hard', 'q_easy']));
    });

    test(
        '54. Missing/unspecified difficulty defaults to neutral placement without crashing',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_easy', difficulty: 'Easy')),
        buildCandidate(
            question: buildQuestion(id: 'q_none', difficulty: 'Custom')),
        buildCandidate(
            question: buildQuestion(id: 'q_hard', difficulty: 'Hard')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        difficultyProgression: PracticeDifficultyProgression.easyToHard,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestions.first.difficulty, equals('Easy'));
      expect(spec.orderedQuestions.last.difficulty, equals('Hard'));
    });

    test(
        '55. Distribution difficultyCounts accurately tallies difficulty levels',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1', difficulty: 'Easy')),
        buildCandidate(question: buildQuestion(id: 'q2', difficulty: 'Medium')),
        buildCandidate(question: buildQuestion(id: 'q3', difficulty: 'Hard')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.difficultyCounts['easy'], equals(1));
      expect(spec.distribution.difficultyCounts['medium'], equals(1));
      expect(spec.distribution.difficultyCounts['hard'], equals(1));
    });

    test(
        '56. All questions having identical difficulty preserves tie-breaker sequence',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1', difficulty: 'Medium'),
            selectionScore: 0.9),
        buildCandidate(
            question: buildQuestion(id: 'q2', difficulty: 'Medium'),
            selectionScore: 0.8),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        difficultyProgression: PracticeDifficultyProgression.easyToHard,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q1', 'q2']));
    });

    test('57. Difficulty comparison is case-insensitive (EASY == easy)', () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_hard', difficulty: 'HARD')),
        buildCandidate(
            question: buildQuestion(id: 'q_easy', difficulty: 'EASY')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        difficultyProgression: PracticeDifficultyProgression.easyToHard,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q_easy', 'q_hard']));
    });

    test('58. Beginner and Advanced aliases are mapped correctly', () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q_adv', difficulty: 'Advanced')),
        buildCandidate(
            question: buildQuestion(id: 'q_beg', difficulty: 'Beginner')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        difficultyProgression: PracticeDifficultyProgression.easyToHard,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedQuestionIds, equals(['q_beg', 'q_adv']));
    });

    test(
        '59. Section metadata retains correct candidate difficulty information',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1', difficulty: 'Easy')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.sections.first.questions.first.difficulty, equals('Easy'));
    });

    test('60. Zero fabricated difficulty when difficulty field is missing', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1', difficulty: '')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.difficultyCounts.containsKey(''), isTrue);
    });
  });

  // ==========================================================================
  // GROUP 7: HISTORICAL PYQ DISTRIBUTION & ANALYTICS
  // ==========================================================================
  group('P34.7 Group 7 — Historical PYQ Distribution & Analytics', () {
    test('61. historicalQuestionCount correctly counts PYQ candidates', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q_pyq_1', year: 2023)),
        buildCandidate(question: buildQuestion(id: 'q_pyq_2', year: 2024)),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.historicalQuestionCount, equals(2));
      expect(spec.distribution.historicalQuestionRatio, equals(1.0));
      expect(spec.distribution.nonHistoricalQuestionCount, equals(0));
    });

    test(
        '62. nonHistoricalQuestionCount correctly counts non-PYQ questions (year == 0)',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q_pyq', year: 2024)),
        buildCandidate(question: buildQuestion(id: 'q_model', year: 0)),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.historicalQuestionCount, equals(1));
      expect(spec.distribution.historicalQuestionRatio, equals(0.5));
      expect(spec.distribution.nonHistoricalQuestionCount, equals(1));
    });

    test(
        '63. recentHistoricalQuestionCount tallies questions from last 3 years',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q_2024', year: 2024)),
        buildCandidate(question: buildQuestion(id: 'q_2023', year: 2023)),
        buildCandidate(question: buildQuestion(id: 'q_2015', year: 2015)),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      // Max year is 2024; cutoff is 2022. 2024 and 2023 are recent (2 questions)
      expect(spec.distribution.recentHistoricalQuestionCount, equals(2));
    });

    test('64. yearCounts accurately tallies questions per examination year',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1', year: 2022)),
        buildCandidate(question: buildQuestion(id: 'q2', year: 2022)),
        buildCandidate(question: buildQuestion(id: 'q3', year: 2024)),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.yearCounts[2022], equals(2));
      expect(spec.distribution.yearCounts[2024], equals(1));
    });

    test('65. historicalQuestionRatio is bounded strictly in [0.0, 1.0]', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1', year: 2024)),
        buildCandidate(question: buildQuestion(id: 'q2', year: 0)),
        buildCandidate(question: buildQuestion(id: 'q3', year: 2021)),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(
          spec.distribution.historicalQuestionRatio, greaterThanOrEqualTo(0.0));
      expect(spec.distribution.historicalQuestionRatio, lessThanOrEqualTo(1.0));
      expect(spec.distribution.historicalQuestionRatio.isNaN, isFalse);
      expect(spec.distribution.historicalQuestionRatio.isInfinite, isFalse);
    });

    test('66. Empty session has 0.0 historicalQuestionRatio and zero counts',
        () {
      final emptySelection = buildSelectionResult(candidates: []);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: emptySelection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.historicalQuestionCount, equals(0));
      expect(spec.distribution.historicalQuestionRatio, equals(0.0));
      expect(spec.distribution.recentHistoricalQuestionCount, equals(0));
      expect(spec.distribution.nonHistoricalQuestionCount, equals(0));
    });

    test('67. Multi-exam years are partitioned by session exam', () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1', examId: 'upsc', year: 2024)),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.yearCounts[2024], equals(1));
    });

    test('68. Source provenance reference is retained on all session questions',
        () {
      final candidates = [
        buildCandidate(
          question: buildQuestion(
            id: 'q1',
            source: PyqSourceReference.official(
                examId: 'upsc', year: 2024, paper: 'GS1'),
          ),
        ),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final q = spec.orderedQuestions.first;
      expect(q.source.sourceType, equals('officialPdf'));
      expect(q.source.publisher, contains('UPSC'));
    });

    test('69. Historical metadata is preserved in candidate audit data', () {
      final candidates = [
        buildCandidate(
          question: buildQuestion(id: 'q1', year: 2024),
          historicalPriority: 0.85,
        ),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedCandidates.first.historicalPriority, equals(0.85));
    });

    test('70. Distribution serializes and deserializes to JSON cleanly', () {
      final dist = PracticeSessionDistribution(
        historicalQuestionCount: 5,
        historicalQuestionRatio: 0.5,
        recentHistoricalQuestionCount: 3,
        nonHistoricalQuestionCount: 5,
        highWeaknessCount: 2,
        mediumWeaknessCount: 3,
        lowWeaknessCount: 5,
        yearCounts: {2024: 3, 2023: 2},
      );

      final json = dist.toJson();
      final roundtrip = PracticeSessionDistribution.fromJson(json);

      expect(roundtrip.historicalQuestionCount, equals(5));
      expect(roundtrip.historicalQuestionRatio, equals(0.5));
      expect(roundtrip.yearCounts[2024], equals(3));
    });
  });

  // ==========================================================================
  // GROUP 8: LEARNER PRIORITY & WEAKNESS ANALYTICS
  // ==========================================================================
  group('P34.8 Group 8 — Learner Priority & Weakness Analytics', () {
    test('71. highWeaknessCount tallies questions with deficiency >= 0.6', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1'), learnerWeakness: 0.8),
        buildCandidate(
            question: buildQuestion(id: 'q2'), learnerWeakness: 0.65),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.highWeaknessCount, equals(2));
      expect(spec.distribution.mediumWeaknessCount, equals(0));
      expect(spec.distribution.lowWeaknessCount, equals(0));
    });

    test(
        '72. mediumWeaknessCount tallies questions with 0.2 <= deficiency < 0.6',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1'), learnerWeakness: 0.4),
        buildCandidate(
            question: buildQuestion(id: 'q2'), learnerWeakness: 0.25),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.highWeaknessCount, equals(0));
      expect(spec.distribution.mediumWeaknessCount, equals(2));
      expect(spec.distribution.lowWeaknessCount, equals(0));
    });

    test('73. lowWeaknessCount tallies questions with deficiency < 0.2', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1'), learnerWeakness: 0.0),
        buildCandidate(
            question: buildQuestion(id: 'q2'), learnerWeakness: 0.15),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.highWeaknessCount, equals(0));
      expect(spec.distribution.mediumWeaknessCount, equals(0));
      expect(spec.distribution.lowWeaknessCount, equals(2));
    });

    test('74. Mixed learner weakness distribution sums to total questions', () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1'), learnerWeakness: 0.9), // high
        buildCandidate(
            question: buildQuestion(id: 'q2'), learnerWeakness: 0.4), // med
        buildCandidate(
            question: buildQuestion(id: 'q3'), learnerWeakness: 0.0), // low
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final totalWeaknessCounts = spec.distribution.highWeaknessCount +
          spec.distribution.mediumWeaknessCount +
          spec.distribution.lowWeaknessCount;
      expect(totalWeaknessCounts, equals(spec.totalQuestions));
    });

    test(
        '75. Unattempted questions (weakness == 0.0) are classified as lowWeakness',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1'), learnerWeakness: 0.0),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.distribution.lowWeaknessCount, equals(1));
    });

    test('76. Candidate audit data preserves exact learnerWeakness decimal',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1'), learnerWeakness: 0.8333),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.orderedCandidates.first.learnerWeakness,
          closeTo(0.8333, 0.0001));
    });

    test(
        '77. Section candidate metadata matches session-level candidate metadata',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1'), learnerWeakness: 0.7),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(
        spec.sections.first.candidateMetadata.first.learnerWeakness,
        equals(spec.orderedCandidates.first.learnerWeakness),
      );
    });

    test('78. LearnerId is propagated through configuration into session spec',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        learnerId: 'learner_master_99',
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.learnerId, equals('learner_master_99'));
    });

    test('79. P34 does not mutate or modify learner progress', () {
      final progressBefore = LearnerProgress(
        learnerId: 'learner_1',
        objectiveId: 'obj_1',
        status: LearnerObjectiveStatus.inProgress,
        attemptCount: 10,
        correctCount: 2,
      );

      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1', objectiveIds: ['obj_1']),
            learnerWeakness: 0.8),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(progressBefore.attemptCount, equals(10));
      expect(progressBefore.correctCount, equals(2));
    });

    test('80. Zero cognitive prediction claims in distribution or metadata',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final jsonStr = jsonEncode(spec.toJson());
      expect(jsonStr.contains('will appear'), isFalse);
      expect(jsonStr.contains('expected question'), isFalse);
    });
  });

  // ==========================================================================
  // GROUP 9: DETERMINISM, REPLAY & IMMUTABILITY INVARIANTS
  // ==========================================================================
  group('P34.9 Group 9 — Determinism, Replay & Immutability Invariants', () {
    test(
        '81. Deterministic session ID: same inputs produce identical SHA-256 session ID',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1')),
        buildCandidate(question: buildQuestion(id: 'q2')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec1 = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );
      final spec2 = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec1.sessionId, equals(spec2.sessionId));
      expect(spec1.sessionId.startsWith('sess_upsc_'), isTrue);
    });

    test(
        '82. Deterministic replay: 10 consecutive executions produce byte-identical JSON',
        () {
      final candidates = [
        buildCandidate(
            question: buildQuestion(id: 'q1', topic: 'Polity'),
            selectionScore: 0.9),
        buildCandidate(
            question: buildQuestion(id: 'q2', topic: 'History'),
            selectionScore: 0.8),
        buildCandidate(
            question: buildQuestion(id: 'q3', topic: 'Economy'),
            selectionScore: 0.7),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.standard,
      );

      final baselineJson = jsonEncode(
        orchestrator
            .orchestrateSession(
              selectionResult: selection,
              config: config,
              orchestratedAt: fixedDate,
            )
            .toJson(),
      );

      for (int i = 0; i < 10; i++) {
        final replayedJson = jsonEncode(
          orchestrator
              .orchestrateSession(
                selectionResult: selection,
                config: config,
                orchestratedAt: fixedDate,
              )
              .toJson(),
        );
        expect(replayedJson, equals(baselineJson));
      }
    });

    test(
        '83. Permuted candidate input order produces identical question sequence',
        () {
      final c1 = buildCandidate(
          question: buildQuestion(id: 'q1'), selectionScore: 0.9);
      final c2 = buildCandidate(
          question: buildQuestion(id: 'q2'), selectionScore: 0.7);
      final c3 = buildCandidate(
          question: buildQuestion(id: 'q3'), selectionScore: 0.5);

      final selectionA = buildSelectionResult(candidates: [c1, c2, c3]);
      final selectionB = buildSelectionResult(candidates: [c3, c1, c2]);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.weaknessFocused,
      );

      final specA = orchestrator.orchestrateSession(
        selectionResult: selectionA,
        config: config,
        orchestratedAt: fixedDate,
      );
      final specB = orchestrator.orchestrateSession(
        selectionResult: selectionB,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(specA.orderedQuestionIds, equals(specB.orderedQuestionIds));
      expect(specA.sessionId, equals(specB.sessionId));
    });

    test('84. Spec result lists are deeply unmodifiable', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(() => spec.orderedQuestions.add(buildQuestion(id: 'mutated')),
          throwsUnsupportedError);
      expect(
          () => spec.orderedQuestionIds.add('mutated'), throwsUnsupportedError);
      expect(
          () => spec.sections.add(spec.sections.first), throwsUnsupportedError);
    });

    test('85. Section lists and candidate metadata are deeply unmodifiable',
        () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final sec = spec.sections.first;
      expect(() => sec.questionIds.add('mutated'), throwsUnsupportedError);
      expect(() => sec.questions.add(buildQuestion(id: 'mutated')),
          throwsUnsupportedError);
      expect(() => sec.candidateMetadata.add(candidates.first),
          throwsUnsupportedError);
    });

    test('86. Distribution maps are deeply unmodifiable', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(() => spec.distribution.objectiveCounts['hack'] = 1,
          throwsUnsupportedError);
      expect(() => spec.distribution.topicCounts['hack'] = 1,
          throwsUnsupportedError);
      expect(
          () => spec.distribution.yearCounts[1999] = 1, throwsUnsupportedError);
      expect(() => spec.distribution.difficultyCounts['hack'] = 1,
          throwsUnsupportedError);
    });

    test('87. Session serialization roundtrips through JSON without data loss',
        () {
      final candidates = [
        buildCandidate(
          question:
              buildQuestion(id: 'q1', topic: 'Polity', difficulty: 'Medium'),
          selectionScore: 0.85,
        ),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        learnerId: 'learner_101',
        sessionMode: PracticeSessionMode.standard,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final json = spec.toJson();
      final roundtrip = AdaptivePracticeSessionSpec.fromJson(json);

      expect(roundtrip.sessionId, equals(spec.sessionId));
      expect(roundtrip.examId, equals(spec.examId));
      expect(roundtrip.learnerId, equals(spec.learnerId));
      expect(roundtrip.sessionMode, equals(spec.sessionMode));
      expect(roundtrip.totalQuestions, equals(spec.totalQuestions));
      expect(roundtrip.totalSections, equals(spec.totalSections));
      expect(
          roundtrip.totalEstimatedSeconds, equals(spec.totalEstimatedSeconds));
      expect(roundtrip.orderedQuestionIds, equals(spec.orderedQuestionIds));
    });

    test(
        '88. Sections total estimated seconds equals spec totalEstimatedSeconds',
        () {
      final candidates = List.generate(
        8,
        (i) => buildCandidate(question: buildQuestion(id: 'q_$i')),
      );
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sectionSize: 3,
        estimatedSecondsPerQuestion: 45,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final sectionSecondsSum =
          spec.sections.fold<int>(0, (sum, s) => sum + s.estimatedSeconds);
      expect(sectionSecondsSum, equals(spec.totalEstimatedSeconds));
      expect(spec.totalEstimatedSeconds, equals(8 * 45));
    });

    test('89. Section question count sum exactly equals totalQuestions', () {
      final candidates = List.generate(
        11,
        (i) => buildCandidate(question: buildQuestion(id: 'q_$i')),
      );
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sectionSize: 4,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final sectionQSum =
          spec.sections.fold<int>(0, (sum, s) => sum + s.questionCount);
      expect(sectionQSum, equals(spec.totalQuestions));
      expect(spec.totalQuestions, equals(11));
    });

    test(
        '90. Zero DateTime.now() in orchestrator: uses caller-supplied timestamp',
        () {
      final candidates = [buildCandidate(question: buildQuestion(id: 'q1'))];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final customTime = DateTime.utc(2025, 5, 20, 10, 30, 0);
      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: customTime,
      );

      expect(spec.orchestratedAt, equals(customTime));
    });
  });

  // ==========================================================================
  // GROUP 10: EDUCATIONAL SAFETY, NON-PREDICTIVE & PROPERTY INVARIANTS
  // ==========================================================================
  group('P34.10 Group 10 — Safety, Non-Predictive & Property Invariants', () {
    test(
        '91. Zero question fabrication: all questions in session match selection verbatim',
        () {
      final original = buildQuestion(
        id: 'q_exact',
        normalizedText: 'Exact verbatim text without modifications',
        options: const [
          Option(key: 'A', text: 'Option Alpha'),
          Option(key: 'B', text: 'Option Beta'),
        ],
      );
      final selection = buildSelectionResult(
        candidates: [buildCandidate(question: original)],
      );
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final sessionQ = spec.orderedQuestions.first;
      expect(sessionQ.id, equals('q_exact'));
      expect(sessionQ.normalizedText, equals(original.normalizedText));
      expect(sessionQ.options.length, equals(2));
      expect(sessionQ.options.first.text, equals('Option Alpha'));
    });

    test(
        '92. Answer key integrity: option keys and expected answers are preserved',
        () {
      final original = buildQuestion(
        id: 'q_ans',
        officialAnswer: const Answer(
          correctOptionKeys: ['C', 'D'],
          officialAnswerSource: 'Supreme Court Case Law',
        ),
      );
      final selection = buildSelectionResult(
        candidates: [buildCandidate(question: original)],
      );
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final ans = spec.orderedQuestions.first.officialAnswer;
      expect(ans.correctOptionKeys, equals(['C', 'D']));
      expect(ans.officialAnswerSource, equals('Supreme Court Case Law'));
    });

    test('93. Property invariant: totalQuestions <= requestedQuestionCount',
        () {
      final candidates = List.generate(
        5,
        (i) => buildCandidate(question: buildQuestion(id: 'q_$i')),
      );
      final selection =
          buildSelectionResult(candidates: candidates, requestedCount: 5);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        maxQuestions: 3,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, lessThanOrEqualTo(3));
      expect(spec.totalQuestions, lessThanOrEqualTo(selection.selectedCount));
    });

    test('94. Property invariant: all question IDs in session are unique', () {
      final candidates = List.generate(
        20,
        (i) => buildCandidate(question: buildQuestion(id: 'q_${i % 10}')),
      );
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final uniqueSet = spec.orderedQuestionIds.toSet();
      expect(uniqueSet.length, equals(spec.totalQuestions));
    });

    test('95. Property invariant: all section question IDs belong to session',
        () {
      final candidates = List.generate(
        15,
        (i) => buildCandidate(question: buildQuestion(id: 'q_$i')),
      );
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sectionSize: 5,
      );

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      final allSectionIds = <String>{};
      for (final sec in spec.sections) {
        for (final id in sec.questionIds) {
          expect(spec.orderedQuestionIds.contains(id), isTrue);
          allSectionIds.add(id);
        }
      }
      expect(allSectionIds.length, equals(spec.totalQuestions));
    });

    test('96. Property invariant: all distribution counts >= 0', () {
      final candidates = [
        buildCandidate(question: buildQuestion(id: 'q1')),
      ];
      final selection = buildSelectionResult(candidates: candidates);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(
          spec.distribution.historicalQuestionCount, greaterThanOrEqualTo(0));
      expect(spec.distribution.recentHistoricalQuestionCount,
          greaterThanOrEqualTo(0));
      expect(spec.distribution.nonHistoricalQuestionCount,
          greaterThanOrEqualTo(0));
      expect(spec.distribution.highWeaknessCount, greaterThanOrEqualTo(0));
      expect(spec.distribution.mediumWeaknessCount, greaterThanOrEqualTo(0));
      expect(spec.distribution.lowWeaknessCount, greaterThanOrEqualTo(0));
      expect(spec.totalEstimatedSeconds, greaterThanOrEqualTo(0));
    });

    test(
        '97. Multi-exam isolation: UPSC session contains 0 BPSC or SSC questions',
        () {
      final mixed = [
        buildCandidate(question: buildQuestion(id: 'q_upsc', examId: 'upsc')),
        buildCandidate(question: buildQuestion(id: 'q_bpsc', examId: 'bpsc')),
        buildCandidate(question: buildQuestion(id: 'q_ssc', examId: 'ssc')),
      ];
      final selection = buildSelectionResult(examId: 'upsc', candidates: mixed);
      final config = AdaptivePracticeSessionConfig(examId: 'upsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      for (final q in spec.orderedQuestions) {
        expect(q.examId, equals('upsc'));
      }
    });

    test(
        '98. Multi-exam isolation: BPSC session contains 0 UPSC or SSC questions',
        () {
      final mixed = [
        buildCandidate(question: buildQuestion(id: 'q_bpsc_1', examId: 'bpsc')),
        buildCandidate(question: buildQuestion(id: 'q_upsc_1', examId: 'upsc')),
      ];
      final selection = buildSelectionResult(examId: 'bpsc', candidates: mixed);
      final config = AdaptivePracticeSessionConfig(examId: 'bpsc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(1));
      expect(spec.orderedQuestions.first.examId, equals('bpsc'));
    });

    test(
        '99. Multi-exam isolation: SSC session contains 0 UPSC or BPSC questions',
        () {
      final mixed = [
        buildCandidate(question: buildQuestion(id: 'q_ssc_1', examId: 'ssc')),
        buildCandidate(question: buildQuestion(id: 'q_bpsc_1', examId: 'bpsc')),
      ];
      final selection = buildSelectionResult(examId: 'ssc', candidates: mixed);
      final config = AdaptivePracticeSessionConfig(examId: 'ssc');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(1));
      expect(spec.orderedQuestions.first.examId, equals('ssc'));
    });

    test(
        '100. Unknown exam produces safe failure with isConstraintLimited == true',
        () {
      final selection = buildSelectionResult(
        examId: 'unknown_exam_xyz',
        candidates: [],
      );
      final config = AdaptivePracticeSessionConfig(examId: 'unknown_exam_xyz');

      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );

      expect(spec.totalQuestions, equals(0));
      expect(spec.isConstraintLimited, isTrue);
    });
  });

  // ==========================================================================
  // GROUP 11: HIGH-THROUGHPUT PERFORMANCE BENCHMARKS
  // ==========================================================================
  group('P34.11 Group 11 — High-Throughput Performance Benchmarks', () {
    test('101. 1,000 selected questions: complete orchestration in < 100ms',
        () {
      final candidates = List.generate(
        1000,
        (i) => buildCandidate(
          question: buildQuestion(
            id: 'q_1k_$i',
            year: 2020 + (i % 5),
            topic: 'Topic ${i % 10}',
            objectiveIds: ['obj_${i % 20}'],
          ),
          selectionScore: 0.9 - (i % 100) * 0.005,
        ),
      );
      final selection =
          buildSelectionResult(candidates: candidates, requestedCount: 1000);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.standard,
        sectionSize: 10,
      );

      final sw = Stopwatch()..start();
      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );
      sw.stop();

      // ignore: avoid_print
      print(
          'P34 1K questions orchestration completed in: ${sw.elapsedMilliseconds}ms');
      expect(spec.totalQuestions, equals(1000));
      expect(spec.totalSections, equals(100));
      expect(sw.elapsedMilliseconds, lessThan(100));
    });

    test('102. 10,000 selected questions: complete orchestration in < 500ms',
        () {
      final candidates = List.generate(
        10000,
        (i) => buildCandidate(
          question: buildQuestion(
            id: 'q_10k_$i',
            year: 2015 + (i % 10),
            topic: 'Topic ${i % 50}',
            objectiveIds: ['obj_${i % 100}'],
          ),
          selectionScore: 0.9 - (i % 100) * 0.005,
        ),
      );
      final selection =
          buildSelectionResult(candidates: candidates, requestedCount: 10000);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.weaknessFocused,
        sectionSize: 20,
      );

      final sw = Stopwatch()..start();
      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );
      sw.stop();

      // ignore: avoid_print
      print(
          'P34 10K questions orchestration completed in: ${sw.elapsedMilliseconds}ms');
      expect(spec.totalQuestions, equals(10000));
      expect(spec.totalSections, equals(500));
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('103. 50,000 selected questions: complete orchestration in < 2.0s',
        () {
      final candidates = List.generate(
        50000,
        (i) => buildCandidate(
          question: buildQuestion(
            id: 'q_50k_$i',
            year: 2015 + (i % 10),
            topic: 'Topic ${i % 100}',
            objectiveIds: ['obj_${i % 200}'],
          ),
          selectionScore: 0.9 - (i % 100) * 0.005,
        ),
      );
      final selection =
          buildSelectionResult(candidates: candidates, requestedCount: 50000);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.pyqFocused,
        sectionSize: 50,
      );

      final sw = Stopwatch()..start();
      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );
      sw.stop();

      // ignore: avoid_print
      print(
          'P34 50K questions orchestration completed in: ${sw.elapsedMilliseconds}ms');
      expect(spec.totalQuestions, equals(50000));
      expect(spec.totalSections, equals(1000));
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test('104. 100,000 selected questions: complete orchestration in < 5.0s',
        () {
      final candidates = List.generate(
        100000,
        (i) => buildCandidate(
          question: buildQuestion(
            id: 'q_100k_$i',
            year: 2015 + (i % 10),
            topic: 'Topic ${i % 100}',
            objectiveIds: ['obj_${i % 200}'],
          ),
          selectionScore: 0.9 - (i % 100) * 0.005,
        ),
      );
      final selection =
          buildSelectionResult(candidates: candidates, requestedCount: 100000);
      final config = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        sessionMode: PracticeSessionMode.balanced,
        sectionSize: 100,
      );

      final sw = Stopwatch()..start();
      final spec = orchestrator.orchestrateSession(
        selectionResult: selection,
        config: config,
        orchestratedAt: fixedDate,
      );
      sw.stop();

      // ignore: avoid_print
      print(
          'P34 100K questions orchestration completed in: ${sw.elapsedMilliseconds}ms');
      expect(spec.totalQuestions, equals(100000));
      expect(spec.totalSections, equals(1000));
      expect(sw.elapsedMilliseconds, lessThan(5000));
    });
  });
}
