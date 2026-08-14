import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('SpacedRepetitionService Unit Tests (TITAN-KO-020.0 P20)', () {
    late InMemoryReviewScheduleRepository repository;
    late SpacedRepetitionService service;
    final now = DateTime.utc(2026, 8, 14, 12, 0);

    setUp(() {
      repository = InMemoryReviewScheduleRepository();
      service = SpacedRepetitionService(repository: repository);
    });

    test('addToSchedule initializes new item with 1-day interval', () async {
      final item =
          await service.addToSchedule('learner_101', 'obj_001', now: now);

      expect(item.objectiveId, 'obj_001');
      expect(item.intervalDays, 1);
      expect(item.easeFactor, 2.5);
      expect(item.reviewCount, 0);

      final schedule = await service.getSchedule('learner_101');
      expect(schedule, isNotNull);
      expect(schedule!.itemCount, 1);
    });

    test('updateAfterReview with Easy score (1.0) increases interval and EF',
        () async {
      await service.addToSchedule('learner_101', 'obj_001', now: now);

      final updated = await service.updateAfterReview(
        learnerId: 'learner_101',
        objectiveId: 'obj_001',
        assessmentScore: 1.0,
        timestamp: now,
      );

      expect(updated.reviewCount, 1);
      expect(updated.intervalDays, 4); // Easy boost on first attempt
      expect(updated.easeFactor, 2.5); // Clamped max 2.5
      expect(updated.lastReviewed, now);
      expect(updated.nextReviewDate, DateTime.utc(2026, 8, 18, 12, 0));
    });

    test(
        'updateAfterReview with Good score (0.75) applies standard SM-2 growth',
        () async {
      await service.addToSchedule('learner_101', 'obj_001', now: now);

      final updated1 = await service.updateAfterReview(
        learnerId: 'learner_101',
        objectiveId: 'obj_001',
        assessmentScore: 0.75, // Good
        timestamp: now,
      );

      expect(updated1.intervalDays, 3);
      expect(updated1.reviewCount, 1);

      final t2 = DateTime.utc(2026, 8, 17, 12, 0);
      final updated2 = await service.updateAfterReview(
        learnerId: 'learner_101',
        objectiveId: 'obj_001',
        assessmentScore: 0.75, // Good
        timestamp: t2,
      );

      expect(updated2.intervalDays, (3 * updated1.easeFactor).round());
      expect(updated2.reviewCount, 2);
    });

    test('updateAfterReview with Again score (0.2) resets interval to 1 day',
        () async {
      final initialItem = ReviewItem(
        objectiveId: 'obj_001',
        intervalDays: 14,
        easeFactor: 2.3,
        nextReviewDate: now,
        reviewCount: 3,
      );
      await repository.saveReviewItem('learner_101', initialItem);

      final updated = await service.updateAfterReview(
        learnerId: 'learner_101',
        objectiveId: 'obj_001',
        assessmentScore: 0.2, // Again
        timestamp: now,
      );

      expect(updated.intervalDays, 1);
      expect(updated.reviewCount, 4);
      expect(updated.easeFactor, lessThan(2.3));
    });

    test('calculateNextState is purely deterministic', () {
      final item = ReviewItem.initial('obj_001', now: now);
      final result = ReviewResult.fromScore(
        objectiveId: 'obj_001',
        score: 0.85,
        timestamp: now,
      );

      final res1 =
          service.calculateNextState(item: item, result: result, now: now);
      final res2 =
          service.calculateNextState(item: item, result: result, now: now);

      expect(res1, equals(res2));
    });

    test('getDueItems returns items due as of cutoff date', () async {
      await service.addToSchedule('learner_101', 'obj_001', now: now);

      final dueNow = await service.getDueItems('learner_101', asOf: now);
      expect(dueNow, isEmpty);

      final dueTomorrow = await service.getDueItems(
        'learner_101',
        asOf: DateTime.utc(2026, 8, 15, 12, 0),
      );
      expect(dueTomorrow.length, 1);
      expect(dueTomorrow.first.objectiveId, 'obj_001');
    });
  });
}
