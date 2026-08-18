import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/dismissal_reason.dart';
import 'package:garuda_learning/domain/entities/recommendation_interaction.dart';
import 'package:garuda_learning/domain/entities/recommendation_lifecycle_state.dart';

void main() {
  group('RecommendationInteraction Domain Entity Tests', () {
    final timestamp = DateTime.utc(2026, 8, 18, 10, 0, 0);

    test('instantiates valid interaction with defaults and explicit values',
        () {
      final interaction = RecommendationInteraction(
        interactionId: 'inter_101',
        instanceId: 'inst_202',
        targetState: RecommendationLifecycleState.viewed,
        timestamp: timestamp,
        metadata: const {'source': 'feed_card'},
      );

      expect(interaction.interactionId, equals('inter_101'));
      expect(interaction.instanceId, equals('inst_202'));
      expect(
          interaction.targetState, equals(RecommendationLifecycleState.viewed));
      expect(interaction.dismissalReason, isNull);
      expect(interaction.timestamp, equals(timestamp));
      expect(interaction.metadata['source'], equals('feed_card'));
    });

    test('factory constructors produce valid state-specific interactions', () {
      final viewed = RecommendationInteraction.viewed(
        interactionId: 'v1',
        instanceId: 'inst_1',
        timestamp: timestamp,
      );
      expect(viewed.targetState, equals(RecommendationLifecycleState.viewed));

      final accepted = RecommendationInteraction.accepted(
        interactionId: 'a1',
        instanceId: 'inst_1',
        timestamp: timestamp,
      );
      expect(
          accepted.targetState, equals(RecommendationLifecycleState.accepted));

      final dismissed = RecommendationInteraction.dismissed(
        interactionId: 'd1',
        instanceId: 'inst_1',
        reason: DismissalReason.tooDifficult,
        timestamp: timestamp,
      );
      expect(dismissed.targetState,
          equals(RecommendationLifecycleState.dismissed));
      expect(dismissed.dismissalReason, equals(DismissalReason.tooDifficult));

      final deferred = RecommendationInteraction.deferred(
        interactionId: 'def1',
        instanceId: 'inst_1',
        timestamp: timestamp,
      );
      expect(
          deferred.targetState, equals(RecommendationLifecycleState.deferred));
    });

    test('throws ArgumentError on invalid construction', () {
      expect(
        () => RecommendationInteraction(
          interactionId: '   ',
          instanceId: 'inst_1',
          targetState: RecommendationLifecycleState.viewed,
          timestamp: timestamp,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationInteraction(
          interactionId: 'inter_1',
          instanceId: '',
          targetState: RecommendationLifecycleState.viewed,
          timestamp: timestamp,
        ),
        throwsArgumentError,
      );

      // Dismissed targetState requires a non-null dismissalReason
      expect(
        () => RecommendationInteraction(
          interactionId: 'inter_1',
          instanceId: 'inst_1',
          targetState: RecommendationLifecycleState.dismissed,
          dismissalReason: null,
          timestamp: timestamp,
        ),
        throwsArgumentError,
      );
    });

    test('serializes and deserializes to/from JSON accurately', () {
      final interaction = RecommendationInteraction.dismissed(
        interactionId: 'inter_999',
        instanceId: 'inst_888',
        reason: DismissalReason.alreadyMastered,
        timestamp: timestamp,
        metadata: const {'reasonNote': 'Done in offline class'},
      );

      final json = interaction.toJson();
      final restored = RecommendationInteraction.fromJson(json);

      expect(restored, equals(interaction));
      expect(
          restored.targetState, equals(RecommendationLifecycleState.dismissed));
      expect(restored.dismissalReason, equals(DismissalReason.alreadyMastered));
      expect(restored.metadata['reasonNote'], equals('Done in offline class'));
    });

    test('value equality and hashCode are deterministic', () {
      final i1 = RecommendationInteraction(
        interactionId: 'int_1',
        instanceId: 'inst_1',
        targetState: RecommendationLifecycleState.accepted,
        timestamp: timestamp,
      );
      final i2 = RecommendationInteraction(
        interactionId: 'int_1',
        instanceId: 'inst_1',
        targetState: RecommendationLifecycleState.accepted,
        timestamp: timestamp,
      );
      final i3 = RecommendationInteraction(
        interactionId: 'int_2',
        instanceId: 'inst_1',
        targetState: RecommendationLifecycleState.accepted,
        timestamp: timestamp,
      );

      expect(i1, equals(i2));
      expect(i1.hashCode, equals(i2.hashCode));
      expect(i1, isNot(equals(i3)));
    });
  });
}
