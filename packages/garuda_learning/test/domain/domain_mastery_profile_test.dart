import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/bloom_mastery_distribution.dart';
import 'package:garuda_learning/domain/entities/bloom_taxonomy_level.dart';
import 'package:garuda_learning/domain/entities/domain_mastery_profile.dart';

void main() {
  group('DomainMasteryProfile Entity Tests (P23 Stage 1)', () {
    final fixedTime = DateTime.utc(2026, 8, 25, 12, 0, 0);

    test('1. Valid construction with sufficient evidence', () {
      final profile = DomainMasteryProfile(
        domainId: 'pol_domain_fr',
        learnerId: 'learner_001',
        totalObjectivesCount: 10,
        attemptedObjectivesCount: 8,
        achievedObjectivesCount: 6,
        totalAttemptsCount: 25,
        totalCorrectCount: 20,
        observedMasteryScore: 0.75,
        supportingObjectiveIds: const ['pol_lo_001', 'pol_lo_002'],
        calculatedAt: fixedTime,
      );

      expect(profile.domainId, equals('pol_domain_fr'));
      expect(profile.learnerId, equals('learner_001'));
      expect(profile.totalObjectivesCount, equals(10));
      expect(profile.attemptedObjectivesCount, equals(8));
      expect(profile.achievedObjectivesCount, equals(6));
      expect(profile.unattemptedObjectivesCount, equals(2));
      expect(profile.totalAttemptsCount, equals(25));
      expect(profile.totalCorrectCount, equals(20));
      expect(profile.observedAccuracy, closeTo(0.80, 0.001));
      expect(profile.observedMasteryScore, equals(0.75));
      expect(profile.hasSufficientEvidence, isTrue);
      expect(profile.coverageRatio, closeTo(0.80, 0.001));
      expect(profile.achievementRatio, closeTo(0.60, 0.001));
      expect(profile.supportingObjectiveIds, contains('pol_lo_001'));
    });

    test(
        '2. Zero attempts yields null accuracy and mastery without poor mastery bias',
        () {
      final profile = DomainMasteryProfile(
        domainId: 'pol_domain_dpsp',
        learnerId: 'learner_001',
        totalObjectivesCount: 5,
        attemptedObjectivesCount: 0,
        achievedObjectivesCount: 0,
        totalAttemptsCount: 0,
        totalCorrectCount: 0,
        calculatedAt: fixedTime,
      );

      expect(profile.observedAccuracy, isNull);
      expect(profile.observedMasteryScore, isNull);
      expect(profile.hasSufficientEvidence, isFalse);
      expect(profile.coverageRatio, equals(0.0));
      expect(profile.achievementRatio, equals(0.0));
      expect(profile.unattemptedObjectivesCount, equals(5));
    });

    test('3. Sparse evidence below threshold marks insufficient evidence', () {
      final profile = DomainMasteryProfile(
        domainId: 'pol_domain_exec',
        learnerId: 'learner_001',
        totalObjectivesCount: 10,
        attemptedObjectivesCount: 1,
        achievedObjectivesCount: 0,
        totalAttemptsCount: 2, // Below default threshold 5
        totalCorrectCount: 2,
        minimumEvidenceThreshold: 5,
        calculatedAt: fixedTime,
      );

      expect(profile.observedAccuracy, equals(1.0)); // 2/2 correct
      expect(profile.hasSufficientEvidence, isFalse); // but sparse evidence
    });

    test('4. Zero denominator safety when totalObjectivesCount is 0', () {
      final profile = DomainMasteryProfile(
        domainId: 'empty_domain',
        learnerId: 'learner_001',
        totalObjectivesCount: 0,
        attemptedObjectivesCount: 0,
        achievedObjectivesCount: 0,
        totalAttemptsCount: 0,
        totalCorrectCount: 0,
        calculatedAt: fixedTime,
      );

      expect(profile.coverageRatio.isNaN, isFalse);
      expect(profile.coverageRatio.isInfinite, isFalse);
      expect(profile.coverageRatio, equals(0.0));
      expect(profile.achievementRatio.isNaN, isFalse);
      expect(profile.achievementRatio.isInfinite, isFalse);
      expect(profile.achievementRatio, equals(0.0));
    });

    test('5. Argument validation: empty IDs throw ArgumentError', () {
      expect(
        () => DomainMasteryProfile(
          domainId: '',
          learnerId: 'learner_001',
          totalObjectivesCount: 5,
          attemptedObjectivesCount: 0,
          achievedObjectivesCount: 0,
          totalAttemptsCount: 0,
          totalCorrectCount: 0,
          calculatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => DomainMasteryProfile(
          domainId: 'domain_001',
          learnerId: '   ',
          totalObjectivesCount: 5,
          attemptedObjectivesCount: 0,
          achievedObjectivesCount: 0,
          totalAttemptsCount: 0,
          totalCorrectCount: 0,
          calculatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('6. Argument validation: inconsistent counts throw ArgumentError', () {
      // attempted > total
      expect(
        () => DomainMasteryProfile(
          domainId: 'dom_1',
          learnerId: 'l_1',
          totalObjectivesCount: 5,
          attemptedObjectivesCount: 6,
          achievedObjectivesCount: 0,
          totalAttemptsCount: 10,
          totalCorrectCount: 5,
          calculatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      // achieved > attempted
      expect(
        () => DomainMasteryProfile(
          domainId: 'dom_1',
          learnerId: 'l_1',
          totalObjectivesCount: 5,
          attemptedObjectivesCount: 3,
          achievedObjectivesCount: 4,
          totalAttemptsCount: 10,
          totalCorrectCount: 5,
          calculatedAt: fixedTime,
        ),
        throwsArgumentError,
      );

      // correct > totalAttempts
      expect(
        () => DomainMasteryProfile(
          domainId: 'dom_1',
          learnerId: 'l_1',
          totalObjectivesCount: 5,
          attemptedObjectivesCount: 3,
          achievedObjectivesCount: 2,
          totalAttemptsCount: 5,
          totalCorrectCount: 6,
          calculatedAt: fixedTime,
        ),
        throwsArgumentError,
      );
    });

    test('7. Immutability: defensive copy of supporting lists and metadata',
        () {
      final ids = ['lo_1', 'lo_2'];
      final meta = {'tag': 'upsc'};

      final profile = DomainMasteryProfile(
        domainId: 'dom_1',
        learnerId: 'l_1',
        totalObjectivesCount: 5,
        attemptedObjectivesCount: 2,
        achievedObjectivesCount: 1,
        totalAttemptsCount: 5,
        totalCorrectCount: 4,
        supportingObjectiveIds: ids,
        metadata: meta,
        calculatedAt: fixedTime,
      );

      ids.add('lo_3');
      meta['tag'] = 'state_psc';

      expect(profile.supportingObjectiveIds.length, equals(2));
      expect(profile.metadata['tag'], equals('upsc'));
      expect(() => profile.supportingObjectiveIds.add('lo_x'),
          throwsUnsupportedError);
    });

    test('8. JSON Serialization round-trip', () {
      final bloomDist = BloomMasteryDistribution(
        learnerId: 'l_1',
        scopeId: 'dom_1',
        levels: {
          BloomTaxonomyLevel.remember: BloomLevelMetric(
            level: BloomTaxonomyLevel.remember,
            totalObjectivesCount: 3,
            attemptedObjectivesCount: 2,
            achievedObjectivesCount: 1,
            totalAttemptsCount: 6,
            totalCorrectCount: 5,
          ),
        },
        calculatedAt: fixedTime,
      );

      final profile = DomainMasteryProfile(
        domainId: 'dom_1',
        learnerId: 'l_1',
        totalObjectivesCount: 10,
        attemptedObjectivesCount: 5,
        achievedObjectivesCount: 3,
        totalAttemptsCount: 15,
        totalCorrectCount: 12,
        observedMasteryScore: 0.60,
        bloomDistribution: bloomDist,
        supportingObjectiveIds: const ['lo_1', 'lo_2'],
        calculatedAt: fixedTime,
      );

      final json = profile.toJson();
      final reconstructed = DomainMasteryProfile.fromJson(json);

      expect(reconstructed.domainId, equals(profile.domainId));
      expect(reconstructed.learnerId, equals(profile.learnerId));
      expect(reconstructed.totalObjectivesCount,
          equals(profile.totalObjectivesCount));
      expect(reconstructed.observedAccuracy, closeTo(0.80, 0.001));
      expect(reconstructed.observedMasteryScore, equals(0.60));
      expect(reconstructed.bloomDistribution, isNotNull);
      expect(reconstructed.bloomDistribution!.levels.length, equals(1));
      expect(reconstructed, equals(profile));
    });

    test('9. Equality and hashCode contract', () {
      final p1 = DomainMasteryProfile(
        domainId: 'dom_1',
        learnerId: 'l_1',
        totalObjectivesCount: 5,
        attemptedObjectivesCount: 2,
        achievedObjectivesCount: 1,
        totalAttemptsCount: 5,
        totalCorrectCount: 4,
        calculatedAt: fixedTime,
      );

      final p2 = DomainMasteryProfile(
        domainId: 'dom_1',
        learnerId: 'l_1',
        totalObjectivesCount: 5,
        attemptedObjectivesCount: 2,
        achievedObjectivesCount: 1,
        totalAttemptsCount: 5,
        totalCorrectCount: 4,
        calculatedAt: fixedTime,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });
}
