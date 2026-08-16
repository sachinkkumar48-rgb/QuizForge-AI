import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('AdaptiveRecommendationService Tests', () {
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryProgressRepository progressRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryReviewScheduleRepository reviewScheduleRepo;
    late SpacedRepetitionService spacedRepetitionService;
    late InMemoryRecommendationRepository recRepo;
    late AdaptiveRecommendationService service;

    setUp(() {
      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
      progressRepo = InMemoryProgressRepository();
      attemptRepo = InMemoryAttemptRepository();
      reviewScheduleRepo = InMemoryReviewScheduleRepository();
      spacedRepetitionService =
          SpacedRepetitionService(repository: reviewScheduleRepo);
      recRepo = InMemoryRecommendationRepository();

      service = AdaptiveRecommendationService(
        curriculumService: curriculumService,
        progressRepository: progressRepo,
        attemptRepository: attemptRepo,
        spacedRepetitionService: spacedRepetitionService,
        recommendationRepository: recRepo,
      );
    });

    test(
        'cold-start learner receives curriculumAdvance recommendations for root objective',
        () async {
      final now = DateTime.utc(2026, 8, 16, 12, 0, 0);
      final queue = await service.generateRecommendations(
        learnerId: 'new_learner_1',
        asOfDate: now,
      );

      expect(queue.isNotEmpty, isTrue);
      final top = queue.topRecommendation;
      expect(top, isNotNull);
      // 'lo_preamble_identity' has no prerequisites, so it should be available for curriculum advancement
      expect(top?.objectiveId, equals('lo_preamble_identity'));
      expect(top?.type, equals(RecommendationType.curriculumAdvance));
      expect(top?.suggestedConfig.selectionPolicy,
          equals(QuestionSelectionPolicy.unattemptedOnly));
      expect(top?.suggestedConfig.sequencerPolicy,
          equals(QuestionSequencerPolicy.curriculumOrder));
      expect(top?.priorityScore, greaterThan(0.0));
      expect(top?.priorityScore, lessThanOrEqualTo(1.0));
    });

    test(
        'spacedReview strategy activates when objective has overdue P20 review',
        () async {
      final asOf = DateTime.utc(2026, 8, 16, 12, 0, 0);
      const learnerId = 'review_learner';
      const objectiveId = 'lo_preamble_identity';

      // Mark objective achieved
      progressRepo.saveProgress(LearnerProgress(
        learnerId: learnerId,
        objectiveId: objectiveId,
        attemptCount: 10,
        correctCount: 9,
        successRate: 0.90,
        status: LearnerObjectiveStatus.achieved,
      ));

      // Add to schedule with overdue date (due 3 days ago)
      final reviewItem = ReviewItem(
        objectiveId: objectiveId,
        intervalDays: 1,
        easeFactor: 2.5,
        nextReviewDate: asOf.subtract(const Duration(days: 3)),
      );
      await reviewScheduleRepo.saveReviewItem(learnerId, reviewItem);

      final rec = await service.evaluateObjective(
        learnerId: learnerId,
        objectiveId: objectiveId,
        asOfDate: asOf,
      );

      expect(rec, isNotNull);
      expect(rec?.type, equals(RecommendationType.spacedReview));
      expect(rec?.suggestedConfig.selectionPolicy,
          equals(QuestionSelectionPolicy.balanced));
      expect(rec?.suggestedConfig.sequencerPolicy,
          equals(QuestionSequencerPolicy.difficultyAscending));
      expect(rec?.rationale.contains('overdue'), isTrue);
      expect(rec?.metadata['overdueHours'], greaterThan(0));
    });

    test('prerequisiteGap strategy prioritizes unachieved blocker objective',
        () async {
      final asOf = DateTime.utc(2026, 8, 16, 12, 0, 0);
      const learnerId = 'gap_learner';

      // 'lo_preamble_identity' blocks 'lo_basic_structure_doctrine'
      // Both are unachieved, but lo_preamble_identity is a prerequisite
      final rec = await service.evaluateObjective(
        learnerId: learnerId,
        objectiveId: 'lo_preamble_identity',
        asOfDate: asOf,
      );

      expect(rec, isNotNull);
      expect(rec?.metadata['sPrereq'], greaterThan(0.0));
      expect(rec?.metadata['blockedCount'], greaterThanOrEqualTo(1));
    });

    test('weakDomainRemediation enforces minimum 3 attempts cold-start guard',
        () async {
      final asOf = DateTime.utc(2026, 8, 16, 12, 0, 0);
      const learnerId = 'weak_learner';
      const objectiveId = 'lo_preamble_identity';

      // Case A: 0 attempts -> G_weak MUST be 0.0
      var rec = await service.evaluateObjective(
        learnerId: learnerId,
        objectiveId: objectiveId,
        asOfDate: asOf,
      );
      expect(rec?.metadata['gWeak'], equals(0.0));

      // Case B: 2 attempts with 0% accuracy (< minDomainAttempts: 3) -> G_weak MUST still be 0.0
      for (int i = 1; i <= 2; i++) {
        final attempt = QuestionAttempt(
          attemptId: 'att_$i',
          learnerId: learnerId,
          questionId: 'q_$i',
          objectiveId: objectiveId,
          submittedAnswer: 'wrong',
        );
        attemptRepo.saveAttempt(attempt);
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_$i',
          isCorrect: false,
          score: 0.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }

      rec = await service.evaluateObjective(
        learnerId: learnerId,
        objectiveId: objectiveId,
        asOfDate: asOf,
      );
      expect(rec?.metadata['gWeak'], equals(0.0),
          reason: '2 attempts is below minDomainAttempts=3');

      // Case C: 4 attempts with 0% accuracy (>= minDomainAttempts: 3) -> G_weak MUST be > 0.0
      for (int i = 3; i <= 4; i++) {
        final attempt = QuestionAttempt(
          attemptId: 'att_$i',
          learnerId: learnerId,
          questionId: 'q_$i',
          objectiveId: objectiveId,
          submittedAnswer: 'wrong',
        );
        attemptRepo.saveAttempt(attempt);
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_$i',
          isCorrect: false,
          score: 0.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }

      rec = await service.evaluateObjective(
        learnerId: learnerId,
        objectiveId: objectiveId,
        asOfDate: asOf,
      );
      expect(rec?.metadata['gWeak'], greaterThan(0.0),
          reason: '4 attempts with 0% accuracy triggers weak domain');
      expect(rec?.metadata['domainAttempts'], equals(4));
      expect(rec?.metadata['domainAccuracy'], equals(0.0));
    });

    test('policy filters by targetUnitId and enforces maxRecommendations',
        () async {
      final asOf = DateTime.utc(2026, 8, 16, 12, 0, 0);
      const policy = RecommendationPolicy(
        targetUnitId: 'unit_preamble_and_basic_structure',
        maxRecommendations: 1,
      );

      final queue = await service.generateRecommendations(
        learnerId: 'filter_learner',
        policy: policy,
        asOfDate: asOf,
      );

      expect(queue.length, equals(1));
      expect(queue.items.first.objectiveId,
          anyOf('lo_preamble_identity', 'lo_basic_structure_doctrine'));
    });
  });
}
