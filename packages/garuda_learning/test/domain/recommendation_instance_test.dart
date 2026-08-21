import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/dismissal_reason.dart';
import 'package:garuda_learning/domain/entities/learning_recommendation.dart';
import 'package:garuda_learning/domain/entities/recommendation_instance.dart';
import 'package:garuda_learning/domain/entities/recommendation_lifecycle_state.dart';
import 'package:garuda_learning/domain/entities/recommendation_type.dart';
import 'package:garuda_learning/domain/entities/session_configuration.dart';

void main() {
  group('RecommendationInstance Domain Tests (P22 Stage 5)', () {
    final baseTime = DateTime.utc(2026, 8, 20, 10, 0, 0);

    final baseConfig = SessionConfiguration(
      learnerId: 'learner-001',
      objectiveIds: const ['lo-01'],
      questionLimit: 10,
    );

    RecommendationInstance createValidInstance({
      String instanceId = 'inst-001',
      RecommendationLifecycleState state = RecommendationLifecycleState.issued,
      Duration validityDuration =
          RecommendationInstance.defaultValidityDuration,
      DismissalReason? dismissalReason,
    }) {
      return RecommendationInstance(
        instanceId: instanceId,
        learnerId: 'learner-001',
        objectiveId: 'lo-01',
        recommendationId: 'rec-001',
        recommendationType: RecommendationType.spacedReview,
        priorityScore: 0.85,
        rationale: 'Review scheduled due to forgetting curve',
        suggestedConfig: baseConfig,
        state: state,
        issuedAt: baseTime,
        validityDuration: validityDuration,
        dismissalReason: dismissalReason,
      );
    }

    test('1. Valid construction and field access', () {
      final inst = createValidInstance();
      expect(inst.instanceId, equals('inst-001'));
      expect(inst.learnerId, equals('learner-001'));
      expect(inst.objectiveId, equals('lo-01'));
      expect(inst.recommendationId, equals('rec-001'));
      expect(inst.recommendationType, equals(RecommendationType.spacedReview));
      expect(inst.priorityScore, closeTo(0.85, 0.0001));
      expect(inst.state, equals(RecommendationLifecycleState.issued));
      expect(inst.issuedAt, equals(baseTime));
      expect(inst.validityDuration,
          equals(RecommendationInstance.defaultValidityDuration));
    });

    test('2. Constructor validation guards', () {
      expect(
        () => RecommendationInstance(
          instanceId: '',
          learnerId: 'l1',
          objectiveId: 'lo1',
          recommendationId: 'r1',
          recommendationType: RecommendationType.spacedReview,
          priorityScore: 0.5,
          rationale: 'Test',
          suggestedConfig: baseConfig,
          issuedAt: baseTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationInstance(
          instanceId: 'i1',
          learnerId: '',
          objectiveId: 'lo1',
          recommendationId: 'r1',
          recommendationType: RecommendationType.spacedReview,
          priorityScore: 0.5,
          rationale: 'Test',
          suggestedConfig: baseConfig,
          issuedAt: baseTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationInstance(
          instanceId: 'i1',
          learnerId: 'l1',
          objectiveId: '',
          recommendationId: 'r1',
          recommendationType: RecommendationType.spacedReview,
          priorityScore: 0.5,
          rationale: 'Test',
          suggestedConfig: baseConfig,
          issuedAt: baseTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationInstance(
          instanceId: 'i1',
          learnerId: 'l1',
          objectiveId: 'lo1',
          recommendationId: '',
          recommendationType: RecommendationType.spacedReview,
          priorityScore: 0.5,
          rationale: 'Test',
          suggestedConfig: baseConfig,
          issuedAt: baseTime,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationInstance(
          instanceId: 'i1',
          learnerId: 'l1',
          objectiveId: 'lo1',
          recommendationId: 'r1',
          recommendationType: RecommendationType.spacedReview,
          priorityScore: 0.5,
          rationale: '',
          suggestedConfig: baseConfig,
          issuedAt: baseTime,
        ),
        throwsArgumentError,
      );

      // Dismissed state requires dismissalReason
      expect(
        () => RecommendationInstance(
          instanceId: 'i1',
          learnerId: 'l1',
          objectiveId: 'lo1',
          recommendationId: 'r1',
          recommendationType: RecommendationType.spacedReview,
          priorityScore: 0.5,
          rationale: 'Test',
          suggestedConfig: baseConfig,
          state: RecommendationLifecycleState.dismissed,
          dismissalReason: null,
          issuedAt: baseTime,
        ),
        throwsArgumentError,
      );
    });

    test('3. Factory from LearningRecommendation', () {
      final rec = LearningRecommendation(
        recommendationId: 'rec-p21',
        learnerId: 'learner-p21',
        objectiveId: 'lo-p21',
        type: RecommendationType.curriculumAdvance,
        priorityScore: 0.95,
        rationale: 'Advance to next unit',
        suggestedConfig: baseConfig,
        metadata: const {'origin': 'p21_planner'},
      );

      final instance = RecommendationInstance.fromRecommendation(
        rec,
        instanceId: 'inst-p21',
        issuedAt: baseTime,
      );

      expect(instance.instanceId, equals('inst-p21'));
      expect(instance.recommendationId, equals('rec-p21'));
      expect(instance.learnerId, equals('learner-p21'));
      expect(instance.recommendationType,
          equals(RecommendationType.curriculumAdvance));
      expect(instance.state, equals(RecommendationLifecycleState.issued));
      expect(instance.metadata['origin'], equals('p21_planner'));
    });

    test('4. Lifecycle transitions and helpers', () {
      final inst = createValidInstance();

      // issued -> viewed
      final viewed =
          inst.markViewed(asOf: baseTime.add(const Duration(minutes: 5)));
      expect(viewed.state, equals(RecommendationLifecycleState.viewed));

      // viewed -> accepted
      final accepted =
          viewed.accept(asOf: baseTime.add(const Duration(minutes: 10)));
      expect(accepted.state, equals(RecommendationLifecycleState.accepted));

      // accepted -> started
      final started =
          accepted.start(asOf: baseTime.add(const Duration(minutes: 15)));
      expect(started.state, equals(RecommendationLifecycleState.started));

      // started -> completed
      final completed =
          started.complete(asOf: baseTime.add(const Duration(minutes: 30)));
      expect(completed.state, equals(RecommendationLifecycleState.completed));
      expect(completed.state.isTerminal, isTrue);
    });

    test('5. Dismissal transition requires reason', () {
      final inst = createValidInstance();

      final dismissed = inst.dismiss(
        reason: DismissalReason.tooEasy,
        asOf: baseTime.add(const Duration(minutes: 5)),
      );
      expect(dismissed.state, equals(RecommendationLifecycleState.dismissed));
      expect(dismissed.dismissalReason, equals(DismissalReason.tooEasy));

      // Cannot transition from terminal dismissed state
      expect(
        () => dismissed.accept(asOf: baseTime.add(const Duration(minutes: 10))),
        throwsStateError,
      );
    });

    test('6. Invalid state transitions throw StateError', () {
      final inst = createValidInstance();

      // issued cannot transition directly to started or completed
      expect(
        () => inst.start(asOf: baseTime.add(const Duration(minutes: 5))),
        throwsStateError,
      );
      expect(
        () => inst.complete(asOf: baseTime.add(const Duration(minutes: 5))),
        throwsStateError,
      );
    });

    test('7. Expiration check against validityDuration', () {
      final inst = createValidInstance(
        validityDuration: const Duration(days: 3),
      );

      expect(
        inst.isExpired(asOf: baseTime.add(const Duration(days: 2))),
        isFalse,
      );
      expect(
        inst.isExpired(asOf: baseTime.add(const Duration(days: 4))),
        isTrue,
      );

      // Terminal states are not considered expired
      final dismissed = inst.dismiss(
        reason: DismissalReason.other,
        asOf: baseTime,
      );
      expect(
        dismissed.isExpired(asOf: baseTime.add(const Duration(days: 10))),
        isFalse,
      );
    });

    test('8. JSON serialization and deserialization round-trip', () {
      final original = createValidInstance(
        dismissalReason: null,
      );

      final json = original.toJson();
      final restored = RecommendationInstance.fromJson(json);

      expect(restored, equals(original));
      expect(restored.instanceId, equals(original.instanceId));
      expect(restored.priorityScore, closeTo(original.priorityScore, 0.0001));
    });

    test('9. Value equality and hashCode', () {
      final a = createValidInstance();
      final b = createValidInstance();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
