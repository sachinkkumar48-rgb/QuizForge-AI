import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P43 Mastery-Driven Learning Progression Integration Tests', () {
    const String testLearner = 'learner_p43_lifecycle';
    const String testExam = 'upsc_prelims_gs1';
    final baseDate = DateTime.utc(2026, 9, 8, 12, 0, 0);

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
    late MasteryProgressionService progressionService;

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
        normalizedText: 'Question stem for $id',
        originalText: 'Original text for $id',
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
      remedialRepo.saveLesson(
        RemedialLesson(
          lessonId: 'rem_art21_01',
          objectiveId: 'lo_article_21_foundations',
          title: 'Article 21: Life and Personal Liberty Micro-Lesson',
          summary: 'Review foundational expansion of Article 21 rights.',
          learningPoints: const ['Substantive due process evolution'],
          explanation: 'Detailed explanation of Article 21 rights.',
          estimatedMinutes: 8,
          authoredAt: baseDate,
        ),
      );
      remedialRepo.saveLesson(
        RemedialLesson(
          lessonId: 'rem_bs_01',
          objectiveId: 'lo_basic_structure_doctrine',
          title: 'Basic Structure Doctrine Remedial Micro-Lesson',
          summary: 'Limits of constitutional amending power under Article 368.',
          learningPoints: const ['Kesavananda Bharati framework'],
          explanation: 'Detailed analysis of basic structure limits.',
          estimatedMinutes: 10,
          authoredAt: baseDate,
        ),
      );

      remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );
      diagnosticRepo = InMemoryDiagnosticPlacementRepository();

      contentService = ContentLearningPathService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
      );

      seedCorpus = [
        buildTestQuestion(
          id: 'q_art21_01',
          subject: 'Indian Polity',
          topic: 'Fundamental Rights',
          objectiveId: 'lo_article_21_foundations',
        ),
        buildTestQuestion(
          id: 'q_bs_01',
          subject: 'Indian Polity',
          topic: 'Basic Structure',
          objectiveId: 'lo_basic_structure_doctrine',
        ),
        buildTestQuestion(
          id: 'q_preamble_01',
          subject: 'Indian Polity',
          topic: 'Preamble',
          objectiveId: 'lo_preamble_identity',
        ),
      ];

      progressionService = MasteryProgressionService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        contentService: contentService,
        diagnosticRepository: diagnosticRepo,
        remedialService: remedialService,
        seedQuestions: seedCorpus,
      );
    });

    test('1. Full Closed-Loop: Cold Start -> Failure -> Remediation Priority -> Practice -> Mastery -> Priority Shift', () async {
      // Step A: Cold start check
      final qCold = await progressionService.resolvePriorityQueue(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );
      expect(qCold.currentPriority, isNotNull);
      expect(qCold.currentPriority!.action, PriorityActionType.takeDiagnostic);
      expect(qCold.currentPriority!.stage, ProgressionStage.notStarted);

      // Step B: Practice session completed with persistent failure on Article 21
      // 6 attempts, 1 correct (16.7% accuracy)
      final stateFailure = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate.add(const Duration(minutes: 30)),
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 6,
            correctCount: 1,
            status: LearnerObjectiveStatus.inProgress,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 5,
            correctCount: 3,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateFailure));

      // Step C: Queue resolves - Article 21 requires remediation and points to remedial lesson
      final qRem = await progressionService.resolvePriorityQueue(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate.add(const Duration(minutes: 30)),
      );
      expect(qRem.currentPriority, isNotNull);
      expect(qRem.currentPriority!.objectiveId, 'lo_article_21_foundations');
      expect(qRem.currentPriority!.stage, ProgressionStage.remediationRequired);
      expect(qRem.currentPriority!.action, PriorityActionType.startRemedialLesson);
      expect(qRem.currentPriority!.remedialLessonId, 'rem_art21_01');
      expect(qRem.currentPriority!.isExecutable, isTrue);

      // Step D: Learner studies remedial lesson and completes targeted reinforcement practice
      // Total 12 attempts, 11 correct (91.7% accuracy -> Mastered)
      final stateMastered = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        lastUpdatedAt: baseDate.add(const Duration(hours: 2)),
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 12,
            correctCount: 11,
            status: LearnerObjectiveStatus.achieved,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 5,
            correctCount: 3,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateMastered));

      // Step E: Queue resolves - Prerequisite foundational concept lo_preamble_identity takes priority
      final qNext = await progressionService.resolvePriorityQueue(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate.add(const Duration(hours: 2)),
      );
      expect(qNext.currentPriority, isNotNull);
      expect(qNext.currentPriority!.objectiveId, 'lo_preamble_identity');
      expect(qNext.currentPriority!.action, PriorityActionType.practice);

      // Article 21 is now mastered and relegated to spaced review
      final art21Item = qNext.items.firstWhere((i) => i.objectiveId == 'lo_article_21_foundations');
      expect(art21Item.stage, ProgressionStage.mastered);
      expect(art21Item.action, PriorityActionType.reviewRevision);
      expect(art21Item.priorityRank, greaterThan(qNext.currentPriority!.priorityRank));
    });

    test('2. Regression & Remediation Loop: Mastery -> Accuracy Drop -> Regressed Priority -> Remediation', () async {
      // Step A: Initially mastered objective
      final statePrior = AuthoritativeLearnerState(
        learnerId: 'learner_regress_test',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'learner_regress_test',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(statePrior));

      final qInit = await progressionService.resolvePriorityQueue(
        learnerId: 'learner_regress_test',
        examId: testExam,
        asOfDate: baseDate,
      );
      final bsInit = qInit.items.firstWhere((i) => i.objectiveId == 'lo_basic_structure_doctrine');
      expect(bsInit.stage, ProgressionStage.mastered);
      expect(bsInit.action, PriorityActionType.reviewRevision);

      // Step B: Accuracy drops in subsequent mock exam (e.g. 10 attempts, 3 correct)
      final stateDropped = AuthoritativeLearnerState(
        learnerId: 'learner_regress_test',
        examId: testExam,
        revision: 2,
        lastUpdatedAt: baseDate.add(const Duration(days: 3)),
        progressMap: {
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'learner_regress_test',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 10,
            correctCount: 3,
            status: LearnerObjectiveStatus.achieved, // Was previously achieved!
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateDropped));

      final qRegressed = await progressionService.resolvePriorityQueue(
        learnerId: 'learner_regress_test',
        examId: testExam,
        asOfDate: baseDate.add(const Duration(days: 3)),
      );
      final bsReg = qRegressed.items.firstWhere((i) => i.objectiveId == 'lo_basic_structure_doctrine');
      expect(bsReg.stage, ProgressionStage.regressed);
      expect(bsReg.action, PriorityActionType.practice);
      expect(qRegressed.currentPriority!.objectiveId, 'lo_basic_structure_doctrine');
    });

    test('3. Multi-Learner Concurrency: Distinct states produce independent personalized priorities', () async {
      final stateLearner1 = AuthoritativeLearnerState(
        learnerId: 'learner_alpha',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_alpha',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 6,
            correctCount: 1,
            status: LearnerObjectiveStatus.inProgress,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'learner_alpha',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );
      final stateLearner2 = AuthoritativeLearnerState(
        learnerId: 'learner_beta',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'learner_beta',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'learner_beta',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 6,
            correctCount: 1,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );

      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateLearner1));
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateLearner2));

      final q1 = await progressionService.resolvePriorityQueue(
        learnerId: 'learner_alpha',
        examId: testExam,
        asOfDate: baseDate,
      );
      final q2 = await progressionService.resolvePriorityQueue(
        learnerId: 'learner_beta',
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(q1.currentPriority!.objectiveId, 'lo_article_21_foundations');
      expect(q2.currentPriority!.objectiveId, 'lo_basic_structure_doctrine');
      expect(q1.items.firstWhere((i) => i.objectiveId == 'lo_article_21_foundations').stage, ProgressionStage.remediationRequired);
      expect(q2.items.firstWhere((i) => i.objectiveId == 'lo_article_21_foundations').stage, ProgressionStage.mastered);
    });
  });
}
