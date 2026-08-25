import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/bloom_mastery_distribution.dart';
import 'package:garuda_learning/domain/entities/bloom_taxonomy_level.dart';

void main() {
  group('BloomMasteryDistribution Entity Tests (P23 Stage 1)', () {
    final fixedTime = DateTime.utc(2026, 8, 25, 12, 0, 0);

    test('1. Valid construction of BloomLevelMetric with evidence', () {
      final metric = BloomLevelMetric(
        level: BloomTaxonomyLevel.analyze,
        totalObjectivesCount: 5,
        attemptedObjectivesCount: 4,
        achievedObjectivesCount: 3,
        totalAttemptsCount: 12,
        totalCorrectCount: 9,
      );

      expect(metric.level, equals(BloomTaxonomyLevel.analyze));
      expect(metric.totalObjectivesCount, equals(5));
      expect(metric.attemptedObjectivesCount, equals(4));
      expect(metric.achievedObjectivesCount, equals(3));
      expect(metric.totalAttemptsCount, equals(12));
      expect(metric.totalCorrectCount, equals(9));
      expect(metric.observedAccuracy, equals(0.75));
      expect(metric.hasSufficientEvidence, isTrue);
      expect(metric.coverageRatio, equals(0.80));
      expect(metric.achievementRatio, equals(0.60));
    });

    test(
        '2. BloomLevelMetric with zero attempts yields null accuracy and insufficient evidence',
        () {
      final metric = BloomLevelMetric(
        level: BloomTaxonomyLevel.evaluate,
        totalObjectivesCount: 3,
        attemptedObjectivesCount: 0,
        achievedObjectivesCount: 0,
        totalAttemptsCount: 0,
        totalCorrectCount: 0,
      );

      expect(metric.observedAccuracy, isNull);
      expect(metric.hasSufficientEvidence, isFalse);
      expect(metric.coverageRatio, equals(0.0));
      expect(metric.achievementRatio, equals(0.0));
    });

    test('3. BloomLevelMetric argument validations', () {
      // attempted > total
      expect(
        () => BloomLevelMetric(
          level: BloomTaxonomyLevel.remember,
          totalObjectivesCount: 3,
          attemptedObjectivesCount: 4,
          achievedObjectivesCount: 0,
          totalAttemptsCount: 5,
          totalCorrectCount: 3,
        ),
        throwsArgumentError,
      );

      // achieved > attempted
      expect(
        () => BloomLevelMetric(
          level: BloomTaxonomyLevel.remember,
          totalObjectivesCount: 5,
          attemptedObjectivesCount: 2,
          achievedObjectivesCount: 3,
          totalAttemptsCount: 5,
          totalCorrectCount: 3,
        ),
        throwsArgumentError,
      );

      // correct > totalAttempts
      expect(
        () => BloomLevelMetric(
          level: BloomTaxonomyLevel.remember,
          totalObjectivesCount: 5,
          attemptedObjectivesCount: 2,
          achievedObjectivesCount: 2,
          totalAttemptsCount: 4,
          totalCorrectCount: 5,
        ),
        throwsArgumentError,
      );
    });

    test('4. BloomMasteryDistribution multi-level aggregation', () {
      final levels = <BloomTaxonomyLevel, BloomLevelMetric>{
        BloomTaxonomyLevel.remember: BloomLevelMetric(
          level: BloomTaxonomyLevel.remember,
          totalObjectivesCount: 4,
          attemptedObjectivesCount: 4,
          achievedObjectivesCount: 4,
          totalAttemptsCount: 10,
          totalCorrectCount: 9,
        ),
        BloomTaxonomyLevel.understand: BloomLevelMetric(
          level: BloomTaxonomyLevel.understand,
          totalObjectivesCount: 6,
          attemptedObjectivesCount: 5,
          achievedObjectivesCount: 3,
          totalAttemptsCount: 15,
          totalCorrectCount: 11,
        ),
        BloomTaxonomyLevel.apply: BloomLevelMetric(
          level: BloomTaxonomyLevel.apply,
          totalObjectivesCount: 3,
          attemptedObjectivesCount: 0,
          achievedObjectivesCount: 0,
          totalAttemptsCount: 0,
          totalCorrectCount: 0,
        ),
      };

      final dist = BloomMasteryDistribution(
        learnerId: 'learner_001',
        scopeId: 'domain_fr',
        levels: levels,
        calculatedAt: fixedTime,
      );

      expect(dist.learnerId, equals('learner_001'));
      expect(dist.scopeId, equals('domain_fr'));
      expect(dist.levels.length, equals(3));
      expect(dist.getAccuracy(BloomTaxonomyLevel.remember), equals(0.90));
      expect(dist.getAccuracy(BloomTaxonomyLevel.understand),
          closeTo(0.733, 0.001));
      expect(dist.getAccuracy(BloomTaxonomyLevel.apply), isNull);
      expect(dist.totalAttemptsAcrossAllLevels, equals(25)); // 10 + 15 + 0
      expect(dist.totalCorrectAcrossAllLevels, equals(20)); // 9 + 11 + 0
      expect(dist.overallAccuracy, equals(0.80)); // 20 / 25
    });

    test('5. Empty learnerId throws ArgumentError', () {
      expect(
        () => BloomMasteryDistribution(
          learnerId: '',
          levels: const {},
          calculatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test(
        '6. JSON serialization round-trip for BloomLevelMetric and Distribution',
        () {
      final metric = BloomLevelMetric(
        level: BloomTaxonomyLevel.analyze,
        totalObjectivesCount: 5,
        attemptedObjectivesCount: 3,
        achievedObjectivesCount: 2,
        totalAttemptsCount: 8,
        totalCorrectCount: 6,
      );

      final metricJson = metric.toJson();
      final reconstructedMetric = BloomLevelMetric.fromJson(metricJson);
      expect(reconstructedMetric, equals(metric));

      final dist = BloomMasteryDistribution(
        learnerId: 'learner_001',
        scopeId: 'scope_upsc',
        levels: {BloomTaxonomyLevel.analyze: metric},
        calculatedAt: fixedTime,
      );

      final distJson = dist.toJson();
      final reconstructedDist = BloomMasteryDistribution.fromJson(distJson);

      expect(reconstructedDist.learnerId, equals('learner_001'));
      expect(reconstructedDist.scopeId, equals('scope_upsc'));
      expect(reconstructedDist.levels.length, equals(1));
      expect(reconstructedDist.getMetric(BloomTaxonomyLevel.analyze),
          equals(metric));
      expect(reconstructedDist, equals(dist));
    });

    test('7. Equality and hashCode contract for BloomMasteryDistribution', () {
      final d1 = BloomMasteryDistribution(
        learnerId: 'l_1',
        scopeId: 's_1',
        levels: {
          BloomTaxonomyLevel.remember: BloomLevelMetric(
            level: BloomTaxonomyLevel.remember,
            totalObjectivesCount: 2,
            attemptedObjectivesCount: 1,
            achievedObjectivesCount: 1,
            totalAttemptsCount: 3,
            totalCorrectCount: 3,
          ),
        },
        calculatedAt: fixedTime,
      );

      final d2 = BloomMasteryDistribution(
        learnerId: 'l_1',
        scopeId: 's_1',
        levels: {
          BloomTaxonomyLevel.remember: BloomLevelMetric(
            level: BloomTaxonomyLevel.remember,
            totalObjectivesCount: 2,
            attemptedObjectivesCount: 1,
            achievedObjectivesCount: 1,
            totalAttemptsCount: 3,
            totalCorrectCount: 3,
          ),
        },
        calculatedAt: fixedTime,
      );

      expect(d1, equals(d2));
      expect(d1.hashCode, equals(d2.hashCode));
    });
  });
}
