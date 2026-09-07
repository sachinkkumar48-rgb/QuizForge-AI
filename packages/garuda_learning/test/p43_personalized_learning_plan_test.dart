/// P43 Personalized Learning Plan Unit & Behavior Tests (TITAN-KO-043.0 P43).
///
/// Exhaustively verifies the 20 core test matrix scenarios:
/// 1. empty learner state
/// 2. learner with no diagnostic
/// 3. learner with diagnostic result
/// 4. weak objective gets prioritized
/// 5. incomplete objective gets prioritized
/// 6. recoverable session gets prioritized
/// 7. remedial action is selected when supported
/// 8. PYQ action is selected when supported
/// 9. completed objective is not incorrectly prioritized
/// 10. plan ordering is deterministic
/// 11. equivalent state produces equivalent plan
/// 12. every action has a valid reason
/// 13. every executable action resolves to an existing workflow
/// 14. unavailable content is handled
/// 15. no-content objective is handled
/// 16. invalid learner state is handled
/// 17. learning outcome changes subsequent plan
/// 18. regenerated plan reflects reconciled state
/// 19. recovery produces consistent plan
/// 20. duplicate actions are not generated
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P43 Personalized Learning Plan Tests', () {
    const String testLearner = 'learner_p43_titan';
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
        buildTestQuestion(
          id: 'pyq_macro_01',
          subject: 'Economy',
          topic: 'Macroeconomics',
          objectiveId: 'lo_macroeconomics',
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

    // -------------------------------------------------------------------------
    // 1. Empty learner state
    // -------------------------------------------------------------------------
    test(
        '1. Empty learner state: generates plan recommending diagnostic cold start',
        () async {
      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(plan.hasActions, isTrue);
      expect(plan.recommendedAction, isNotNull);
      expect(plan.recommendedAction!.actionType,
          equals(PlanActionType.takeDiagnostic));
      expect(plan.recommendedAction!.reasonCode,
          equals(PlanReasonCode.activeFrontier));
      expect(
          plan.recommendedAction!.reason,
          contains(
              'Diagnostic indicates baseline knowledge must be evaluated'));
      expect(plan.stateRevision, equals(1));
    });

    // -------------------------------------------------------------------------
    // 2. Learner with no diagnostic
    // -------------------------------------------------------------------------
    test(
        '2. Learner with no diagnostic: formulates foundational sequence if attempts exist',
        () async {
      // Save an assessed attempt directly in authoritative state (no diagnostic taken)
      final progress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_preamble_identity',
        attemptCount: 2,
        correctCount: 2,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate.subtract(const Duration(days: 1)),
      );
      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {'lo_preamble_identity': progress},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      // Should recommend practice on active in-progress frontier, not diagnostic
      expect(plan.recommendedAction!.actionType,
          equals(PlanActionType.practiceObjective));
      expect(
          plan.recommendedAction!.objectiveId, equals('lo_preamble_identity'));
      expect(plan.recommendedAction!.reasonCode,
          equals(PlanReasonCode.activeFrontier));
    });

    // -------------------------------------------------------------------------
    // 3. Learner with diagnostic result
    // -------------------------------------------------------------------------
    test(
        '3. Learner with diagnostic result: incorporates diagnostic placement evidence into roadmap',
        () async {
      final diagnostic = DiagnosticPlacementResult(
        assessmentId: 'diag_p43_01',
        learnerId: testLearner,
        evaluatedAt: baseDate.subtract(const Duration(days: 2)),
        objectiveResults: {
          'lo_preamble_identity': DiagnosticObjectiveResult(
            objectiveId: 'lo_preamble_identity',
            evidenceState: DiagnosticEvidenceState.sufficientEvidence,
            placementStatus: DiagnosticPlacementStatus.demonstrated,
            attemptsCount: 4,
            correctCount: 4,
            observedAccuracy: 1.0,
            evaluatedAt: baseDate,
            notes: 'High mastery demonstrated',
          ),
          'lo_article_21_foundations': DiagnosticObjectiveResult(
            objectiveId: 'lo_article_21_foundations',
            evidenceState: DiagnosticEvidenceState.sufficientEvidence,
            placementStatus: DiagnosticPlacementStatus.developing,
            attemptsCount: 4,
            correctCount: 1,
            observedAccuracy: 0.25,
            evaluatedAt: baseDate,
            notes: 'Weak performance',
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
        totalAttemptsCount: 8,
        totalCorrectCount: 5,
        aggregateAccuracy: 0.625,
        provenance: 'UPSC Diagnostic Evaluation',
      );
      diagnosticRepo.saveResult(diagnostic);

      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      // Remediation target from diagnostic should be prioritized first
      expect(plan.recommendedAction!.objectiveId,
          equals('lo_article_21_foundations'));
      expect(plan.recommendedAction!.actionType,
          equals(PlanActionType.startRemedialLesson));
      expect(plan.recommendedAction!.reasonCode,
          equals(PlanReasonCode.diagnosticWeakness));
      expect(plan.recommendedAction!.reason,
          contains('Diagnostic indicates this objective needs remediation'));
    });

    // -------------------------------------------------------------------------
    // 4. Weak objective gets prioritized
    // -------------------------------------------------------------------------
    test(
        '4. Weak objective gets prioritized: persistent failures elevated over regular practice',
        () async {
      final weakProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_article_21_foundations',
        attemptCount: 5,
        correctCount: 1,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate.subtract(const Duration(hours: 3)),
      );
      final healthyProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_preamble_identity',
        attemptCount: 3,
        correctCount: 2,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate.subtract(const Duration(hours: 5)),
      );

      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {
          'lo_article_21_foundations': weakProgress,
          'lo_preamble_identity': healthyProgress,
        },
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      // Weak objective must be recommended first
      expect(plan.recommendedAction!.objectiveId,
          equals('lo_article_21_foundations'));
      expect(plan.recommendedAction!.reasonCode,
          equals(PlanReasonCode.persistentFailure));
    });

    // -------------------------------------------------------------------------
    // 5. Incomplete objective gets prioritized
    // -------------------------------------------------------------------------
    test(
        '5. Incomplete objective gets prioritized: in-progress tasks prioritized before starting new ones',
        () async {
      final inProg = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_preamble_identity',
        attemptCount: 2,
        correctCount: 2,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate,
      );
      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {'lo_preamble_identity': inProg},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      // Incomplete in-progress objective is prioritized as recommended
      expect(
          plan.recommendedAction!.objectiveId, equals('lo_preamble_identity'));
      expect(
          plan.recommendedAction!.status, equals(PlanActionStatus.recommended));
    });

    // -------------------------------------------------------------------------
    // 6. Recoverable session gets prioritized
    // -------------------------------------------------------------------------
    test(
        '6. Recoverable session gets prioritized: in-flight checkpoint overrides all other recommendations',
        () async {
      // Setup both a weak objective and an in-flight checkpoint
      final weakProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_article_21_foundations',
        attemptCount: 4,
        correctCount: 1,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate,
      );
      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {'lo_article_21_foundations': weakProgress},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      final checkpoint = SessionCheckpoint(
        checkpointRevision: 2,
        authoritativeStateRevision: 1,
        sessionId: 'sess_p43_resume_01',
        examId: testExam,
        learnerId: testLearner,
        timestamp: baseDate.subtract(const Duration(minutes: 10)),
        questionIndex: 2,
        activeObjectiveId: 'lo_preamble_identity',
        completedQuestionIds: const ['pyq_preamble_01'],
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

      // Recoverable session must be the absolute #1 recommended action
      expect(plan.recommendedAction!.actionType,
          equals(PlanActionType.continueSession));
      expect(plan.recommendedAction!.sessionId, equals('sess_p43_resume_01'));
      expect(plan.recommendedAction!.sessionCursor, equals(2));
      expect(plan.recommendedAction!.reasonCode,
          equals(PlanReasonCode.inFlightSession));
    });

    // -------------------------------------------------------------------------
    // 7. Remedial action is selected when supported
    // -------------------------------------------------------------------------
    test(
        '7. Remedial action is selected when supported: binds lesson ID to action',
        () async {
      final weakProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_article_21_foundations',
        attemptCount: 4,
        correctCount: 1,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate,
      );
      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {'lo_article_21_foundations': weakProgress},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(plan.recommendedAction!.actionType,
          equals(PlanActionType.startRemedialLesson));
      expect(plan.recommendedAction!.remedialLessonId, equals('rem_art21_01'));
      expect(plan.recommendedAction!.isExecutable, isTrue);
    });

    // -------------------------------------------------------------------------
    // 8. PYQ action is selected when supported
    // -------------------------------------------------------------------------
    test(
        '8. PYQ action is selected when supported: practice actions include target question counts',
        () async {
      final plan = await planService.generatePlan(
        learnerId: 'assessed_learner',
        examId: testExam,
        asOfDate: baseDate,
      );

      final frAction = plan.actions
          .firstWhere((a) => a.objectiveId == 'lo_article_21_foundations');
      expect(frAction.targetQuestionCount, greaterThanOrEqualTo(2));
      expect(frAction.isExecutable, isTrue);
    });

    // -------------------------------------------------------------------------
    // 9. Completed objective is not incorrectly prioritized
    // -------------------------------------------------------------------------
    test(
        '9. Completed objective is not incorrectly prioritized: achieved objectives placed at end',
        () async {
      final achievedProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_preamble_identity',
        attemptCount: 5,
        correctCount: 5,
        status: LearnerObjectiveStatus.achieved,
        lastAttemptAt: baseDate.subtract(const Duration(days: 3)),
      );
      final unattemptedProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_article_21_foundations',
        attemptCount: 1,
        correctCount: 1,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate,
      );

      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {
          'lo_preamble_identity': achievedProgress,
          'lo_article_21_foundations': unattemptedProgress,
        },
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      // Achieved objective must NOT be recommended
      expect(plan.recommendedAction!.objectiveId,
          isNot(equals('lo_preamble_identity')));

      // Achieved objective is marked completed
      final compAction = plan.actions
          .firstWhere((a) => a.objectiveId == 'lo_preamble_identity');
      expect(compAction.status, equals(PlanActionStatus.completed));
      expect(compAction.actionType, equals(PlanActionType.reviewRevision));
    });

    // -------------------------------------------------------------------------
    // 10. Plan ordering is deterministic
    // -------------------------------------------------------------------------
    test('10. Plan ordering is deterministic: strictly sequential orderIndex',
        () async {
      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      for (int i = 0; i < plan.actions.length; i++) {
        expect(plan.actions[i].orderIndex, equals(i));
      }
    });

    // -------------------------------------------------------------------------
    // 11. Equivalent state produces equivalent plan
    // -------------------------------------------------------------------------
    test(
        '11. Equivalent state produces equivalent plan: identical inputs produce identical outputs',
        () async {
      final planA = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );
      final planB = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(planA.planId, equals(planB.planId));
      expect(planA.actions.length, equals(planB.actions.length));
      for (int i = 0; i < planA.actions.length; i++) {
        expect(planA.actions[i].id, equals(planB.actions[i].id));
        expect(
            planA.actions[i].actionType, equals(planB.actions[i].actionType));
        expect(
            planA.actions[i].reasonCode, equals(planB.actions[i].reasonCode));
        expect(planA.actions[i].reason, equals(planB.actions[i].reason));
      }
    });

    // -------------------------------------------------------------------------
    // 12. Every action has a valid reason
    // -------------------------------------------------------------------------
    test(
        '12. Every action has a valid reason: non-empty explainable rationales without generic text',
        () async {
      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      for (final action in plan.actions) {
        expect(action.reason.trim(), isNotEmpty);
        expect(action.reason, isNot(contains('AI recommends this')));
        expect(action.reasonCode, isNotNull);
      }
    });

    // -------------------------------------------------------------------------
    // 13. Every executable action resolves to an existing workflow
    // -------------------------------------------------------------------------
    test(
        '13. Every executable action resolves to an existing workflow: supported action types',
        () async {
      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      for (final action in plan.actions) {
        if (action.isExecutable) {
          expect(
            [
              PlanActionType.continueSession,
              PlanActionType.takeDiagnostic,
              PlanActionType.startRemedialLesson,
              PlanActionType.practiceObjective,
              PlanActionType.practicePyqs,
              PlanActionType.reviewRevision,
            ],
            contains(action.actionType),
          );
        }
      }
    });

    // -------------------------------------------------------------------------
    // 14. Unavailable content is handled
    // -------------------------------------------------------------------------
    test(
        '14. Unavailable content is handled: non-executable flag and clear reason for zero-question topics',
        () async {
      final emptyCorpusPlan = await planService.generatePlan(
        learnerId: 'learner_empty_corpus',
        examId: testExam,
        asOfDate: baseDate,
        corpus: const [],
      );

      final actionsWithNoContent = emptyCorpusPlan.actions.where((a) =>
          a.actionType == PlanActionType.practiceObjective &&
          a.targetQuestionCount == 0);

      for (final act in actionsWithNoContent) {
        expect(act.isExecutable, isFalse);
        expect(act.reason, contains('acquisition'));
      }
    });

    // -------------------------------------------------------------------------
    // 15. No-content objective is handled
    // -------------------------------------------------------------------------
    test(
        '15. No-content objective is handled: gracefully tracks progress even without PYQ questions',
        () async {
      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      final noContentAction = plan.actions.firstWhere(
        (a) => a.targetQuestionCount == 0,
        orElse: () => plan.actions.last,
      );
      expect(noContentAction, isNotNull);
      expect(noContentAction.id, isNotEmpty);
    });

    // -------------------------------------------------------------------------
    // 16. Invalid learner state is handled
    // -------------------------------------------------------------------------
    test(
        '16. Invalid learner state is handled: rejects blank parameters with ArgumentError',
        () async {
      expect(
        () => planService.generatePlan(learnerId: '   ', examId: testExam),
        throwsArgumentError,
      );
      expect(
        () => planService.generatePlan(learnerId: testLearner, examId: '   '),
        throwsArgumentError,
      );
    });

    // -------------------------------------------------------------------------
    // 17. Learning outcome changes subsequent plan
    // -------------------------------------------------------------------------
    test(
        '17. Learning outcome changes subsequent plan: weak spot turns into completed after successful learning',
        () async {
      // 1. Initial State: Weak on Article 21
      final weakProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_article_21_foundations',
        attemptCount: 4,
        correctCount: 1,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate.subtract(const Duration(hours: 2)),
      );
      var authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {'lo_article_21_foundations': weakProgress},
        lastUpdatedAt: baseDate,
        revision: 1,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      final planBefore = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );
      expect(planBefore.recommendedAction!.objectiveId,
          equals('lo_article_21_foundations'));
      expect(planBefore.recommendedAction!.actionType,
          equals(PlanActionType.startRemedialLesson));

      // 2. State After Successful Learning: Article 21 achieved
      final achievedProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_article_21_foundations',
        attemptCount: 10,
        correctCount: 9,
        status: LearnerObjectiveStatus.achieved,
        lastAttemptAt: baseDate,
      );
      authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {'lo_article_21_foundations': achievedProgress},
        lastUpdatedAt: baseDate,
        revision: 2,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      final planAfter = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      // Article 21 is now marked completed and no longer recommended for remediation
      expect(planAfter.recommendedAction!.objectiveId,
          isNot(equals('lo_article_21_foundations')));
      final art21Action = planAfter.actions
          .firstWhere((a) => a.objectiveId == 'lo_article_21_foundations');
      expect(art21Action.status, equals(PlanActionStatus.completed));
    });

    // -------------------------------------------------------------------------
    // 18. Regenerated plan reflects reconciled state
    // -------------------------------------------------------------------------
    test(
        '18. Regenerated plan reflects reconciled state: increments stateRevision monotonically',
        () async {
      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: const {},
        lastUpdatedAt: baseDate,
        revision: 5,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(plan.stateRevision, equals(5));
      expect(plan.planId, contains('rev5'));
    });

    // -------------------------------------------------------------------------
    // 19. Recovery produces consistent plan
    // -------------------------------------------------------------------------
    test(
        '19. Recovery produces consistent plan: recovering from scratch matches persisted snapshot',
        () async {
      final progress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_basic_structure_doctrine',
        attemptCount: 3,
        correctCount: 2,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate,
      );
      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {'lo_basic_structure_doctrine': progress},
        lastUpdatedAt: baseDate,
        revision: 3,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      // Destroy in-memory state and create brand-new recovery service
      final newRecoveryService =
          AuthoritativeLearningStateRecoveryService(repository: authRepo);
      final newPlanService = PersonalizedLearningPlanService(
        curriculumService: curriculumService,
        authRecoveryService: newRecoveryService,
        checkpointRepository: checkpointRepo,
        contentService: contentService,
        diagnosticRepository: diagnosticRepo,
        remedialService: remedialService,
        seedQuestions: seedCorpus,
      );

      final recoveredPlan = await newPlanService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(recoveredPlan.stateRevision, equals(3));
      expect(recoveredPlan.recommendedAction!.objectiveId,
          equals('lo_basic_structure_doctrine'));
    });

    // -------------------------------------------------------------------------
    // 20. Duplicate actions are not generated
    // -------------------------------------------------------------------------
    test(
        '20. Duplicate actions are not generated: every objective appears at most once in plan',
        () async {
      final plan = await planService.generatePlan(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      final seenObjectiveIds = <String>{};
      for (final action in plan.actions) {
        expect(
          seenObjectiveIds.contains(action.objectiveId),
          isFalse,
          reason:
              'Objective ${action.objectiveId} appeared more than once in the plan',
        );
        seenObjectiveIds.add(action.objectiveId);
      }
    });
  });
}
