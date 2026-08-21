import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/recommendation_effectiveness.dart';

void main() {
  group('RecommendationEffectiveness Domain Model Tests (P22 Stage 4)', () {
    final testEvaluatedAt = DateTime.utc(2026, 8, 20, 10, 0, 0);

    test('1. Valid construction with observed improvement', () {
      final effectiveness = RecommendationEffectiveness(
        instanceId: 'inst-001',
        objectiveId: 'lo-polity-01',
        learnerId: 'learner-001',
        baselineAccuracy: 0.50,
        baselineAttemptsCount: 10,
        followUpAccuracy: 0.80,
        followUpAttemptsCount: 10,
        evaluatedAt: testEvaluatedAt,
      );

      expect(effectiveness.instanceId, equals('inst-001'));
      expect(effectiveness.objectiveId, equals('lo-polity-01'));
      expect(effectiveness.learnerId, equals('learner-001'));
      expect(effectiveness.baselineAccuracy, equals(0.50));
      expect(effectiveness.baselineAttemptsCount, equals(10));
      expect(effectiveness.followUpAccuracy, equals(0.80));
      expect(effectiveness.followUpAttemptsCount, equals(10));
      expect(effectiveness.observedPerformanceDelta, closeTo(0.30, 0.0001));
      expect(effectiveness.insufficientEvidence, isFalse);
      expect(
        effectiveness.category,
        equals(EffectivenessCategory.observedImprovement),
      );
    });

    test('2. Observed decline categorization', () {
      final effectiveness = RecommendationEffectiveness(
        instanceId: 'inst-002',
        objectiveId: 'lo-polity-01',
        learnerId: 'learner-001',
        baselineAccuracy: 0.75,
        baselineAttemptsCount: 8,
        followUpAccuracy: 0.40,
        followUpAttemptsCount: 5,
        evaluatedAt: testEvaluatedAt,
      );

      expect(effectiveness.observedPerformanceDelta, closeTo(-0.35, 0.0001));
      expect(effectiveness.insufficientEvidence, isFalse);
      expect(
        effectiveness.category,
        equals(EffectivenessCategory.observedDecline),
      );
    });

    test('3. No measurable change categorization', () {
      final effectiveness = RecommendationEffectiveness(
        instanceId: 'inst-003',
        objectiveId: 'lo-polity-01',
        learnerId: 'learner-001',
        baselineAccuracy: 0.70,
        baselineAttemptsCount: 10,
        followUpAccuracy: 0.70,
        followUpAttemptsCount: 10,
        evaluatedAt: testEvaluatedAt,
      );

      expect(effectiveness.observedPerformanceDelta, closeTo(0.0, 0.0001));
      expect(effectiveness.insufficientEvidence, isFalse);
      expect(
        effectiveness.category,
        equals(EffectivenessCategory.noMeasurableChange),
      );
    });

    test('4. Null baseline accuracy results in insufficientEvidence', () {
      final effectiveness = RecommendationEffectiveness(
        instanceId: 'inst-004',
        objectiveId: 'lo-polity-01',
        learnerId: 'learner-001',
        baselineAccuracy: null,
        baselineAttemptsCount: 0,
        followUpAccuracy: 0.80,
        followUpAttemptsCount: 5,
        evaluatedAt: testEvaluatedAt,
      );

      expect(effectiveness.baselineAccuracy, isNull);
      expect(effectiveness.observedPerformanceDelta, isNull);
      expect(effectiveness.insufficientEvidence, isTrue);
      expect(
        effectiveness.category,
        equals(EffectivenessCategory.insufficientEvidence),
      );
    });

    test('5. Null followUp accuracy results in insufficientEvidence', () {
      final effectiveness = RecommendationEffectiveness(
        instanceId: 'inst-005',
        objectiveId: 'lo-polity-01',
        learnerId: 'learner-001',
        baselineAccuracy: 0.60,
        baselineAttemptsCount: 10,
        followUpAccuracy: null,
        followUpAttemptsCount: 0,
        evaluatedAt: testEvaluatedAt,
      );

      expect(effectiveness.followUpAccuracy, isNull);
      expect(effectiveness.observedPerformanceDelta, isNull);
      expect(effectiveness.insufficientEvidence, isTrue);
      expect(
        effectiveness.category,
        equals(EffectivenessCategory.insufficientEvidence),
      );
    });

    test('6. Zero baseline attempts causes insufficientEvidence', () {
      final effectiveness = RecommendationEffectiveness(
        instanceId: 'inst-006',
        objectiveId: 'lo-polity-01',
        learnerId: 'learner-001',
        baselineAccuracy: 0.0,
        baselineAttemptsCount: 0,
        followUpAccuracy: 0.50,
        followUpAttemptsCount: 5,
        evaluatedAt: testEvaluatedAt,
      );

      expect(effectiveness.insufficientEvidence, isTrue);
      expect(
        effectiveness.category,
        equals(EffectivenessCategory.insufficientEvidence),
      );
    });

    test('7. Validation guards throw on invalid parameters', () {
      expect(
        () => RecommendationEffectiveness(
          instanceId: '',
          objectiveId: 'lo-1',
          learnerId: 'learner-1',
          baselineAttemptsCount: 0,
          followUpAttemptsCount: 0,
          evaluatedAt: testEvaluatedAt,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationEffectiveness(
          instanceId: 'inst-1',
          objectiveId: '',
          learnerId: 'learner-1',
          baselineAttemptsCount: 0,
          followUpAttemptsCount: 0,
          evaluatedAt: testEvaluatedAt,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationEffectiveness(
          instanceId: 'inst-1',
          objectiveId: 'lo-1',
          learnerId: '',
          baselineAttemptsCount: 0,
          followUpAttemptsCount: 0,
          evaluatedAt: testEvaluatedAt,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationEffectiveness(
          instanceId: 'inst-1',
          objectiveId: 'lo-1',
          learnerId: 'learner-1',
          baselineAttemptsCount: -1,
          followUpAttemptsCount: 0,
          evaluatedAt: testEvaluatedAt,
        ),
        throwsArgumentError,
      );
    });

    test('8. JSON serialization round-trip', () {
      final original = RecommendationEffectiveness(
        instanceId: 'inst-008',
        objectiveId: 'lo-polity-01',
        learnerId: 'learner-001',
        baselineAccuracy: 0.55,
        baselineAttemptsCount: 12,
        followUpAccuracy: 0.85,
        followUpAttemptsCount: 8,
        measurementWindow: const Duration(days: 14),
        evaluatedAt: testEvaluatedAt,
        metadata: const {'source': 'quiz_review'},
      );

      final json = original.toJson();
      final restored = RecommendationEffectiveness.fromJson(json);

      expect(restored, equals(original));
      expect(restored.measurementWindow, equals(const Duration(days: 14)));
      expect(restored.metadata['source'], equals('quiz_review'));
    });

    test('9. Deterministic equality and hashCode', () {
      final a = RecommendationEffectiveness(
        instanceId: 'inst-009',
        objectiveId: 'lo-01',
        learnerId: 'learner-01',
        baselineAccuracy: 0.5,
        baselineAttemptsCount: 5,
        followUpAccuracy: 0.7,
        followUpAttemptsCount: 5,
        evaluatedAt: testEvaluatedAt,
      );

      final b = RecommendationEffectiveness(
        instanceId: 'inst-009',
        objectiveId: 'lo-01',
        learnerId: 'learner-01',
        baselineAccuracy: 0.5,
        baselineAttemptsCount: 5,
        followUpAccuracy: 0.7,
        followUpAttemptsCount: 5,
        evaluatedAt: testEvaluatedAt,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
