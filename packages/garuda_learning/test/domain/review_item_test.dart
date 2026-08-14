import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('PerformanceRating Domain Tests (TITAN-KO-020.0 P20)', () {
    test('PerformanceRating.fromScore maps score thresholds deterministically',
        () {
      expect(PerformanceRating.fromScore(1.0), PerformanceRating.easy);
      expect(PerformanceRating.fromScore(0.85), PerformanceRating.easy);
      expect(PerformanceRating.fromScore(0.80), PerformanceRating.easy);

      expect(PerformanceRating.fromScore(0.79), PerformanceRating.good);
      expect(PerformanceRating.fromScore(0.65), PerformanceRating.good);
      expect(PerformanceRating.fromScore(0.60), PerformanceRating.good);

      expect(PerformanceRating.fromScore(0.59), PerformanceRating.hard);
      expect(PerformanceRating.fromScore(0.45), PerformanceRating.hard);
      expect(PerformanceRating.fromScore(0.40), PerformanceRating.hard);

      expect(PerformanceRating.fromScore(0.39), PerformanceRating.again);
      expect(PerformanceRating.fromScore(0.10), PerformanceRating.again);
      expect(PerformanceRating.fromScore(0.0), PerformanceRating.again);
    });

    test('PerformanceRating clamps out-of-bounds scores safely', () {
      expect(PerformanceRating.fromScore(1.5), PerformanceRating.easy);
      expect(PerformanceRating.fromScore(-0.5), PerformanceRating.again);
    });
  });

  group('ReviewItem & ReviewSchedule Domain Tests (TITAN-KO-020.0 P20)', () {
    final now = DateTime.utc(2026, 8, 14, 12, 0);

    test('ReviewItem.initial sets 1-day interval and 2.5 ease factor', () {
      final item = ReviewItem.initial('obj_const_001', now: now);

      expect(item.objectiveId, 'obj_const_001');
      expect(item.intervalDays, 1);
      expect(item.easeFactor, 2.5);
      expect(item.nextReviewDate, DateTime.utc(2026, 8, 15, 12, 0));
      expect(item.lastReviewed, isNull);
      expect(item.reviewCount, 0);
      expect(item.createdAt, now);
    });

    test('ReviewItem constructor clamps bounds correctly', () {
      final item = ReviewItem(
        objectiveId: 'obj_const_002',
        intervalDays: 500, // Clamped to 180
        easeFactor: 5.0, // Clamped to 2.5
        nextReviewDate: now,
      );

      expect(item.intervalDays, 180);
      expect(item.easeFactor, 2.5);

      final itemLow = ReviewItem(
        objectiveId: 'obj_const_002',
        intervalDays: 0, // Clamped to 1
        easeFactor: 0.5, // Clamped to 1.3
        nextReviewDate: now,
      );

      expect(itemLow.intervalDays, 1);
      expect(itemLow.easeFactor, 1.3);
    });

    test('ReviewItem isDue evaluates against cutoff date correctly', () {
      final item = ReviewItem.initial('obj_const_001', now: now);

      expect(item.isDue(asOfDate: now), isFalse);
      expect(item.isDue(asOfDate: DateTime.utc(2026, 8, 15, 12, 0)), isTrue);
      expect(item.isDue(asOfDate: DateTime.utc(2026, 8, 16, 12, 0)), isTrue);
    });

    test('ReviewItem serialization round-trip (toJson / fromJson)', () {
      final item = ReviewItem.initial('obj_const_001', now: now);
      final json = item.toJson();
      final restored = ReviewItem.fromJson(json);

      expect(restored, equals(item));
    });

    test('ReviewSchedule aggregates items and sorts due items by priority', () {
      var schedule = ReviewSchedule(
        learnerId: 'learner_101',
        createdAt: now,
        updatedAt: now,
      );

      final item1 = ReviewItem(
        objectiveId: 'obj_001',
        intervalDays: 1,
        easeFactor: 2.5,
        nextReviewDate:
            DateTime.utc(2026, 8, 14, 10, 0), // 2 hours overdue at 12:00
      );

      final item2 = ReviewItem(
        objectiveId: 'obj_002',
        intervalDays: 1,
        easeFactor: 2.5,
        nextReviewDate: DateTime.utc(2026, 8, 14, 12, 0), // 0 hours overdue
      );

      final item3 = ReviewItem(
        objectiveId: 'obj_003',
        intervalDays: 5,
        easeFactor: 2.5,
        nextReviewDate: DateTime.utc(2026, 8, 20, 12, 0), // Not due
      );

      schedule = schedule.addItem(item1).addItem(item2).addItem(item3);

      expect(schedule.itemCount, 3);
      final due = schedule.getDueItems(asOfDate: now);

      expect(due.length, 2);
      expect(due.first.objectiveId, 'obj_001'); // Most overdue first
      expect(due.last.objectiveId, 'obj_002');
    });

    test('ReviewSchedule serialization round-trip', () {
      final item = ReviewItem.initial('obj_001', now: now);
      final schedule = ReviewSchedule(
        learnerId: 'learner_101',
        items: {'obj_001': item},
        createdAt: now,
        updatedAt: now,
      );

      final json = schedule.toJson();
      final restored = ReviewSchedule.fromJson(json);

      expect(restored, equals(schedule));
    });
  });
}
