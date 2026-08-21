import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/domain/entities/dismissal_reason.dart';
import 'package:garuda_learning/domain/entities/learner_objective_status.dart';
import 'package:garuda_learning/domain/entities/learning_recommendation.dart';
import 'package:garuda_learning/domain/entities/recommendation_effectiveness.dart';
import 'package:garuda_learning/domain/entities/recommendation_evidence_snapshot.dart';
import 'package:garuda_learning/domain/entities/recommendation_lifecycle_state.dart';
import 'package:garuda_learning/domain/entities/recommendation_type.dart';
import 'package:garuda_learning/domain/entities/session_configuration.dart';
import 'package:garuda_learning/repository/in_memory_recommendation_lifecycle_repository.dart';
import 'package:garuda_learning/service/recommendation_lifecycle_service.dart';

void main() {
  group('RecommendationLifecycleService Tests (P22 Stage 5)', () {
    late InMemoryRecommendationLifecycleRepository repository;
    late RecommendationLifecycleService service;

    final testNow = DateTime.utc(2026, 8, 20, 10, 0, 0);

    setUp(() {
      repository = InMemoryRecommendationLifecycleRepository();
      service = RecommendationLifecycleService(repository: repository);
    });

    final testRecommendation = LearningRecommendation(
      recommendationId: 'rec-001',
      learnerId: 'learner-001',
      objectiveId: 'lo-polity-01',
      type: RecommendationType.prerequisiteGap,
      priorityScore: 0.90,
      rationale: 'Review fundamental rights prerequisites',
      suggestedConfig: SessionConfiguration(
        learnerId: 'learner-001',
        objectiveIds: ['lo-polity-01'],
        questionLimit: 5,
      ),
      metadata: const {'source': 'p21_engine'},
    );

    test('1. Issue recommendation creates and persists RecommendationInstance',
        () async {
      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: 0.8,
        prerequisiteBlockerFactor: 0.7,
        weakDomainFactor: 0.6,
        curriculumAdvancementFactor: 0.5,
        practiceDensityFactor: 0.4,
        baselineAccuracy: 0.45,
        baselineAttemptsCount: 10,
        baselineStatus: LearnerObjectiveStatus.inProgress,
      );

      final instance = await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-001',
        issuedAt: testNow,
        evidenceSnapshot: snapshot,
      );

      expect(instance.instanceId, equals('inst-001'));
      expect(instance.state, equals(RecommendationLifecycleState.issued));
      expect(instance.metadata['evidenceSnapshot'], isNotNull);

      final stored = await service.getInstance('inst-001');
      expect(stored, isNotNull);
      expect(stored!.instanceId, equals('inst-001'));
      expect(stored.state, equals(RecommendationLifecycleState.issued));
    });

    test('2. Record interaction transitions lifecycle state and logs event',
        () async {
      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-002',
        issuedAt: testNow,
      );

      final viewedInstance = await service.markViewed(
        interactionId: 'int-001',
        instanceId: 'inst-002',
        timestamp: testNow.add(const Duration(minutes: 5)),
      );

      expect(
        viewedInstance.state,
        equals(RecommendationLifecycleState.viewed),
      );

      final interactions = await service.getInteractions('inst-002');
      expect(interactions.length, equals(1));
      expect(
        interactions.first.targetState,
        equals(RecommendationLifecycleState.viewed),
      );

      final acceptedInstance = await service.acceptRecommendation(
        interactionId: 'int-002',
        instanceId: 'inst-002',
        timestamp: testNow.add(const Duration(minutes: 10)),
      );

      expect(
        acceptedInstance.state,
        equals(RecommendationLifecycleState.accepted),
      );
    });

    test('3. Dismiss recommendation requires structured DismissalReason',
        () async {
      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-003',
        issuedAt: testNow,
      );

      final dismissedInstance = await service.dismissRecommendation(
        interactionId: 'int-003',
        instanceId: 'inst-003',
        reason: DismissalReason.tooDifficult,
        timestamp: testNow.add(const Duration(minutes: 5)),
      );

      expect(
        dismissedInstance.state,
        equals(RecommendationLifecycleState.dismissed),
      );
      expect(
        dismissedInstance.dismissalReason,
        equals(DismissalReason.tooDifficult),
      );
    });

    test('4. Link session creates provenance link and updates state to started',
        () async {
      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-004',
        issuedAt: testNow,
      );

      await service.acceptRecommendation(
        interactionId: 'int-004',
        instanceId: 'inst-004',
        timestamp: testNow.add(const Duration(minutes: 2)),
      );

      final link = await service.linkSession(
        linkId: 'link-001',
        instanceId: 'inst-004',
        sessionId: 'session-001',
        linkedAt: testNow.add(const Duration(minutes: 3)),
      );

      expect(link.instanceId, equals('inst-004'));
      expect(link.sessionId, equals('session-001'));

      final updatedInstance = await service.getInstance('inst-004');
      expect(
        updatedInstance!.state,
        equals(RecommendationLifecycleState.started),
      );

      final links = await service.getLinks('inst-004');
      expect(links.length, equals(1));
    });

    test(
        '5. Record outcome saves outcome and transitions state to completed / abandoned',
        () async {
      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-005',
        issuedAt: testNow,
      );

      await service.acceptRecommendation(
        interactionId: 'int-005',
        instanceId: 'inst-005',
        timestamp: testNow.add(const Duration(minutes: 1)),
      );

      await service.linkSession(
        linkId: 'link-002',
        instanceId: 'inst-005',
        sessionId: 'session-002',
        linkedAt: testNow.add(const Duration(minutes: 2)),
      );

      final outcome = await service.recordOutcome(
        outcomeId: 'out-001',
        instanceId: 'inst-005',
        sessionId: 'session-002',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.80,
        isCompleted: true,
        evaluatedAt: testNow.add(const Duration(minutes: 15)),
      );

      expect(outcome.isCompleted, isTrue);
      expect(outcome.sessionAccuracy, equals(0.80));

      final completedInstance = await service.getInstance('inst-005');
      expect(
        completedInstance!.state,
        equals(RecommendationLifecycleState.completed),
      );
    });

    test(
        '6. Complete lifecycle workflow, evaluate and persist observed effectiveness',
        () async {
      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: 0.7,
        prerequisiteBlockerFactor: 0.6,
        weakDomainFactor: 0.5,
        curriculumAdvancementFactor: 0.4,
        practiceDensityFactor: 0.3,
        baselineAccuracy: 0.40,
        baselineAttemptsCount: 10,
        baselineStatus: LearnerObjectiveStatus.inProgress,
      );

      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-006',
        issuedAt: testNow,
        evidenceSnapshot: snapshot,
      );

      await service.acceptRecommendation(
        interactionId: 'int-006a',
        instanceId: 'inst-006',
        timestamp: testNow.add(const Duration(minutes: 1)),
      );

      await service.linkSession(
        linkId: 'link-006',
        instanceId: 'inst-006',
        sessionId: 'session-006',
        linkedAt: testNow.add(const Duration(minutes: 2)),
      );

      await service.recordOutcome(
        outcomeId: 'out-006',
        instanceId: 'inst-006',
        sessionId: 'session-006',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.80,
        isCompleted: true,
        evaluatedAt: testNow.add(const Duration(minutes: 20)),
      );

      final effectiveness = await service.evaluateEffectiveness(
        'inst-006',
        asOf: testNow.add(const Duration(minutes: 30)),
      );

      expect(effectiveness.insufficientEvidence, isFalse);
      expect(effectiveness.baselineAccuracy, equals(0.40));
      expect(effectiveness.followUpAccuracy, equals(0.80));
      expect(effectiveness.observedPerformanceDelta, closeTo(0.40, 0.0001));
      expect(
        effectiveness.category,
        equals(EffectivenessCategory.observedImprovement),
      );

      // Verify evaluation was persisted in repository
      final persisted = await service.getEffectiveness('inst-006');
      expect(persisted, isNotNull);
      expect(persisted!.instanceId, equals('inst-006'));
      expect(persisted.category,
          equals(EffectivenessCategory.observedImprovement));

      // Verify learner effectiveness query
      final learnerEvals =
          await service.getEffectivenessForLearner('learner-001');
      expect(learnerEvals.length, equals(1));
      expect(learnerEvals.first.instanceId, equals('inst-006'));
    });

    test('7. Active recommendations filtering excludes terminal/expired',
        () async {
      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-active',
        issuedAt: testNow,
        validityDuration: const Duration(days: 7),
      );

      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-expired',
        issuedAt: testNow.subtract(const Duration(days: 10)),
        validityDuration: const Duration(days: 5),
      );

      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-dismissed',
        issuedAt: testNow,
      );

      await service.dismissRecommendation(
        interactionId: 'int-dismiss',
        instanceId: 'inst-dismissed',
        reason: DismissalReason.alreadyMastered,
        timestamp: testNow,
      );

      final active = await service.getActiveRecommendationsForLearner(
        'learner-001',
        asOf: testNow,
      );

      expect(active.length, equals(1));
      expect(active.first.instanceId, equals('inst-active'));
    });

    test('8. Partial lifecycle flows operate safely without crashing',
        () async {
      // Partial Flow A: Issue only
      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-partial-a',
        issuedAt: testNow,
      );
      final evalA = await service.evaluateEffectiveness(
        'inst-partial-a',
        asOf: testNow.add(const Duration(hours: 1)),
      );
      expect(evalA.insufficientEvidence, isTrue);

      // Partial Flow B: Issue + Viewed
      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-partial-b',
        issuedAt: testNow,
      );
      await service.markViewed(
        interactionId: 'int-pb',
        instanceId: 'inst-partial-b',
        timestamp: testNow.add(const Duration(minutes: 5)),
      );
      final evalB = await service.evaluateEffectiveness(
        'inst-partial-b',
        asOf: testNow.add(const Duration(hours: 1)),
      );
      expect(evalB.insufficientEvidence, isTrue);

      // Partial Flow C: Issue + Accept + Link (without Outcome)
      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-partial-c',
        issuedAt: testNow,
      );
      await service.acceptRecommendation(
        interactionId: 'int-pc',
        instanceId: 'inst-partial-c',
        timestamp: testNow.add(const Duration(minutes: 2)),
      );
      await service.linkSession(
        linkId: 'link-pc',
        instanceId: 'inst-partial-c',
        sessionId: 'session-pc',
        linkedAt: testNow.add(const Duration(minutes: 3)),
      );
      final evalC = await service.evaluateEffectiveness(
        'inst-partial-c',
        asOf: testNow.add(const Duration(hours: 1)),
      );
      expect(evalC.insufficientEvidence, isTrue);
    });

    test(
        '9. Missing baseline evidence in snapshot results in insufficientEvidence',
        () async {
      // Snapshot with null baseline accuracy
      final snapshotNoBaseline = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: 0.5,
        prerequisiteBlockerFactor: 0.5,
        weakDomainFactor: 0.5,
        curriculumAdvancementFactor: 0.5,
        practiceDensityFactor: 0.5,
        baselineAccuracy: null,
        baselineAttemptsCount: 0,
        baselineStatus: LearnerObjectiveStatus.notStarted,
      );

      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-nobase',
        issuedAt: testNow,
        evidenceSnapshot: snapshotNoBaseline,
      );

      await service.acceptRecommendation(
        interactionId: 'int-nobase',
        instanceId: 'inst-nobase',
        timestamp: testNow.add(const Duration(minutes: 1)),
      );

      await service.linkSession(
        linkId: 'link-nobase',
        instanceId: 'inst-nobase',
        sessionId: 'sess-nobase',
        linkedAt: testNow.add(const Duration(minutes: 2)),
      );

      await service.recordOutcome(
        outcomeId: 'out-nobase',
        instanceId: 'inst-nobase',
        sessionId: 'sess-nobase',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.90,
        isCompleted: true,
        evaluatedAt: testNow.add(const Duration(minutes: 10)),
      );

      final eval = await service.evaluateEffectiveness(
        'inst-nobase',
        asOf: testNow.add(const Duration(minutes: 20)),
      );

      expect(eval.insufficientEvidence, isTrue);
      expect(eval.baselineAccuracy, isNull);
      expect(eval.observedPerformanceDelta, isNull);
      expect(eval.category, equals(EffectivenessCategory.insufficientEvidence));
    });

    test('10. Idempotency of repeated lifecycle operations', () async {
      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: 0.6,
        prerequisiteBlockerFactor: 0.6,
        weakDomainFactor: 0.6,
        curriculumAdvancementFactor: 0.6,
        practiceDensityFactor: 0.6,
        baselineAccuracy: 0.50,
        baselineAttemptsCount: 5,
        baselineStatus: LearnerObjectiveStatus.inProgress,
      );

      // 1. Issue twice
      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-idem',
        issuedAt: testNow,
        evidenceSnapshot: snapshot,
      );
      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-idem',
        issuedAt: testNow,
        evidenceSnapshot: snapshot,
      );
      final inst = await service.getInstance('inst-idem');
      expect(inst, isNotNull);

      // 2. Accept
      await service.acceptRecommendation(
        interactionId: 'int-idem',
        instanceId: 'inst-idem',
        timestamp: testNow.add(const Duration(minutes: 1)),
      );

      // 3. Link session twice
      await service.linkSession(
        linkId: 'link-idem',
        instanceId: 'inst-idem',
        sessionId: 'sess-idem',
        linkedAt: testNow.add(const Duration(minutes: 2)),
      );
      await service.linkSession(
        linkId: 'link-idem',
        instanceId: 'inst-idem',
        sessionId: 'sess-idem',
        linkedAt: testNow.add(const Duration(minutes: 2)),
      );
      final links = await service.getLinks('inst-idem');
      expect(links.length, equals(1));

      // 4. Record outcome twice
      await service.recordOutcome(
        outcomeId: 'out-idem',
        instanceId: 'inst-idem',
        sessionId: 'sess-idem',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.80,
        isCompleted: true,
        evaluatedAt: testNow.add(const Duration(minutes: 10)),
      );
      await service.recordOutcome(
        outcomeId: 'out-idem',
        instanceId: 'inst-idem',
        sessionId: 'sess-idem',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.80,
        isCompleted: true,
        evaluatedAt: testNow.add(const Duration(minutes: 10)),
      );
      final outcome = await service.getOutcome('inst-idem');
      expect(outcome, isNotNull);

      // 5. Evaluate twice
      final eval1 = await service.evaluateEffectiveness(
        'inst-idem',
        asOf: testNow.add(const Duration(minutes: 20)),
      );
      final eval2 = await service.evaluateEffectiveness(
        'inst-idem',
        asOf: testNow.add(const Duration(minutes: 20)),
      );
      expect(eval1, equals(eval2));
    });

    test('11. Multi-learner isolation guarantees complete separation',
        () async {
      final recA = LearningRecommendation(
        recommendationId: 'rec-A',
        learnerId: 'learner-A',
        objectiveId: 'lo-01',
        type: RecommendationType.spacedReview,
        priorityScore: 0.8,
        rationale: 'Learner A review',
        suggestedConfig: SessionConfiguration(
          learnerId: 'learner-A',
          objectiveIds: ['lo-01'],
          questionLimit: 5,
        ),
      );

      final recB = LearningRecommendation(
        recommendationId: 'rec-B',
        learnerId: 'learner-B',
        objectiveId: 'lo-02',
        type: RecommendationType.curriculumAdvance,
        priorityScore: 0.7,
        rationale: 'Learner B advance',
        suggestedConfig: SessionConfiguration(
          learnerId: 'learner-B',
          objectiveIds: ['lo-02'],
          questionLimit: 5,
        ),
      );

      // Learner A workflow
      await service.issueRecommendation(
        recA,
        instanceId: 'inst-A',
        issuedAt: testNow,
        evidenceSnapshot: RecommendationEvidenceSnapshot(
          reviewUrgencyFactor: 0.8,
          prerequisiteBlockerFactor: 0.0,
          weakDomainFactor: 0.5,
          curriculumAdvancementFactor: 0.3,
          practiceDensityFactor: 0.5,
          baselineAccuracy: 0.30,
          baselineAttemptsCount: 10,
          baselineStatus: LearnerObjectiveStatus.inProgress,
        ),
      );
      await service.acceptRecommendation(
        interactionId: 'int-A',
        instanceId: 'inst-A',
        timestamp: testNow.add(const Duration(minutes: 1)),
      );
      await service.linkSession(
        linkId: 'link-A',
        instanceId: 'inst-A',
        sessionId: 'sess-A',
        linkedAt: testNow.add(const Duration(minutes: 2)),
      );
      await service.recordOutcome(
        outcomeId: 'out-A',
        instanceId: 'inst-A',
        sessionId: 'sess-A',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.90,
        isCompleted: true,
        evaluatedAt: testNow.add(const Duration(minutes: 10)),
      );
      await service.evaluateEffectiveness(
        'inst-A',
        asOf: testNow.add(const Duration(minutes: 15)),
      );

      // Learner B workflow
      await service.issueRecommendation(
        recB,
        instanceId: 'inst-B',
        issuedAt: testNow,
        evidenceSnapshot: RecommendationEvidenceSnapshot(
          reviewUrgencyFactor: 0.1,
          prerequisiteBlockerFactor: 0.0,
          weakDomainFactor: 0.1,
          curriculumAdvancementFactor: 0.9,
          practiceDensityFactor: 0.2,
          baselineAccuracy: 0.80,
          baselineAttemptsCount: 10,
          baselineStatus: LearnerObjectiveStatus.inProgress,
        ),
      );
      await service.acceptRecommendation(
        interactionId: 'int-B',
        instanceId: 'inst-B',
        timestamp: testNow.add(const Duration(minutes: 1)),
      );
      await service.linkSession(
        linkId: 'link-B',
        instanceId: 'inst-B',
        sessionId: 'sess-B',
        linkedAt: testNow.add(const Duration(minutes: 2)),
      );
      await service.recordOutcome(
        outcomeId: 'out-B',
        instanceId: 'inst-B',
        sessionId: 'sess-B',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.50,
        isCompleted: true,
        evaluatedAt: testNow.add(const Duration(minutes: 10)),
      );
      await service.evaluateEffectiveness(
        'inst-B',
        asOf: testNow.add(const Duration(minutes: 15)),
      );

      // Check Learner A queries
      final evalsA = await service.getEffectivenessForLearner('learner-A');
      expect(evalsA.length, equals(1));
      expect(evalsA.first.instanceId, equals('inst-A'));
      expect(evalsA.first.category,
          equals(EffectivenessCategory.observedImprovement));

      // Check Learner B queries
      final evalsB = await service.getEffectivenessForLearner('learner-B');
      expect(evalsB.length, equals(1));
      expect(evalsB.first.instanceId, equals('inst-B'));
      expect(
          evalsB.first.category, equals(EffectivenessCategory.observedDecline));
    });

    test(
        '12. Multi-recommendation isolation for same learner prevents cross-talk',
        () async {
      final rec1 = LearningRecommendation(
        recommendationId: 'rec-101',
        learnerId: 'learner-X',
        objectiveId: 'lo-01',
        type: RecommendationType.spacedReview,
        priorityScore: 0.9,
        rationale: 'Review LO 1',
        suggestedConfig: SessionConfiguration(
          learnerId: 'learner-X',
          objectiveIds: ['lo-01'],
          questionLimit: 5,
        ),
      );

      final rec2 = LearningRecommendation(
        recommendationId: 'rec-102',
        learnerId: 'learner-X',
        objectiveId: 'lo-02',
        type: RecommendationType.prerequisiteGap,
        priorityScore: 0.7,
        rationale: 'Prereq LO 2',
        suggestedConfig: SessionConfiguration(
          learnerId: 'learner-X',
          objectiveIds: ['lo-02'],
          questionLimit: 5,
        ),
      );

      await service.issueRecommendation(
        rec1,
        instanceId: 'inst-X1',
        issuedAt: testNow,
        evidenceSnapshot: RecommendationEvidenceSnapshot(
          reviewUrgencyFactor: 0.9,
          prerequisiteBlockerFactor: 0.0,
          weakDomainFactor: 0.5,
          curriculumAdvancementFactor: 0.0,
          practiceDensityFactor: 0.5,
          baselineAccuracy: 0.40,
          baselineAttemptsCount: 5,
          baselineStatus: LearnerObjectiveStatus.inProgress,
        ),
      );

      await service.issueRecommendation(
        rec2,
        instanceId: 'inst-X2',
        issuedAt: testNow.add(const Duration(minutes: 5)),
        evidenceSnapshot: RecommendationEvidenceSnapshot(
          reviewUrgencyFactor: 0.0,
          prerequisiteBlockerFactor: 0.8,
          weakDomainFactor: 0.8,
          curriculumAdvancementFactor: 0.0,
          practiceDensityFactor: 0.5,
          baselineAccuracy: 0.20,
          baselineAttemptsCount: 5,
          baselineStatus: LearnerObjectiveStatus.notStarted,
        ),
      );

      // Only execute session for Rec 1
      await service.acceptRecommendation(
        interactionId: 'int-X1',
        instanceId: 'inst-X1',
        timestamp: testNow.add(const Duration(minutes: 6)),
      );
      await service.linkSession(
        linkId: 'link-X1',
        instanceId: 'inst-X1',
        sessionId: 'sess-X1',
        linkedAt: testNow.add(const Duration(minutes: 7)),
      );
      await service.recordOutcome(
        outcomeId: 'out-X1',
        instanceId: 'inst-X1',
        sessionId: 'sess-X1',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.80,
        isCompleted: true,
        evaluatedAt: testNow.add(const Duration(minutes: 20)),
      );

      final eval1 = await service.evaluateEffectiveness(
        'inst-X1',
        asOf: testNow.add(const Duration(minutes: 30)),
      );
      final eval2 = await service.evaluateEffectiveness(
        'inst-X2',
        asOf: testNow.add(const Duration(minutes: 30)),
      );

      expect(eval1.insufficientEvidence, isFalse);
      expect(eval1.category, equals(EffectivenessCategory.observedImprovement));

      expect(eval2.insufficientEvidence, isTrue);
      expect(
          eval2.category, equals(EffectivenessCategory.insufficientEvidence));
    });

    test('13. Abandoned session flow transitions state and evaluates cleanly',
        () async {
      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-abandon',
        issuedAt: testNow,
        evidenceSnapshot: RecommendationEvidenceSnapshot(
          reviewUrgencyFactor: 0.5,
          prerequisiteBlockerFactor: 0.5,
          weakDomainFactor: 0.5,
          curriculumAdvancementFactor: 0.5,
          practiceDensityFactor: 0.5,
          baselineAccuracy: 0.50,
          baselineAttemptsCount: 5,
          baselineStatus: LearnerObjectiveStatus.inProgress,
        ),
      );

      await service.acceptRecommendation(
        interactionId: 'int-ab-1',
        instanceId: 'inst-abandon',
        timestamp: testNow.add(const Duration(minutes: 1)),
      );

      await service.linkSession(
        linkId: 'link-ab-1',
        instanceId: 'inst-abandon',
        sessionId: 'sess-abandon',
        linkedAt: testNow.add(const Duration(minutes: 2)),
      );

      // Session abandoned with only 2 attempts out of 10
      await service.recordOutcome(
        outcomeId: 'out-abandon',
        instanceId: 'inst-abandon',
        sessionId: 'sess-abandon',
        totalQuestionsScheduled: 10,
        totalQuestionsAttempted: 2,
        sessionAccuracy: 0.50,
        isCompleted: false,
        evaluatedAt: testNow.add(const Duration(minutes: 10)),
      );

      final inst = await service.getInstance('inst-abandon');
      expect(inst!.state, equals(RecommendationLifecycleState.abandoned));

      final eval = await service.evaluateEffectiveness(
        'inst-abandon',
        asOf: testNow.add(const Duration(minutes: 15)),
      );

      // Evaluated without crash
      expect(eval.instanceId, equals('inst-abandon'));
      expect(eval.metadata['instanceState'], equals('abandoned'));
      expect(eval.metadata['outcomeCompleted'], isFalse);
    });

    test('14. Deferral interaction and subsequent re-engagement', () async {
      await service.issueRecommendation(
        testRecommendation,
        instanceId: 'inst-defer',
        issuedAt: testNow,
      );

      final deferred = await service.deferRecommendation(
        interactionId: 'int-def-1',
        instanceId: 'inst-defer',
        timestamp: testNow.add(const Duration(minutes: 5)),
      );
      expect(deferred.state, equals(RecommendationLifecycleState.deferred));

      // Re-engagement: learner accepts deferred recommendation
      final reAccepted = await service.acceptRecommendation(
        interactionId: 'int-def-2',
        instanceId: 'inst-defer',
        timestamp: testNow.add(const Duration(hours: 2)),
      );
      expect(reAccepted.state, equals(RecommendationLifecycleState.accepted));
    });
  });
}
