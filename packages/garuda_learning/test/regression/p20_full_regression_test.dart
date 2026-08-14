import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('TITAN-KO-020.0 P20 Full Regression & Integration Test Suite', () {
    late InMemoryReviewScheduleRepository repo;
    late SpacedRepetitionService service;
    final baseTime = DateTime.utc(2026, 8, 14, 12, 0);

    setUp(() {
      repo = InMemoryReviewScheduleRepository();
      service = SpacedRepetitionService(repository: repo);
    });

    test('15. Multi-step repeated review progression over virtual time',
        () async {
      // Step 1: Initial creation at T0
      var item = await service.addToSchedule('learner_200', 'lo_fr_art21',
          now: baseTime);
      expect(item.intervalDays, 1);
      expect(item.reviewCount, 0);

      // Step 2: Day 1 review with Good score (0.75)
      final t1 = baseTime.add(const Duration(days: 1));
      item = await service.updateAfterReview(
        learnerId: 'learner_200',
        objectiveId: 'lo_fr_art21',
        assessmentScore: 0.75,
        timestamp: t1,
      );
      expect(item.reviewCount, 1);
      expect(item.intervalDays, 3);
      expect(item.lastReviewed, t1);

      // Step 3: Day 4 review with Easy score (0.95)
      final t4 = t1.add(const Duration(days: 3));
      item = await service.updateAfterReview(
        learnerId: 'learner_200',
        objectiveId: 'lo_fr_art21',
        assessmentScore: 0.95,
        timestamp: t4,
      );
      expect(item.reviewCount, 2);
      expect(item.intervalDays, (3 * item.easeFactor * 1.3).round());

      // Step 4: Next review fails (0.10) -> resets interval to 1
      final tNext = t4.add(Duration(days: item.intervalDays));
      item = await service.updateAfterReview(
        learnerId: 'learner_200',
        objectiveId: 'lo_fr_art21',
        assessmentScore: 0.10,
        timestamp: tNext,
      );
      expect(item.reviewCount, 3);
      expect(item.intervalDays, 1);
    });

    test(
        '16 & 17 & 18. Due item detection, deterministic ordering & objectiveId tie-breaking',
        () async {
      final tAsOf = baseTime.add(const Duration(days: 5));

      // Schedule 3 items with distinct overdue timestamps
      final itemA = ReviewItem(
        objectiveId: 'obj_AAA',
        intervalDays: 1,
        easeFactor: 2.5,
        nextReviewDate: baseTime.add(const Duration(days: 2)), // 3 days overdue
      );
      final itemB = ReviewItem(
        objectiveId: 'obj_BBB',
        intervalDays: 1,
        easeFactor: 2.5,
        nextReviewDate: baseTime
            .add(const Duration(days: 1)), // 4 days overdue (most overdue)
      );
      final itemC = ReviewItem(
        objectiveId: 'obj_CCC',
        intervalDays: 1,
        easeFactor: 2.5,
        nextReviewDate: baseTime.add(const Duration(
            days: 2)), // 3 days overdue (same priority as obj_AAA)
      );

      await repo.saveReviewItem('learner_300', itemA);
      await repo.saveReviewItem('learner_300', itemB);
      await repo.saveReviewItem('learner_300', itemC);

      final dueItems = await service.getDueItems('learner_300', asOf: tAsOf);
      expect(dueItems.length, 3);

      // Most overdue first (obj_BBB)
      expect(dueItems[0].objectiveId, 'obj_BBB');

      // Tie-breaking by lexical objectiveId ('obj_AAA' before 'obj_CCC')
      expect(dueItems[1].objectiveId, 'obj_AAA');
      expect(dueItems[2].objectiveId, 'obj_CCC');
    });

    test(
        '19. Missing-data behavior (non-existent learner & unscheduled objective auto-creation)',
        () async {
      // Non-existent learner schedule returns empty list
      final emptyDue =
          await service.getDueItems('unknown_learner', asOf: baseTime);
      expect(emptyDue, isEmpty);

      // Updating an unscheduled objective auto-initializes it first
      final item = await service.updateAfterReview(
        learnerId: 'learner_400',
        objectiveId: 'unscheduled_lo_001',
        assessmentScore: 0.85,
        timestamp: baseTime,
      );

      expect(item.objectiveId, 'unscheduled_lo_001');
      expect(item.reviewCount, 1);
      expect(item.intervalDays, 4);
    });

    test('20. Offline behavior & serialization determinism', () {
      final item = ReviewItem.initial('lo_fr_art19', now: baseTime);
      final schedule = ReviewSchedule(
        learnerId: 'learner_500',
        items: {'lo_fr_art19': item},
        createdAt: baseTime,
        updatedAt: baseTime,
      );

      // Verify full JSON serialization and deserialization
      final json = schedule.toJson();
      final restored = ReviewSchedule.fromJson(json);

      expect(restored.learnerId, 'learner_500');
      expect(restored.getItem('lo_fr_art19'), equals(item));
      expect(restored, equals(schedule));
    });

    test('21, 22 & 23. P17, P18 and P19 Integration Compatibility', () async {
      // P17 Objective reference
      const p17ObjectiveId = 'lo_fr_art21';

      // P18 AttemptResult scoring event simulation
      final p18AttemptResult = AttemptResult(
        attemptId: 'att_101',
        isCorrect: true,
        score: 0.85,
        evaluatedAt: baseTime,
        evaluationMethod: EvaluationMethod.multipleChoice,
        feedback: 'Correct choice',
      );

      // Feed P18 result score into P20 SpacedRepetitionService
      final p20ReviewItem = await service.updateAfterReview(
        learnerId: 'learner_integration',
        objectiveId: p17ObjectiveId,
        assessmentScore: p18AttemptResult.score,
        timestamp: p18AttemptResult.evaluatedAt,
      );

      expect(p20ReviewItem.objectiveId, p17ObjectiveId);
      expect(p20ReviewItem.reviewCount, 1);
      expect(p20ReviewItem.intervalDays, 4);

      // P19 Queue Retrieval simulation as of review date
      final p19ReviewQueue = await service.getDueItems(
        'learner_integration',
        asOf: p20ReviewItem.nextReviewDate,
      );

      expect(p19ReviewQueue.length, 1);
      expect(p19ReviewQueue.first.objectiveId, p17ObjectiveId);
    });
  });
}
