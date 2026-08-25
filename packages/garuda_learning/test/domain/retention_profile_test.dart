import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/retention_profile.dart';

void main() {
  group('RetentionProfile Entity Tests (P23 Stage 2)', () {
    final fixedTime = DateTime.utc(2026, 8, 25, 12, 0, 0);

    test('1. Valid construction with sufficient evidence', () {
      final profile = RetentionProfile(
        learnerId: 'learner_001',
        scopeId: 'pol_domain_fr',
        totalTrackedObjectives: 10,
        activeReviewItemsCount: 8,
        overdueItemsCount: 2,
        averageEaseFactor: 2.3,
        averageIntervalDays: 14.5,
        observedRetentionRate: 0.85,
        projectedMemoryStability: 0.78,
        evaluatedAt: fixedTime,
      );

      expect(profile.learnerId, equals('learner_001'));
      expect(profile.scopeId, equals('pol_domain_fr'));
      expect(profile.totalTrackedObjectives, equals(10));
      expect(profile.activeReviewItemsCount, equals(8));
      expect(profile.overdueItemsCount, equals(2));
      expect(profile.upcomingItemsCount, equals(8)); // 10 - 2
      expect(profile.averageEaseFactor, equals(2.3));
      expect(profile.averageIntervalDays, equals(14.5));
      expect(profile.observedRetentionRate, equals(0.85));
      expect(profile.projectedMemoryStability, equals(0.78));
      expect(profile.hasSufficientEvidence, isTrue);
      expect(profile.overdueRatio, closeTo(0.20, 0.001));
      expect(profile.isReviewScheduleUpToDate, isFalse);
    });

    test(
        '2. Zero tracked objectives yields null metrics and insufficient evidence without bias',
        () {
      final profile = RetentionProfile(
        learnerId: 'learner_001',
        totalTrackedObjectives: 0,
        activeReviewItemsCount: 0,
        overdueItemsCount: 0,
        evaluatedAt: fixedTime,
      );

      expect(profile.averageEaseFactor, isNull);
      expect(profile.averageIntervalDays, isNull);
      expect(profile.observedRetentionRate, isNull);
      expect(profile.projectedMemoryStability, isNull);
      expect(profile.hasSufficientEvidence, isFalse);
      expect(profile.overdueRatio, equals(0.0));
      expect(profile.upcomingItemsCount, equals(0));
      expect(profile.isReviewScheduleUpToDate, isFalse);
    });

    test('3. Sparse evidence below threshold marks insufficient evidence', () {
      final profile = RetentionProfile(
        learnerId: 'learner_001',
        totalTrackedObjectives: 5,
        activeReviewItemsCount: 1, // below default threshold 3
        overdueItemsCount: 0,
        averageEaseFactor: 2.5,
        averageIntervalDays: 1.0,
        observedRetentionRate: 1.0,
        minimumEvidenceThreshold: 3,
        evaluatedAt: fixedTime,
      );

      expect(profile.observedRetentionRate, equals(1.0));
      expect(profile.projectedMemoryStability, isNull);
      expect(profile.hasSufficientEvidence, isFalse);
      expect(profile.isReviewScheduleUpToDate, isTrue);
    });

    test(
        '4. Argument validations: empty learnerId and inconsistent counts throw ArgumentError',
        () {
      expect(
        () => RetentionProfile(
          learnerId: '',
          totalTrackedObjectives: 5,
          activeReviewItemsCount: 2,
          overdueItemsCount: 1,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      // active > total
      expect(
        () => RetentionProfile(
          learnerId: 'l_1',
          totalTrackedObjectives: 5,
          activeReviewItemsCount: 6,
          overdueItemsCount: 1,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      // overdue > total
      expect(
        () => RetentionProfile(
          learnerId: 'l_1',
          totalTrackedObjectives: 5,
          activeReviewItemsCount: 3,
          overdueItemsCount: 6,
          evaluatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('5. JSON serialization and deserialization round-trip', () {
      final profile = RetentionProfile(
        learnerId: 'learner_001',
        scopeId: 'scope_upsc',
        totalTrackedObjectives: 8,
        activeReviewItemsCount: 6,
        overdueItemsCount: 0,
        averageEaseFactor: 2.4,
        averageIntervalDays: 21.0,
        observedRetentionRate: 0.90,
        projectedMemoryStability: 0.82,
        metadata: const {'source': 'p20_schedule'},
        evaluatedAt: fixedTime,
      );

      final json = profile.toJson();
      final reconstructed = RetentionProfile.fromJson(json);

      expect(reconstructed.learnerId, equals(profile.learnerId));
      expect(reconstructed.scopeId, equals(profile.scopeId));
      expect(reconstructed.totalTrackedObjectives, equals(8));
      expect(reconstructed.overdueItemsCount, equals(0));
      expect(reconstructed.averageEaseFactor, equals(2.4));
      expect(reconstructed.averageIntervalDays, equals(21.0));
      expect(reconstructed.observedRetentionRate, equals(0.90));
      expect(reconstructed.projectedMemoryStability, equals(0.82));
      expect(reconstructed.isReviewScheduleUpToDate, isTrue);
      expect(reconstructed.metadata['source'], equals('p20_schedule'));
      expect(reconstructed, equals(profile));
    });

    test('6. Equality and hashCode contract', () {
      final p1 = RetentionProfile(
        learnerId: 'l_1',
        totalTrackedObjectives: 5,
        activeReviewItemsCount: 3,
        overdueItemsCount: 1,
        evaluatedAt: fixedTime,
      );

      final p2 = RetentionProfile(
        learnerId: 'l_1',
        totalTrackedObjectives: 5,
        activeReviewItemsCount: 3,
        overdueItemsCount: 1,
        evaluatedAt: fixedTime,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });
}
