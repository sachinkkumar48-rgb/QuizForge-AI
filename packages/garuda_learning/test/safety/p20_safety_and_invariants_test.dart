import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P20 Safety & Invariants Tests (TITAN-KO-020.0 P20)', () {
    final now = DateTime.utc(2026, 8, 14, 12, 0);

    test('1. PerformanceRating mapping & score boundary clamping', () {
      expect(PerformanceRating.fromScore(1.0), PerformanceRating.easy);
      expect(PerformanceRating.fromScore(0.80), PerformanceRating.easy);
      expect(PerformanceRating.fromScore(0.79), PerformanceRating.good);
      expect(PerformanceRating.fromScore(0.60), PerformanceRating.good);
      expect(PerformanceRating.fromScore(0.59), PerformanceRating.hard);
      expect(PerformanceRating.fromScore(0.40), PerformanceRating.hard);
      expect(PerformanceRating.fromScore(0.39), PerformanceRating.again);
      expect(PerformanceRating.fromScore(0.00), PerformanceRating.again);

      // Out of bounds score clamping
      expect(PerformanceRating.fromScore(99.0), PerformanceRating.easy);
      expect(PerformanceRating.fromScore(-5.0), PerformanceRating.again);
    });

    test('2. ReviewResult validation & factory construction', () {
      final res = ReviewResult.fromScore(
        objectiveId: 'obj_fr_art21',
        score: 0.85,
        timestamp: now,
      );

      expect(res.objectiveId, 'obj_fr_art21');
      expect(res.rating, PerformanceRating.easy);
      expect(res.assessmentScore, 0.85);
      expect(res.timestamp, now);

      final json = res.toJson();
      final restored = ReviewResult.fromJson(json);
      expect(restored, equals(res));
    });

    test('3. ReviewItem interval and ease factor boundary clamping invariants',
        () {
      final itemHigh = ReviewItem(
        objectiveId: 'obj_001',
        intervalDays: 999,
        easeFactor: 9.9,
        nextReviewDate: now,
      );
      expect(itemHigh.intervalDays, 180);
      expect(itemHigh.easeFactor, 2.5);

      final itemLow = ReviewItem(
        objectiveId: 'obj_001',
        intervalDays: -10,
        easeFactor: 0.1,
        nextReviewDate: now,
      );
      expect(itemLow.intervalDays, 1);
      expect(itemLow.easeFactor, 1.3);
    });

    test('4. ReviewSchedule aggregate invariants & duplicate rejection', () {
      final item1 = ReviewItem.initial('obj_001', now: now);
      var schedule = ReviewSchedule(learnerId: 'learner_p20', createdAt: now);

      schedule = schedule.addItem(item1);
      expect(schedule.containsObjective('obj_001'), isTrue);

      // Duplicate addItem throws ArgumentError
      expect(
        () => schedule.addItem(item1),
        throwsArgumentError,
      );

      // Updating item works
      final updatedItem = item1.copyWith(intervalDays: 5);
      schedule = schedule.updateItem(updatedItem);
      expect(schedule.getItem('obj_001')!.intervalDays, 5);

      // Removing item works
      schedule = schedule.removeItem('obj_001');
      expect(schedule.containsObjective('obj_001'), isFalse);
    });

    test('5. InMemoryReviewScheduleRepository persistence lifecycle', () async {
      final repo = InMemoryReviewScheduleRepository();
      expect(await repo.getSchedule('learner_101'), isNull);

      final item = ReviewItem.initial('obj_001', now: now);
      await repo.saveReviewItem('learner_101', item);

      final fetchedItem = await repo.getReviewItem('learner_101', 'obj_001');
      expect(fetchedItem, equals(item));

      final schedule = await repo.getSchedule('learner_101');
      expect(schedule, isNotNull);
      expect(schedule!.itemCount, 1);

      await repo.clear();
      expect(await repo.getSchedule('learner_101'), isNull);
    });

    test('6. First review interval determination (reviewCount == 0)', () {
      final service = SpacedRepetitionService();
      final item = ReviewItem.initial('obj_001', now: now);

      // Hard (q=3) on initial review -> interval 1
      final resHard = service.calculateNextState(
        item: item,
        result: ReviewResult(
          objectiveId: 'obj_001',
          rating: PerformanceRating.hard,
          assessmentScore: 0.5,
          timestamp: now,
        ),
        now: now,
      );
      expect(resHard.intervalDays, 1);

      // Good (q=4) on initial review -> interval 3
      final resGood = service.calculateNextState(
        item: item,
        result: ReviewResult(
          objectiveId: 'obj_001',
          rating: PerformanceRating.good,
          assessmentScore: 0.7,
          timestamp: now,
        ),
        now: now,
      );
      expect(resGood.intervalDays, 3);

      // Easy (q=5) on initial review -> interval 4
      final resEasy = service.calculateNextState(
        item: item,
        result: ReviewResult(
          objectiveId: 'obj_001',
          rating: PerformanceRating.easy,
          assessmentScore: 0.9,
          timestamp: now,
        ),
        now: now,
      );
      expect(resEasy.intervalDays, 4);
    });

    test(
        '7 & 8. Successful recall (q>=3) vs Failed recall (q<3) interval reset',
        () {
      final service = SpacedRepetitionService();
      final currentItem = ReviewItem(
        objectiveId: 'obj_001',
        intervalDays: 30,
        easeFactor: 2.2,
        nextReviewDate: now,
        reviewCount: 3,
      );

      // Fail (Again, q=2) -> reset interval to 1 day
      final failedState = service.calculateNextState(
        item: currentItem,
        result: ReviewResult(
          objectiveId: 'obj_001',
          rating: PerformanceRating.again,
          assessmentScore: 0.2,
          timestamp: now,
        ),
        now: now,
      );
      expect(failedState.intervalDays, 1);
      expect(failedState.reviewCount, 4);

      // Success (Good, q=4) -> interval grows by EF'
      final successState = service.calculateNextState(
        item: currentItem,
        result: ReviewResult(
          objectiveId: 'obj_001',
          rating: PerformanceRating.good,
          assessmentScore: 0.7,
          timestamp: now,
        ),
        now: now,
      );
      expect(successState.intervalDays, greaterThan(30));
    });

    test('9. Hard vs Good vs Easy multipliers on subsequent reviews', () {
      final service = SpacedRepetitionService();
      final item = ReviewItem(
        objectiveId: 'obj_001',
        intervalDays: 10,
        easeFactor: 2.0,
        nextReviewDate: now,
        reviewCount: 2,
      );

      // Hard (q=3): 10 * 1.2 = 12
      final hardState = service.calculateNextState(
        item: item,
        result: ReviewResult(
          objectiveId: 'obj_001',
          rating: PerformanceRating.hard,
          assessmentScore: 0.5,
          timestamp: now,
        ),
        now: now,
      );
      expect(hardState.intervalDays, 12);

      // Good (q=4): 10 * EF' = 10 * 2.0 = 20
      final goodState = service.calculateNextState(
        item: item,
        result: ReviewResult(
          objectiveId: 'obj_001',
          rating: PerformanceRating.good,
          assessmentScore: 0.7,
          timestamp: now,
        ),
        now: now,
      );
      expect(goodState.intervalDays, 20);

      // Easy (q=5): 10 * EF' * 1.3 = 10 * 2.1 * 1.3 = 27
      final easyState = service.calculateNextState(
        item: item,
        result: ReviewResult(
          objectiveId: 'obj_001',
          rating: PerformanceRating.easy,
          assessmentScore: 0.9,
          timestamp: now,
        ),
        now: now,
      );
      expect(easyState.intervalDays, 27);
    });

    test('10, 11 & 12. Ease factor calculation and clamping [1.3, 2.5]', () {
      final service = SpacedRepetitionService();

      // EF upper clamp check (EF starts at 2.5, q=5 gives delta +0.10 => 2.6 => clamped to 2.5)
      final itemMax = ReviewItem.initial('obj_001', now: now);
      final resMax = service.calculateNextState(
        item: itemMax,
        result: ReviewResult(
          objectiveId: 'obj_001',
          rating: PerformanceRating.easy,
          assessmentScore: 1.0,
          timestamp: now,
        ),
        now: now,
      );
      expect(resMax.easeFactor, 2.5);

      // EF lower clamp check (EF starts at 1.3, q=2 gives delta -0.32 => 0.98 => clamped to 1.3)
      final itemMin = ReviewItem(
        objectiveId: 'obj_001',
        intervalDays: 1,
        easeFactor: 1.3,
        nextReviewDate: now,
      );
      final resMin = service.calculateNextState(
        item: itemMin,
        result: ReviewResult(
          objectiveId: 'obj_001',
          rating: PerformanceRating.again,
          assessmentScore: 0.1,
          timestamp: now,
        ),
        now: now,
      );
      expect(resMin.easeFactor, 1.3);
    });

    test('13 & 14. Interval lower clamp (1 day) and upper clamp (180 days)',
        () {
      final service = SpacedRepetitionService();

      // Lower clamp
      final itemLow = ReviewItem.initial('obj_001', now: now);
      final resLow = service.calculateNextState(
        item: itemLow,
        result: ReviewResult(
          objectiveId: 'obj_001',
          rating: PerformanceRating.again,
          assessmentScore: 0.0,
          timestamp: now,
        ),
        now: now,
      );
      expect(resLow.intervalDays, 1);

      // Upper clamp (100 days * 2.5 * 1.3 = 325 days => clamped to 180)
      final itemHigh = ReviewItem(
        objectiveId: 'obj_001',
        intervalDays: 100,
        easeFactor: 2.5,
        nextReviewDate: now,
        reviewCount: 5,
      );
      final resHigh = service.calculateNextState(
        item: itemHigh,
        result: ReviewResult(
          objectiveId: 'obj_001',
          rating: PerformanceRating.easy,
          assessmentScore: 1.0,
          timestamp: now,
        ),
        now: now,
      );
      expect(resHigh.intervalDays, 180);
    });
  });
}
