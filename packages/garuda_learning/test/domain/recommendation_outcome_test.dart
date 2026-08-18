import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/recommendation_outcome.dart';

void main() {
  group('RecommendationOutcome Domain Entity Tests', () {
    final timestamp = DateTime.utc(2026, 8, 18, 11, 0, 0);

    test(
        'instantiates valid recommendation outcome with calculated completion rate',
        () {
      final outcome = RecommendationOutcome(
        outcomeId: 'out_101',
        instanceId: 'inst_202',
        sessionId: 'session_303',
        totalQuestionsScheduled: 10,
        totalQuestionsAttempted: 8,
        sessionAccuracy: 0.75,
        isCompleted: true,
        evaluatedAt: timestamp,
        metadata: const {'durationSeconds': 420},
      );

      expect(outcome.outcomeId, equals('out_101'));
      expect(outcome.instanceId, equals('inst_202'));
      expect(outcome.sessionId, equals('session_303'));
      expect(outcome.totalQuestionsScheduled, equals(10));
      expect(outcome.totalQuestionsAttempted, equals(8));
      expect(outcome.completionRate, closeTo(0.8, 0.0001));
      expect(outcome.sessionAccuracy, closeTo(0.75, 0.0001));
      expect(outcome.isCompleted, isTrue);
      expect(outcome.insufficientEvidence, isFalse);
      expect(outcome.evaluatedAt, equals(timestamp));
      expect(outcome.metadata['durationSeconds'], equals(420));
    });

    test('handles zero attempts safely with insufficient evidence flag', () {
      final unattemptedOutcome = RecommendationOutcome(
        outcomeId: 'out_unattempted',
        instanceId: 'inst_1',
        sessionId: 'session_1',
        totalQuestionsScheduled: 10,
        totalQuestionsAttempted: 0,
        sessionAccuracy: null,
        isCompleted: false,
        evaluatedAt: timestamp,
      );

      expect(unattemptedOutcome.completionRate, equals(0.0));
      expect(unattemptedOutcome.sessionAccuracy, isNull);
      expect(unattemptedOutcome.isCompleted, isFalse);
      expect(unattemptedOutcome.insufficientEvidence, isTrue);
    });

    test('handles zero scheduled questions safely without division by zero',
        () {
      final zeroScheduled = RecommendationOutcome(
        outcomeId: 'out_zero_sched',
        instanceId: 'inst_1',
        sessionId: 'session_1',
        totalQuestionsScheduled: 0,
        totalQuestionsAttempted: 0,
        isCompleted: false,
        evaluatedAt: timestamp,
      );

      expect(zeroScheduled.completionRate, equals(0.0));
      expect(zeroScheduled.insufficientEvidence, isTrue);
    });

    test('clamps completionRate and sessionAccuracy to valid range [0.0, 1.0]',
        () {
      final clamped = RecommendationOutcome(
        outcomeId: 'out_clamped',
        instanceId: 'inst_1',
        sessionId: 'session_1',
        totalQuestionsScheduled: 10,
        totalQuestionsAttempted: 10,
        completionRate: 1.5,
        sessionAccuracy: 1.25,
        isCompleted: true,
        evaluatedAt: timestamp,
      );

      expect(clamped.completionRate, equals(1.0));
      expect(clamped.sessionAccuracy, equals(1.0));
    });

    test('throws ArgumentError on invalid inputs', () {
      expect(
        () => RecommendationOutcome(
          outcomeId: '',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          totalQuestionsScheduled: 10,
          totalQuestionsAttempted: 5,
          isCompleted: true,
          evaluatedAt: timestamp,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationOutcome(
          outcomeId: 'out_1',
          instanceId: '  ',
          sessionId: 'sess_1',
          totalQuestionsScheduled: 10,
          totalQuestionsAttempted: 5,
          isCompleted: true,
          evaluatedAt: timestamp,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationOutcome(
          outcomeId: 'out_1',
          instanceId: 'inst_1',
          sessionId: '',
          totalQuestionsScheduled: 10,
          totalQuestionsAttempted: 5,
          isCompleted: true,
          evaluatedAt: timestamp,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationOutcome(
          outcomeId: 'out_1',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          totalQuestionsScheduled: -1,
          totalQuestionsAttempted: 5,
          isCompleted: true,
          evaluatedAt: timestamp,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationOutcome(
          outcomeId: 'out_1',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          totalQuestionsScheduled: 10,
          totalQuestionsAttempted: -2,
          isCompleted: true,
          evaluatedAt: timestamp,
        ),
        throwsArgumentError,
      );
    });

    test('serializes and deserializes to/from JSON accurately', () {
      final outcome = RecommendationOutcome(
        outcomeId: 'out_json',
        instanceId: 'inst_json',
        sessionId: 'sess_json',
        totalQuestionsScheduled: 15,
        totalQuestionsAttempted: 12,
        completionRate: 0.8,
        sessionAccuracy: 0.833,
        isCompleted: true,
        insufficientEvidence: false,
        evaluatedAt: timestamp,
        metadata: const {'policy': 'spacedReview'},
      );

      final json = outcome.toJson();
      final restored = RecommendationOutcome.fromJson(json);

      expect(restored, equals(outcome));
      expect(restored.completionRate, closeTo(0.8, 0.0001));
      expect(restored.sessionAccuracy, closeTo(0.833, 0.0001));
      expect(restored.metadata['policy'], equals('spacedReview'));
    });

    test('value equality and hashCode are deterministic', () {
      final o1 = RecommendationOutcome(
        outcomeId: 'out_1',
        instanceId: 'inst_1',
        sessionId: 'sess_1',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.8,
        isCompleted: true,
        evaluatedAt: timestamp,
      );
      final o2 = RecommendationOutcome(
        outcomeId: 'out_1',
        instanceId: 'inst_1',
        sessionId: 'sess_1',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.8,
        isCompleted: true,
        evaluatedAt: timestamp,
      );
      final o3 = RecommendationOutcome(
        outcomeId: 'out_2',
        instanceId: 'inst_1',
        sessionId: 'sess_1',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.8,
        isCompleted: true,
        evaluatedAt: timestamp,
      );

      expect(o1, equals(o2));
      expect(o1.hashCode, equals(o2.hashCode));
      expect(o1, isNot(equals(o3)));
    });
  });
}
