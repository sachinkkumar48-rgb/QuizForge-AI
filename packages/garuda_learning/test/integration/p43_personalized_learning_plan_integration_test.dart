import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P43 Personalized Learning Plan Integration Tests', () {
    const String testLearner = 'learner_p43_integration';
    const String testExam = 'upsc_prelims_gs1';
    final baseDate = DateTime.utc(2026, 9, 7, 12, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryRemedialLessonRepository remedialRepo;
    late DeterministicRemedialLessonService remedialService;
    late InMemoryDiagnosticPlacementRepository diagnosticRepo;
    late ContentLearningPathService contentService;
    late List<NormalizedQuestion> seedCorpus;
    late PersonalizedLearningPlanService planService;

    NormalizedQuestion buildTestQuestion({
      required String id,
      required String subject,
      required String topic,
      required String objectiveId,
    }) {
      return NormalizedQuestion(
        id: id,
        examId: testExam,
        year: 2024,
        paper: 'GS1',
        subject: subject,
        topic: topic,
        normalizedText: 'Question text for $id',
        originalText: 'Original stem for $id',
        options: const [
          Option(key: 'A', text: 'Option A', isCorrect: true),
          Option(key: 'B', text: 'Option B', isCorrect: false),
          Option(key: 'C', text: 'Option C', isCorrect: false),
          Option(key: 'D', text: 'Option D', isCorrect: false),
        ],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        explanation: 'Official explanation for $id',
        difficulty: 'Medium',
        source: PyqSourceReference.official(
          examId: testExam,
          year: 2024,
          paper: 'GS1',
        ),
        objectiveIds: [objectiveId],
      );
    }

    setUp(() {
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      checkpointRepo = InMemorySessionCheckpointRepository();
      authRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );
      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);

      remedialRepo = InMemoryRemedialLessonRepository();
      remedialRepo.saveLesson(RemedialLesson(
        lessonId: 'rem_art21_01',
        objectiveId: 'lo_article_21_foundations',
        title: 'Article 21 Remedial Review',
        summary: 'Targeted remediation on personal liberty jurisprudence.',
        learningPoints: const ['Procedure by Law', 'Due Process of Law'],
        explanation: 'Detailed micro-lesson on Article 21.',
        estimatedMinutes: 10,
        authoredAt: baseDate,
      ));
      remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );

      diagnosticRepo = InMemoryDiagnosticPlacementRepository();

      seedCorpus = [
        buildTestQuestion(
          id: 'pyq_fr_01',
          subject: 'Indian Polity',
          topic: 'Fundamental Rights',
          objectiveId: 'lo_article_21_foundations',
        ),
        buildTestQuestion(
          id: 'pyq_fr_02',
          subject: 'Indian Polity',
          topic: 'Fundamental Rights',
          objectiveId: 'lo_article_21_foundations',
        ),
        buildTestQuestion(
          id: 'pyq_bs_01',
          subject: 'Indian Polity',
          topic: 'Preamble & Basic Structure',
          objectiveId: 'lo_basic_structure_doctrine',
        ),
        buildTestQuestion(
          id: 'pyq_preamble_01',
          subject: 'Indian Polity',
          topic: 'Preamble & Basic Structure',
          objectiveId: 'lo_preamble_identity',
        ),
      ];

      contentService = ContentLearningPathService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        remedialService: remedialService,
        seedQuestions: seedCorpus,
      );

      planService = PersonalizedLearningPlanService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        contentService: contentService,
        diagnosticRepository: diagnosticRepo,
        remedialService: remedialService,
        seedQuestions: seedCorpus,
      );
    });

    test('Integration 1: Diagnostic Placement -> Personalized Learning Plan',
        () async {
      // Learner takes a diagnostic placement assessment
      // Result: Preamble is demonstrated, Article 21 needs remediation
      final diagnostic = DiagnosticPlacementResult(
        assessmentId: 'diag_p43_integ_01',
        learnerId: testLearner,
        evaluatedAt: baseDate,
        objectiveResults: {
          'lo_preamble_identity': DiagnosticObjectiveResult(
            objectiveId: 'lo_preamble_identity',
            evidenceState: DiagnosticEvidenceState.sufficientEvidence,
            placementStatus: DiagnosticPlacementStatus.demonstrated,
            attemptsCount: 4,
            correctCount: 4,
            observedAccuracy: 1.0,
            evaluatedAt: baseDate,
            notes: 'Strong conceptual foundation',
          ),
          'lo_article_21_foundations': DiagnosticObjectiveResult(
            objectiveId: 'lo_article_21_foundations',
            evidenceState: DiagnosticEvidenceState.sufficientEvidence,
            placementStatus: DiagnosticPlacementStatus.developing,
            attemptsCount: 5,
            correctCount: 1,
            observedAccuracy: 0.20,
            evaluatedAt: baseDate,
            notes: 'Substantial conceptual gap',
          ),
        },
        frontier: DiagnosticPlacementFrontier(
          activeFrontierObjectiveIds: ['lo_basic_structure_doctrine'],
          demonstratedObjectiveIds: ['lo_preamble_identity'],
          developingObjectiveIds: ['lo_article_21_foundations'],
          unassessedObjectiveIds: [],
          remediationTargetObjectiveIds: ['lo_article_21_foundations'],
        ),
        totalAssessedObjectives: 2,
        demonstratedObjectivesCount: 1,
        totalAttemptsCount: 9,
        totalCorrectCount: 5,
        aggregateAccuracy: 5 / 9,
        provenance: 'UPSC Diagnostic Evaluation',
      );
      diagnosticRepo.saveResult(diagnostic);

      // Generate learning plan
      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      // Verify that diagnosed weakness is elevated to top priority recommendation
      expect(plan.recommendedAction, isNotNull);
      expect(plan.recommendedAction!.objectiveId,
          equals('lo_article_21_foundations'));
      expect(plan.recommendedAction!.reasonCode,
          equals(PlanReasonCode.diagnosticWeakness));
      expect(plan.recommendedAction!.reason,
          contains('Diagnostic indicates this objective needs remediation'));
      expect(
          plan.recommendedAction!.status, equals(PlanActionStatus.recommended));
      expect(plan.recommendedAction!.actionType,
          equals(PlanActionType.startRemedialLesson));
      expect(plan.recommendedAction!.remedialLessonId, equals('rem_art21_01'));

      // Active frontier objective follows weakness
      final nextAction = plan.upcomingActions.first;
      expect(nextAction.objectiveId, equals('lo_basic_structure_doctrine'));
    });

    test(
        'Integration 2: In-flight Session Checkpoint -> Prioritized Resume Action',
        () async {
      // Diagnostic exists, but learner was in the middle of a practice session when interrupted
      final checkpoint = SessionCheckpoint(
        checkpointRevision: 2,
        authoritativeStateRevision: 1,
        sessionId: 'sess_p43_interrupted_99',
        examId: testExam,
        learnerId: testLearner,
        timestamp: baseDate.subtract(const Duration(minutes: 10)),
        questionIndex: 2,
        activeObjectiveId: 'lo_basic_structure_doctrine',
        completedQuestionIds: const ['pyq_bs_01'],
        isCompleted: false,
        metadata: const {
          'topic': 'Preamble & Basic Structure',
          'totalQuestions': 3
        },
      );
      await checkpointRepo.saveCheckpoint(checkpoint);

      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      // In-flight session must supersede even diagnosed weaknesses
      expect(plan.recommendedAction, isNotNull);
      expect(plan.recommendedAction!.actionType,
          equals(PlanActionType.continueSession));
      expect(
          plan.recommendedAction!.sessionId, equals('sess_p43_interrupted_99'));
      expect(plan.recommendedAction!.sessionCursor, equals(2));
      expect(plan.recommendedAction!.reasonCode,
          equals(PlanReasonCode.inFlightSession));
      expect(plan.recommendedAction!.reason,
          contains('unfinished practice session'));
      expect(
          plan.recommendedAction!.status, equals(PlanActionStatus.recommended));
    });

    test(
        'Integration 3: Closed-Loop Lifecycle — Practice Outcome -> State Update -> Plan Refresh',
        () async {
      // Step A: Initial state — learner is practicing 'lo_preamble_identity' (not yet achieved)
      final initialProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_preamble_identity',
        attemptCount: 2,
        correctCount: 2,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate,
      );
      final initialAuthState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        progressMap: {'lo_preamble_identity': initialProgress},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(
              initialAuthState));

      // Initial Plan: 'lo_preamble_identity' is recommended
      final planV1 = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );
      expect(planV1.stateRevision, equals(1));
      expect(planV1.recommendedAction!.objectiveId,
          equals('lo_preamble_identity'));
      expect(planV1.recommendedAction!.actionType,
          equals(PlanActionType.practiceObjective));
      expect(planV1.recommendedAction!.status,
          equals(PlanActionStatus.recommended));
      expect(planV1.completedActions, isEmpty);

      // Step B: Learner executes practice session and completes 'lo_preamble_identity'
      // Outcome consolidation & reconciliation occurs, updating authoritative learner state
      final completedProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_preamble_identity',
        attemptCount: 6,
        correctCount: 6,
        status: LearnerObjectiveStatus.achieved,
        achievedAt: baseDate.add(const Duration(hours: 1)),
        lastAttemptAt: baseDate.add(const Duration(hours: 1)),
      );
      final updatedAuthState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        progressMap: {'lo_preamble_identity': completedProgress},
        lastUpdatedAt: baseDate.add(const Duration(hours: 1)),
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(
              updatedAuthState));

      // Step C: Plan Refresh — plan is regenerated with updated authoritative state
      final planV2 = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate.add(const Duration(hours: 1)),
      );

      // Step D: Closed-loop verification
      // 1. Revision increments
      expect(planV2.stateRevision, equals(2));

      // 2. Previously recommended action 'lo_preamble_identity' is now marked completed
      expect(planV2.completedActions.length, equals(1));
      expect(planV2.completedActions.first.objectiveId,
          equals('lo_preamble_identity'));
      expect(planV2.completedActions.first.actionType,
          equals(PlanActionType.reviewRevision));
      expect(planV2.completedActions.first.status,
          equals(PlanActionStatus.completed));
      expect(
          planV2.completedActions.first.reason, contains('Mastery achieved'));

      // 3. Next objective in sequence ('lo_basic_structure_doctrine') is promoted to recommended
      expect(planV2.recommendedAction, isNotNull);
      expect(planV2.recommendedAction!.objectiveId,
          equals('lo_basic_structure_doctrine'));
      expect(planV2.recommendedAction!.actionType,
          equals(PlanActionType.practiceObjective));
      expect(planV2.recommendedAction!.status,
          equals(PlanActionStatus.recommended));

      // 4. Progress percentage advanced
      expect(planV2.progressPercentage, greaterThan(planV1.progressPercentage));
      expect(planV2.progressPercentage,
          equals(1 / 3)); // 1 of 3 objectives completed
    });
  });
}
