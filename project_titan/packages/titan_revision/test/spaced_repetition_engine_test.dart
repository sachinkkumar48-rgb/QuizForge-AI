import 'package:test/test.dart';
import 'package:titan_revision/titan_revision.dart';

void main() {
  group('SpacedRepetitionEngine (SM-2 Algorithm)', () {
    const engine = SpacedRepetitionEngine();
    final now = DateTime(2026, 7, 24, 10, 0);

    final initialItem = RevisionItem(
      id: 'item_test_01',
      topic: 'Indian Polity',
      subtopic: 'Fundamental Rights',
      easeFactor: 2.5,
      intervalDays: 1,
      repetitions: 0,
      nextReviewDate: now,
      lastReviewedAt: now,
    );

    test(
        'Quality rating < 3 resets repetition count to 0 and interval to 1 day',
        () {
      final schedule =
          engine.calculateNextSchedule(initialItem, 2, reviewTimestamp: now);
      final updated = schedule.updatedItem;

      expect(updated.repetitions, equals(0));
      expect(updated.intervalDays, equals(1));
      expect(updated.masteryLevel, equals('Novice'));
      expect(updated.priority, equals('Urgent'));
      expect(schedule.nextReviewDate, equals(now.add(const Duration(days: 1))));
    });

    test(
        'First successful recall (q >= 3) sets repetitions = 1 and interval = 1 day',
        () {
      final schedule =
          engine.calculateNextSchedule(initialItem, 4, reviewTimestamp: now);
      final updated = schedule.updatedItem;

      expect(updated.repetitions, equals(1));
      expect(updated.intervalDays, equals(1));
      expect(updated.masteryLevel, equals('Learning'));
      expect(updated.priority, equals('High'));
    });

    test(
        'Second successful recall (q >= 3) sets repetitions = 2 and interval = 6 days',
        () {
      final itemRep1 = initialItem.copyWith(repetitions: 1, intervalDays: 1);
      final schedule =
          engine.calculateNextSchedule(itemRep1, 4, reviewTimestamp: now);
      final updated = schedule.updatedItem;

      expect(updated.repetitions, equals(2));
      expect(updated.intervalDays, equals(6));
      expect(updated.masteryLevel, equals('Proficient'));
    });

    test('Subsequent successful recall calculates interval = I * EF', () {
      final itemRep2 = initialItem.copyWith(
          repetitions: 2, intervalDays: 6, easeFactor: 2.5);
      final schedule =
          engine.calculateNextSchedule(itemRep2, 5, reviewTimestamp: now);
      final updated = schedule.updatedItem;

      expect(updated.repetitions, equals(3));
      // EF for q=5: 2.5 + (0.1 - 0) = 2.6. Next interval = 6 * 2.6 = 15.6 -> 16
      expect(updated.intervalDays, equals(16));
      expect(updated.easeFactor, equals(2.6));
    });

    test('Ease factor is clamped to minimum 1.3', () {
      var itemLowEf = initialItem.copyWith(easeFactor: 1.3);
      final schedule =
          engine.calculateNextSchedule(itemLowEf, 0, reviewTimestamp: now);
      expect(schedule.calculatedEaseFactor, equals(1.3));
    });
  });
}
