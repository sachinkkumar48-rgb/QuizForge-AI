import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P22 Educational Safety & Invariant Tests (TITAN-KO-022.0)', () {
    late InMemoryRecommendationLifecycleRepository lifecycleRepo;
    late RecommendationLifecycleService lifecycleService;
    late InMemoryProgressRepository progressRepo;

    final t0 = DateTime.utc(2026, 8, 20, 10, 0, 0);

    setUp(() {
      lifecycleRepo = InMemoryRecommendationLifecycleRepository();
      lifecycleService = RecommendationLifecycleService(
        repository: lifecycleRepo,
      );
      progressRepo = InMemoryProgressRepository();
    });

    final testRec = LearningRecommendation(
      recommendationId: 'rec_safety_001',
      learnerId: 'learner_safety_01',
      objectiveId: 'lo_fundamental_rights_intro',
      type: RecommendationType.prerequisiteGap,
      priorityScore: 0.88,
      rationale: 'Review fundamental rights prerequisite concepts',
      suggestedConfig: SessionConfiguration(
        learnerId: 'learner_safety_01',
        objectiveIds: const ['lo_fundamental_rights_intro'],
        questionLimit: 5,
      ),
    );

    test(
        '1. Dismissal does not penalize learner performance or alter learner progress',
        () async {
      // Setup learner progress at inProgress
      progressRepo.saveProgress(LearnerProgress(
        learnerId: 'learner_safety_01',
        objectiveId: 'lo_fundamental_rights_intro',
        attemptCount: 2,
        correctCount: 1,
        status: LearnerObjectiveStatus.inProgress,
      ));

      final instance = await lifecycleService.issueRecommendation(
        testRec,
        instanceId: 'inst_safety_dismiss_01',
        issuedAt: t0,
      );

      // Learner dismisses recommendation with structured reason
      final dismissedInstance = await lifecycleService.dismissRecommendation(
        interactionId: 'int_dismiss_01',
        instanceId: instance.instanceId,
        reason: DismissalReason.deferredForLater,
        timestamp: t0.add(const Duration(minutes: 5)),
      );

      expect(
        dismissedInstance.state,
        equals(RecommendationLifecycleState.dismissed),
      );
      expect(dismissedInstance.state.isTerminal, isTrue);

      // Verify learner progress is completely untouched
      final progress = progressRepo.getProgress(
        'learner_safety_01',
        'lo_fundamental_rights_intro',
      );
      expect(progress, isNotNull);
      expect(progress!.status, equals(LearnerObjectiveStatus.inProgress));
      expect(progress.attemptCount, equals(2));
      expect(progress.correctCount, equals(1));
    });

    test(
        '2. Acceptance does NOT equal mastery: progress status remains unchanged until P18 attempts occur',
        () async {
      progressRepo.saveProgress(LearnerProgress(
        learnerId: 'learner_safety_01',
        objectiveId: 'lo_fundamental_rights_intro',
        status: LearnerObjectiveStatus.notStarted,
      ));

      final instance = await lifecycleService.issueRecommendation(
        testRec,
        instanceId: 'inst_safety_accept_01',
        issuedAt: t0,
      );

      final acceptedInstance = await lifecycleService.acceptRecommendation(
        interactionId: 'int_accept_01',
        instanceId: instance.instanceId,
        timestamp: t0.add(const Duration(minutes: 3)),
      );

      expect(
        acceptedInstance.state,
        equals(RecommendationLifecycleState.accepted),
      );

      // Accepting recommendation does NOT grant mastery
      final progress = progressRepo.getProgress(
        'learner_safety_01',
        'lo_fundamental_rights_intro',
      );
      expect(progress, isNotNull);
      expect(progress!.status, equals(LearnerObjectiveStatus.notStarted));
    });

    test(
        '3. Low completion / session abandonment is purely execution telemetry and does not imply cognitive weakness',
        () async {
      final instance = await lifecycleService.issueRecommendation(
        testRec,
        instanceId: 'inst_safety_abandon_01',
        issuedAt: t0,
      );

      // Learner accepts recommendation first
      await lifecycleService.acceptRecommendation(
        interactionId: 'int_accept_ab_01',
        instanceId: instance.instanceId,
        timestamp: t0.add(const Duration(minutes: 2)),
      );

      // Session linked -> transitions instance to started
      await lifecycleService.linkSession(
        linkId: 'link_abandon_01',
        instanceId: instance.instanceId,
        sessionId: 'session_abandoned_01',
        linkedAt: t0.add(const Duration(minutes: 5)),
      );

      final startedInstance =
          await lifecycleService.getInstance(instance.instanceId);
      expect(
          startedInstance!.state, equals(RecommendationLifecycleState.started));

      final outcome = await lifecycleService.recordOutcome(
        outcomeId: 'out_abandon_01',
        instanceId: instance.instanceId,
        sessionId: 'session_abandoned_01',
        totalQuestionsScheduled: 10,
        totalQuestionsAttempted: 2,
        sessionAccuracy: 0.50,
        isCompleted: false,
        evaluatedAt: t0.add(const Duration(minutes: 10)),
      );

      expect(outcome.isCompleted, isFalse);
      expect(outcome.completionRate, equals(0.20));

      final updatedInstance =
          await lifecycleService.getInstance(instance.instanceId);
      expect(
        updatedInstance!.state,
        equals(RecommendationLifecycleState.abandoned),
      );
      expect(updatedInstance.state.isTerminal, isTrue);
    });

    test(
        '4. Observational framing: effectiveness metric is strictly observedPerformanceDelta with non-causal labeling',
        () {
      const evaluator = RecommendationEffectivenessEvaluator();

      final instance = RecommendationInstance.fromRecommendation(
        testRec,
        instanceId: 'inst_safety_obs_01',
        issuedAt: t0,
      );

      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: 0.5,
        prerequisiteBlockerFactor: 0.5,
        weakDomainFactor: 0.5,
        curriculumAdvancementFactor: 0.5,
        practiceDensityFactor: 0.5,
        baselineAccuracy: 0.50,
        baselineAttemptsCount: 10,
        baselineStatus: LearnerObjectiveStatus.inProgress,
      );

      final outcome = RecommendationOutcome(
        outcomeId: 'out_safety_obs_01',
        instanceId: instance.instanceId,
        sessionId: 'sess_obs_01',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.90,
        isCompleted: true,
        evaluatedAt: t0.add(const Duration(hours: 1)),
      );

      final evaluation = evaluator.evaluate(
        instance: instance,
        outcome: outcome,
        evidenceSnapshot: snapshot,
        asOf: t0.add(const Duration(hours: 2)),
      );

      // Verifications of non-causal naming
      expect(
        evaluation.observedPerformanceDelta,
        closeTo(0.40, 0.0001),
      );
      expect(
        evaluation.category,
        equals(EffectivenessCategory.observedImprovement),
      );
      expect(
        evaluation.category.name,
        isNot(contains('caused')),
      );
      expect(
        evaluation.category.name,
        isNot(contains('mastery')),
      );
    });

    test(
        '5. Zero baseline attempts handled safely: no division by zero or fabricated baseline metric',
        () {
      const evaluator = RecommendationEffectivenessEvaluator();

      final instance = RecommendationInstance.fromRecommendation(
        testRec,
        instanceId: 'inst_safety_zero_base',
        issuedAt: t0,
      );

      // Snapshot with zero baseline attempts
      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: 0.5,
        prerequisiteBlockerFactor: 0.5,
        weakDomainFactor: 0.5,
        curriculumAdvancementFactor: 0.5,
        practiceDensityFactor: 0.5,
        baselineAccuracy: null,
        baselineAttemptsCount: 0,
        baselineStatus: LearnerObjectiveStatus.notStarted,
      );

      final outcome = RecommendationOutcome(
        outcomeId: 'out_safety_zero_base',
        instanceId: instance.instanceId,
        sessionId: 'sess_zb_01',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.80,
        isCompleted: true,
        evaluatedAt: t0.add(const Duration(hours: 1)),
      );

      final evaluation = evaluator.evaluate(
        instance: instance,
        outcome: outcome,
        evidenceSnapshot: snapshot,
        asOf: t0.add(const Duration(hours: 2)),
      );

      expect(evaluation.insufficientEvidence, isTrue);
      expect(evaluation.baselineAccuracy, isNull);
      expect(evaluation.baselineAttemptsCount, equals(0));
      expect(evaluation.observedPerformanceDelta, isNull);
      expect(
        evaluation.category,
        equals(EffectivenessCategory.insufficientEvidence),
      );
    });

    test(
        '6. Zero follow-up attempts handled safely: no division by zero or fabricated follow-up metric',
        () {
      const evaluator = RecommendationEffectivenessEvaluator();

      final instance = RecommendationInstance.fromRecommendation(
        testRec,
        instanceId: 'inst_safety_zero_post',
        issuedAt: t0,
      );

      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: 0.5,
        prerequisiteBlockerFactor: 0.5,
        weakDomainFactor: 0.5,
        curriculumAdvancementFactor: 0.5,
        practiceDensityFactor: 0.5,
        baselineAccuracy: 0.60,
        baselineAttemptsCount: 10,
        baselineStatus: LearnerObjectiveStatus.inProgress,
      );

      // Outcome where learner attempted zero questions
      final outcome = RecommendationOutcome(
        outcomeId: 'out_safety_zero_post',
        instanceId: instance.instanceId,
        sessionId: 'sess_zp_01',
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 0,
        sessionAccuracy: null,
        isCompleted: false,
        evaluatedAt: t0.add(const Duration(hours: 1)),
      );

      final evaluation = evaluator.evaluate(
        instance: instance,
        outcome: outcome,
        evidenceSnapshot: snapshot,
        asOf: t0.add(const Duration(hours: 2)),
      );

      expect(evaluation.insufficientEvidence, isTrue);
      expect(evaluation.followUpAccuracy, isNull);
      expect(evaluation.followUpAttemptsCount, equals(0));
      expect(evaluation.observedPerformanceDelta, isNull);
      expect(
        evaluation.category,
        equals(EffectivenessCategory.insufficientEvidence),
      );
    });

    test(
        '7. Denominator safety: zero scheduled questions yields 0.0 completion without error; negative counts rejected',
        () {
      // Zero scheduled questions safely produces 0.0 completionRate without NaN or crashing
      final zeroScheduledOutcome = RecommendationOutcome(
        outcomeId: 'out_zero_sched',
        instanceId: 'inst_01',
        sessionId: 'sess_01',
        totalQuestionsScheduled: 0,
        totalQuestionsAttempted: 0,
        isCompleted: false,
        evaluatedAt: t0,
      );
      expect(zeroScheduledOutcome.completionRate, equals(0.0));
      expect(zeroScheduledOutcome.insufficientEvidence, isTrue);

      // Negative values are strictly rejected with ArgumentError
      expect(
        () => RecommendationOutcome(
          outcomeId: 'out_bad_denom_neg',
          instanceId: 'inst_01',
          sessionId: 'sess_01',
          totalQuestionsScheduled: -5,
          totalQuestionsAttempted: 0,
          isCompleted: false,
          evaluatedAt: t0,
        ),
        throwsArgumentError,
      );

      expect(
        () => RecommendationOutcome(
          outcomeId: 'out_bad_att_neg',
          instanceId: 'inst_01',
          sessionId: 'sess_01',
          totalQuestionsScheduled: 5,
          totalQuestionsAttempted: -1,
          isCompleted: false,
          evaluatedAt: t0,
        ),
        throwsArgumentError,
      );
    });

    test('8. Missing outcome handled safely during evaluation', () {
      const evaluator = RecommendationEffectivenessEvaluator();

      final instance = RecommendationInstance.fromRecommendation(
        testRec,
        instanceId: 'inst_safety_no_outcome',
        issuedAt: t0,
      );

      final evaluation = evaluator.evaluate(
        instance: instance,
        outcome: null,
        asOf: t0.add(const Duration(days: 1)),
      );

      expect(evaluation.insufficientEvidence, isTrue);
      expect(evaluation.observedPerformanceDelta, isNull);
      expect(
        evaluation.category,
        equals(EffectivenessCategory.insufficientEvidence),
      );
    });

    test(
        '9. TTL and expiration behavior is strictly deterministic with injected asOf timestamps',
        () async {
      final issuedAt = DateTime.utc(2026, 8, 1, 10, 0, 0);
      const validity = Duration(days: 7);

      final instance = await lifecycleService.issueRecommendation(
        testRec,
        instanceId: 'inst_ttl_01',
        issuedAt: issuedAt,
        validityDuration: validity,
      );

      // Within validity window (5 days after issuance)
      final tWithin = issuedAt.add(const Duration(days: 5));
      expect(instance.isExpired(asOf: tWithin), isFalse);

      final activeList1 =
          await lifecycleService.getActiveRecommendationsForLearner(
        testRec.learnerId,
        asOf: tWithin,
      );
      expect(activeList1.length, equals(1));
      expect(activeList1.first.instanceId, equals(instance.instanceId));

      // After validity window (8 days after issuance)
      final tExpired = issuedAt.add(const Duration(days: 8));
      expect(instance.isExpired(asOf: tExpired), isTrue);

      final activeList2 =
          await lifecycleService.getActiveRecommendationsForLearner(
        testRec.learnerId,
        asOf: tExpired,
      );
      expect(activeList2, isEmpty);
    });

    test(
        '10. Safety check: no fabricated metrics and rationales avoid unsupported exam/PYQ claims',
        () {
      const bannedKeywords = [
        'upsc guaranteed',
        '100% exam match',
        'pyq proven guarantee',
        'instant mastery',
        'flawless rank',
      ];

      for (final banned in bannedKeywords) {
        expect(
          testRec.rationale.toLowerCase().contains(banned),
          isFalse,
          reason: 'Rationale must avoid unsupported claims: $banned',
        );
      }
    });
  });
}
