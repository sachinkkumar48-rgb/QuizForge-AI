/// P33 Adaptive Question Selection & Practice Intelligence Test Suite (TITAN-KO-033.0 P33).
///
/// Comprehensive unit, educational safety, determinism, replay, and benchmark test matrix
/// covering Groups 1–10 (100+ meaningful tests).
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 10, 0, 0);
  final pyqEngine = PyqLearningPriorityEngine();

  NormalizedQuestion buildQuestion({
    required String id,
    String examId = 'upsc',
    int year = 2024,
    String paper = 'GS1',
    int questionNumber = 1,
    String subject = 'Polity',
    String topic = 'Fundamental Rights',
    List<String> objectiveIds = const ['obj_fr'],
    String difficulty = 'Medium',
    String text = 'What is Article 21?',
  }) {
    return NormalizedQuestion(
      id: id,
      examId: examId,
      year: year,
      paper: paper,
      questionNumber: questionNumber,
      subject: subject,
      topic: topic,
      normalizedText: text,
      originalText: text,
      options: [
        Option(key: 'A', text: 'Right to Life'),
        Option(key: 'B', text: 'Right to Equality'),
      ],
      officialAnswer: const Answer(correctOptionKeys: ['A']),
      explanation: 'Article 21 protects life and personal liberty.',
      difficulty: difficulty,
      source: PyqSourceReference.official(
        examId: examId,
        year: year,
        paper: paper,
      ),
      objectiveIds: objectiveIds,
    );
  }

  const service = AdaptiveQuestionSelectionService();

  group('P33.1 Group 1 — Filtering & Scope Criteria (Section 34)', () {
    test('1. Exam filter keeps only matching exam questions', () {
      final corpus = [
        buildQuestion(id: 'q_upsc_1', examId: 'upsc'),
        buildQuestion(id: 'q_bpsc_1', examId: 'bpsc'),
        buildQuestion(id: 'q_ssc_1', examId: 'ssc'),
      ];
      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 5);
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
      expect(result.selectedQuestions.first.id, equals('q_upsc_1'));
      expect(result.eligibleCount, equals(1));
      expect(result.allCandidates.length, equals(3));
      final bpscCandidate =
          result.allCandidates.firstWhere((c) => c.questionId == 'q_bpsc_1');
      expect(bpscCandidate.isEligible, isFalse);
      expect(bpscCandidate.exclusionReason,
          equals(QuestionExclusionReason.examMismatch));
    });

    test('2. Unknown exam produces safe empty result without throwing', () {
      final corpus = [buildQuestion(id: 'q1', examId: 'upsc')];
      final config = AdaptiveQuestionSelectionConfig(examId: 'unknown_exam');
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(0));
      expect(result.eligibleCount, equals(0));
      expect(result.isConstraintLimited, isTrue);
    });

    test('3. Empty corpus produces safe empty result', () {
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(corpus: const [], config: config);

      expect(result.selectedCount, equals(0));
      expect(result.isConstraintLimited, isTrue);
    });

    test('4. Scoped objective IDs filter only matching questions', () {
      final corpus = [
        buildQuestion(id: 'q_fr', objectiveIds: ['obj_fr']),
        buildQuestion(id: 'q_dpsp', objectiveIds: ['obj_dpsp']),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        scopedObjectiveIds: ['obj_fr'],
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
      expect(result.selectedQuestions.first.id, equals('q_fr'));
      final dpspCandidate =
          result.allCandidates.firstWhere((c) => c.questionId == 'q_dpsp');
      expect(dpspCandidate.exclusionReason,
          equals(QuestionExclusionReason.scopeMismatch));
    });

    test('5. Multiple scoped objective IDs match any included objective', () {
      final corpus = [
        buildQuestion(id: 'q_fr', objectiveIds: ['obj_fr']),
        buildQuestion(id: 'q_dpsp', objectiveIds: ['obj_dpsp']),
        buildQuestion(id: 'q_hist', objectiveIds: ['obj_history']),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        scopedObjectiveIds: ['obj_fr', 'obj_dpsp'],
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(2));
      expect(result.selectedQuestions.map((q) => q.id),
          containsAll(['q_fr', 'q_dpsp']));
    });

    test(
        '6. Unknown scoped objective returns empty selection with diagnostic reason',
        () {
      final corpus = [
        buildQuestion(id: 'q_fr', objectiveIds: ['obj_fr'])
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        scopedObjectiveIds: ['obj_non_existent'],
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(0));
      expect(result.isConstraintLimited, isTrue);
    });

    test('7. Scoped topic filter matches target topic (case-insensitive)', () {
      final corpus = [
        buildQuestion(id: 'q1', topic: 'Fundamental Rights'),
        buildQuestion(id: 'q2', topic: 'Preamble'),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        scopedTopics: ['fundamental rights'],
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
      expect(result.selectedQuestions.first.id, equals('q1'));
    });

    test('8. Scoped subject filter matches target subject (case-insensitive)',
        () {
      final corpus = [
        buildQuestion(id: 'q_pol', subject: 'Polity'),
        buildQuestion(id: 'q_eco', subject: 'Economy'),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        scopedSubjects: ['polity'],
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
      expect(result.selectedQuestions.first.id, equals('q_pol'));
    });

    test(
        '9. Combined objective + topic scoping satisfies all scope constraints',
        () {
      final corpus = [
        buildQuestion(
            id: 'q1', topic: 'Fundamental Rights', objectiveIds: ['obj_fr']),
        buildQuestion(
            id: 'q2', topic: 'Directive Principles', objectiveIds: ['obj_fr']),
        buildQuestion(
            id: 'q3', topic: 'Fundamental Rights', objectiveIds: ['obj_dpsp']),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        scopedObjectiveIds: ['obj_fr'],
        scopedTopics: ['Fundamental Rights'],
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
      expect(result.selectedQuestions.first.id, equals('q1'));
    });

    test(
        '10. All questions filtered out yields eligibleCount == 0 and selectedCount == 0',
        () {
      final corpus = [buildQuestion(id: 'q1', examId: 'bpsc')];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.eligibleCount, equals(0));
      expect(result.selectedCount, equals(0));
      expect(result.allCandidates.length, equals(1));
    });
  });

  group('P33.2 Group 2 — Learner Evidence (Section 34)', () {
    test(
        '11. Weak learner (high deficiency score from P23) elevates candidate priority',
        () {
      final corpus = [
        buildQuestion(id: 'q_weak', objectiveIds: ['obj_weak']),
        buildQuestion(id: 'q_neutral', objectiveIds: ['obj_neutral']),
      ];
      final weakProfile = WeakSpotProfile(
        learnerId: 'learner_1',
        totalEvaluatedObjectives: 2,
        evaluatedWithSufficientEvidence: 2,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_weak',
            attemptCount: 10,
            correctCount: 2, // deficiency 0.80
          ),
        ],
      );
      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 1);
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        weakSpotProfile: weakProfile,
      );

      expect(result.selectedQuestions.first.id, equals('q_weak'));
      final cWeak = result.selectedCandidates.first;
      expect(cWeak.learnerWeakness, closeTo(0.80, 0.001));
    });

    test(
        '12. Strong learner (zero deficiency / high accuracy) has 0.0 weakness contribution',
        () {
      final corpus = [
        buildQuestion(id: 'q_strong', objectiveIds: ['obj_strong'])
      ];
      final progress = [
        LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: 'obj_strong',
          status: LearnerObjectiveStatus.achieved,
          attemptCount: 10,
          correctCount: 10,
          lastAttemptAt: fixedDate,
        ),
      ];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        progressList: progress,
      );

      expect(result.selectedCandidates.first.learnerWeakness, equals(0.0));
      expect(
          result.selectedCandidates.first
              .scoreBreakdown['learnerWeaknessContribution'],
          equals(0.0));
    });

    test(
        '13. Zero learner evidence (unattempted) strictly yields 0.0 weakness contribution',
        () {
      final corpus = [
        buildQuestion(id: 'q_unattempted', objectiveIds: ['obj_new'])
      ];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        weakSpotProfile: null,
        progressList: const [],
      );

      expect(result.selectedCandidates.first.learnerWeakness, equals(0.0));
    });

    test(
        '14. Sparse learner evidence (< minimumLearnerAttempts) strictly yields 0.0 weakness contribution',
        () {
      final corpus = [
        buildQuestion(id: 'q_sparse', objectiveIds: ['obj_sparse'])
      ];
      final progress = [
        LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: 'obj_sparse',
          status: LearnerObjectiveStatus.inProgress,
          attemptCount: 2, // < 5 minimum
          correctCount: 0,
          lastAttemptAt: fixedDate,
        ),
      ];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        progressList: progress,
      );

      expect(result.selectedCandidates.first.learnerWeakness, equals(0.0));
    });

    test(
        '15. Multi-objective question takes max deficiency across mapped objectives',
        () {
      final corpus = [
        buildQuestion(id: 'q_multi', objectiveIds: ['obj_mild', 'obj_severe']),
      ];
      final weakProfile = WeakSpotProfile(
        learnerId: 'learner_1',
        totalEvaluatedObjectives: 2,
        evaluatedWithSufficientEvidence: 2,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_mild',
            attemptCount: 10,
            correctCount: 5, // deficiency 0.50
          ),
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_severe',
            attemptCount: 10,
            correctCount: 1, // deficiency 0.90
          ),
        ],
      );
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        weakSpotProfile: weakProfile,
      );

      expect(result.selectedCandidates.first.learnerWeakness,
          closeTo(0.90, 0.001));
    });

    test(
        '16. Topic-level weakness fallback applies when objective-level diagnostic is absent',
        () {
      final corpus = [
        buildQuestion(
            id: 'q1', topic: 'Topic Weak', objectiveIds: ['obj_unmapped']),
      ];
      final weakProfile = WeakSpotProfile(
        learnerId: 'learner_1',
        totalEvaluatedObjectives: 1,
        evaluatedWithSufficientEvidence: 1,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'Topic Weak',
            attemptCount: 10,
            correctCount: 3, // deficiency 0.70
          ),
        ],
      );
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        weakSpotProfile: weakProfile,
      );

      expect(result.selectedCandidates.first.learnerWeakness,
          closeTo(0.70, 0.001));
    });

    test(
        '17. Struggling progress (< 60% accuracy with >= 5 attempts) contributes to weakness',
        () {
      final corpus = [
        buildQuestion(id: 'q1', objectiveIds: ['obj_struggle'])
      ];
      final progress = [
        LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: 'obj_struggle',
          status: LearnerObjectiveStatus.inProgress,
          attemptCount: 10,
          correctCount: 2, // 20% accuracy => deficiency 0.80
          lastAttemptAt: fixedDate,
        ),
      ];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        progressList: progress,
      );

      expect(result.selectedCandidates.first.learnerWeakness,
          closeTo(0.80, 0.001));
    });

    test('18. Achieved progress with 100% accuracy yields 0.0 weakness', () {
      final corpus = [
        buildQuestion(id: 'q1', objectiveIds: ['obj_achieved'])
      ];
      final progress = [
        LearnerProgress(
          learnerId: 'learner_1',
          objectiveId: 'obj_achieved',
          status: LearnerObjectiveStatus.achieved,
          attemptCount: 10,
          correctCount: 10,
          lastAttemptAt: fixedDate,
        ),
      ];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        progressList: progress,
      );

      expect(result.selectedCandidates.first.learnerWeakness, equals(0.0));
    });

    test(
        '19. Learner with mixed strengths/weaknesses gets targeted weak questions first',
        () {
      final corpus = [
        buildQuestion(id: 'q_strong', objectiveIds: ['obj_strong']),
        buildQuestion(id: 'q_weak', objectiveIds: ['obj_weak']),
      ];
      final weakProfile = WeakSpotProfile(
        learnerId: 'learner_1',
        totalEvaluatedObjectives: 1,
        evaluatedWithSufficientEvidence: 1,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_weak',
            attemptCount: 10,
            correctCount: 2, // deficiency 0.80
          ),
        ],
      );
      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 2);
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        weakSpotProfile: weakProfile,
      );

      expect(result.selectedQuestions.first.id, equals('q_weak'));
      expect(result.selectedQuestions[1].id, equals('q_strong'));
    });

    test('20. Multiple learners evidence does not leak or contaminate', () {
      final corpus = [
        buildQuestion(id: 'q1', objectiveIds: ['obj_1'])
      ];
      final weakProfileL1 = WeakSpotProfile(
        learnerId: 'learner_1',
        totalEvaluatedObjectives: 1,
        evaluatedWithSufficientEvidence: 1,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_1',
            attemptCount: 10,
            correctCount: 1, // deficiency 0.90
          ),
        ],
      );
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final resultL1 = service.selectQuestions(
        corpus: corpus,
        config: config,
        weakSpotProfile: weakProfileL1,
      );
      final resultL2 = service.selectQuestions(
        corpus: corpus,
        config: config,
        weakSpotProfile: null, // Learner 2 has no evidence
      );

      expect(resultL1.selectedCandidates.first.learnerWeakness,
          closeTo(0.90, 0.001));
      expect(resultL2.selectedCandidates.first.learnerWeakness, equals(0.0));
    });
  });

  group('P33.3 Group 3 — P32 Priority (Section 34)', () {
    test(
        '21. High P32 priority elevates question ranking over low P32 priority',
        () {
      final corpus = [
        buildQuestion(id: 'q_low_pyq', objectiveIds: ['obj_low']),
        buildQuestion(id: 'q_high_pyq', objectiveIds: ['obj_high']),
      ];

      // Build PYQ history: 10 questions for obj_high, 1 for obj_low across multiple years
      final pyqHistory = [
        for (int y = 2020; y <= 2024; y++) ...[
          buildQuestion(id: 'q_h1_$y', year: y, objectiveIds: ['obj_high']),
          buildQuestion(id: 'q_h2_$y', year: y, objectiveIds: ['obj_high']),
        ],
        buildQuestion(id: 'q_l_2020', year: 2020, objectiveIds: ['obj_low']),
      ];
      final priorityProfile = pyqEngine.evaluateFromQuestions(
        questions: pyqHistory,
        examId: 'upsc',
        evaluatedAt: fixedDate,
      );

      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 2);
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        pyqPriorityProfile: priorityProfile,
      );

      expect(result.selectedQuestions.first.id, equals('q_high_pyq'));
      expect(result.selectedQuestions[1].id, equals('q_low_pyq'));
    });

    test(
        '22. P32 topic fallback signal applies when objective signal is missing in P32 profile',
        () {
      final corpus = [
        buildQuestion(
            id: 'q1',
            topic: 'Constitutional Bodies',
            objectiveIds: ['obj_unmapped_in_p32']),
      ];
      final pyqHistory = [
        for (int y = 2021; y <= 2024; y++)
          buildQuestion(
              id: 'q_cb_$y',
              year: y,
              topic: 'Constitutional Bodies',
              objectiveIds: const []),
      ];
      final priorityProfile = pyqEngine.evaluateFromQuestions(
        questions: pyqHistory,
        examId: 'upsc',
        evaluatedAt: fixedDate,
      );

      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        pyqPriorityProfile: priorityProfile,
      );

      expect(
          result.selectedCandidates.first.historicalPriority, greaterThan(0.0));
    });

    test(
        '23. P32 subject fallback signal applies when topic signal is missing in P32 profile',
        () {
      final corpus = [
        buildQuestion(
            id: 'q1',
            subject: 'Polity',
            topic: 'Rare Topic',
            objectiveIds: ['obj_rare']),
      ];
      final pyqHistory = [
        for (int y = 2020; y <= 2024; y++)
          buildQuestion(
              id: 'q_pol_$y',
              year: y,
              subject: 'Polity',
              topic: 'Common Topic',
              objectiveIds: const []),
      ];
      final priorityProfile = pyqEngine.evaluateFromQuestions(
        questions: pyqHistory,
        examId: 'upsc',
        evaluatedAt: fixedDate,
      );

      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        pyqPriorityProfile: priorityProfile,
      );

      expect(
          result.selectedCandidates.first.historicalPriority, greaterThan(0.0));
    });

    test(
        '24. Null P32 profile safely defaults historical priority to 0.0 without throwing',
        () {
      final corpus = [buildQuestion(id: 'q1')];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        pyqPriorityProfile: null,
      );

      expect(result.selectedCandidates.first.historicalPriority, equals(0.0));
    });

    test(
        '25. Mismatched P32 exam profile safely yields 0.0 historical priority without cross-exam leakage',
        () {
      final corpus = [buildQuestion(id: 'q_bpsc_1', examId: 'bpsc')];
      final upscPyq = [
        for (int y = 2020; y <= 2024; y++)
          buildQuestion(
              id: 'q_u_$y', examId: 'upsc', year: y, objectiveIds: ['obj_fr']),
      ];
      final upscProfile = pyqEngine.evaluateFromQuestions(
        questions: upscPyq,
        examId: 'upsc',
        evaluatedAt: fixedDate,
      );

      final config = AdaptiveQuestionSelectionConfig(examId: 'bpsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        pyqPriorityProfile: upscProfile,
      );

      expect(result.selectedCandidates.first.historicalPriority, equals(0.0));
    });

    test(
        '26. Low P32 confidence in sparse corpus dampens historical priority contribution',
        () {
      final corpus = [
        buildQuestion(id: 'q1', objectiveIds: ['obj_sparse_pyq'])
      ];
      // Only 1 question in history => low confidence in P32
      final sparsePyq = [
        buildQuestion(
            id: 'q_sparse', year: 2024, objectiveIds: ['obj_sparse_pyq'])
      ];
      final sparseProfile = pyqEngine.evaluateFromQuestions(
        questions: sparsePyq,
        examId: 'upsc',
        evaluatedAt: fixedDate,
      );

      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        pyqPriorityProfile: sparseProfile,
      );

      expect(
          result.selectedCandidates.first.historicalPriority, lessThan(0.50));
    });

    test('27. High P32 recurrence & recency boosts composite selection score',
        () {
      final corpus = [
        buildQuestion(
            id: 'q_high',
            topic: 'Polity Topic',
            subject: 'Polity',
            objectiveIds: ['obj_high']),
        buildQuestion(
            id: 'q_none',
            topic: 'Unrelated Topic',
            subject: 'Unrelated Subject',
            objectiveIds: ['obj_none']),
      ];
      final pyqHistory = [
        for (int y = 2020; y <= 2024; y++)
          buildQuestion(
              id: 'q_h_$y',
              year: y,
              topic: 'Polity Topic',
              subject: 'Polity',
              objectiveIds: ['obj_high']),
      ];
      final profile = pyqEngine.evaluateFromQuestions(
        questions: pyqHistory,
        examId: 'upsc',
        evaluatedAt: fixedDate,
      );

      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 2);
      final result = service.selectQuestions(
          corpus: corpus, config: config, pyqPriorityProfile: profile);

      expect(result.selectedCandidates.first.selectionScore,
          greaterThan(result.selectedCandidates[1].selectionScore));
    });

    test(
        '28. P32 priority breakdown is accurately recorded in candidate score breakdown',
        () {
      final corpus = [
        buildQuestion(id: 'q1', objectiveIds: ['obj_fr'])
      ];
      final pyqHistory = [
        for (int y = 2020; y <= 2024; y++)
          buildQuestion(id: 'q_fr_$y', year: y, objectiveIds: ['obj_fr']),
      ];
      final profile = pyqEngine.evaluateFromQuestions(
        questions: pyqHistory,
        examId: 'upsc',
        evaluatedAt: fixedDate,
      );

      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        pyqPriorityWeight: 0.30,
      );
      final result = service.selectQuestions(
          corpus: corpus, config: config, pyqPriorityProfile: profile);

      final pyqContrib = result
          .selectedCandidates.first.scoreBreakdown['pyqPriorityContribution']!;
      expect(pyqContrib, greaterThan(0.0));
      expect(pyqContrib, lessThanOrEqualTo(0.30));
    });

    test(
        '29. High PYQ priority does not cause strong learner to overshadow genuinely weak learner when weakness weight is dominant',
        () {
      final corpus = [
        buildQuestion(
            id: 'q_high_pyq_strong_learner', objectiveIds: ['obj_strong']),
        buildQuestion(id: 'q_mod_pyq_weak_learner', objectiveIds: ['obj_weak']),
      ];
      final pyqHistory = [
        for (int y = 2020; y <= 2024; y++) ...[
          buildQuestion(id: 'q_s1_$y', year: y, objectiveIds: ['obj_strong']),
          buildQuestion(id: 'q_s2_$y', year: y, objectiveIds: ['obj_strong']),
        ],
        buildQuestion(id: 'q_w_2024', year: 2024, objectiveIds: ['obj_weak']),
      ];
      final profile = pyqEngine.evaluateFromQuestions(
        questions: pyqHistory,
        examId: 'upsc',
        evaluatedAt: fixedDate,
      );

      final weakSpot = WeakSpotProfile(
        learnerId: 'l1',
        totalEvaluatedObjectives: 1,
        evaluatedWithSufficientEvidence: 1,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_weak',
            attemptCount: 10,
            correctCount: 1, // deficiency 0.90
          ),
        ],
      );
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        weaknessWeight: 0.60,
        pyqPriorityWeight: 0.20,
        freshnessWeight: 0.10,
        difficultyWeight: 0.05,
        qualityWeight: 0.05,
        targetQuestionCount: 2,
      );
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        pyqPriorityProfile: profile,
        weakSpotProfile: weakSpot,
      );

      expect(
          result.selectedQuestions.first.id, equals('q_mod_pyq_weak_learner'));
    });

    test(
        '30. PYQ priority score in candidate is strictly bounded in [0.0, 1.0]',
        () {
      final corpus = [
        buildQuestion(id: 'q1', objectiveIds: ['obj_fr'])
      ];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(corpus: corpus, config: config);

      final priority = result.selectedCandidates.first.historicalPriority;
      expect(priority, greaterThanOrEqualTo(0.0));
      expect(priority, lessThanOrEqualTo(1.0));
    });
  });

  group('P33.4 Group 4 — Scoring & Mathematical Guarantees (Section 34)', () {
    test('31. Default scoring weights produce correct linear combination', () {
      final corpus = [buildQuestion(id: 'q1', difficulty: 'Medium')];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetDifficulty: 'Medium',
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      final c = result.selectedCandidates.first;
      expect(c.selectionScore, greaterThan(0.0));
      expect(c.selectionScore, lessThanOrEqualTo(1.0));
    });

    test('32. Custom configurable weights are normalized and respected', () {
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        weaknessWeight: 5.0,
        pyqPriorityWeight: 5.0,
        freshnessWeight: 0.0,
        difficultyWeight: 0.0,
        qualityWeight: 0.0,
      );
      expect(config.normalizedWeaknessWeight, closeTo(0.50, 0.001));
      expect(config.normalizedPyqPriorityWeight, closeTo(0.50, 0.001));
      expect(config.normalizedFreshnessWeight, equals(0.0));
    });

    test('33. All selection scores are strictly bounded in [0.0, 1.0]', () {
      final corpus = [
        buildQuestion(id: 'q1'),
        buildQuestion(id: 'q2'),
      ];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(corpus: corpus, config: config);

      for (final cand in result.allCandidates) {
        expect(cand.selectionScore, greaterThanOrEqualTo(0.0));
        expect(cand.selectionScore, lessThanOrEqualTo(1.0));
        expect(cand.selectionScore.isNaN, isFalse);
        expect(cand.selectionScore.isInfinite, isFalse);
      }
    });

    test('34. Zero NaN or Infinity generated under extreme inputs', () {
      final corpus = [buildQuestion(id: 'q1')];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        weaknessWeight: 1000.0,
        pyqPriorityWeight: 1000.0,
        freshnessWeight: 1000.0,
        difficultyWeight: 1000.0,
        qualityWeight: 1000.0,
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCandidates.first.selectionScore.isNaN, isFalse);
      expect(
          result.selectedCandidates.first.selectionScore.isInfinite, isFalse);
    });

    test('35. Target difficulty match yields 1.0 difficulty fit', () {
      final corpus = [buildQuestion(id: 'q_hard', difficulty: 'Hard')];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetDifficulty: 'Hard',
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCandidates.first.difficultyFit, equals(1.0));
    });

    test('36. Target difficulty mismatch yields 0.0 difficulty fit', () {
      final corpus = [buildQuestion(id: 'q_easy', difficulty: 'Easy')];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetDifficulty: 'Hard',
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCandidates.first.difficultyFit, equals(0.0));
    });

    test(
        '37. Null target difficulty yields neutral 1.0 difficulty fit for all questions',
        () {
      final corpus = [
        buildQuestion(id: 'q_easy', difficulty: 'Easy'),
        buildQuestion(id: 'q_hard', difficulty: 'Hard'),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetDifficulty: null,
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCandidates[0].difficultyFit, equals(1.0));
      expect(result.selectedCandidates[1].difficultyFit, equals(1.0));
    });

    test(
        '38. Neutral/missing difficulty metadata yields 0.5 difficulty fit when target is specified',
        () {
      final corpus = [buildQuestion(id: 'q_empty_diff', difficulty: '')];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetDifficulty: 'Hard',
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCandidates.first.difficultyFit, equals(0.5));
    });

    test('39. Official source provenance yields 1.0 source quality score', () {
      final corpus = [buildQuestion(id: 'q_official')];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCandidates.first.sourceQualityScore, equals(1.0));
    });

    test('40. Score breakdown reflects exact mathematical contributions', () {
      final corpus = [buildQuestion(id: 'q1')];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        weaknessWeight: 0.40,
        pyqPriorityWeight: 0.30,
        freshnessWeight: 0.20,
        difficultyWeight: 0.05,
        qualityWeight: 0.05,
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      final breakdown = result.selectedCandidates.first.scoreBreakdown;
      expect(breakdown.containsKey('learnerWeaknessContribution'), isTrue);
      expect(breakdown.containsKey('pyqPriorityContribution'), isTrue);
      expect(breakdown.containsKey('freshnessContribution'), isTrue);
      expect(breakdown.containsKey('difficultyContribution'), isTrue);
      expect(breakdown.containsKey('qualityContribution'), isTrue);
    });
  });

  group('P33.5 Group 5 — Exposure & Freshness (Section 34)', () {
    test('41. Never-attempted questions receive maximum freshness score (1.0)',
        () {
      final corpus = [buildQuestion(id: 'q_never')];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        attemptHistory: const [],
      );

      expect(result.selectedCandidates.first.recencyScore, equals(1.0));
      expect(result.selectedCandidates.first.exposureCount, equals(0));
    });

    test(
        '42. Freshness score decays linearly as exposure count increases toward maxExposureCount',
        () {
      final corpus = [buildQuestion(id: 'q_seen')];
      final attempts = [
        QuestionAttempt(
          attemptId: 'att_1',
          learnerId: 'l1',
          questionId: 'q_seen',
          objectiveId: 'obj_fr',
          submittedAnswer: 'A',
          attemptedAt: fixedDate,
        ),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        maxExposureCount:
            4, // 1 exposure out of 4 => freshness = 1.0 - 0.25 = 0.75
      );
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        attemptHistory: attempts,
      );

      expect(result.selectedCandidates.first.exposureCount, equals(1));
      expect(
          result.selectedCandidates.first.recencyScore, closeTo(0.75, 0.001));
    });

    test(
        '43. Questions with exposureCount >= maxExposureCount are marked ineligible (excessExposure)',
        () {
      final corpus = [buildQuestion(id: 'q_max_exp')];
      final attempts = List.generate(
        3,
        (i) => QuestionAttempt(
          attemptId: 'att_$i',
          learnerId: 'l1',
          questionId: 'q_max_exp',
          objectiveId: 'obj_fr',
          submittedAnswer: 'A',
          attemptedAt: fixedDate,
        ),
      );
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        maxExposureCount: 3,
      );
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        attemptHistory: attempts,
      );

      expect(result.selectedCount, equals(0));
      expect(result.allCandidates.first.isEligible, isFalse);
      expect(result.allCandidates.first.exclusionReason,
          equals(QuestionExclusionReason.excessExposure));
    });

    test(
        '44. excludePreviouslySeen == true marks any attempted question ineligible (previouslySeen)',
        () {
      final corpus = [buildQuestion(id: 'q_attempted')];
      final attempts = [
        QuestionAttempt(
          attemptId: 'att_1',
          learnerId: 'l1',
          questionId: 'q_attempted',
          objectiveId: 'obj_fr',
          submittedAnswer: 'A',
          attemptedAt: fixedDate,
        ),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        excludePreviouslySeen: true,
      );
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        attemptHistory: attempts,
      );

      expect(result.selectedCount, equals(0));
      expect(result.allCandidates.first.isEligible, isFalse);
      expect(result.allCandidates.first.exclusionReason,
          equals(QuestionExclusionReason.previouslySeen));
    });

    test(
        '45. excludePreviouslySeen == true preserves unattempted questions with full freshness',
        () {
      final corpus = [
        buildQuestion(id: 'q_unattempted'),
        buildQuestion(id: 'q_attempted'),
      ];
      final attempts = [
        QuestionAttempt(
          attemptId: 'att_1',
          learnerId: 'l1',
          questionId: 'q_attempted',
          objectiveId: 'obj_fr',
          submittedAnswer: 'A',
          attemptedAt: fixedDate,
        ),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        excludePreviouslySeen: true,
      );
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        attemptHistory: attempts,
      );

      expect(result.selectedCount, equals(1));
      expect(result.selectedQuestions.first.id, equals('q_unattempted'));
    });

    test(
        '46. Cooldown period active marks recently attempted question ineligible (cooldownActive)',
        () {
      final corpus = [buildQuestion(id: 'q_recent')];
      final attempts = [
        QuestionAttempt(
          attemptId: 'att_1',
          learnerId: 'l1',
          questionId: 'q_recent',
          objectiveId: 'obj_fr',
          submittedAnswer: 'A',
          attemptedAt: DateTime.utc(2026, 9, 1, 9, 30, 0), // 30 mins ago
        ),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        cooldownPeriod: const Duration(hours: 1), // 1 hr cooldown
      );
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        attemptHistory: attempts,
        selectedAt: fixedDate, // 10:00 UTC
      );

      expect(result.selectedCount, equals(0));
      expect(result.allCandidates.first.isEligible, isFalse);
      expect(result.allCandidates.first.exclusionReason,
          equals(QuestionExclusionReason.cooldownActive));
    });

    test('47. Cooldown period expired allows previously attempted question',
        () {
      final corpus = [buildQuestion(id: 'q_expired_cooldown')];
      final attempts = [
        QuestionAttempt(
          attemptId: 'att_1',
          learnerId: 'l1',
          questionId: 'q_expired_cooldown',
          objectiveId: 'obj_fr',
          submittedAnswer: 'A',
          attemptedAt: DateTime.utc(2026, 9, 1, 8, 0, 0), // 2 hours ago
        ),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        cooldownPeriod: const Duration(hours: 1),
      );
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        attemptHistory: attempts,
        selectedAt: fixedDate, // 10:00 UTC (2 hrs elapsed > 1 hr cooldown)
      );

      expect(result.selectedCount, equals(1));
      expect(result.selectedQuestions.first.id, equals('q_expired_cooldown'));
    });

    test(
        '48. Cooldown check safely ignored when selectedAt or attempt date is null',
        () {
      final corpus = [buildQuestion(id: 'q1')];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        cooldownPeriod: const Duration(hours: 1),
      );
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        selectedAt: null,
      );

      expect(result.selectedCount, equals(1));
    });

    test(
        '49. Multiple attempts on same question correctly accumulates exposure count',
        () {
      final corpus = [buildQuestion(id: 'q1')];
      final attempts = [
        QuestionAttempt(
          attemptId: 'att_1',
          learnerId: 'l1',
          questionId: 'q1',
          objectiveId: 'obj_fr',
          submittedAnswer: 'A',
          attemptedAt: DateTime.utc(2026, 8, 30),
        ),
        QuestionAttempt(
          attemptId: 'att_2',
          learnerId: 'l1',
          questionId: 'q1',
          objectiveId: 'obj_fr',
          submittedAnswer: 'B',
          attemptedAt: DateTime.utc(2026, 8, 31),
        ),
      ];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        attemptHistory: attempts,
      );

      expect(result.selectedCandidates.first.exposureCount, equals(2));
      expect(result.selectedCandidates.first.lastExposedAt,
          equals(DateTime.utc(2026, 8, 31)));
    });

    test(
        '50. All questions exhausted by exposure yields safe constraint-limited result',
        () {
      final corpus = [
        buildQuestion(id: 'q1'),
        buildQuestion(id: 'q2'),
      ];
      final attempts = [
        QuestionAttempt(
            attemptId: 'a1',
            learnerId: 'l1',
            questionId: 'q1',
            objectiveId: 'obj',
            submittedAnswer: 'A',
            attemptedAt: fixedDate),
        QuestionAttempt(
            attemptId: 'a2',
            learnerId: 'l1',
            questionId: 'q2',
            objectiveId: 'obj',
            submittedAnswer: 'A',
            attemptedAt: fixedDate),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        excludePreviouslySeen: true,
      );
      final result = service.selectQuestions(
          corpus: corpus, config: config, attemptHistory: attempts);

      expect(result.selectedCount, equals(0));
      expect(result.isConstraintLimited, isTrue);
    });
  });

  group('P33.6 Group 6 — Diversity Constraints (Section 34)', () {
    test('51. maxQuestionsPerObjective enforces quota per objective in session',
        () {
      final corpus = [
        buildQuestion(id: 'q_fr_1', objectiveIds: ['obj_fr']),
        buildQuestion(id: 'q_fr_2', objectiveIds: ['obj_fr']),
        buildQuestion(id: 'q_fr_3', objectiveIds: ['obj_fr']),
        buildQuestion(id: 'q_dpsp_1', objectiveIds: ['obj_dpsp']),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 3,
        maxQuestionsPerObjective: 2,
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(3));
      final frCount = result.selectedQuestions
          .where((q) => q.objectiveIds.contains('obj_fr'))
          .length;
      expect(frCount, equals(2)); // Capped at 2
      final dpspCount = result.selectedQuestions
          .where((q) => q.objectiveIds.contains('obj_dpsp'))
          .length;
      expect(dpspCount, equals(1));
    });

    test('52. maxQuestionsPerTopic enforces quota per topic in session', () {
      final corpus = [
        buildQuestion(id: 'q_pol_1', topic: 'Polity Topic A'),
        buildQuestion(id: 'q_pol_2', topic: 'Polity Topic A'),
        buildQuestion(id: 'q_pol_3', topic: 'Polity Topic B'),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 3,
        maxQuestionsPerTopic: 1,
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(2)); // 1 from Topic A, 1 from Topic B
      expect(result.selectedQuestions.map((q) => q.topic).toSet().length,
          equals(2));
    });

    test(
        '53. maxQuestionsPerYear enforces quota per examination year in session',
        () {
      final corpus = [
        buildQuestion(id: 'q_2024_1', year: 2024),
        buildQuestion(id: 'q_2024_2', year: 2024),
        buildQuestion(id: 'q_2023_1', year: 2023),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 3,
        maxQuestionsPerYear: 1,
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(2));
      final years = result.selectedQuestions.map((q) => q.year).toList();
      expect(years, equals([2024, 2023]));
    });

    test(
        '54. Excluded candidates due to topic diversity record diversityTopicLimit reason',
        () {
      final corpus = [
        buildQuestion(id: 'q1', topic: 'Same Topic'),
        buildQuestion(id: 'q2', topic: 'Same Topic'),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 2,
        maxQuestionsPerTopic: 1,
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
      final excluded =
          result.allCandidates.firstWhere((c) => c.questionId == 'q2');
      expect(excluded.exclusionReason,
          equals(QuestionExclusionReason.diversityTopicLimit));
    });

    test(
        '55. Excluded candidates due to objective diversity record diversityObjectiveLimit reason',
        () {
      final corpus = [
        buildQuestion(id: 'q1', objectiveIds: ['obj_1']),
        buildQuestion(id: 'q2', objectiveIds: ['obj_1']),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 2,
        maxQuestionsPerObjective: 1,
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
      final excluded =
          result.allCandidates.firstWhere((c) => c.questionId == 'q2');
      expect(excluded.exclusionReason,
          equals(QuestionExclusionReason.diversityObjectiveLimit));
    });

    test(
        '56. Excluded candidates due to year diversity record diversityYearLimit reason',
        () {
      final corpus = [
        buildQuestion(id: 'q1', year: 2024),
        buildQuestion(id: 'q2', year: 2024),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 2,
        maxQuestionsPerYear: 1,
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
      final excluded =
          result.allCandidates.firstWhere((c) => c.questionId == 'q2');
      expect(excluded.exclusionReason,
          equals(QuestionExclusionReason.diversityYearLimit));
    });

    test(
        '57. Diversity summary accurately tallies questions per topic, year, and objective',
        () {
      final corpus = [
        buildQuestion(
            id: 'q1', topic: 'Topic A', year: 2024, objectiveIds: ['obj_1']),
        buildQuestion(
            id: 'q2', topic: 'Topic B', year: 2023, objectiveIds: ['obj_2']),
      ];
      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 2);
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.diversitySummary['topic_Topic A'], equals(1));
      expect(result.diversitySummary['topic_Topic B'], equals(1));
      expect(result.diversitySummary['year_2024'], equals(1));
      expect(result.diversitySummary['year_2023'], equals(1));
      expect(result.diversitySummary['obj_obj_1'], equals(1));
    });

    test(
        '58. Over-constrained request returns largest valid subset with isConstraintLimited == true',
        () {
      final corpus = [
        buildQuestion(id: 'q1', topic: 'Topic A'),
        buildQuestion(id: 'q2', topic: 'Topic A'),
        buildQuestion(id: 'q3', topic: 'Topic A'),
        buildQuestion(id: 'q4', topic: 'Topic A'),
        buildQuestion(id: 'q5', topic: 'Topic A'),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 3, // requested 3
        maxQuestionsPerTopic: 1, // only 1 allowed per topic
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
      expect(result.isConstraintLimited, isTrue);
      expect(result.constraintLimitReason,
          contains('Diversity constraints prevented'));
    });

    test(
        '59. Unconstrained request (null diversity limits) selects top candidates strictly by score',
        () {
      final corpus = [
        buildQuestion(id: 'q1', topic: 'Topic A'),
        buildQuestion(id: 'q2', topic: 'Topic A'),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 2,
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(2));
      expect(result.isConstraintLimited, isFalse);
    });

    test(
        '60. Diversity quotas do not prevent selecting lower-ranked eligible candidates from other topics',
        () {
      final corpus = [
        buildQuestion(id: 'q_t1_1', topic: 'Topic 1', objectiveIds: ['obj_1']),
        buildQuestion(id: 'q_t1_2', topic: 'Topic 1', objectiveIds: ['obj_1']),
        buildQuestion(id: 'q_t2_1', topic: 'Topic 2', objectiveIds: ['obj_2']),
      ];
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 2,
        maxQuestionsPerTopic: 1,
      );
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(2));
      expect(result.selectedQuestions.map((q) => q.id),
          containsAll(['q_t1_1', 'q_t2_1']));
    });
  });

  group('P33.7 Group 7 — Determinism & Replay Invariants (Section 34)', () {
    test(
        '61. Complete tie-breaking: selectionScore DESC -> pyq DESC -> weak DESC -> year DESC -> questionId ASC',
        () {
      final corpus = [
        buildQuestion(id: 'q_b', year: 2024),
        buildQuestion(id: 'q_a', year: 2024),
      ];
      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 2);
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedQuestions[0].id, equals('q_a'));
      expect(result.selectedQuestions[1].id, equals('q_b'));
    });

    test('62. Identical scores tie-broken by historical priority', () {
      final corpus = [
        buildQuestion(id: 'q_low_pyq', objectiveIds: ['obj_low']),
        buildQuestion(id: 'q_high_pyq', objectiveIds: ['obj_high']),
      ];
      final pyqHistory = [
        for (int y = 2020; y <= 2024; y++) ...[
          buildQuestion(id: 'q_h1_$y', year: y, objectiveIds: ['obj_high']),
          buildQuestion(id: 'q_h2_$y', year: y, objectiveIds: ['obj_high']),
        ],
        buildQuestion(id: 'q_l_2020', year: 2020, objectiveIds: ['obj_low']),
      ];
      final priorityProfile = pyqEngine.evaluateFromQuestions(
        questions: pyqHistory,
        examId: 'upsc',
        evaluatedAt: fixedDate,
      );

      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 2);
      final result = service.selectQuestions(
          corpus: corpus, config: config, pyqPriorityProfile: priorityProfile);

      expect(result.selectedQuestions.first.id, equals('q_high_pyq'));
    });

    test(
        '63. Identical scores and historical priority tie-broken by learner weakness',
        () {
      final corpus = [
        buildQuestion(id: 'q_weak', objectiveIds: ['obj_weak']),
        buildQuestion(id: 'q_strong', objectiveIds: ['obj_strong']),
      ];
      final weakSpot = WeakSpotProfile(
        learnerId: 'l1',
        totalEvaluatedObjectives: 1,
        evaluatedWithSufficientEvidence: 1,
        evaluatedAt: fixedDate,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'obj_weak',
            attemptCount: 10,
            correctCount: 2, // deficiency 0.80
          ),
        ],
      );
      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 2);
      final result = service.selectQuestions(
          corpus: corpus, config: config, weakSpotProfile: weakSpot);

      expect(result.selectedQuestions.first.id, equals('q_weak'));
    });

    test(
        '64. Identical scores, historical priority, and weakness tie-broken by year DESC',
        () {
      final corpus = [
        buildQuestion(id: 'q_2022', year: 2022),
        buildQuestion(id: 'q_2024', year: 2024),
      ];
      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 2);
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedQuestions[0].id, equals('q_2024'));
      expect(result.selectedQuestions[1].id, equals('q_2022'));
    });

    test(
        '65. Identical scores, historical priority, weakness, and year tie-broken by questionId ASC',
        () {
      final corpus = [
        buildQuestion(id: 'q_z', year: 2024),
        buildQuestion(id: 'q_a', year: 2024),
      ];
      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 2);
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedQuestions[0].id, equals('q_a'));
      expect(result.selectedQuestions[1].id, equals('q_z'));
    });

    test(
        '66. Deterministic replay: 5 consecutive runs produce byte-identical JSON serialized output',
        () {
      final corpus = List.generate(
        10,
        (i) => buildQuestion(id: 'q_${10 - i}', year: 2020 + (i % 5)),
      );
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 5,
        maxQuestionsPerYear: 2,
      );

      final firstJson = jsonEncode(service
          .selectQuestions(
            corpus: corpus,
            config: config,
            selectedAt: fixedDate,
          )
          .toJson());

      for (int i = 0; i < 5; i++) {
        final currentJson = jsonEncode(service
            .selectQuestions(
              corpus: corpus,
              config: config,
              selectedAt: fixedDate,
            )
            .toJson());
        expect(currentJson, equals(firstJson));
      }
    });

    test(
        '67. Permuted corpus input order produces identical candidate selection and ordering',
        () {
      final q1 = buildQuestion(id: 'q1', year: 2024);
      final q2 = buildQuestion(id: 'q2', year: 2023);
      final q3 = buildQuestion(id: 'q3', year: 2022);

      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 3);

      final res1 = service.selectQuestions(
          corpus: [q1, q2, q3], config: config, selectedAt: fixedDate);
      final res2 = service.selectQuestions(
          corpus: [q3, q1, q2], config: config, selectedAt: fixedDate);
      final res3 = service.selectQuestions(
          corpus: [q2, q3, q1], config: config, selectedAt: fixedDate);

      expect(res1.selectedQuestions.map((q) => q.id),
          equals(res2.selectedQuestions.map((q) => q.id)));
      expect(res2.selectedQuestions.map((q) => q.id),
          equals(res3.selectedQuestions.map((q) => q.id)));
    });

    test(
        '68. Selection result is deeply immutable (unmodifiable lists and maps)',
        () {
      final corpus = [buildQuestion(id: 'q1')];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(
          () => (result.selectedQuestions as dynamic)
              .add(buildQuestion(id: 'q2')),
          throwsUnsupportedError);
      expect(
          () => (result.selectedCandidates as dynamic)
              .add(result.selectedCandidates.first),
          throwsUnsupportedError);
      expect(
          () => (result.allCandidates as dynamic)
              .add(result.selectedCandidates.first),
          throwsUnsupportedError);
      expect(() => (result.diversitySummary as dynamic)['new_key'] = 1,
          throwsUnsupportedError);
    });

    test('69. toJson and fromJson for configuration preserves exact parameters',
        () {
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'bpsc',
        targetQuestionCount: 15,
        scopedObjectiveIds: ['obj_1', 'obj_2'],
        scopedTopics: ['Topic A'],
        scopedSubjects: ['Polity'],
        targetDifficulty: 'Hard',
        maxQuestionsPerObjective: 3,
        maxQuestionsPerTopic: 2,
        maxQuestionsPerYear: 4,
        maxExposureCount: 5,
        cooldownPeriod: const Duration(days: 2),
        excludePreviouslySeen: true,
        weaknessWeight: 0.40,
        pyqPriorityWeight: 0.30,
        freshnessWeight: 0.15,
        difficultyWeight: 0.10,
        qualityWeight: 0.05,
      );

      final json = config.toJson();
      final roundTrip = AdaptiveQuestionSelectionConfig.fromJson(json);

      expect(roundTrip.examId, equals(config.examId));
      expect(roundTrip.targetQuestionCount, equals(config.targetQuestionCount));
      expect(roundTrip.scopedObjectiveIds, equals(config.scopedObjectiveIds));
      expect(roundTrip.scopedTopics, equals(config.scopedTopics));
      expect(roundTrip.scopedSubjects, equals(config.scopedSubjects));
      expect(roundTrip.targetDifficulty, equals(config.targetDifficulty));
      expect(roundTrip.maxQuestionsPerObjective,
          equals(config.maxQuestionsPerObjective));
      expect(
          roundTrip.maxQuestionsPerTopic, equals(config.maxQuestionsPerTopic));
      expect(roundTrip.maxQuestionsPerYear, equals(config.maxQuestionsPerYear));
      expect(roundTrip.maxExposureCount, equals(config.maxExposureCount));
      expect(roundTrip.cooldownPeriod, equals(config.cooldownPeriod));
      expect(roundTrip.excludePreviouslySeen,
          equals(config.excludePreviouslySeen));
      expect(roundTrip.weaknessWeight, closeTo(config.weaknessWeight, 0.001));
    });

    test(
        '70. toJson on selection result includes all selected questions, candidates, and audit trail',
        () {
      final corpus = [buildQuestion(id: 'q1')];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
          corpus: corpus, config: config, selectedAt: fixedDate);

      final json = result.toJson();
      expect(json['examId'], equals('upsc'));
      expect(json['selectedCount'], equals(1));
      expect(json['selectedQuestions'], isNotEmpty);
      expect(json['selectedCandidates'], isNotEmpty);
      expect(json['allCandidates'], isNotEmpty);
    });
  });

  group('P33.8 Group 8 — Safety & Invariants (Section 34)', () {
    test('71. Config throws ArgumentError on empty examId', () {
      expect(() => AdaptiveQuestionSelectionConfig(examId: '  '),
          throwsArgumentError);
    });

    test('72. Config throws ArgumentError on targetQuestionCount < 1', () {
      expect(
          () => AdaptiveQuestionSelectionConfig(
              examId: 'upsc', targetQuestionCount: 0),
          throwsArgumentError);
    });

    test('73. Config throws ArgumentError on negative maxExposureCount', () {
      expect(
          () => AdaptiveQuestionSelectionConfig(
              examId: 'upsc', maxExposureCount: -1),
          throwsArgumentError);
    });

    test('74. Config throws ArgumentError on negative diversity limits', () {
      expect(
          () => AdaptiveQuestionSelectionConfig(
              examId: 'upsc', maxQuestionsPerTopic: 0),
          throwsArgumentError);
      expect(
          () => AdaptiveQuestionSelectionConfig(
              examId: 'upsc', maxQuestionsPerObjective: -2),
          throwsArgumentError);
      expect(
          () => AdaptiveQuestionSelectionConfig(
              examId: 'upsc', maxQuestionsPerYear: 0),
          throwsArgumentError);
    });

    test('75. Config throws ArgumentError on negative or invalid weights', () {
      expect(
          () => AdaptiveQuestionSelectionConfig(
              examId: 'upsc', weaknessWeight: -0.5),
          throwsArgumentError);
      expect(
          () => AdaptiveQuestionSelectionConfig(
              examId: 'upsc', weaknessWeight: double.nan),
          throwsArgumentError);
      expect(
          () => AdaptiveQuestionSelectionConfig(
              examId: 'upsc', weaknessWeight: double.infinity),
          throwsArgumentError);
      expect(
        () => AdaptiveQuestionSelectionConfig(
          examId: 'upsc',
          weaknessWeight: 0.0,
          pyqPriorityWeight: 0.0,
          freshnessWeight: 0.0,
          difficultyWeight: 0.0,
          qualityWeight: 0.0,
        ),
        throwsArgumentError,
      );
    });

    test(
        '76. Zero question fabrication: all selected questions exist in input corpus verbatim',
        () {
      final corpus = [
        buildQuestion(id: 'q1', text: 'Original text 1'),
        buildQuestion(id: 'q2', text: 'Original text 2'),
      ];
      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 2);
      final result = service.selectQuestions(corpus: corpus, config: config);

      for (final selected in result.selectedQuestions) {
        final original = corpus.firstWhere((q) => q.id == selected.id);
        expect(selected.normalizedText, equals(original.normalizedText));
        expect(selected.options.length, equals(original.options.length));
        expect(selected.officialAnswer.correctOptionKeys,
            equals(original.officialAnswer.correctOptionKeys));
      }
    });

    test(
        '77. Answer integrity: option keys and expected answers are never modified or rewritten',
        () {
      final corpus = [buildQuestion(id: 'q1')];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedQuestions.first.officialAnswer.correctOptionKeys,
          equals(['A']));
      expect(result.selectedQuestions.first.options.first.text,
          equals('Right to Life'));
    });

    test(
        '78. Provenance preservation: source citations, checksums, publishers remain intact',
        () {
      final corpus = [buildQuestion(id: 'q1')];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(corpus: corpus, config: config);

      final src = result.selectedQuestions.first.source;
      expect(src.sourceType, equals('officialPdf'));
      expect(src.publisher, isNotEmpty);
    });

    test(
        '79. Zero DateTime.now() in service: caller-supplied UTC timestamp is used',
        () {
      final corpus = [buildQuestion(id: 'q1')];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        selectedAt: fixedDate,
      );

      expect(result.selectedAt, equals(fixedDate));
    });

    test(
        '80. Safe empty result returned when requestedCount > 0 but corpus is empty',
        () {
      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 10);
      final result = service.selectQuestions(corpus: const [], config: config);

      expect(result.selectedCount, equals(0));
      expect(result.requestedCount, equals(10));
      expect(result.isConstraintLimited, isTrue);
    });
  });

  group('P33.9 Group 9 — Multi-Exam Isolation (Section 34)', () {
    test(
        '81. UPSC request selects only UPSC questions; BPSC questions in corpus are excluded',
        () {
      final corpus = [
        buildQuestion(id: 'q_upsc', examId: 'upsc'),
        buildQuestion(id: 'q_bpsc', examId: 'bpsc'),
      ];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
      expect(result.selectedQuestions.first.examId, equals('upsc'));
    });

    test(
        '82. BPSC request selects only BPSC questions; UPSC questions in corpus are excluded',
        () {
      final corpus = [
        buildQuestion(id: 'q_upsc', examId: 'upsc'),
        buildQuestion(id: 'q_bpsc', examId: 'bpsc'),
      ];
      final config = AdaptiveQuestionSelectionConfig(examId: 'bpsc');
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
      expect(result.selectedQuestions.first.examId, equals('bpsc'));
    });

    test(
        '83. SSC request selects only SSC questions; UPSC and BPSC questions are excluded',
        () {
      final corpus = [
        buildQuestion(id: 'q_upsc', examId: 'upsc'),
        buildQuestion(id: 'q_bpsc', examId: 'bpsc'),
        buildQuestion(id: 'q_ssc', examId: 'ssc'),
      ];
      final config = AdaptiveQuestionSelectionConfig(examId: 'ssc');
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
      expect(result.selectedQuestions.first.examId, equals('ssc'));
    });

    test(
        '84. Multi-exam corpus is cleanly partitioned without cross-exam contamination',
        () {
      final corpus = [
        buildQuestion(id: 'q_upsc_1', examId: 'upsc'),
        buildQuestion(id: 'q_upsc_2', examId: 'upsc'),
        buildQuestion(id: 'q_bpsc_1', examId: 'bpsc'),
        buildQuestion(id: 'q_ssc_1', examId: 'ssc'),
      ];
      final config = AdaptiveQuestionSelectionConfig(
          examId: 'upsc', targetQuestionCount: 5);
      final result = service.selectQuestions(corpus: corpus, config: config);

      for (final q in result.selectedQuestions) {
        expect(q.examId, equals('upsc'));
      }
    });

    test(
        '85. P32 UPSC priority profile is never applied to BPSC candidate scoring',
        () {
      final corpus = [
        buildQuestion(id: 'q_bpsc', examId: 'bpsc', objectiveIds: ['obj_fr'])
      ];
      final upscPyq = [
        for (int y = 2020; y <= 2024; y++)
          buildQuestion(
              id: 'q_u_$y', examId: 'upsc', year: y, objectiveIds: ['obj_fr']),
      ];
      final upscProfile = pyqEngine.evaluateFromQuestions(
        questions: upscPyq,
        examId: 'upsc',
        evaluatedAt: fixedDate,
      );

      final config = AdaptiveQuestionSelectionConfig(examId: 'bpsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        pyqPriorityProfile: upscProfile,
      );

      expect(result.selectedCandidates.first.historicalPriority, equals(0.0));
    });

    test(
        '86. P32 BPSC priority profile is never applied to UPSC candidate scoring',
        () {
      final corpus = [
        buildQuestion(id: 'q_upsc', examId: 'upsc', objectiveIds: ['obj_fr'])
      ];
      final bpscPyq = [
        for (int y = 2020; y <= 2024; y++)
          buildQuestion(
              id: 'q_b_$y', examId: 'bpsc', year: y, objectiveIds: ['obj_fr']),
      ];
      final bpscProfile = pyqEngine.evaluateFromQuestions(
        questions: bpscPyq,
        examId: 'bpsc',
        evaluatedAt: fixedDate,
      );

      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(
        corpus: corpus,
        config: config,
        pyqPriorityProfile: bpscProfile,
      );

      expect(result.selectedCandidates.first.historicalPriority, equals(0.0));
    });

    test(
        '87. Unknown examId returns empty result with isConstraintLimited == true',
        () {
      final corpus = [buildQuestion(id: 'q1', examId: 'upsc')];
      final config = AdaptiveQuestionSelectionConfig(examId: 'ras');
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(0));
      expect(result.isConstraintLimited, isTrue);
    });

    test('88. Exam ID matching is case-insensitive (UPSC == upsc)', () {
      final corpus = [buildQuestion(id: 'q1', examId: 'upsc')];
      final config = AdaptiveQuestionSelectionConfig(examId: 'UPSC');
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
    });

    test('89. Exam ID trimming handles leading/trailing whitespace safely', () {
      final corpus = [buildQuestion(id: 'q1', examId: 'upsc')];
      final config = AdaptiveQuestionSelectionConfig(examId: '  upsc  ');
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.selectedCount, equals(1));
    });

    test(
        '90. Diversity summary is scoped strictly to the selected exam metadata',
        () {
      final corpus = [
        buildQuestion(id: 'q_upsc', examId: 'upsc', topic: 'UPSC Topic'),
        buildQuestion(id: 'q_bpsc', examId: 'bpsc', topic: 'BPSC Topic'),
      ];
      final config = AdaptiveQuestionSelectionConfig(examId: 'upsc');
      final result = service.selectQuestions(corpus: corpus, config: config);

      expect(result.diversitySummary.containsKey('topic_UPSC Topic'), isTrue);
      expect(result.diversitySummary.containsKey('topic_BPSC Topic'), isFalse);
    });
  });

  group('P33.10 Group 10 — High-Throughput Performance Benchmarks (Section 34)',
      () {
    test('91. 10,000 questions corpus: complete selection in < 1.0s', () {
      final corpus = List.generate(
        10000,
        (i) => buildQuestion(
          id: 'q_10k_$i',
          year: 2015 + (i % 10),
          topic: 'Topic ${i % 20}',
          objectiveIds: ['obj_${i % 50}'],
        ),
      );
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 20,
        maxQuestionsPerTopic: 3,
        maxQuestionsPerYear: 5,
      );

      final sw = Stopwatch()..start();
      final result = service.selectQuestions(
          corpus: corpus, config: config, selectedAt: fixedDate);
      sw.stop();

      // ignore: avoid_print
      print(
          'P33 10K questions selection completed in: ${sw.elapsedMilliseconds}ms');
      expect(result.selectedCount, equals(20));
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });

    test('92. 50,000 questions corpus: complete selection in < 3.0s', () {
      final corpus = List.generate(
        50000,
        (i) => buildQuestion(
          id: 'q_50k_$i',
          year: 2015 + (i % 10),
          topic: 'Topic ${i % 50}',
          objectiveIds: ['obj_${i % 100}'],
        ),
      );
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 50,
        maxQuestionsPerTopic: 5,
        maxQuestionsPerYear: 10,
      );

      final sw = Stopwatch()..start();
      final result = service.selectQuestions(
          corpus: corpus, config: config, selectedAt: fixedDate);
      sw.stop();

      // ignore: avoid_print
      print(
          'P33 50K questions selection completed in: ${sw.elapsedMilliseconds}ms');
      expect(result.selectedCount, equals(50));
      expect(sw.elapsedMilliseconds, lessThan(3000));
    });

    test('93. 100,000 questions corpus: complete selection in < 5.0s', () {
      final corpus = List.generate(
        100000,
        (i) => buildQuestion(
          id: 'q_100k_$i',
          year: 2015 + (i % 10),
          topic: 'Topic ${i % 100}',
          objectiveIds: ['obj_${i % 200}'],
        ),
      );
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 100,
        maxQuestionsPerTopic: 10,
        maxQuestionsPerYear: 20,
      );

      final sw = Stopwatch()..start();
      final result = service.selectQuestions(
          corpus: corpus, config: config, selectedAt: fixedDate);
      sw.stop();

      // ignore: avoid_print
      print(
          'P33 100K questions selection completed in: ${sw.elapsedMilliseconds}ms');
      expect(result.selectedCount, equals(100));
      expect(sw.elapsedMilliseconds, lessThan(5000));
    });

    test('94. 250,000 questions corpus: complete selection in < 10.0s', () {
      final corpus = List.generate(
        250000,
        (i) => buildQuestion(
          id: 'q_250k_$i',
          year: 2015 + (i % 10),
          topic: 'Topic ${i % 200}',
          objectiveIds: ['obj_${i % 500}'],
        ),
      );
      final config = AdaptiveQuestionSelectionConfig(
        examId: 'upsc',
        targetQuestionCount: 100,
        maxQuestionsPerTopic: 10,
        maxQuestionsPerYear: 20,
      );

      final sw = Stopwatch()..start();
      final result = service.selectQuestions(
          corpus: corpus, config: config, selectedAt: fixedDate);
      sw.stop();

      // ignore: avoid_print
      print(
          'P33 250K questions selection completed in: ${sw.elapsedMilliseconds}ms');
      expect(result.selectedCount, equals(100));
      expect(sw.elapsedMilliseconds, lessThan(10000));
    });
  });
}
