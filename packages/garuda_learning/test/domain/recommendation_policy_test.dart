import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('RecommendationPolicy Value Object Tests', () {
    test('default configuration has correct weights and sum to 1.0', () {
      const policy = RecommendationPolicy();

      expect(policy.weightSpacedReview, equals(0.35));
      expect(policy.weightPrerequisiteGap, equals(0.25));
      expect(policy.weightWeakDomain, equals(0.20));
      expect(policy.weightCurriculumAdvance, equals(0.10));
      expect(policy.weightPracticeDensity, equals(0.10));
      expect(policy.totalWeight, closeTo(1.00, 0.0001));
      expect(policy.maxRecommendations, equals(10));
      expect(policy.weakDomainThreshold, equals(0.60));
      expect(policy.minDomainAttempts, equals(3));
    });

    test('custom policy initializes properly and serializes to JSON', () {
      const policy = RecommendationPolicy(
        weightSpacedReview: 0.50,
        weightPrerequisiteGap: 0.20,
        weightWeakDomain: 0.15,
        weightCurriculumAdvance: 0.10,
        weightPracticeDensity: 0.05,
        maxRecommendations: 5,
        weakDomainThreshold: 0.75,
        minDomainAttempts: 5,
        targetDomainId: 'domain_constitutional_foundations',
        targetUnitId: 'unit_personal_liberty_art21',
      );

      expect(policy.totalWeight, closeTo(1.00, 0.0001));
      expect(policy.minDomainAttempts, equals(5));

      final json = policy.toJson();
      final restored = RecommendationPolicy.fromJson(json);

      expect(restored, equals(policy));
      expect(
          restored.targetDomainId, equals('domain_constitutional_foundations'));
      expect(restored.targetUnitId, equals('unit_personal_liberty_art21'));
    });

    test('validates assertion boundaries', () {
      expect(
        () => RecommendationPolicy(weightSpacedReview: -0.1),
        throwsAssertionError,
      );

      expect(
        () => RecommendationPolicy(maxRecommendations: 0),
        throwsAssertionError,
      );

      expect(
        () => RecommendationPolicy(weakDomainThreshold: 1.5),
        throwsAssertionError,
      );

      expect(
        () => RecommendationPolicy(minDomainAttempts: 0),
        throwsAssertionError,
      );
    });
  });
}
