import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/bloom_taxonomy_level.dart';
import 'package:garuda_learning/domain/entities/weak_spot_profile.dart';

void main() {
  group('WeakSpotProfile & WeakObjectiveDiagnostic Entity Tests (P23 Stage 2)',
      () {
    final fixedTime = DateTime.utc(2026, 8, 25, 12, 0, 0);

    test('1. Valid construction of WeakObjectiveDiagnostic with evidence', () {
      final diag = WeakObjectiveDiagnostic(
        objectiveId: 'pol_lo_art21',
        domainId: 'pol_domain_fr',
        attemptCount: 10,
        correctCount: 3,
        bloomLevel: BloomTaxonomyLevel.analyze,
        consecutiveIncorrectCount: 2,
        lastAttemptedAt: fixedTime,
      );

      expect(diag.objectiveId, equals('pol_lo_art21'));
      expect(diag.domainId, equals('pol_domain_fr'));
      expect(diag.attemptCount, equals(10));
      expect(diag.correctCount, equals(3));
      expect(diag.observedAccuracy, closeTo(0.30, 0.001));
      expect(diag.deficiencyScore, closeTo(0.70, 0.001)); // 1.0 - 0.30
      expect(diag.bloomLevel, equals(BloomTaxonomyLevel.analyze));
      expect(diag.consecutiveIncorrectCount, equals(2));
      expect(diag.lastAttemptedAt, equals(fixedTime));
    });

    test(
        '2. WeakObjectiveDiagnostic validations: empty ID, 0 attempts, invalid counts',
        () {
      expect(
        () => WeakObjectiveDiagnostic(
          objectiveId: '',
          attemptCount: 5,
          correctCount: 2,
        ),
        throwsArgumentError,
      );

      // attemptCount < 1
      expect(
        () => WeakObjectiveDiagnostic(
          objectiveId: 'lo_1',
          attemptCount: 0,
          correctCount: 0,
        ),
        throwsArgumentError,
      );

      // correct > attempt
      expect(
        () => WeakObjectiveDiagnostic(
          objectiveId: 'lo_1',
          attemptCount: 5,
          correctCount: 6,
        ),
        throwsArgumentError,
      );
    });

    test(
        '3. WeakSpotProfile with diagnosed weak spots sorted deterministically',
        () {
      final diag1 = WeakObjectiveDiagnostic(
        objectiveId: 'pol_lo_b',
        attemptCount: 8,
        correctCount: 4, // accuracy 0.50, deficiency 0.50
      );

      final diag2 = WeakObjectiveDiagnostic(
        objectiveId: 'pol_lo_a',
        attemptCount: 10,
        correctCount: 2, // accuracy 0.20, deficiency 0.80
      );

      final diag3 = WeakObjectiveDiagnostic(
        objectiveId: 'pol_lo_c',
        attemptCount: 10,
        correctCount: 5, // accuracy 0.50, deficiency 0.50 (tie with diag1)
      );

      final profile = WeakSpotProfile(
        learnerId: 'learner_001',
        scopeId: 'pol_domain_fr',
        totalEvaluatedObjectives: 15,
        evaluatedWithSufficientEvidence: 12,
        weakObjectives: [diag1, diag2, diag3],
        weaknessThreshold: 0.60,
        evaluatedAt: fixedTime,
      );

      expect(profile.learnerId, equals('learner_001'));
      expect(profile.totalEvaluatedObjectives, equals(15));
      expect(profile.evaluatedWithSufficientEvidence, equals(12));
      expect(profile.identifiedWeakSpotsCount, equals(3));
      expect(profile.hasWeakSpots, isTrue);

      // Deterministic sort: highest deficiency first (diag2: 0.80),
      // then alphanumeric tie-breaker (pol_lo_b before pol_lo_c)
      expect(profile.weakObjectives[0].objectiveId, equals('pol_lo_a'));
      expect(profile.weakObjectives[1].objectiveId, equals('pol_lo_b'));
      expect(profile.weakObjectives[2].objectiveId, equals('pol_lo_c'));
    });

    test('4. WeakSpotProfile with zero weak spots', () {
      final profile = WeakSpotProfile(
        learnerId: 'learner_001',
        totalEvaluatedObjectives: 5,
        evaluatedWithSufficientEvidence: 5,
        weakObjectives: const [],
        evaluatedAt: fixedTime,
      );

      expect(profile.identifiedWeakSpotsCount, equals(0));
      expect(profile.hasWeakSpots, isFalse);
    });

    test('5. JSON serialization and deserialization round-trip', () {
      final diag = WeakObjectiveDiagnostic(
        objectiveId: 'pol_lo_writs',
        domainId: 'pol_domain_judiciary',
        attemptCount: 10,
        correctCount: 3,
        bloomLevel: BloomTaxonomyLevel.apply,
        consecutiveIncorrectCount: 3,
        lastAttemptedAt: fixedTime,
        metadata: const {'article': '32'},
      );

      final profile = WeakSpotProfile(
        learnerId: 'learner_001',
        scopeId: 'upsc_prelims_polity',
        totalEvaluatedObjectives: 20,
        evaluatedWithSufficientEvidence: 16,
        weakObjectives: [diag],
        weaknessThreshold: 0.65,
        minimumEvidenceThreshold: 5,
        evaluatedAt: fixedTime,
        metadata: const {'cohort': '2026_aspirants'},
      );

      final json = profile.toJson();
      final reconstructed = WeakSpotProfile.fromJson(json);

      expect(reconstructed.learnerId, equals(profile.learnerId));
      expect(reconstructed.scopeId, equals(profile.scopeId));
      expect(reconstructed.totalEvaluatedObjectives, equals(20));
      expect(reconstructed.evaluatedWithSufficientEvidence, equals(16));
      expect(reconstructed.identifiedWeakSpotsCount, equals(1));
      expect(reconstructed.weakObjectives.first.objectiveId,
          equals('pol_lo_writs'));
      expect(reconstructed.weakObjectives.first.bloomLevel,
          equals(BloomTaxonomyLevel.apply));
      expect(reconstructed.weaknessThreshold, equals(0.65));
      expect(reconstructed.metadata['cohort'], equals('2026_aspirants'));
      expect(reconstructed, equals(profile));
    });

    test('6. Equality and hashCode contract', () {
      final diag = WeakObjectiveDiagnostic(
        objectiveId: 'lo_1',
        attemptCount: 5,
        correctCount: 1,
      );

      final p1 = WeakSpotProfile(
        learnerId: 'l_1',
        totalEvaluatedObjectives: 5,
        evaluatedWithSufficientEvidence: 3,
        weakObjectives: [diag],
        evaluatedAt: fixedTime,
      );

      final p2 = WeakSpotProfile(
        learnerId: 'l_1',
        totalEvaluatedObjectives: 5,
        evaluatedWithSufficientEvidence: 3,
        weakObjectives: [diag],
        evaluatedAt: fixedTime,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
    });
  });
}
