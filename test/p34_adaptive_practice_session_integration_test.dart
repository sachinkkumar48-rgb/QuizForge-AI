/// P34 Adaptive Practice Session Orchestrator Integration Test Suite (TITAN-KO-034.0 P34).
///
/// End-to-end pipeline verification:
/// P30 Acquisition -> P29 Normalization -> P31 Historical Intelligence ->
/// P32 Priority -> P23 Learner Evidence -> P33 Question Selection ->
/// P34 Practice Session Orchestration -> P19 Evidence-Ready Handoff.
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 1, 12, 0, 0);

  test(
      'P34 Mega Integration: Full Pipeline P30 -> P29 -> P31 -> P32 -> P23 -> P33 -> P34 -> P19',
      () {
    // ========================================================================
    // STAGE 1: P30 Acquisition & P29 Normalization Pipeline
    // Construct multi-exam raw question batches across BPSC, UPSC, and SSC.
    // ========================================================================
    final rawBatch = <RawQuestionInput>[];
    int qCounter = 0;

    // 1. BPSC Historical PYQs (2020-2024) across Bihar Special, History, Science
    for (int year = 2020; year <= 2024; year++) {
      // 3 Bihar History questions per year (total: 15)
      for (int i = 0; i < 3; i++) {
        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'Bihar Special',
          topic: 'Bihar History and Freedom Movement',
          questionText:
              'BPSC Champaran satyagraha regional impact question $qCounter in $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'A',
          difficulty: i == 0 ? 'Easy' : (i == 1 ? 'Medium' : 'Hard'),
          objectiveIds: const ['obj_bihar_hist'],
          source: PyqSourceReference.official(
            examId: 'bpsc',
            year: year,
            paper: 'GS1',
          ),
        ));
      }
      // 2 Modern History questions per year (total: 10)
      for (int i = 0; i < 2; i++) {
        qCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
          questionNumber: qCounter,
          subject: 'History',
          topic: 'Modern Indian National Movement',
          questionText:
              'BPSC Indian National Congress session question $qCounter in $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'B',
          difficulty: i == 0 ? 'Easy' : 'Medium',
          objectiveIds: const ['obj_modern_hist'],
          source: PyqSourceReference.official(
            examId: 'bpsc',
            year: year,
            paper: 'GS1',
          ),
        ));
      }
      // 1 Science question per year (total: 5)
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
        difficulty: 'Medium',
        objectiveIds: const ['obj_physics'],
        source: PyqSourceReference.official(
          examId: 'bpsc',
          year: year,
          paper: 'GS1',
        ),
      ));
    }

    // 2. UPSC Questions (to verify cross-exam firewall)
    for (int year = 2022; year <= 2024; year++) {
      qCounter++;
      rawBatch.add(RawQuestionInput(
        examId: 'upsc',
        year: year,
        paper: 'GS1',
        questionNumber: qCounter,
        subject: 'Polity',
        topic: 'Fundamental Rights and Duties',
        questionText:
            'UPSC Judicial review doctrine Article 32 question $qCounter in $year',
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
    final bpscQuestions =
        normalizedBatch.where((q) => q.examId == 'bpsc').toList();
    expect(bpscQuestions.length, equals(30)); // 6 * 5 = 30

    // ========================================================================
    // STAGE 2: P31 Multi-Exam Historical PYQ Intelligence
    // ========================================================================
    const p31Engine = PyqHistoricalIntelligenceEngine();
    final bpscIntelligence = p31Engine.buildExamProfile(
      bpscQuestions,
      examId: 'bpsc',
      frameworkObjectiveIds: const [
        'obj_bihar_hist',
        'obj_modern_hist',
        'obj_physics',
      ],
    );

    expect(bpscIntelligence.examId, equals('bpsc'));
    expect(bpscIntelligence.questionCount, equals(30));
    expect(bpscIntelligence.sufficientEvidence, isTrue);

    // ========================================================================
    // STAGE 3: P23 Learner Weak Spot Diagnoses & P18 Progress
    // Learner is WEAK in 'obj_bihar_hist' (deficiency 0.80), STRONG in 'obj_modern_hist' (deficiency 0.0),
    // and UNATTEMPTED in 'obj_physics'.
    // ========================================================================
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

    // ========================================================================
    // STAGE 4: P32 PYQ Learning Priority Engine
    // ========================================================================
    final p32Engine = PyqLearningPriorityEngine();
    final p32PriorityProfile = p32Engine.evaluateFromExamProfile(
      examProfile: bpscIntelligence,
      weakSpotProfile: weakSpotProfile,
      progressList: progressList,
      evaluatedAt: fixedDate,
    );

    expect(p32PriorityProfile.examId, equals('bpsc'));
    final biharHistSignal =
        p32PriorityProfile.getObjectiveSignal('obj_bihar_hist');
    final modernHistSignal =
        p32PriorityProfile.getObjectiveSignal('obj_modern_hist');
    expect(biharHistSignal.priorityScore,
        greaterThan(modernHistSignal.priorityScore));

    // ========================================================================
    // STAGE 5: P33 Adaptive Question Selection Engine
    // Select 20 practice questions from corpus with diversity constraints.
    // ========================================================================
    const p33Service = AdaptiveQuestionSelectionService();
    final selectionConfig = AdaptiveQuestionSelectionConfig(
      examId: 'bpsc',
      targetQuestionCount: 20,
      maxQuestionsPerTopic: 10,
      maxQuestionsPerYear: 6,
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

    expect(selectionResult.selectedCount, equals(20));
    expect(selectionResult.isConstraintLimited, isFalse);

    // ========================================================================
    // STAGE 6: P34 Adaptive Practice Session Orchestrator
    // Orchestrate a 20-question practice session with section size = 5.
    // ========================================================================
    const p34Orchestrator = AdaptivePracticeSessionOrchestrator();
    final practiceSessionConfig = AdaptivePracticeSessionConfig(
      examId: 'bpsc',
      learnerId: 'learner_aspirant_bpsc_2026',
      sessionMode: PracticeSessionMode.standard,
      completionPolicy: PracticeCompletionPolicy.allRequired,
      objectiveBalancing: ObjectiveBalancingPolicy.balanced,
      difficultyProgression: PracticeDifficultyProgression.easyToHard,
      sectionSize: 5,
      estimatedSecondsPerQuestion: 60,
    );

    final sessionSpec = p34Orchestrator.orchestrateSession(
      selectionResult: selectionResult,
      config: practiceSessionConfig,
      orchestratedAt: fixedDate,
    );

    // ========================================================================
    // PROPERTY-STYLE INVARIANT ASSERTIONS
    // ========================================================================

    // 1. Session Composition & Sizing
    expect(sessionSpec.totalQuestions, equals(20));
    expect(sessionSpec.totalSections, equals(4)); // 20 / 5 = 4 sections
    for (final sec in sessionSpec.sections) {
      expect(sec.questionCount, equals(5));
      expect(sec.estimatedSeconds, equals(300)); // 5 * 60s = 300s
    }
    expect(sessionSpec.totalEstimatedSeconds,
        equals(1200)); // 20 * 60s = 1200s (20 mins)

    // 2. Strict Multi-Exam Isolation: 100% BPSC questions, 0 UPSC questions
    for (final q in sessionSpec.orderedQuestions) {
      expect(q.examId, equals('bpsc'));
    }
    expect(
        sessionSpec.orderedQuestions.any((q) => q.examId == 'upsc'), isFalse);

    // 3. Question Uniqueness Invariant
    final uniqueIds = sessionSpec.orderedQuestionIds.toSet();
    expect(uniqueIds.length, equals(20));

    // 4. Section Invariants: Section question IDs match session question IDs
    final collectedSectionIds = <String>[];
    for (final sec in sessionSpec.sections) {
      collectedSectionIds.addAll(sec.questionIds);
    }
    expect(collectedSectionIds, equals(sessionSpec.orderedQuestionIds));

    // 5. Multi-dimensional Distribution Analytics
    expect(sessionSpec.distribution.historicalQuestionCount, equals(20));
    expect(sessionSpec.distribution.historicalQuestionRatio, equals(1.0));
    expect(sessionSpec.distribution.nonHistoricalQuestionCount, equals(0));
    expect(sessionSpec.distribution.highWeaknessCount, greaterThan(0));
    expect(
        sessionSpec.distribution.topicCounts.length, greaterThanOrEqualTo(2));
    expect(
        sessionSpec.distribution.objectiveCounts.containsKey('obj_bihar_hist'),
        isTrue);

    // 6. Zero Question Fabrication & Provenance Retention
    for (final q in sessionSpec.orderedQuestions) {
      final original = normalizedBatch.firstWhere((orig) => orig.id == q.id);
      expect(q.normalizedText, equals(original.normalizedText));
      expect(q.options.length, equals(original.options.length));
      expect(q.officialAnswer.correctOptionKeys,
          equals(original.officialAnswer.correctOptionKeys));
      expect(q.source.publisher, equals(original.source.publisher));
    }

    // 7. Deterministic Replay: 10 consecutive orchestrations produce identical SHA-256 session ID and JSON
    final baselineJson = jsonEncode(sessionSpec.toJson());
    for (int i = 0; i < 10; i++) {
      final replayedSpec = p34Orchestrator.orchestrateSession(
        selectionResult: selectionResult,
        config: practiceSessionConfig,
        orchestratedAt: fixedDate,
      );
      expect(replayedSpec.sessionId, equals(sessionSpec.sessionId));
      expect(jsonEncode(replayedSpec.toJson()), equals(baselineJson));
    }

    // ========================================================================
    // STAGE 7: P19 Evidence-Ready Handoff Adapter
    // ========================================================================
    final p19LearningSession =
        sessionSpec.toLearningSession(startedAt: fixedDate);
    expect(p19LearningSession.sessionId, equals(sessionSpec.sessionId));
    expect(p19LearningSession.learnerId, equals('learner_aspirant_bpsc_2026'));
    expect(p19LearningSession.totalQuestions, equals(20));
    expect(p19LearningSession.orderedQuestionIds,
        equals(sessionSpec.orderedQuestionIds));
    expect(p19LearningSession.state, equals(LearningSessionState.created));
  });
}
