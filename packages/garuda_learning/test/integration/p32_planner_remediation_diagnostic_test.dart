import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

NormalizedQuestion _makeQ({
  required String examId,
  required int year,
  String paper = 'GS1',
  String subject = 'Polity',
  String topic = 'Constitution',
  List<String> objectiveIds = const [],
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
    language: 'en',
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
      Option(key: 'A', text: 'Opt A'),
      Option(key: 'B', text: 'Opt B'),
      Option(key: 'C', text: 'Opt C'),
      Option(key: 'D', text: 'Opt D'),
    ],
    officialAnswer: const Answer(correctOptionKeys: ['A']),
    language: 'en',
    source: src,
    objectiveIds: objectiveIds,
  );
}

void main() {
  group('P32.8 P24 Study Planner Integration (Section 23)', () {
    final fixedTime = DateTime.utc(2026, 8, 30, 12, 0, 0);
    final planStart = DateTime.utc(2026, 9, 1);
    final planEnd = DateTime.utc(2026, 9, 3); // 3 days

    test(
        'P32 priority context guides candidate ordering while P24 strictly owns time allocation',
        () {
      final engine = PyqLearningPriorityEngine();

      // Corpus: 12 questions for lo_high_pyq, 1 question for lo_low_pyq
      final corpus = <NormalizedQuestion>[];
      for (int i = 0; i < 12; i++) {
        corpus.add(_makeQ(
          examId: 'upsc',
          year: 2020 + (i % 5),
          topic: 'High Topic',
          objectiveIds: ['lo_high_pyq'],
          questionNumber: i + 1,
        ));
      }
      corpus.add(_makeQ(
        examId: 'upsc',
        year: 2024,
        topic: 'Low Topic',
        objectiveIds: ['lo_low_pyq'],
        questionNumber: 20,
      ));

      final priorityProfile = engine.evaluateFromQuestions(
        questions: corpus,
        examId: 'upsc',
        evaluatedAt: fixedTime,
      );

      final loHigh = LearningObjective(
        id: 'lo_high_pyq',
        unitId: 'unit_polity',
        title: 'High Priority Constitutional Principles',
        description: 'Frequently tested in PYQs',
        bloomLevel: BloomTaxonomyLevel.understand,
        provenance: 'test_p17',
      );
      final loLow = LearningObjective(
        id: 'lo_low_pyq',
        unitId: 'unit_polity',
        title: 'Low Priority Minor Provision',
        description: 'Rarely tested in PYQs',
        bloomLevel: BloomTaxonomyLevel.understand,
        provenance: 'test_p17',
      );

      // Learner time budget: 60 min/day, 30 min session duration -> 2 sessions allowed per day
      final budget = StudyTimeBudget(
        learnerId: 'learner_p24',
        dailyAvailableMinutes: 60,
        preferredSessionDurationMinutes: 30,
        maxSessionsPerDay: 2,
        effectiveFrom: fixedTime,
      );

      final request = StudyPlanRequest(
        learnerId: 'learner_p24',
        planningWindowStart: planStart,
        planningWindowEnd: planEnd,
        timeBudget: budget,
        requestedAt: fixedTime,
      );

      final adapter = PyqStudyPlanAdapter();

      // Pass available objectives in inverse order (loLow first)
      final plan = adapter.generatePlanWithPyqPriority(
        request: request,
        priorityProfile: priorityProfile,
        availableObjectives: [loLow, loHigh],
      );

      // Verify P24 owns the time allocation and constraints:
      expect(plan.dailyAgendas, isNotEmpty);
      final day1 = plan.dailyAgendas.first;
      expect(day1.allocatedMinutes, equals(60));
      expect(day1.items.length, equals(2));
      for (final item in day1.items) {
        expect(item.allocatedMinutes, equals(30)); // P24 session duration
      }

      // Verify P32 priority context prioritized lo_high_pyq ahead of lo_low_pyq:
      expect(day1.items.first.objectiveId, equals('lo_high_pyq'));
      expect(day1.items[1].objectiveId, equals('lo_low_pyq'));

      // Verify metadata carried priority context
      expect(plan.request.metadata['pyqExamId'], equals('upsc'));
      expect(plan.request.metadata['pyqPriorityIntegrated'], isTrue);
    });
  });

  group('P32.9 P25 Remedial Framework Integration (Section 24)', () {
    final fixedTime = DateTime.utc(2026, 8, 30, 14, 0, 0);

    test(
        'P32 contextualizes remediation priority while P25 owns lesson binding',
        () async {
      final engine = PyqLearningPriorityEngine();

      // Corpus: 15 questions for lo_pyq_heavy, 1 for lo_pyq_light
      final corpus = <NormalizedQuestion>[];
      for (int i = 0; i < 15; i++) {
        corpus.add(_makeQ(
          examId: 'upsc',
          year: 2020 + (i % 5),
          topic: 'Fundamental Rights',
          objectiveIds: ['lo_pyq_heavy'],
          questionNumber: i + 1,
        ));
      }
      corpus.add(_makeQ(
        examId: 'upsc',
        year: 2024,
        topic: 'Tribunals',
        objectiveIds: ['lo_pyq_light'],
        questionNumber: 30,
      ));

      final priorityProfile = engine.evaluateFromQuestions(
        questions: corpus,
        examId: 'upsc',
        evaluatedAt: fixedTime,
      );

      // P23 WeakSpotProfile: both are weak spots
      // lo_pyq_light has slightly higher deficiency (0.75 vs 0.70)
      // BUT lo_pyq_heavy has vastly higher PYQ importance
      final weakProfile = WeakSpotProfile(
        learnerId: 'learner_remedial',
        totalEvaluatedObjectives: 2,
        evaluatedWithSufficientEvidence: 2,
        minimumEvidenceThreshold: 5,
        evaluatedAt: fixedTime,
        weakObjectives: [
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_pyq_light',
            attemptCount: 8,
            correctCount: 2,
            observedAccuracy: 0.25,
            deficiencyScore: 0.75,
          ),
          WeakObjectiveDiagnostic(
            objectiveId: 'lo_pyq_heavy',
            attemptCount: 10,
            correctCount: 3,
            observedAccuracy: 0.30,
            deficiencyScore: 0.70,
          ),
        ],
      );

      final repo = InMemoryRemedialLessonRepository();
      await repo.saveLesson(RemedialLesson(
        lessonId: 'lesson_heavy',
        objectiveId: 'lo_pyq_heavy',
        title: 'Fundamental Rights Remediation',
        summary: 'Deep dive into FR principles',
        explanation: 'Detailed constitutional analysis',
        learningPoints: const ['Point 1', 'Point 2'],
        sourceReferences: [
          SourceReference(
            sourceId: 'const_source',
            sourceType: SourceReferenceType.constitution,
            referenceIdentifier: 'Part_III',
          ),
        ],
        estimatedMinutes: 20,
        bloomLevel: BloomTaxonomyLevel.understand,
        authoredAt: fixedTime,
      ));
      await repo.saveLesson(RemedialLesson(
        lessonId: 'lesson_light',
        objectiveId: 'lo_pyq_light',
        title: 'Tribunals Overview',
        summary: 'Tribunal jurisdiction',
        explanation: 'Overview of Article 323A',
        learningPoints: const ['Point A'],
        sourceReferences: [
          SourceReference(
            sourceId: 'const_source',
            sourceType: SourceReferenceType.constitution,
            referenceIdentifier: 'Part_XIVA',
          ),
        ],
        estimatedMinutes: 20,
        bloomLevel: BloomTaxonomyLevel.understand,
        authoredAt: fixedTime,
      ));

      final remedialService =
          DeterministicRemedialLessonService(lessonRepository: repo);
      final adapter = PyqRemediationAdapter();

      // With maxLessons: 1, the PYQ-critical topic should win!
      final bindings = await adapter.bindContextualizedRemedialLessons(
        weakSpotProfile: weakProfile,
        priorityProfile: priorityProfile,
        remedialService: remedialService,
        maxLessons: 1,
        boundAt: fixedTime,
      );

      expect(bindings.length, equals(1));
      expect(bindings.first.objectiveId, equals('lo_pyq_heavy'));
      expect(bindings.first.lesson.lessonId, equals('lesson_heavy'));
      expect(bindings.first.trigger,
          equals(RemedialBindingTrigger.weakSpotDiagnostic));
    });
  });

  group('P32.10 P26 Diagnostic Placement Integration (Section 25)', () {
    final fixedTime = DateTime.utc(2026, 8, 30, 15, 0, 0);

    test(
        'P32 provides contextual coverage without altering diagnostic placement or correctness',
        () {
      final engine = PyqLearningPriorityEngine();

      final corpus = <NormalizedQuestion>[];
      for (int i = 0; i < 10; i++) {
        corpus.add(_makeQ(
          examId: 'upsc',
          year: 2020 + (i % 5),
          topic: 'High Frontier Topic',
          objectiveIds: ['lo_frontier_high'],
          questionNumber: i + 1,
        ));
      }
      corpus.add(_makeQ(
        examId: 'upsc',
        year: 2024,
        topic: 'Low Frontier Topic',
        objectiveIds: ['lo_frontier_low'],
        questionNumber: 25,
      ));

      final priorityProfile = engine.evaluateFromQuestions(
        questions: corpus,
        examId: 'upsc',
        evaluatedAt: fixedTime,
      );

      // P26 placement result: frontier contains both objectives
      final placementResult = DiagnosticPlacementResult(
        assessmentId: 'diag_101',
        learnerId: 'learner_diag',
        evaluatedAt: fixedTime,
        frontier: DiagnosticPlacementFrontier(
          activeFrontierObjectiveIds: ['lo_frontier_low', 'lo_frontier_high'],
          demonstratedObjectiveIds: const [],
          developingObjectiveIds: ['lo_frontier_low', 'lo_frontier_high'],
          unassessedObjectiveIds: ['lo_frontier_low', 'lo_frontier_high'],
          remediationTargetObjectiveIds: const [],
        ),
        objectiveResults: {
          'lo_frontier_low': DiagnosticObjectiveResult(
            objectiveId: 'lo_frontier_low',
            evidenceState: DiagnosticEvidenceState.sufficientEvidence,
            placementStatus: DiagnosticPlacementStatus.developing,
            attemptsCount: 6,
            correctCount: 3,
            observedAccuracy: 0.50,
            evaluatedAt: fixedTime,
            notes: 'Developing performance',
          ),
          'lo_frontier_high': DiagnosticObjectiveResult(
            objectiveId: 'lo_frontier_high',
            evidenceState: DiagnosticEvidenceState.sufficientEvidence,
            placementStatus: DiagnosticPlacementStatus.developing,
            attemptsCount: 6,
            correctCount: 3,
            observedAccuracy: 0.50,
            evaluatedAt: fixedTime,
            notes: 'Developing performance',
          ),
        },
        totalAssessedObjectives: 2,
        demonstratedObjectivesCount: 0,
        totalAttemptsCount: 12,
        totalCorrectCount: 6,
        aggregateAccuracy: 0.50,
        provenance: 'P26 Test',
      );

      const adapter = PyqDiagnosticAdapter();
      final contextualized = adapter.contextualizePlacementResult(
        placementResult: placementResult,
        priorityProfile: priorityProfile,
      );

      // Verify diagnostic correctness is untouched
      expect(contextualized.placementResult.aggregateAccuracy, equals(0.50));
      expect(
          contextualized.placementResult.objectiveResults['lo_frontier_low']!
              .placementStatus,
          equals(DiagnosticPlacementStatus.developing));
      expect(
          contextualized.placementResult.objectiveResults['lo_frontier_high']!
              .placementStatus,
          equals(DiagnosticPlacementStatus.developing));

      // Verify active frontier is prioritized by PYQ importance
      expect(contextualized.prioritizedActiveFrontierIds.first,
          equals('lo_frontier_high'));
      expect(contextualized.prioritizedActiveFrontierIds[1],
          equals('lo_frontier_low'));

      // Verify contextual distinction in notes
      final highEntry = contextualized.contextualizedObjectives
          .firstWhere((o) => o.objectiveId == 'lo_frontier_high');
      expect(highEntry.historicalQuestionCount, equals(10));
      expect(highEntry.notes, contains('PYQ: 10 question(s) observed'));
      expect(highEntry.notes, contains('Learner: developing'));
    });
  });

  group('P32.11 Multi-Exam Awareness & Safe Failure (Section 11)', () {
    test(
        'Learner preparing for BPSC or SSC correctly scopes to that exam without UPSC fallback',
        () {
      final engine = PyqLearningPriorityEngine();

      final bpscCorpus = [
        _makeQ(
            examId: 'bpsc',
            year: 2023,
            subject: 'Bihar History',
            topic: 'Revolt of 1857 in Bihar',
            objectiveIds: ['obj_bihar_1857']),
        _makeQ(
            examId: 'bpsc',
            year: 2024,
            subject: 'Bihar History',
            topic: 'Revolt of 1857 in Bihar',
            objectiveIds: ['obj_bihar_1857']),
      ];

      final bpscProfile = engine.evaluateFromQuestions(
        questions: bpscCorpus,
        examId: 'bpsc',
      );

      expect(bpscProfile.examId, 'bpsc');
      expect(bpscProfile.corpusQuestionCount, 2);
      final sig = bpscProfile.getObjectiveSignal('obj_bihar_1857');
      expect(sig.examId, 'bpsc');
      expect(sig.historicalQuestionCount, 2);

      // Unknown exam produces safe profile with 0 questions and does NOT fallback to UPSC or BPSC
      final unknownProfile = engine.evaluateFromQuestions(
        questions: bpscCorpus,
        examId: 'unknown_exam_xyz',
      );

      expect(unknownProfile.examId, 'unknown_exam_xyz');
      expect(unknownProfile.corpusQuestionCount, 0);
      expect(unknownProfile.sufficientEvidence, isFalse);
      final unknownSig = unknownProfile.getObjectiveSignal('obj_bihar_1857');
      expect(unknownSig.level, PrioritySignalLevel.none);
      expect(unknownSig.historicalQuestionCount, 0);
      expect(unknownSig.priorityScore, 0.0);
    });
  });
}
