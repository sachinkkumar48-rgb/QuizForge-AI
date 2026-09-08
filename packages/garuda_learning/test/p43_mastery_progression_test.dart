import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P43 Mastery-Driven Personalized Learning Progression Tests', () {
    const testExam = 'upsc_prelims_gs1';
    final baseDate = DateTime.utc(2026, 9, 8, 10, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late AuthoritativeLearningStateRecoveryService recoveryService;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late ContentLearningPathService contentService;
    late InMemoryDiagnosticPlacementRepository diagnosticRepo;
    late InMemoryRemedialLessonRepository remedialRepo;
    late DeterministicRemedialLessonService remedialService;
    late List<NormalizedQuestion> testCorpus;
    late MasteryProgressionService service;

    NormalizedQuestion buildTestQuestion({
      required String id,
      required String subject,
      required String topic,
      required String objectiveId,
    }) {
      return NormalizedQuestion(
        id: id,
        examId: testExam,
        paper: 'GS1',
        subject: subject,
        topic: topic,
        year: 2024,
        normalizedText: 'Question stem for $id',
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
      recoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );
      checkpointRepo = InMemorySessionCheckpointRepository();
      diagnosticRepo = InMemoryDiagnosticPlacementRepository();
      remedialRepo = InMemoryRemedialLessonRepository();
      remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );

      // Populate remedial lessons
      remedialRepo.saveLesson(
        RemedialLesson(
          lessonId: 'lesson_fr_remedial',
          objectiveId: 'lo_article_21_foundations',
          title: 'Article 21: Life and Personal Liberty Micro-Lesson',
          summary: 'Review foundational expansion of Article 21 rights.',
          learningPoints: const ['Procedure established by law vs due process'],
          explanation: 'Detailed micro-lesson on Article 21.',
          estimatedMinutes: 10,
          authoredAt: baseDate,
        ),
      );

      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
      contentService = ContentLearningPathService(
        curriculumService: curriculumService,
        authRecoveryService: recoveryService,
        checkpointRepository: checkpointRepo,
      );

      testCorpus = [
        buildTestQuestion(
          id: 'q_polity_01',
          subject: 'Indian Polity',
          topic: 'Fundamental Rights',
          objectiveId: 'lo_article_21_foundations',
        ),
        buildTestQuestion(
          id: 'q_polity_02',
          subject: 'Indian Polity',
          topic: 'Basic Structure',
          objectiveId: 'lo_basic_structure_doctrine',
        ),
      ];

      service = MasteryProgressionService(
        curriculumService: curriculumService,
        authRecoveryService: recoveryService,
        checkpointRepository: checkpointRepo,
        contentService: contentService,
        diagnosticRepository: diagnosticRepo,
        remedialService: remedialService,
        seedQuestions: testCorpus,
      );
    });

    // -------------------------------------------------------------------------
    // 1. New Learner (Cold Start)
    // -------------------------------------------------------------------------
    test('1. New learner triggers diagnostic placement recommendation', () async {
      final queue = await service.resolvePriorityQueue(
        learnerId: 'new_learner_01',
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(queue.isEmpty, isFalse);
      expect(queue.currentPriority, isNotNull);
      expect(queue.currentPriority!.action, PriorityActionType.takeDiagnostic);
      expect(queue.currentPriority!.priorityRank, 1);
      expect(queue.currentPriority!.reason, contains('Diagnostic indicates baseline knowledge'));
    });

    // -------------------------------------------------------------------------
    // 2. Insufficient Evidence (< 3 attempts)
    // -------------------------------------------------------------------------
    test('2. Insufficient evidence classified accurately', () {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_sparse',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_sparse',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 2,
            correctCount: 2,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );

      final decision = service.evaluateObjective(
        objectiveId: 'lo_article_21_foundations',
        authState: state,
      );

      expect(decision.stage, ProgressionStage.insufficientEvidence);
      expect(decision.masteryStatus, ObjectiveMasteryStatus.insufficientEvidence);
      expect(decision.isAdditionalPracticeAppropriate, isTrue);
      expect(decision.canProgress, isFalse);
      expect(decision.rationale, contains('Insufficient evidence'));
    });

    // -------------------------------------------------------------------------
    // 3. Weak Objective (< 50% accuracy with >= 3 attempts)
    // -------------------------------------------------------------------------
    test('3. Weak objective classified as remediation required', () {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_weak',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_weak',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 6,
            correctCount: 2,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );

      final decision = service.evaluateObjective(
        objectiveId: 'lo_article_21_foundations',
        authState: state,
      );

      expect(decision.stage, ProgressionStage.remediationRequired);
      expect(decision.masteryStatus, ObjectiveMasteryStatus.remediationRequired);
      expect(decision.isRemediationRequired, isTrue);
      expect(decision.canProgress, isFalse);
      expect(decision.rationale, contains('Persistent difficulty observed'));
    });

    // -------------------------------------------------------------------------
    // 4. Improving Objective (65% to 79% accuracy)
    // -------------------------------------------------------------------------
    test('4. Improving objective classified with positive trend', () {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_improving',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_improving',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 7,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );

      final decision = service.evaluateObjective(
        objectiveId: 'lo_article_21_foundations',
        authState: state,
      );

      expect(decision.stage, ProgressionStage.improving);
      expect(decision.masteryStatus, ObjectiveMasteryStatus.inProgress);
      expect(decision.isRemediationRequired, isFalse);
      expect(decision.isAdditionalPracticeAppropriate, isTrue);
      expect(decision.rationale, contains('Steady progress demonstrated'));
    });

    // -------------------------------------------------------------------------
    // 5. Mastered Objective (>= 80% accuracy with >= 5 attempts)
    // -------------------------------------------------------------------------
    test('5. Mastered objective classified with revision scheduled', () {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_master',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_master',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final decision = service.evaluateObjective(
        objectiveId: 'lo_article_21_foundations',
        authState: state,
      );

      expect(decision.stage, ProgressionStage.mastered);
      expect(decision.masteryStatus, ObjectiveMasteryStatus.mastered);
      expect(decision.canProgress, isTrue);
      expect(decision.isRevisionAppropriate, isTrue);
      expect(decision.isRemediationRequired, isFalse);
    });

    // -------------------------------------------------------------------------
    // 6. Remediation-Required Objective
    // -------------------------------------------------------------------------
    test('6. Diagnostic target maps to remediation required', () {
      final diag = DiagnosticPlacementResult(
        assessmentId: 'diag_test_01',
        learnerId: 'learner_diag',
        evaluatedAt: baseDate,
        totalAssessedObjectives: 1,
        demonstratedObjectivesCount: 0,
        totalAttemptsCount: 5,
        totalCorrectCount: 1,
        aggregateAccuracy: 0.2,
        provenance: 'test',
        frontier: DiagnosticPlacementFrontier(
          demonstratedObjectiveIds: [],
          activeFrontierObjectiveIds: [],
          developingObjectiveIds: [],
          remediationTargetObjectiveIds: ['lo_article_21_foundations'],
          unassessedObjectiveIds: [],
        ),
        objectiveResults: const {},
      );

      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_diag',
        examId: testExam,
        createdAt: baseDate,
      );

      final decision = service.evaluateObjective(
        objectiveId: 'lo_article_21_foundations',
        authState: state,
        diagnosticResult: diag,
      );

      expect(decision.stage, ProgressionStage.remediationRequired);
      expect(decision.masteryStatus, ObjectiveMasteryStatus.remediationRequired);
      expect(decision.isRemediationRequired, isTrue);
    });

    // -------------------------------------------------------------------------
    // 7. Regressed Objective
    // -------------------------------------------------------------------------
    test('7. Regressed objective detected when accuracy drops after achievement', () {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_regressed',
        examId: testExam,
        revision: 2,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_regressed',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 4,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );

      // Artificially evaluate after prior achieved status
      final diagPrior = DiagnosticPlacementResult(
        assessmentId: 'diag_prev',
        learnerId: 'learner_regressed',
        evaluatedAt: baseDate.subtract(const Duration(days: 5)),
        totalAssessedObjectives: 1,
        demonstratedObjectivesCount: 1,
        totalAttemptsCount: 10,
        totalCorrectCount: 9,
        aggregateAccuracy: 0.9,
        provenance: 'test',
        frontier: DiagnosticPlacementFrontier(
          demonstratedObjectiveIds: ['lo_article_21_foundations'],
          activeFrontierObjectiveIds: [],
          developingObjectiveIds: [],
          remediationTargetObjectiveIds: [],
          unassessedObjectiveIds: [],
        ),
        objectiveResults: const {},
      );

      final decision = service.evaluateObjective(
        objectiveId: 'lo_article_21_foundations',
        authState: state,
        diagnosticResult: diagPrior,
      );

      expect(decision.stage, ProgressionStage.regressed);
      expect(decision.masteryStatus, ObjectiveMasteryStatus.regressed);
      expect(decision.isRemediationRequired, isTrue);
      expect(decision.rationale, contains('Performance dropped'));
    });

    // -------------------------------------------------------------------------
    // 8. Multiple Objectives With Different Mastery
    // -------------------------------------------------------------------------
    test('8. Multiple objectives correctly evaluated in batch', () {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_multi',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_multi',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'learner_multi',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 6,
            correctCount: 2,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );

      final allDecisions = service.evaluateAllObjectives(authState: state);

      expect(allDecisions['lo_article_21_foundations']!.stage, ProgressionStage.mastered);
      expect(allDecisions['lo_basic_structure_doctrine']!.stage, ProgressionStage.remediationRequired);
      expect(allDecisions.length, greaterThanOrEqualTo(2));
    });

    // -------------------------------------------------------------------------
    // 9. Priority Ordering
    // -------------------------------------------------------------------------
    test('9. Priority ordering orders weak before improving before revision', () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_prio_test',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_prio_test',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'learner_prio_test',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 6,
            correctCount: 2,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final queue = await service.resolvePriorityQueue(
        learnerId: 'learner_prio_test',
        examId: testExam,
        asOfDate: baseDate,
      );

      final basicItem = queue.items.firstWhere((i) => i.objectiveId == 'lo_basic_structure_doctrine');
      final art21Item = queue.items.firstWhere((i) => i.objectiveId == 'lo_article_21_foundations');

      expect(basicItem.priorityRank, lessThan(art21Item.priorityRank));
      expect(queue.currentPriority!.objectiveId, 'lo_basic_structure_doctrine');
    });

    // -------------------------------------------------------------------------
    // 10. Deterministic Ordering
    // -------------------------------------------------------------------------
    test('10. Equivalent state produces identical priority rankings', () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_det',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_det',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 8,
            correctCount: 5,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final q1 = await service.resolvePriorityQueue(
        learnerId: 'learner_det',
        examId: testExam,
        asOfDate: baseDate,
      );
      final q2 = await service.resolvePriorityQueue(
        learnerId: 'learner_det',
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(q1.items.length, q2.items.length);
      for (var i = 0; i < q1.items.length; i++) {
        expect(q1.items[i].id, q2.items[i].id);
        expect(q1.items[i].priorityRank, q2.items[i].priorityRank);
        expect(q1.items[i].action, q2.items[i].action);
      }
    });

    // -------------------------------------------------------------------------
    // 11. Learner A vs Learner B Different Priorities
    // -------------------------------------------------------------------------
    test('11. Learner A vs Learner B get inverse priorities based on mastery', () async {
      // Learner A: Article 21 weak, Basic Structure mastered
      final stateA = AuthoritativeLearnerState(
        learnerId: 'learner_A',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_A',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 6,
            correctCount: 1,
            status: LearnerObjectiveStatus.inProgress,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'learner_A',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateA));

      // Learner B: Article 21 mastered, Basic Structure weak
      final stateB = AuthoritativeLearnerState(
        learnerId: 'learner_B',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_B',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'learner_B',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 6,
            correctCount: 1,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateB));

      final queueA = await service.resolvePriorityQueue(
        learnerId: 'learner_A',
        examId: testExam,
        asOfDate: baseDate,
      );
      final queueB = await service.resolvePriorityQueue(
        learnerId: 'learner_B',
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(queueA.currentPriority!.objectiveId, 'lo_article_21_foundations');
      expect(queueB.currentPriority!.objectiveId, 'lo_basic_structure_doctrine');
    });

    // -------------------------------------------------------------------------
    // 12. Active Session Takes Precedence
    // -------------------------------------------------------------------------
    test('12. Active session checkpoint preempts all other priority tiers', () async {
      await checkpointRepo.saveCheckpoint(
        SessionCheckpoint(
          sessionId: 'sess_active_01',
          learnerId: 'learner_checkpoint',
          examId: testExam,
          checkpointRevision: 1,
          authoritativeStateRevision: 1,
          activeObjectiveId: 'lo_basic_structure_doctrine',
          questionIndex: 2,
          completedQuestionIds: const ['q1', 'q2'],
          timestamp: baseDate,
          isCompleted: false,
          metadata: const {'topic': 'Basic Structure', 'totalQuestions': 5},
        ),
      );

      final queue = await service.resolvePriorityQueue(
        learnerId: 'learner_checkpoint',
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(queue.currentPriority, isNotNull);
      expect(queue.currentPriority!.action, PriorityActionType.continueSession);
      expect(queue.currentPriority!.sessionId, 'sess_active_01');
      expect(queue.currentPriority!.priorityRank, 1);
    });

    // -------------------------------------------------------------------------
    // 13. Weak Objective Beats Mastered Objective
    // -------------------------------------------------------------------------
    test('13. Weak objective strictly beats mastered objective in priority', () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_comp',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_comp',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'learner_comp',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 5,
            correctCount: 1,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final queue = await service.resolvePriorityQueue(
        learnerId: 'learner_comp',
        examId: testExam,
        asOfDate: baseDate,
      );

      final weakRank = queue.items.firstWhere((i) => i.objectiveId == 'lo_basic_structure_doctrine').priorityRank;
      final masterRank = queue.items.firstWhere((i) => i.objectiveId == 'lo_article_21_foundations').priorityRank;

      expect(weakRank, lessThan(masterRank));
    });

    // -------------------------------------------------------------------------
    // 14. Prerequisite Handling Where Supported
    // -------------------------------------------------------------------------
    test('14. Unmet prerequisite flags objective decision appropriately', () {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_prereq',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: const {}, // No objectives completed
      );

      // Objective with prerequisite
      final advancedObj = framework.allObjectives.firstWhere(
        (o) => o.prerequisites.isNotEmpty,
        orElse: () => framework.allObjectives.first,
      );

      final decision = service.evaluateObjective(
        objectiveId: advancedObj.id,
        authState: state,
      );

      if (advancedObj.prerequisites.isNotEmpty) {
        expect(decision.hasUnmetPrerequisites, isTrue);
        expect(decision.unmetPrerequisiteIds, isNotEmpty);
        expect(decision.canProgress, isFalse);
      }
    });

    // -------------------------------------------------------------------------
    // 15. PYQ Availability Affects Executable Action
    // -------------------------------------------------------------------------
    test('15. Content availability correctly reflects in isExecutable flag', () async {
      final queue = await service.resolvePriorityQueue(
        learnerId: 'learner_content',
        examId: testExam,
        asOfDate: baseDate,
      );

      for (final item in queue.items) {
        if (!item.isAvailable && item.action != PriorityActionType.startRemedialLesson) {
          expect(item.isExecutable, isFalse);
        }
      }
    });

    // -------------------------------------------------------------------------
    // 16. Remediation Availability Affects Action
    // -------------------------------------------------------------------------
    test('16. Remediation action assigns remedialLessonId when lesson is available', () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_rem_check',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_rem_check',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 6,
            correctCount: 1,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final queue = await service.resolvePriorityQueue(
        learnerId: 'learner_rem_check',
        examId: testExam,
        asOfDate: baseDate,
      );

      final remItem = queue.items.firstWhere((i) => i.objectiveId == 'lo_article_21_foundations');
      expect(remItem.action, PriorityActionType.startRemedialLesson);
      expect(remItem.remedialLessonId, 'lesson_fr_remedial');
    });

    // -------------------------------------------------------------------------
    // 17. Completed Objective Does Not Appear as Active Learning
    // -------------------------------------------------------------------------
    test('17. Mastered objective assigned reviewRevision rather than active practice', () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_done',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_done',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 10,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final queue = await service.resolvePriorityQueue(
        learnerId: 'learner_done',
        examId: testExam,
        asOfDate: baseDate,
      );

      final item = queue.items.firstWhere((i) => i.objectiveId == 'lo_article_21_foundations');
      expect(item.action, PriorityActionType.reviewRevision);
    });

    // -------------------------------------------------------------------------
    // 18. Practice Completion Changes Evidence
    // -------------------------------------------------------------------------
    test('18. Updating authoritative state alters recorded evidence and accuracy', () async {
      final initialDecision = service.evaluateObjective(
        objectiveId: 'lo_article_21_foundations',
        authState: AuthoritativeLearnerState.empty(
          learnerId: 'learner_ev',
          examId: testExam,
          createdAt: baseDate,
        ),
      );
      expect(initialDecision.evidenceCount, 0);

      final updatedState = AuthoritativeLearnerState(
        learnerId: 'learner_ev',
        examId: testExam,
        revision: 2,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_ev',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 5,
            correctCount: 4,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final updatedDecision = service.evaluateObjective(
        objectiveId: 'lo_article_21_foundations',
        authState: updatedState,
      );

      expect(updatedDecision.evidenceCount, 5);
      expect(updatedDecision.correctCount, 4);
      expect(updatedDecision.successRate, 0.80);
    });

    // -------------------------------------------------------------------------
    // 19. Mastery Recalculates After Completion
    // -------------------------------------------------------------------------
    test('19. Mastery stage updates from developing to mastered upon achieving threshold', () {
      final beforeState = AuthoritativeLearnerState(
        learnerId: 'learner_trans',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_trans',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 4,
            correctCount: 2,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      final beforeDecision = service.evaluateObjective(
        objectiveId: 'lo_article_21_foundations',
        authState: beforeState,
      );
      expect(beforeDecision.stage, ProgressionStage.learning);

      final afterState = AuthoritativeLearnerState(
        learnerId: 'learner_trans',
        examId: testExam,
        revision: 2,
        lastUpdatedAt: baseDate.add(const Duration(minutes: 15)),
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_trans',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );
      final afterDecision = service.evaluateObjective(
        objectiveId: 'lo_article_21_foundations',
        authState: afterState,
      );
      expect(afterDecision.stage, ProgressionStage.mastered);
    });

    // -------------------------------------------------------------------------
    // 20. Priority Recalculates After Completion (Closed-Loop Priority Shift)
    // -------------------------------------------------------------------------
    test('20. Priority shifts dynamically when top priority objective reaches mastery', () async {
      // Step 1: Article 21 is weak, Basic Structure is learning
      final state1 = AuthoritativeLearnerState(
        learnerId: 'learner_shift',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_shift',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 6,
            correctCount: 1,
            status: LearnerObjectiveStatus.inProgress,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'learner_shift',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 5,
            correctCount: 3,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(state1));

      final queue1 = await service.resolvePriorityQueue(
        learnerId: 'learner_shift',
        examId: testExam,
        asOfDate: baseDate,
      );
      expect(queue1.currentPriority!.objectiveId, 'lo_article_21_foundations');

      // Step 2: Practice completed on Article 21 -> Mastered
      final state2 = AuthoritativeLearnerState(
        learnerId: 'learner_shift',
        examId: testExam,
        revision: 2,
        lastUpdatedAt: baseDate.add(const Duration(hours: 1)),
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_shift',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 12,
            correctCount: 11,
            status: LearnerObjectiveStatus.achieved,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'learner_shift',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 5,
            correctCount: 3,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(state2));

      final queue2 = await service.resolvePriorityQueue(
        learnerId: 'learner_shift',
        examId: testExam,
        asOfDate: baseDate.add(const Duration(hours: 1)),
      );

      // Now Basic Structure must become current priority!
      expect(queue2.currentPriority!.objectiveId, 'lo_basic_structure_doctrine');
    });

    // -------------------------------------------------------------------------
    // 21. Persistence/Recovery Preserves Equivalent Result
    // -------------------------------------------------------------------------
    test('21. Serialized recovery maintains identical queue output', () async {
      final state = AuthoritativeLearnerState(
        learnerId: 'learner_persist',
        examId: testExam,
        revision: 3,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_persist',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 8,
            correctCount: 6,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final queue = await service.resolvePriorityQueue(
        learnerId: 'learner_persist',
        examId: testExam,
        asOfDate: baseDate,
      );

      final jsonMap = queue.toJson();
      expect(jsonMap['learnerId'], 'learner_persist');
      expect(jsonMap['stateRevision'], 3);
      expect((jsonMap['items'] as List).isNotEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // 22. Invalid State Validation
    // -------------------------------------------------------------------------
    test('22. Throws ArgumentError when learnerId or examId is empty', () async {
      expect(
        () => service.resolvePriorityQueue(learnerId: '', examId: testExam),
        throwsArgumentError,
      );
      expect(
        () => service.resolvePriorityQueue(learnerId: 'l1', examId: ''),
        throwsArgumentError,
      );
    });

    // -------------------------------------------------------------------------
    // 23. Empty Curriculum Handling
    // -------------------------------------------------------------------------
    test('23. Handles empty framework gracefully', () async {
      final emptyCurriculum = CurriculumService(
        framework: CurriculumFramework(
          id: 'empty_fw',
          version: CurriculumVersion(
            version: '1.0.0',
            effectiveDate: '2026-08-15',
            provenance: 'test',
          ),
          title: 'Empty Framework',
          description: 'Empty Description',
          provenance: 'test',
          domains: [],
        ),
      );
      final emptyService = MasteryProgressionService(
        curriculumService: emptyCurriculum,
        authRecoveryService: recoveryService,
        checkpointRepository: checkpointRepo,
      );

      final queue = await emptyService.resolvePriorityQueue(
        learnerId: 'learner_empty',
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(queue.items.isEmpty, isTrue);
      expect(queue.currentPriority, isNull);
    });

    // -------------------------------------------------------------------------
    // 24. Unavailable Content
    // -------------------------------------------------------------------------
    test('24. Content without questions marks isExecutable appropriately', () async {
      final emptyContentService = ContentLearningPathService(
        curriculumService: curriculumService,
        authRecoveryService: recoveryService,
        checkpointRepository: checkpointRepo,
      );
      final serviceNoContent = MasteryProgressionService(
        curriculumService: curriculumService,
        authRecoveryService: recoveryService,
        checkpointRepository: checkpointRepo,
        contentService: emptyContentService,
        seedQuestions: const [], // Empty questions
      );

      final queue = await serviceNoContent.resolvePriorityQueue(
        learnerId: 'learner_nocontent',
        examId: testExam,
        asOfDate: baseDate,
      );

      final remaining = queue.items.where((i) => i.action == PriorityActionType.practice);
      for (final item in remaining) {
        expect(item.isAvailable, isFalse);
      }
    });

    // -------------------------------------------------------------------------
    // 25. Service Resilience / Failure Isolation
    // -------------------------------------------------------------------------
    test('25. Recovers safely with empty state when recovery returns null', () async {
      final queue = await service.resolvePriorityQueue(
        learnerId: 'unrecorded_learner',
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(queue.stateRevision, 1);
      expect(queue.currentPriority, isNotNull);
    });

    // -------------------------------------------------------------------------
    // 26. Duplicate Queue Entries Prevented
    // -------------------------------------------------------------------------
    test('26. Guarantees no duplicate objective appearances in the queue', () async {
      await checkpointRepo.saveCheckpoint(
        SessionCheckpoint(
          sessionId: 'cp_dup',
          learnerId: 'learner_dup',
          examId: testExam,
          checkpointRevision: 1,
          authoritativeStateRevision: 1,
          activeObjectiveId: 'lo_article_21_foundations',
          questionIndex: 1,
          completedQuestionIds: const ['q1'],
          timestamp: baseDate,
          isCompleted: false,
        ),
      );

      final queue = await service.resolvePriorityQueue(
        learnerId: 'learner_dup',
        examId: testExam,
        asOfDate: baseDate,
      );

      final seenObjIds = <String>{};
      for (final item in queue.items) {
        expect(seenObjIds.contains(item.objectiveId), isFalse,
            reason: 'Duplicate objective ${item.objectiveId} found in queue');
        seenObjIds.add(item.objectiveId);
      }
    });
  });
}
