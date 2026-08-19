import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/dismissal_reason.dart';
import 'package:garuda_learning/domain/entities/recommendation_instance.dart';
import 'package:garuda_learning/domain/entities/recommendation_interaction.dart';
import 'package:garuda_learning/domain/entities/recommendation_lifecycle_state.dart';
import 'package:garuda_learning/domain/entities/recommendation_outcome.dart';
import 'package:garuda_learning/domain/entities/recommendation_session_link.dart';
import 'package:garuda_learning/domain/entities/recommendation_type.dart';
import 'package:garuda_learning/domain/entities/session_configuration.dart';
import 'package:garuda_learning/repository/in_memory_recommendation_lifecycle_repository.dart';
import 'package:garuda_learning/repository/recommendation_lifecycle_repository.dart';

void main() {
  group('InMemoryRecommendationLifecycleRepository', () {
    late InMemoryRecommendationLifecycleRepository repo;

    final baseConfig = SessionConfiguration(
      learnerId: 'learner_1',
      objectiveIds: const ['lo_1'],
      questionLimit: 10,
    );

    final baseTime = DateTime.utc(2026, 8, 18, 12, 0, 0);

    RecommendationInstance createInstance({
      String instanceId = 'inst_1',
      String learnerId = 'learner_1',
      String objectiveId = 'lo_1',
      String recommendationId = 'rec_1',
      RecommendationLifecycleState state = RecommendationLifecycleState.issued,
      DateTime? issuedAt,
    }) {
      return RecommendationInstance(
        instanceId: instanceId,
        learnerId: learnerId,
        objectiveId: objectiveId,
        recommendationId: recommendationId,
        recommendationType: RecommendationType.spacedReview,
        priorityScore: 0.85,
        rationale: 'Review urgency high',
        suggestedConfig: baseConfig,
        state: state,
        issuedAt: issuedAt ?? baseTime,
      );
    }

    setUp(() {
      repo = InMemoryRecommendationLifecycleRepository();
    });

    // -----------------------------------------------------------------------
    // Interface conformance
    // -----------------------------------------------------------------------

    test('implements RecommendationLifecycleRepository', () {
      expect(repo, isA<RecommendationLifecycleRepository>());
    });

    // -----------------------------------------------------------------------
    // Instance CRUD
    // -----------------------------------------------------------------------

    group('instance operations', () {
      test('save and retrieve by instanceId', () async {
        final instance = createInstance();
        await repo.saveInstance(instance);

        final retrieved = await repo.getInstanceById('inst_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.instanceId, equals('inst_1'));
        expect(retrieved.learnerId, equals('learner_1'));
        expect(retrieved.objectiveId, equals('lo_1'));
        expect(retrieved.state, equals(RecommendationLifecycleState.issued));
      });

      test('retrieve by recommendationId', () async {
        final instance = createInstance(recommendationId: 'rec_42');
        await repo.saveInstance(instance);

        final retrieved = await repo.getInstanceByRecommendationId('rec_42');
        expect(retrieved, isNotNull);
        expect(retrieved!.recommendationId, equals('rec_42'));
      });

      test('returns null for missing instanceId', () async {
        final result = await repo.getInstanceById('nonexistent');
        expect(result, isNull);
      });

      test('returns null for missing recommendationId', () async {
        final result = await repo.getInstanceByRecommendationId('nonexistent');
        expect(result, isNull);
      });

      test('save overwrites existing instance with same instanceId', () async {
        final original = createInstance();
        await repo.saveInstance(original);

        final updated = original.transitionTo(
          RecommendationLifecycleState.viewed,
          asOf: baseTime.add(const Duration(minutes: 5)),
        );
        await repo.saveInstance(updated);

        final retrieved = await repo.getInstanceById('inst_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.state, equals(RecommendationLifecycleState.viewed));
      });

      test('getInstancesForLearner returns all for learner', () async {
        await repo.saveInstance(createInstance(
          instanceId: 'inst_a',
          learnerId: 'learner_1',
        ));
        await repo.saveInstance(createInstance(
          instanceId: 'inst_b',
          learnerId: 'learner_1',
        ));
        await repo.saveInstance(createInstance(
          instanceId: 'inst_c',
          learnerId: 'learner_2',
        ));

        final results = await repo.getInstancesForLearner('learner_1');
        expect(results.length, equals(2));
        expect(
          results.map((e) => e.instanceId).toList(),
          containsAll(['inst_a', 'inst_b']),
        );
      });

      test('getInstancesForLearner filters by state', () async {
        final issued = createInstance(instanceId: 'inst_1');
        final viewed = createInstance(instanceId: 'inst_2').transitionTo(
          RecommendationLifecycleState.viewed,
          asOf: baseTime.add(const Duration(minutes: 1)),
        );

        await repo.saveInstance(issued);
        await repo.saveInstance(viewed);

        final issuedResults = await repo.getInstancesForLearner(
          'learner_1',
          state: RecommendationLifecycleState.issued,
        );
        expect(issuedResults.length, equals(1));
        expect(issuedResults.first.instanceId, equals('inst_1'));

        final viewedResults = await repo.getInstancesForLearner(
          'learner_1',
          state: RecommendationLifecycleState.viewed,
        );
        expect(viewedResults.length, equals(1));
        expect(viewedResults.first.instanceId, equals('inst_2'));
      });

      test('getInstancesForLearner filters by objectiveId', () async {
        await repo.saveInstance(createInstance(
          instanceId: 'inst_1',
          objectiveId: 'lo_1',
        ));
        await repo.saveInstance(createInstance(
          instanceId: 'inst_2',
          objectiveId: 'lo_2',
        ));

        final results = await repo.getInstancesForLearner(
          'learner_1',
          objectiveId: 'lo_1',
        );
        expect(results.length, equals(1));
        expect(results.first.objectiveId, equals('lo_1'));
      });

      test('getInstancesForLearner returns empty for unknown learner',
          () async {
        await repo.saveInstance(createInstance());
        final results = await repo.getInstancesForLearner('unknown');
        expect(results, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // Deterministic Ordering
    // -----------------------------------------------------------------------

    group('deterministic ordering', () {
      test('instances ordered by issuedAt ascending', () async {
        await repo.saveInstance(createInstance(
          instanceId: 'inst_b',
          issuedAt: baseTime.add(const Duration(hours: 2)),
        ));
        await repo.saveInstance(createInstance(
          instanceId: 'inst_a',
          issuedAt: baseTime,
        ));
        await repo.saveInstance(createInstance(
          instanceId: 'inst_c',
          issuedAt: baseTime.add(const Duration(hours: 1)),
        ));

        final results = await repo.getInstancesForLearner('learner_1');
        expect(results.length, equals(3));
        expect(results[0].instanceId, equals('inst_a'));
        expect(results[1].instanceId, equals('inst_c'));
        expect(results[2].instanceId, equals('inst_b'));
      });

      test('instances with same issuedAt tie-break by instanceId', () async {
        await repo.saveInstance(createInstance(
          instanceId: 'inst_c',
          issuedAt: baseTime,
        ));
        await repo.saveInstance(createInstance(
          instanceId: 'inst_a',
          issuedAt: baseTime,
        ));
        await repo.saveInstance(createInstance(
          instanceId: 'inst_b',
          issuedAt: baseTime,
        ));

        final results = await repo.getInstancesForLearner('learner_1');
        expect(results[0].instanceId, equals('inst_a'));
        expect(results[1].instanceId, equals('inst_b'));
        expect(results[2].instanceId, equals('inst_c'));
      });

      test('interactions ordered by timestamp ascending', () async {
        await repo.saveInstance(createInstance());

        await repo.recordInteraction(RecommendationInteraction.viewed(
          interactionId: 'int_2',
          instanceId: 'inst_1',
          timestamp: baseTime.add(const Duration(minutes: 10)),
        ));
        await repo.recordInteraction(RecommendationInteraction.accepted(
          interactionId: 'int_1',
          instanceId: 'inst_1',
          timestamp: baseTime.add(const Duration(minutes: 5)),
        ));

        final interactions = await repo.getInteractionsForInstance('inst_1');
        expect(interactions.length, equals(2));
        expect(interactions[0].interactionId, equals('int_1'));
        expect(interactions[1].interactionId, equals('int_2'));
      });

      test('session links ordered by linkedAt ascending', () async {
        await repo.saveSessionLink(RecommendationSessionLink(
          linkId: 'link_2',
          instanceId: 'inst_1',
          sessionId: 'sess_2',
          linkedAt: baseTime.add(const Duration(hours: 1)),
        ));
        await repo.saveSessionLink(RecommendationSessionLink(
          linkId: 'link_1',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          linkedAt: baseTime,
        ));

        final links = await repo.getLinksForInstance('inst_1');
        expect(links.length, equals(2));
        expect(links[0].linkId, equals('link_1'));
        expect(links[1].linkId, equals('link_2'));
      });
    });

    // -----------------------------------------------------------------------
    // Interaction Operations
    // -----------------------------------------------------------------------

    group('interaction operations', () {
      test('record and retrieve interactions for instance', () async {
        final interaction = RecommendationInteraction.viewed(
          interactionId: 'int_1',
          instanceId: 'inst_1',
          timestamp: baseTime,
        );
        await repo.recordInteraction(interaction);

        final results = await repo.getInteractionsForInstance('inst_1');
        expect(results.length, equals(1));
        expect(results.first.interactionId, equals('int_1'));
        expect(results.first.targetState,
            equals(RecommendationLifecycleState.viewed));
      });

      test('returns empty list for instance with no interactions', () async {
        final results = await repo.getInteractionsForInstance('nonexistent');
        expect(results, isEmpty);
      });

      test('records dismissed interaction with reason', () async {
        final interaction = RecommendationInteraction.dismissed(
          interactionId: 'int_d',
          instanceId: 'inst_1',
          reason: DismissalReason.tooEasy,
          timestamp: baseTime,
        );
        await repo.recordInteraction(interaction);

        final results = await repo.getInteractionsForInstance('inst_1');
        expect(results.first.dismissalReason, equals(DismissalReason.tooEasy));
      });
    });

    // -----------------------------------------------------------------------
    // Session Link Operations
    // -----------------------------------------------------------------------

    group('session link operations', () {
      test('save and retrieve link by sessionId', () async {
        final link = RecommendationSessionLink(
          linkId: 'link_1',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          linkedAt: baseTime,
        );
        await repo.saveSessionLink(link);

        final retrieved = await repo.getLinkForSession('sess_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.linkId, equals('link_1'));
        expect(retrieved.instanceId, equals('inst_1'));
      });

      test('returns null for missing session link', () async {
        final result = await repo.getLinkForSession('nonexistent');
        expect(result, isNull);
      });

      test('retrieve all links for instance', () async {
        await repo.saveSessionLink(RecommendationSessionLink(
          linkId: 'link_1',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          linkedAt: baseTime,
        ));
        await repo.saveSessionLink(RecommendationSessionLink(
          linkId: 'link_2',
          instanceId: 'inst_1',
          sessionId: 'sess_2',
          linkedAt: baseTime.add(const Duration(hours: 1)),
        ));
        await repo.saveSessionLink(RecommendationSessionLink(
          linkId: 'link_3',
          instanceId: 'inst_2',
          sessionId: 'sess_3',
          linkedAt: baseTime,
        ));

        final links = await repo.getLinksForInstance('inst_1');
        expect(links.length, equals(2));
        expect(links.every((l) => l.instanceId == 'inst_1'), isTrue);
      });

      test('returns empty list for instance with no links', () async {
        final results = await repo.getLinksForInstance('nonexistent');
        expect(results, isEmpty);
      });
    });

    // -----------------------------------------------------------------------
    // Outcome Operations
    // -----------------------------------------------------------------------

    group('outcome operations', () {
      test('save and retrieve outcome for instance', () async {
        final outcome = RecommendationOutcome(
          outcomeId: 'out_1',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          totalQuestionsScheduled: 10,
          totalQuestionsAttempted: 8,
          isCompleted: true,
          evaluatedAt: baseTime,
        );
        await repo.saveOutcome(outcome);

        final retrieved = await repo.getOutcomeForInstance('inst_1');
        expect(retrieved, isNotNull);
        expect(retrieved!.outcomeId, equals('out_1'));
        expect(retrieved.totalQuestionsAttempted, equals(8));
        expect(retrieved.isCompleted, isTrue);
      });

      test('returns null for missing outcome', () async {
        final result = await repo.getOutcomeForInstance('nonexistent');
        expect(result, isNull);
      });

      test('save overwrites existing outcome for same instance', () async {
        final first = RecommendationOutcome(
          outcomeId: 'out_1',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          totalQuestionsScheduled: 10,
          totalQuestionsAttempted: 5,
          isCompleted: false,
          evaluatedAt: baseTime,
        );
        await repo.saveOutcome(first);

        final second = RecommendationOutcome(
          outcomeId: 'out_2',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          totalQuestionsScheduled: 10,
          totalQuestionsAttempted: 10,
          isCompleted: true,
          evaluatedAt: baseTime.add(const Duration(hours: 1)),
        );
        await repo.saveOutcome(second);

        final retrieved = await repo.getOutcomeForInstance('inst_1');
        expect(retrieved!.outcomeId, equals('out_2'));
        expect(retrieved.totalQuestionsAttempted, equals(10));
        expect(retrieved.isCompleted, isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // Clear
    // -----------------------------------------------------------------------

    group('clear', () {
      test('clear removes all records', () async {
        await repo.saveInstance(createInstance());
        await repo.recordInteraction(RecommendationInteraction.viewed(
          interactionId: 'int_1',
          instanceId: 'inst_1',
          timestamp: baseTime,
        ));
        await repo.saveSessionLink(RecommendationSessionLink(
          linkId: 'link_1',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          linkedAt: baseTime,
        ));
        await repo.saveOutcome(RecommendationOutcome(
          outcomeId: 'out_1',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          totalQuestionsScheduled: 10,
          totalQuestionsAttempted: 10,
          isCompleted: true,
          evaluatedAt: baseTime,
        ));

        await repo.clear();

        expect(await repo.getInstanceById('inst_1'), isNull);
        expect(await repo.getInteractionsForInstance('inst_1'), isEmpty);
        expect(await repo.getLinksForInstance('inst_1'), isEmpty);
        expect(await repo.getOutcomeForInstance('inst_1'), isNull);
      });
    });

    // -----------------------------------------------------------------------
    // Defensive Copy / Isolation
    // -----------------------------------------------------------------------

    group('defensive copy and isolation', () {
      test('saved instance is isolated from caller reference', () async {
        final original = createInstance();
        await repo.saveInstance(original);

        // Mutate original via state transition — repository should be unaffected.
        final mutated = original.transitionTo(
          RecommendationLifecycleState.viewed,
          asOf: baseTime.add(const Duration(minutes: 5)),
        );
        // mutated is a new object; original is immutable.
        // Verify repository still returns the issued state.
        final retrieved = await repo.getInstanceById('inst_1');
        expect(retrieved!.state, equals(RecommendationLifecycleState.issued));
        expect(mutated.state, equals(RecommendationLifecycleState.viewed));
      });

      test('retrieved instance is isolated from repository state', () async {
        await repo.saveInstance(createInstance());

        final retrieved1 = await repo.getInstanceById('inst_1');
        final retrieved2 = await repo.getInstanceById('inst_1');

        // Different object references but equal values.
        expect(retrieved1, equals(retrieved2));
        expect(identical(retrieved1, retrieved2), isFalse);
      });

      test('modifying retrieved list does not affect repository', () async {
        await repo.saveInstance(
          createInstance(instanceId: 'inst_1'),
        );
        await repo.saveInstance(
          createInstance(instanceId: 'inst_2'),
        );

        final results = await repo.getInstancesForLearner('learner_1');
        expect(results.length, equals(2));

        // Mutate the returned list.
        results.clear();

        // Repository should still have both instances.
        final recheck = await repo.getInstancesForLearner('learner_1');
        expect(recheck.length, equals(2));
      });

      test('retrieved interaction is isolated from repository state', () async {
        await repo.recordInteraction(RecommendationInteraction.viewed(
          interactionId: 'int_1',
          instanceId: 'inst_1',
          timestamp: baseTime,
        ));

        final results1 = await repo.getInteractionsForInstance('inst_1');
        final results2 = await repo.getInteractionsForInstance('inst_1');

        expect(results1.first, equals(results2.first));
        expect(identical(results1.first, results2.first), isFalse);
      });

      test('retrieved session link is isolated from repository state',
          () async {
        await repo.saveSessionLink(RecommendationSessionLink(
          linkId: 'link_1',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          linkedAt: baseTime,
        ));

        final r1 = await repo.getLinkForSession('sess_1');
        final r2 = await repo.getLinkForSession('sess_1');

        expect(r1, equals(r2));
        expect(identical(r1, r2), isFalse);
      });

      test('retrieved outcome is isolated from repository state', () async {
        await repo.saveOutcome(RecommendationOutcome(
          outcomeId: 'out_1',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          totalQuestionsScheduled: 10,
          totalQuestionsAttempted: 8,
          isCompleted: true,
          evaluatedAt: baseTime,
        ));

        final r1 = await repo.getOutcomeForInstance('inst_1');
        final r2 = await repo.getOutcomeForInstance('inst_1');

        expect(r1, equals(r2));
        expect(identical(r1, r2), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // JSON Round-Trip Persistence Safety
    // -----------------------------------------------------------------------

    group('persistence round-trip', () {
      test('instance survives JSON round-trip via repository', () async {
        final instance = createInstance(
          instanceId: 'inst_rt',
          recommendationId: 'rec_rt',
        );
        await repo.saveInstance(instance);

        final retrieved = await repo.getInstanceById('inst_rt');
        expect(retrieved, isNotNull);
        expect(retrieved!.instanceId, equals('inst_rt'));
        expect(retrieved.recommendationId, equals('rec_rt'));
        expect(retrieved.priorityScore, closeTo(0.85, 0.01));
        expect(retrieved.state, equals(RecommendationLifecycleState.issued));
      });

      test('interaction survives JSON round-trip via repository', () async {
        final interaction = RecommendationInteraction.dismissed(
          interactionId: 'int_rt',
          instanceId: 'inst_1',
          reason: DismissalReason.alreadyMastered,
          timestamp: baseTime,
          metadata: {'source': 'test'},
        );
        await repo.recordInteraction(interaction);

        final results = await repo.getInteractionsForInstance('inst_1');
        expect(results.first.interactionId, equals('int_rt'));
        expect(results.first.dismissalReason,
            equals(DismissalReason.alreadyMastered));
      });

      test('session link survives JSON round-trip via repository', () async {
        final link = RecommendationSessionLink(
          linkId: 'link_rt',
          instanceId: 'inst_1',
          sessionId: 'sess_rt',
          linkedAt: baseTime,
        );
        await repo.saveSessionLink(link);

        final retrieved = await repo.getLinkForSession('sess_rt');
        expect(retrieved!.linkId, equals('link_rt'));
        expect(retrieved.sessionId, equals('sess_rt'));
      });

      test('outcome survives JSON round-trip via repository', () async {
        final outcome = RecommendationOutcome(
          outcomeId: 'out_rt',
          instanceId: 'inst_1',
          sessionId: 'sess_1',
          totalQuestionsScheduled: 20,
          totalQuestionsAttempted: 15,
          sessionAccuracy: 0.8,
          isCompleted: true,
          evaluatedAt: baseTime,
        );
        await repo.saveOutcome(outcome);

        final retrieved = await repo.getOutcomeForInstance('inst_1');
        expect(retrieved!.outcomeId, equals('out_rt'));
        expect(retrieved.totalQuestionsScheduled, equals(20));
        expect(retrieved.totalQuestionsAttempted, equals(15));
        expect(retrieved.sessionAccuracy, closeTo(0.8, 0.0001));
      });
    });
  });
}
