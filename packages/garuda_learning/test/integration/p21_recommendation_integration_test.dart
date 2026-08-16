import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P21 End-to-End Learning Loop Integration Tests', () {
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryProgressRepository progressRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryReviewScheduleRepository reviewScheduleRepo;
    late SpacedRepetitionService spacedRepetitionService;
    late InMemoryLearnerRepository learnerRepo;
    late ProgressTracker progressTracker;
    late SessionManager sessionManager;
    late AssessmentService assessmentService;
    late LearningSessionOrchestrator sessionOrchestrator;
    late AdaptiveRecommendationService recommendationService;

    setUp(() {
      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
      progressRepo = InMemoryProgressRepository();
      attemptRepo = InMemoryAttemptRepository();
      reviewScheduleRepo = InMemoryReviewScheduleRepository();
      spacedRepetitionService =
          SpacedRepetitionService(repository: reviewScheduleRepo);
      learnerRepo = InMemoryLearnerRepository();

      progressTracker = ProgressTracker(
        attemptRepository: attemptRepo,
        progressRepository: progressRepo,
        thresholdConfig: const AssessmentThresholdConfig(
          minimumAttempts: 2,
          minimumSuccessRate: 0.80,
        ),
      );

      sessionManager = SessionManager(
        learnerRepository: learnerRepo,
      );

      assessmentService = AssessmentService(
        learnerRepository: learnerRepo,
        attemptRepository: attemptRepo,
        curriculumService: curriculumService,
        progressTracker: progressTracker,
        sessionManager: sessionManager,
      );

      sessionOrchestrator = LearningSessionOrchestrator(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        assessmentService: assessmentService,
        sessionManager: sessionManager,
        attemptRepository: attemptRepo,
        progressTracker: progressTracker,
      );

      recommendationService = AdaptiveRecommendationService(
        curriculumService: curriculumService,
        progressRepository: progressRepo,
        attemptRepository: attemptRepo,
        spacedRepetitionService: spacedRepetitionService,
      );
    });

    test('full multi-phase lifecycle from cold start to spaced review loop',
        () async {
      const learnerId = 'e2e_learner_1';
      final t0 = DateTime.utc(2026, 8, 16, 9, 0, 0);

      // 1. Register learner
      final learner = Learner(id: learnerId, name: 'Aspirant Rahul');
      learnerRepo.save(learner);

      // 2. Step 1: Initial recommendation on cold start
      final initialQueue = await recommendationService.generateRecommendations(
        learnerId: learnerId,
        asOfDate: t0,
      );
      expect(initialQueue.isNotEmpty, isTrue);
      final initialTop = initialQueue.topRecommendation!;
      expect(initialTop.objectiveId, equals('lo_preamble_identity'));
      expect(initialTop.type, equals(RecommendationType.curriculumAdvance));

      // 3. Step 2: Feed recommended SessionConfiguration into P19 Orchestrator
      final session =
          sessionOrchestrator.createSession(initialTop.suggestedConfig);
      sessionOrchestrator.startSession(session.sessionId);

      // 4. Step 3: Learner practices and answers questions
      final q1 = sessionOrchestrator.getCurrentQuestion(session.sessionId);
      expect(q1, isNotNull);

      // Submit 5 correct attempts to satisfy assessment threshold
      for (int i = 1; i <= 5; i++) {
        final attempt = QuestionAttempt(
          attemptId: 'att_$i',
          learnerId: learnerId,
          questionId: q1!.questionId,
          objectiveId: 'lo_preamble_identity',
          submittedAnswer: 'Exact match',
        );
        attemptRepo.saveAttempt(attempt);
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_$i',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }
      progressTracker.updateProgress(
        learnerId: learnerId,
        objectiveId: 'lo_preamble_identity',
      );

      final progressObj1 =
          progressRepo.getProgress(learnerId, 'lo_preamble_identity');
      expect(progressObj1?.status, equals(LearnerObjectiveStatus.achieved));

      // 5. Step 4: Schedule in P20 Spaced Repetition
      await spacedRepetitionService.addToSchedule(
        learnerId,
        'lo_preamble_identity',
        now: t0,
      );

      // 6. Step 5: Fast forward 5 days -> lo_preamble_identity is now overdue for review
      final t1 = t0.add(const Duration(days: 5));
      final updatedQueue = await recommendationService.generateRecommendations(
        learnerId: learnerId,
        asOfDate: t1,
      );

      expect(updatedQueue.isNotEmpty, isTrue);

      // Overdue review should now be prioritized
      final reviewRec = updatedQueue.items.firstWhere(
        (r) => r.objectiveId == 'lo_preamble_identity',
      );
      expect(reviewRec.type, equals(RecommendationType.spacedReview));
      expect(reviewRec.suggestedConfig.selectionPolicy,
          equals(QuestionSelectionPolicy.balanced));

      // Downstream objective 'lo_basic_structure_doctrine' is now unblocked
      final nextRec = updatedQueue.items.firstWhere(
        (r) => r.objectiveId == 'lo_basic_structure_doctrine',
      );
      expect(nextRec.type, equals(RecommendationType.curriculumAdvance));
    });
  });
}
