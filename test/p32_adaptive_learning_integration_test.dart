import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

/// P32 End-to-End Mega Integration Test:
/// Full pipeline across:
/// P30 Acquisition -> P29 Normalization -> P31 Historical Intelligence
/// -> P23 Learner Analytics -> P32 Priority Context
/// -> P24 Planner / P25 Remediation / P26 Diagnostic Context
void main() {
  test(
      'P32 Mega Integration: P30 -> P29 -> P31 -> P23 -> P32 -> P24/P25/P26 pipeline',
      () async {
    final fixedTime = DateTime.utc(2026, 8, 30, 16, 0, 0);

    // ========================================================================
    // STAGE 1: P30 Source Descriptors & P29 Multi-Exam Ingestion
    // ========================================================================
    final sourceDescriptor = PyqSourceDescriptor(
      sourceId: 'SRC_UPSC_E2E',
      sourceName: 'UPSC CSE Official Papers',
      examId: 'upsc',
      publisher: 'Union Public Service Commission',
      sourceType: SourceType.officialPdf,
      format: PyqSourceFormat.json,
      years: [2022, 2023, 2024, 2025],
      languages: ['en'],
      uriOrPath: 'fixture://upsc_e2e.json',
    );
    expect(sourceDescriptor.examId, equals('upsc'));

    final p29Service = MultiExamPyqIntelligenceService();

    // Ingest 24 UPSC questions:
    // - 12 questions on Fundamental Rights (obj_fr) across all 4 years
    // - 8 questions on Directive Principles (obj_dpsp) across 3 years
    // - 4 questions on Emergency Provisions (obj_emergency) across 1 year
    final rawBatch = <RawQuestionInput>[];
    int qIdCounter = 0;
    for (int year = 2022; year <= 2025; year++) {
      // 3 FR questions per year
      for (int i = 0; i < 3; i++) {
        qIdCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'upsc',
          year: year,
          paper: 'GS1',
          questionNumber: qIdCounter,
          subject: 'Polity',
          topic: 'Fundamental Rights',
          questionText:
              'Constitutional protection under Article ${14 + i * 2} jurisprudence in year $year',
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
      // 2 DPSP questions per year for 2022, 2023, 2024, 2025
      for (int i = 0; i < 2; i++) {
        qIdCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'upsc',
          year: year,
          paper: 'GS1',
          questionNumber: qIdCounter,
          subject: 'Polity',
          topic: 'Directive Principles',
          questionText:
              'State policy mandate under Article ${38 + i * 2} socio-economic directive in year $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'B',
          objectiveIds: const ['obj_dpsp'],
          source: PyqSourceReference.official(
            examId: 'upsc',
            year: year,
            paper: 'GS1',
          ),
        ));
      }
      // 1 Emergency question in 2024
      if (year == 2024) {
        qIdCounter++;
        rawBatch.add(RawQuestionInput(
          examId: 'upsc',
          year: year,
          paper: 'GS1',
          questionNumber: qIdCounter,
          subject: 'Polity',
          topic: 'Emergency Provisions',
          questionText:
              'Presidential proclamation under Article 352 national security crisis in year $year',
          options: const ['A', 'B', 'C', 'D'],
          correctAnswer: 'C',
          objectiveIds: const ['obj_emergency'],
          source: PyqSourceReference.official(
            examId: 'upsc',
            year: year,
            paper: 'GS1',
          ),
        ));
      }
    }

    final upscResult = p29Service.ingestRawQuestions(
      rawBatch,
      defaultSource: PyqSourceReference.official(
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
      ),
    );
    expect(upscResult.uniqueQuestions.length, greaterThan(15));
    final normalizedQuestions = upscResult.uniqueQuestions;
    expect(normalizedQuestions.isNotEmpty, isTrue);

    // ========================================================================
    // STAGE 2: P31 Historical Intelligence Profile Generation
    // ========================================================================
    final p31Engine = const PyqHistoricalIntelligenceEngine();
    final p31ExamProfile = p31Engine.buildExamProfile(
      normalizedQuestions,
      examId: 'upsc',
      frameworkObjectiveIds: const ['obj_fr', 'obj_dpsp', 'obj_emergency'],
    );

    expect(p31ExamProfile.examId, equals('upsc'));
    expect(p31ExamProfile.sufficientEvidence, isTrue);
    expect(
        p31ExamProfile.subjectWeightage.entries
            .any((e) => e.category == 'Polity'),
        isTrue);

    // ========================================================================
    // STAGE 3: P23 Learner Diagnostics & Analytics
    // ========================================================================
    // Learner is struggling with both obj_fr and obj_emergency:
    // obj_emergency: 6 attempts, 1 correct (deficiency 0.833)
    // obj_fr: 6 attempts, 2 correct (deficiency 0.667)
    // obj_dpsp: 8 attempts, 7 correct (deficiency 0.125 - not weak)
    final p23WeakSpotProfile = WeakSpotProfile(
      learnerId: 'learner_aspirant_e2e',
      totalEvaluatedObjectives: 3,
      evaluatedWithSufficientEvidence: 3,
      minimumEvidenceThreshold: 5,
      evaluatedAt: fixedTime,
      weakObjectives: [
        WeakObjectiveDiagnostic(
          objectiveId: 'obj_emergency',
          attemptCount: 6,
          correctCount: 1,
          observedAccuracy: 0.167,
          deficiencyScore: 0.833,
        ),
        WeakObjectiveDiagnostic(
          objectiveId: 'obj_fr',
          attemptCount: 6,
          correctCount: 2,
          observedAccuracy: 0.333,
          deficiencyScore: 0.667,
        ),
      ],
    );

    // ========================================================================
    // STAGE 4: P32 Priority Engine Context Synthesis
    // ========================================================================
    final p32Engine = PyqLearningPriorityEngine();
    final p32PriorityProfile = p32Engine.evaluateFromExamProfile(
      examProfile: p31ExamProfile,
      weakSpotProfile: p23WeakSpotProfile,
      evaluatedAt: fixedTime,
    );

    expect(p32PriorityProfile.examId, equals('upsc'));
    expect(p32PriorityProfile.sufficientEvidence, isTrue);
    expect(p32PriorityProfile.objectiveSignals, isNotEmpty);

    // Even though obj_emergency had higher deficiency (0.833 vs 0.667),
    // obj_fr has vastly superior PYQ historical share, recurrence (4 years vs 1 year),
    // and recent frequency, so obj_fr achieves higher overall priority!
    final frSignal = p32PriorityProfile.getObjectiveSignal('obj_fr');
    final emergencySignal =
        p32PriorityProfile.getObjectiveSignal('obj_emergency');
    expect(frSignal.priorityScore, greaterThan(emergencySignal.priorityScore));
    expect(frSignal.historicalQuestionCount,
        greaterThan(emergencySignal.historicalQuestionCount));
    expect(frSignal.recurrenceCount, equals(4));

    // ========================================================================
    // STAGE 5: P24 Dynamic Study Planner Integration
    // ========================================================================
    final loFr = LearningObjective(
      id: 'obj_fr',
      unitId: 'unit_polity',
      title: 'Fundamental Rights Jurisprudence',
      description: 'Core constitutional rights under Part III',
      bloomLevel: BloomTaxonomyLevel.analyze,
      provenance: 'e2e_p17',
    );
    final loEmergency = LearningObjective(
      id: 'obj_emergency',
      unitId: 'unit_polity',
      title: 'Emergency Provisions',
      description: 'Articles 352-360 constitutional emergency',
      bloomLevel: BloomTaxonomyLevel.understand,
      provenance: 'e2e_p17',
    );

    final budget = StudyTimeBudget(
      learnerId: 'learner_aspirant_e2e',
      dailyAvailableMinutes: 60,
      preferredSessionDurationMinutes: 30,
      maxSessionsPerDay: 2,
      effectiveFrom: fixedTime,
    );

    final planRequest = StudyPlanRequest(
      learnerId: 'learner_aspirant_e2e',
      planningWindowStart: DateTime.utc(2026, 9, 1),
      planningWindowEnd: DateTime.utc(2026, 9, 2),
      timeBudget: budget,
      requestedAt: fixedTime,
    );

    const p24Adapter = PyqStudyPlanAdapter();
    final generatedPlan = p24Adapter.generatePlanWithPyqPriority(
      request: planRequest,
      priorityProfile: p32PriorityProfile,
      availableObjectives: [
        loEmergency,
        loFr
      ], // passed emergency first intentionally
    );

    // Verify P24 strict ownership invariants:
    expect(generatedPlan.dailyAgendas, isNotEmpty);
    final day1 = generatedPlan.dailyAgendas.first;
    expect(day1.allocatedMinutes, equals(60)); // P24 owns 60-min cap
    expect(day1.items.length, equals(2));
    for (final item in day1.items) {
      expect(item.allocatedMinutes, equals(30)); // P24 owns 30-min duration
    }
    // Verify P32 priority guided the slot sequencing (obj_fr scheduled first!)
    expect(day1.items.first.objectiveId, equals('obj_fr'));
    expect(day1.items[1].objectiveId, equals('obj_emergency'));

    // ========================================================================
    // STAGE 6: P25 Remedial Framework Integration
    // ========================================================================
    final remedialRepo = InMemoryRemedialLessonRepository();
    await remedialRepo.saveLesson(RemedialLesson(
      lessonId: 'lesson_fr',
      objectiveId: 'obj_fr',
      title: 'Remedial: Fundamental Rights',
      summary: 'Deep conceptual remedial module for Part III',
      explanation: 'Exhaustive breakdown of Articles 14 through 32',
      learningPoints: const ['Point A', 'Point B'],
      estimatedMinutes: 25,
      authoredAt: fixedTime,
    ));
    await remedialRepo.saveLesson(RemedialLesson(
      lessonId: 'lesson_emergency',
      objectiveId: 'obj_emergency',
      title: 'Remedial: Emergency Powers',
      summary: 'National and State Emergency framework',
      explanation: 'Analysis of Articles 352, 356, 360',
      learningPoints: const ['Point 1'],
      estimatedMinutes: 20,
      authoredAt: fixedTime,
    ));

    final remedialService =
        DeterministicRemedialLessonService(lessonRepository: remedialRepo);
    const p25Adapter = PyqRemediationAdapter();

    final remedialBindings = await p25Adapter.bindContextualizedRemedialLessons(
      weakSpotProfile: p23WeakSpotProfile,
      priorityProfile: p32PriorityProfile,
      remedialService: remedialService,
      maxLessons: 1, // Single lesson budget
      boundAt: fixedTime,
    );

    expect(remedialBindings.length, equals(1));
    // obj_fr selected for the 1 available lesson slot because PYQ recurrence + weightage elevates it!
    expect(remedialBindings.first.objectiveId, equals('obj_fr'));
    expect(remedialBindings.first.lesson.lessonId, equals('lesson_fr'));
    expect(remedialBindings.first.metadata['pyqExamId'], equals('upsc'));

    // ========================================================================
    // STAGE 7: P26 Diagnostic Placement Context Integration
    // ========================================================================
    final diagnosticResult = DiagnosticPlacementResult(
      assessmentId: 'diag_e2e_001',
      learnerId: 'learner_aspirant_e2e',
      evaluatedAt: fixedTime,
      frontier: DiagnosticPlacementFrontier(
        activeFrontierObjectiveIds: ['obj_emergency', 'obj_fr'],
        demonstratedObjectiveIds: ['obj_dpsp'],
        developingObjectiveIds: ['obj_emergency', 'obj_fr'],
        unassessedObjectiveIds: const [],
        remediationTargetObjectiveIds: ['obj_emergency', 'obj_fr'],
      ),
      objectiveResults: {
        'obj_fr': DiagnosticObjectiveResult(
          objectiveId: 'obj_fr',
          evidenceState: DiagnosticEvidenceState.sufficientEvidence,
          placementStatus: DiagnosticPlacementStatus.developing,
          attemptsCount: 6,
          correctCount: 2,
          observedAccuracy: 0.333,
          evaluatedAt: fixedTime,
          notes: 'Initial placement developing',
        ),
        'obj_emergency': DiagnosticObjectiveResult(
          objectiveId: 'obj_emergency',
          evidenceState: DiagnosticEvidenceState.sufficientEvidence,
          placementStatus: DiagnosticPlacementStatus.developing,
          attemptsCount: 6,
          correctCount: 1,
          observedAccuracy: 0.167,
          evaluatedAt: fixedTime,
          notes: 'Initial placement developing',
        ),
        'obj_dpsp': DiagnosticObjectiveResult(
          objectiveId: 'obj_dpsp',
          evidenceState: DiagnosticEvidenceState.sufficientEvidence,
          placementStatus: DiagnosticPlacementStatus.demonstrated,
          attemptsCount: 8,
          correctCount: 7,
          observedAccuracy: 0.875,
          evaluatedAt: fixedTime,
          notes: 'Mastered',
        ),
      },
      totalAssessedObjectives: 3,
      demonstratedObjectivesCount: 1,
      totalAttemptsCount: 20,
      totalCorrectCount: 10,
      aggregateAccuracy: 0.50,
      provenance: 'E2E Assessment',
    );

    const p26Adapter = PyqDiagnosticAdapter();
    final contextualizedDiagnostic = p26Adapter.contextualizePlacementResult(
      placementResult: diagnosticResult,
      priorityProfile: p32PriorityProfile,
    );

    // Verify P26 diagnostic correctness is strictly preserved:
    expect(contextualizedDiagnostic.placementResult.aggregateAccuracy,
        equals(0.50));
    expect(
        contextualizedDiagnostic
            .placementResult.objectiveResults['obj_dpsp']!.placementStatus,
        equals(DiagnosticPlacementStatus.demonstrated));

    // Verify active frontier is sequenced by PYQ importance (obj_fr first!):
    expect(contextualizedDiagnostic.prioritizedActiveFrontierIds.first,
        equals('obj_fr'));
    expect(contextualizedDiagnostic.prioritizedActiveFrontierIds[1],
        equals('obj_emergency'));
  });
}
