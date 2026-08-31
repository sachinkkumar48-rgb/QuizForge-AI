/// P33 Adaptive Question Selection & Practice Intelligence Integration Test Suite (TITAN-KO-033.0 P33).
///
/// End-to-end integration verifying the complete pipeline:
/// P30 Acquisition -> P29 Normalization -> P31 Historical Intelligence ->
/// P32 Priority -> P23 Learner State -> P33 Adaptive Question Selection -> P19 Session.
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 12, 0, 0);

  test(
      'P33 Mega Integration: P30 -> P29 -> P31 -> P32 -> P23 -> P33 -> P19 Practice Selection Pipeline',
      () {
    // ========================================================================
    // STAGE 1: P30 Acquisition & P29 Normalization Pipeline
    // Construct multi-exam raw question batches (UPSC, BPSC, SSC).
    // ========================================================================
    final rawBatch = <RawQuestionInput>[];
    int qCounter = 0;

    // 1. BPSC Historical PYQs across 2021-2024
    // - Bihar History & Geography (high historical recurrence, 3 questions/yr)
    // - Modern Indian History (moderate recurrence, 2 questions/yr)
    // - General Science (1 question in 2024 only)
    for (int year = 2021; year <= 2024; year++) {
      for (int i = 0; i < 3; i++) {
        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'Bihar Special',
          topic: 'Bihar History and Geography',
          questionText:
              'Historical development of Champaran movement article ${10 + i * 3} in year $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          objectiveIds: const ['obj_bihar_hist'],
          source: PyqSourceReference.official(
            examId: 'bpsc',
            year: year,
            paper: 'GS1',
          ),
        ));
      }
      for (int i = 0; i < 2; i++) {
        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'History',
          topic: 'Modern Indian History',
          questionText:
              'Constitutional reform movement session ${1885 + i * 10} in year $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'B',
          objectiveIds: const ['obj_modern_hist'],
          source: PyqSourceReference.official(
            examId: 'bpsc',
            year: year,
            paper: 'GS1',
          ),
        ));
      }
      if (year == 2024) {
        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'Science',
          topic: 'General Science',
          questionText: 'Thermodynamics basic entropy principle in year $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'C',
          objectiveIds: const ['obj_science'],
          source: PyqSourceReference.official(
            examId: 'bpsc',
            year: year,
            paper: 'GS1',
          ),
        ));
      }
    }

    // 2. UPSC Historical PYQs (to verify strict cross-exam isolation)
    for (int year = 2022; year <= 2024; year++) {
      qCounter++;
      rawBatch.add(RawQuestionInput(
        examId: 'upsc',
        year: year,
        paper: 'GS1',
        questionNumber: qCounter,
        subject: 'Polity',
        topic: 'Fundamental Rights',
        questionText:
            'UPSC Judicial review doctrine under Article 32 in year $year',
        options: const ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
        objectiveIds: const ['obj_fr'],
        source: PyqSourceReference.official(
          examId: 'upsc',
          year: year,
          paper: 'GS1',
        ),
      ));
    }

    final p29Service = MultiExamPyqIntelligenceService();
    final ingestionResult = p29Service.ingestRawQuestions(rawBatch);
    final normalizedBatch = ingestionResult.uniqueQuestions;

    expect(normalizedBatch.length, equals(rawBatch.length));
    expect(normalizedBatch.where((q) => q.examId == 'bpsc').length,
        equals(21)); // 3*4 + 2*4 + 1 = 21
    expect(normalizedBatch.where((q) => q.examId == 'upsc').length, equals(3));

    // ========================================================================
    // STAGE 2: P31 Historical PYQ Intelligence
    // ========================================================================
    const p31Engine = PyqHistoricalIntelligenceEngine();
    final bpscQuestions =
        normalizedBatch.where((q) => q.examId == 'bpsc').toList();
    final bpscIntelligenceProfile = p31Engine.buildExamProfile(
      bpscQuestions,
      examId: 'bpsc',
      frameworkObjectiveIds: const [
        'obj_bihar_hist',
        'obj_modern_hist',
        'obj_science'
      ],
    );

    expect(bpscIntelligenceProfile.examId, equals('bpsc'));
    expect(bpscIntelligenceProfile.questionCount, equals(21));
    expect(bpscIntelligenceProfile.sufficientEvidence, isTrue);

    // ========================================================================
    // STAGE 3: P23 Learner Diagnostics & P18 Progress
    // Learner is WEAK in 'obj_bihar_hist' (20% accuracy), STRONG in 'obj_modern_hist' (90% accuracy),
    // and UNATTEMPTED in 'obj_science'.
    // ========================================================================
    final p23WeakSpotProfile = WeakSpotProfile(
      learnerId: 'learner_bpsc_aspirant',
      totalEvaluatedObjectives: 2,
      evaluatedWithSufficientEvidence: 2,
      evaluatedAt: fixedDate,
      weakObjectives: [
        WeakObjectiveDiagnostic(
          objectiveId: 'obj_bihar_hist',
          attemptCount: 10,
          correctCount: 2, // 20% accuracy => deficiency 0.80
        ),
      ],
    );

    final learnerProgressList = [
      LearnerProgress(
        learnerId: 'learner_bpsc_aspirant',
        objectiveId: 'obj_modern_hist',
        status: LearnerObjectiveStatus.achieved,
        attemptCount: 10,
        correctCount: 9, // 90% accuracy => 0.0 deficiency
        lastAttemptAt: fixedDate,
      ),
    ];

    // ========================================================================
    // STAGE 4: P32 PYQ-Aware Learning Priority Signal Synthesis
    // ========================================================================
    final p32Engine = PyqLearningPriorityEngine();
    final p32PriorityProfile = p32Engine.evaluateFromExamProfile(
      examProfile: bpscIntelligenceProfile,
      weakSpotProfile: p23WeakSpotProfile,
      progressList: learnerProgressList,
      evaluatedAt: fixedDate,
    );

    expect(p32PriorityProfile.examId, equals('bpsc'));
    final biharSignal = p32PriorityProfile.getObjectiveSignal('obj_bihar_hist');
    final modernSignal =
        p32PriorityProfile.getObjectiveSignal('obj_modern_hist');
    final scienceSignal = p32PriorityProfile.getObjectiveSignal('obj_science');

    // Bihar Hist is high PYQ + weak learner => highest priority
    expect(biharSignal.priorityScore, greaterThan(modernSignal.priorityScore));
    // Science is unattempted => strictly 0.0 learner weakness
    expect(scienceSignal.currentWeakness, equals(0.0));

    // ========================================================================
    // STAGE 5: P33 Adaptive Question Selection Engine
    // Select 6 practice questions for BPSC session with diversity constraints.
    // ========================================================================
    const p33Service = AdaptiveQuestionSelectionService();

    final sessionConfig = AdaptiveQuestionSelectionConfig(
      examId: 'bpsc',
      targetQuestionCount: 6,
      maxQuestionsPerTopic: 3, // Cap at 3 per topic
      maxQuestionsPerYear: 3, // Cap at 3 per year
      excludePreviouslySeen: false,
      maxExposureCount: 3,
    );

    // Learner previously attempted 1 specific Bihar History question
    final previousAttempts = [
      QuestionAttempt(
        attemptId: 'att_prev_1',
        learnerId: 'learner_bpsc_aspirant',
        questionId: normalizedBatch
            .firstWhere((q) => q.objectiveIds.contains('obj_bihar_hist'))
            .id,
        objectiveId: 'obj_bihar_hist',
        submittedAnswer: 'B', // incorrect
        attemptedAt: DateTime.utc(2026, 8, 25),
      ),
    ];

    final selectionResult = p33Service.selectQuestions(
      corpus: normalizedBatch,
      config: sessionConfig,
      pyqPriorityProfile: p32PriorityProfile,
      weakSpotProfile: p23WeakSpotProfile,
      progressList: learnerProgressList,
      attemptHistory: previousAttempts,
      selectedAt: fixedDate,
    );

    // ========================================================================
    // PROPERTY-STYLE INVARIANT ASSERTIONS
    // ========================================================================
    expect(selectionResult.selectedCount, equals(6));
    expect(selectionResult.selectedCount,
        lessThanOrEqualTo(sessionConfig.targetQuestionCount));
    expect(selectionResult.selectedCount,
        lessThanOrEqualTo(selectionResult.eligibleCount));
    expect(selectionResult.isConstraintLimited, isFalse);

    // 1. Strict Multi-Exam Isolation: zero UPSC questions in selection
    for (final q in selectionResult.selectedQuestions) {
      expect(q.examId, equals('bpsc'));
    }
    final upscCandidate =
        selectionResult.allCandidates.firstWhere((c) => c.examId == 'upsc');
    expect(upscCandidate.isEligible, isFalse);
    expect(upscCandidate.exclusionReason,
        equals(QuestionExclusionReason.examMismatch));

    // 2. Diversity Invariants:
    for (final entry in selectionResult.diversitySummary.entries) {
      if (entry.key.startsWith('topic_')) {
        expect(entry.value,
            lessThanOrEqualTo(sessionConfig.maxQuestionsPerTopic!));
      }
      if (entry.key.startsWith('year_')) {
        expect(
            entry.value, lessThanOrEqualTo(sessionConfig.maxQuestionsPerYear!));
      }
    }

    // 3. Selection Scoring & Mathematical Bounds:
    for (final cand in selectionResult.allCandidates) {
      expect(cand.selectionScore, greaterThanOrEqualTo(0.0));
      expect(cand.selectionScore, lessThanOrEqualTo(1.0));
      expect(cand.selectionScore.isNaN, isFalse);
      expect(cand.selectionScore.isInfinite, isFalse);
      expect(cand.historicalPriority, greaterThanOrEqualTo(0.0));
      expect(cand.historicalPriority, lessThanOrEqualTo(1.0));
      expect(cand.learnerWeakness, greaterThanOrEqualTo(0.0));
      expect(cand.learnerWeakness, lessThanOrEqualTo(1.0));
    }

    // 4. Prioritization: Bihar History (high PYQ + weak) appears before Modern History (high PYQ + strong)
    final firstSelected = selectionResult.selectedCandidates.first;
    expect(firstSelected.topic, equals('Bihar History and Geography'));
    expect(firstSelected.learnerWeakness, closeTo(0.80, 0.001));

    // 5. Zero Question Fabrication & Provenance Preservation:
    for (final selected in selectionResult.selectedQuestions) {
      final original = normalizedBatch.firstWhere((q) => q.id == selected.id);
      expect(selected.normalizedText, equals(original.normalizedText));
      expect(selected.options.length, equals(original.options.length));
      expect(selected.officialAnswer.correctOptionKeys,
          equals(original.officialAnswer.correctOptionKeys));
      expect(selected.source.publisher, equals(original.source.publisher));
    }

    // 6. Deterministic Replay: 5 identical executions produce byte-identical JSON
    final baselineJson = jsonEncode(selectionResult.toJson());
    for (int i = 0; i < 5; i++) {
      final replayed = p33Service.selectQuestions(
        corpus: normalizedBatch,
        config: sessionConfig,
        pyqPriorityProfile: p32PriorityProfile,
        weakSpotProfile: p23WeakSpotProfile,
        progressList: learnerProgressList,
        attemptHistory: previousAttempts,
        selectedAt: fixedDate,
      );
      expect(jsonEncode(replayed.toJson()), equals(baselineJson));
    }
  });
}
