import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/performance_rating.dart';
import 'package:garuda_learning/domain/entities/review_item.dart';
import 'package:garuda_learning/domain/entities/review_result.dart';
import 'package:garuda_learning/domain/entities/review_schedule.dart';
import 'package:garuda_learning/service/retention_analytics_evaluator.dart';

void main() {
  group('RetentionAnalyticsEvaluator Service Tests (P23 Stage 4)', () {
    const evaluator = RetentionAnalyticsEvaluator();
    final fixedTime = DateTime.utc(2026, 8, 25, 14, 0, 0);

    ReviewSchedule makeSchedule(
        String learnerId, Map<String, ReviewItem> items) {
      return ReviewSchedule(
        learnerId: learnerId,
        items: items,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
    }

    ReviewItem makeItem(
      String objectiveId, {
      int intervalDays = 1,
      double easeFactor = 2.5,
      required DateTime nextReviewDate,
      DateTime? lastReviewed,
      int reviewCount = 0,
    }) {
      return ReviewItem(
        objectiveId: objectiveId,
        intervalDays: intervalDays,
        easeFactor: easeFactor,
        nextReviewDate: nextReviewDate,
        lastReviewed: lastReviewed,
        reviewCount: reviewCount,
      );
    }

    test(
        '1. Zero tracked objectives yields null metrics and insufficient evidence',
        () {
      final schedule = makeSchedule('learner_001', {});

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        schedule: schedule,
        evaluatedAt: fixedTime,
      );

      expect(profile.totalTrackedObjectives, equals(0));
      expect(profile.activeReviewItemsCount, equals(0));
      expect(profile.overdueItemsCount, equals(0));
      expect(profile.upcomingItemsCount, equals(0));
      expect(profile.averageEaseFactor, isNull);
      expect(profile.averageIntervalDays, isNull);
      expect(profile.observedRetentionRate, isNull);
      expect(profile.projectedMemoryStability, isNull);
      expect(profile.hasSufficientEvidence, isFalse);
    });

    test('2. Zero review results with tracked items yields null retention rate',
        () {
      final schedule = makeSchedule('learner_001', {
        'lo_1': makeItem('lo_1',
            nextReviewDate: fixedTime.add(const Duration(days: 1)),
            reviewCount: 1,
            lastReviewed: fixedTime.subtract(const Duration(days: 1))),
      });

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        schedule: schedule,
        reviewResults: const [],
        evaluatedAt: fixedTime,
      );

      expect(profile.totalTrackedObjectives, equals(1));
      expect(profile.activeReviewItemsCount, equals(1));
      expect(profile.observedRetentionRate, isNull);
    });

    test('3. Sparse evidence below threshold yields insufficient evidence', () {
      final schedule = makeSchedule('learner_001', {
        'lo_1': makeItem('lo_1',
            nextReviewDate: fixedTime.add(const Duration(days: 1)),
            reviewCount: 1,
            lastReviewed: fixedTime.subtract(const Duration(days: 1))),
        'lo_2': makeItem('lo_2',
            nextReviewDate: fixedTime.add(const Duration(days: 3))),
      });

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        schedule: schedule,
        minimumEvidenceThreshold: 3,
        evaluatedAt: fixedTime,
      );

      expect(profile.totalTrackedObjectives, equals(2));
      expect(profile.activeReviewItemsCount, equals(1));
      expect(profile.hasSufficientEvidence, isFalse);
      expect(profile.projectedMemoryStability, isNull);
    });

    test('4. Sufficient evidence calculates all retention metrics', () {
      final schedule = makeSchedule('learner_001', {
        'lo_1': makeItem('lo_1',
            intervalDays: 7,
            easeFactor: 2.5,
            nextReviewDate: fixedTime.add(const Duration(days: 5)),
            reviewCount: 3,
            lastReviewed: fixedTime.subtract(const Duration(days: 2))),
        'lo_2': makeItem('lo_2',
            intervalDays: 3,
            easeFactor: 2.0,
            nextReviewDate: fixedTime.add(const Duration(days: 1)),
            reviewCount: 2,
            lastReviewed: fixedTime.subtract(const Duration(days: 1))),
        'lo_3': makeItem('lo_3',
            intervalDays: 5,
            easeFactor: 1.8,
            nextReviewDate: fixedTime.subtract(const Duration(days: 1)),
            reviewCount: 4,
            lastReviewed: fixedTime.subtract(const Duration(days: 6))),
      });

      final reviewResults = [
        ReviewResult(
            objectiveId: 'lo_1',
            rating: PerformanceRating.good,
            assessmentScore: 0.75,
            timestamp: fixedTime.subtract(const Duration(days: 2))),
        ReviewResult(
            objectiveId: 'lo_2',
            rating: PerformanceRating.easy,
            assessmentScore: 0.9,
            timestamp: fixedTime.subtract(const Duration(days: 1))),
        ReviewResult(
            objectiveId: 'lo_3',
            rating: PerformanceRating.again,
            assessmentScore: 0.2,
            timestamp: fixedTime.subtract(const Duration(days: 6))),
        ReviewResult(
            objectiveId: 'lo_1',
            rating: PerformanceRating.hard,
            assessmentScore: 0.5,
            timestamp: fixedTime.subtract(const Duration(days: 5))),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        schedule: schedule,
        reviewResults: reviewResults,
        minimumEvidenceThreshold: 3,
        evaluatedAt: fixedTime,
      );

      expect(profile.totalTrackedObjectives, equals(3));
      expect(profile.activeReviewItemsCount, equals(3));
      expect(profile.hasSufficientEvidence, isTrue);

      // lo_3 is overdue (nextReviewDate is before evaluatedAt).
      expect(profile.overdueItemsCount, equals(1));
      expect(profile.upcomingItemsCount, equals(2));
    });

    test('5. Average ease factor calculated correctly', () {
      final schedule = makeSchedule('learner_001', {
        'lo_1': makeItem('lo_1',
            easeFactor: 2.5,
            nextReviewDate: fixedTime.add(const Duration(days: 1)),
            reviewCount: 1,
            lastReviewed: fixedTime),
        'lo_2': makeItem('lo_2',
            easeFactor: 1.5,
            nextReviewDate: fixedTime.add(const Duration(days: 1)),
            reviewCount: 1,
            lastReviewed: fixedTime),
      });

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        schedule: schedule,
        evaluatedAt: fixedTime,
      );

      // Average ease = (2.5 + 1.5) / 2 = 2.0
      expect(profile.averageEaseFactor, closeTo(2.0, 0.001));
    });

    test('6. Average interval days calculated correctly', () {
      final schedule = makeSchedule('learner_001', {
        'lo_1': makeItem('lo_1',
            intervalDays: 10,
            nextReviewDate: fixedTime.add(const Duration(days: 1))),
        'lo_2': makeItem('lo_2',
            intervalDays: 20,
            nextReviewDate: fixedTime.add(const Duration(days: 1))),
      });

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        schedule: schedule,
        evaluatedAt: fixedTime,
      );

      // Average interval = (10 + 20) / 2 = 15.0
      expect(profile.averageIntervalDays, closeTo(15.0, 0.001));
    });

    test('7. Retention rate: successful = grade >= 3 (hard)', () {
      final schedule = makeSchedule('learner_001', {
        'lo_1': makeItem('lo_1',
            nextReviewDate: fixedTime.add(const Duration(days: 1)),
            reviewCount: 2,
            lastReviewed: fixedTime),
      });

      final reviewResults = [
        ReviewResult(
            objectiveId: 'lo_1',
            rating: PerformanceRating.good,
            assessmentScore: 0.7),
        ReviewResult(
            objectiveId: 'lo_1',
            rating: PerformanceRating.again,
            assessmentScore: 0.1),
        ReviewResult(
            objectiveId: 'lo_1',
            rating: PerformanceRating.easy,
            assessmentScore: 0.95),
        ReviewResult(
            objectiveId: 'lo_1',
            rating: PerformanceRating.hard,
            assessmentScore: 0.45),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        schedule: schedule,
        reviewResults: reviewResults,
        evaluatedAt: fixedTime,
      );

      // 3 successful (good, easy, hard) out of 4 = 0.75
      expect(profile.observedRetentionRate, closeTo(0.75, 0.001));
    });

    test('8. Overdue ratio with explicit evaluatedAt', () {
      final schedule = makeSchedule('learner_001', {
        'lo_1': makeItem('lo_1',
            nextReviewDate: fixedTime.subtract(const Duration(days: 2)),
            reviewCount: 1,
            lastReviewed: fixedTime.subtract(const Duration(days: 5))),
        'lo_2': makeItem('lo_2',
            nextReviewDate: fixedTime, // equal = overdue
            reviewCount: 1,
            lastReviewed: fixedTime.subtract(const Duration(days: 3))),
        'lo_3': makeItem('lo_3',
            nextReviewDate: fixedTime.add(const Duration(days: 1)),
            reviewCount: 1,
            lastReviewed: fixedTime.subtract(const Duration(days: 1))),
      });

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        schedule: schedule,
        minimumEvidenceThreshold: 3,
        evaluatedAt: fixedTime,
      );

      // lo_1 overdue (before), lo_2 overdue (exactly at), lo_3 upcoming
      expect(profile.overdueItemsCount, equals(2));
      expect(profile.upcomingItemsCount, equals(1));
      expect(profile.overdueRatio, closeTo(2.0 / 3.0, 0.001));
    });

    test('9. Projected memory stability formula verification', () {
      final schedule = makeSchedule('learner_001', {
        'lo_1': makeItem('lo_1',
            intervalDays: 10,
            easeFactor: 2.5,
            nextReviewDate: fixedTime.add(const Duration(days: 5)),
            reviewCount: 5,
            lastReviewed: fixedTime.subtract(const Duration(days: 1))),
        'lo_2': makeItem('lo_2',
            intervalDays: 7,
            easeFactor: 2.0,
            nextReviewDate: fixedTime.add(const Duration(days: 2)),
            reviewCount: 3,
            lastReviewed: fixedTime.subtract(const Duration(days: 2))),
        'lo_3': makeItem('lo_3',
            intervalDays: 4,
            easeFactor: 1.5,
            nextReviewDate: fixedTime.add(const Duration(days: 1)),
            reviewCount: 2,
            lastReviewed: fixedTime.subtract(const Duration(days: 3))),
      });

      final reviewResults = [
        ReviewResult(
            objectiveId: 'lo_1',
            rating: PerformanceRating.good,
            assessmentScore: 0.7),
        ReviewResult(
            objectiveId: 'lo_2',
            rating: PerformanceRating.easy,
            assessmentScore: 0.9),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        schedule: schedule,
        reviewResults: reviewResults,
        minimumEvidenceThreshold: 3,
        evaluatedAt: fixedTime,
      );

      expect(profile.hasSufficientEvidence, isTrue);
      expect(profile.projectedMemoryStability, isNotNull);

      // retentionRate = 2/2 = 1.0 (both good/easy >= grade 3)
      // overdueComponent = 1.0 - 0/3 = 1.0 (no overdue items)
      // avgEase = (2.5 + 2.0 + 1.5) / 3 = 2.0
      // easeComponent = (2.0 - 1.3) / (2.5 - 1.3) = 0.7 / 1.2 ≈ 0.5833
      // stability = 0.5 * 1.0 + 0.3 * 1.0 + 0.2 * 0.5833 = 0.5 + 0.3 + 0.1167 = 0.9167
      expect(profile.projectedMemoryStability, closeTo(0.9167, 0.01));
    });

    test('10. Scope filtering across specific curriculum domain', () {
      final schedule = makeSchedule('learner_001', {
        'lo_1': makeItem('lo_1',
            easeFactor: 2.5,
            intervalDays: 10,
            nextReviewDate: fixedTime.add(const Duration(days: 1)),
            reviewCount: 2,
            lastReviewed: fixedTime),
        'lo_2': makeItem('lo_2',
            easeFactor: 1.8,
            intervalDays: 5,
            nextReviewDate: fixedTime.add(const Duration(days: 2)),
            reviewCount: 1,
            lastReviewed: fixedTime),
        'lo_3': makeItem('lo_3', // out of scope
            easeFactor: 2.0,
            intervalDays: 7,
            nextReviewDate: fixedTime.add(const Duration(days: 3)),
            reviewCount: 3,
            lastReviewed: fixedTime),
      });

      final reviewResults = [
        ReviewResult(
            objectiveId: 'lo_1',
            rating: PerformanceRating.good,
            assessmentScore: 0.7),
        ReviewResult(
            objectiveId: 'lo_3', // out of scope
            rating: PerformanceRating.easy,
            assessmentScore: 0.9),
      ];

      final profile = evaluator.evaluate(
        learnerId: 'learner_001',
        scopeId: 'domain_math',
        schedule: schedule,
        reviewResults: reviewResults,
        scopedObjectiveIds: ['lo_1', 'lo_2'],
        evaluatedAt: fixedTime,
      );

      expect(profile.totalTrackedObjectives, equals(2));
      expect(profile.scopeId, equals('domain_math'));
      // Only lo_1 result is in scope
      expect(profile.observedRetentionRate, closeTo(1.0, 0.001));
    });

    test('11. Invalid learnerId throws ArgumentError', () {
      final schedule = makeSchedule('learner_001', {});

      expect(
        () => evaluator.evaluate(
          learnerId: '',
          schedule: schedule,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => evaluator.evaluate(
          learnerId: '   ',
          schedule: schedule,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('12. Invalid threshold throws ArgumentError', () {
      final schedule = makeSchedule('learner_001', {});

      expect(
        () => evaluator.evaluate(
          learnerId: 'learner_001',
          schedule: schedule,
          minimumEvidenceThreshold: 0,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => evaluator.evaluate(
          learnerId: 'learner_001',
          schedule: schedule,
          minimumEvidenceThreshold: -1,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test(
        '13. Deterministic replay: identical inputs produce identical profiles',
        () {
      final schedule = makeSchedule('learner_001', {
        'lo_1': makeItem('lo_1',
            intervalDays: 7,
            easeFactor: 2.3,
            nextReviewDate: fixedTime.add(const Duration(days: 3)),
            reviewCount: 3,
            lastReviewed: fixedTime.subtract(const Duration(days: 1))),
        'lo_2': makeItem('lo_2',
            intervalDays: 4,
            easeFactor: 1.9,
            nextReviewDate: fixedTime.subtract(const Duration(days: 1)),
            reviewCount: 2,
            lastReviewed: fixedTime.subtract(const Duration(days: 5))),
        'lo_3': makeItem('lo_3',
            intervalDays: 14,
            easeFactor: 2.5,
            nextReviewDate: fixedTime.add(const Duration(days: 10)),
            reviewCount: 5,
            lastReviewed: fixedTime.subtract(const Duration(days: 2))),
      });

      final reviewResults = [
        ReviewResult(
            objectiveId: 'lo_1',
            rating: PerformanceRating.good,
            assessmentScore: 0.7),
        ReviewResult(
            objectiveId: 'lo_2',
            rating: PerformanceRating.again,
            assessmentScore: 0.15),
      ];

      final profile1 = evaluator.evaluate(
        learnerId: 'learner_001',
        schedule: schedule,
        reviewResults: reviewResults,
        minimumEvidenceThreshold: 3,
        evaluatedAt: fixedTime,
      );

      final profile2 = evaluator.evaluate(
        learnerId: 'learner_001',
        schedule: schedule,
        reviewResults: reviewResults,
        minimumEvidenceThreshold: 3,
        evaluatedAt: fixedTime,
      );

      expect(profile1, equals(profile2));
      expect(profile1.hashCode, equals(profile2.hashCode));
      expect(profile1.toJson(), equals(profile2.toJson()));
    });
  });
}
