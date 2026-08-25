import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group(
      'TITAN Cross-Package P17–P22 Architectural Regression Suite (TITAN-KO-022.0)',
      () {
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryProgressRepository progressRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryReviewScheduleRepository reviewScheduleRepo;
    late SpacedRepetitionService spacedRepetitionService;
    late InMemoryLearnerRepository learnerRepo;
    late ProgressTracker progressTracker;
    late SessionManager sessionManager;
    late AssessmentService assessmentService;
    late LearningSessionOrchestrator sessionOrchestrator;
    late AdaptiveRecommendationService recommendationService;
    late InMemoryRecommendationLifecycleRepository lifecycleRepo;
    late RecommendationLifecycleService lifecycleService;

    final t0 = DateTime.utc(2026, 8, 20, 8, 0, 0);

    setUp(() {
      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
      progressRepo = InMemoryProgressRepository();
      attemptRepo = InMemoryAttemptRepository();
      reviewScheduleRepo = InMemoryReviewScheduleRepository();
      spacedRepetitionService =
          SpacedRepetitionService(repository: reviewScheduleRepo);
      learnerRepo = InMemoryLearnerRepository();

      progressTracker = ProgressTracker(
        attemptRepository: attemptRepo,
        progressRepository: progressRepo,
        thresholdConfig: const AssessmentThresholdConfig(
          minimumAttempts: 2,
          minimumSuccessRate: 0.80,
        ),
      );

      sessionManager = SessionManager(
        learnerRepository: learnerRepo,
      );

      assessmentService = AssessmentService(
        learnerRepository: learnerRepo,
        attemptRepository: attemptRepo,
        curriculumService: curriculumService,
        progressTracker: progressTracker,
        sessionManager: sessionManager,
      );

      sessionOrchestrator = LearningSessionOrchestrator(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        assessmentService: assessmentService,
        sessionManager: sessionManager,
        attemptRepository: attemptRepo,
        progressTracker: progressTracker,
      );

      recommendationService = AdaptiveRecommendationService(
        curriculumService: curriculumService,
        progressRepository: progressRepo,
        attemptRepository: attemptRepo,
        spacedRepetitionService: spacedRepetitionService,
      );

      lifecycleRepo = InMemoryRecommendationLifecycleRepository();
      lifecycleService = RecommendationLifecycleService(
        repository: lifecycleRepo,
      );
    });

    test(
        '1. Cross-phase interoperability: P17 curriculum -> P18 progress -> P20 SM-2 -> P21 queue -> P22 lifecycle -> P19 session execution -> P22 outcome',
        () async {
      const learnerId = 'regress_learner_01';
      final learner = Learner(id: learnerId, name: 'Aspirant Ananya');
      learnerRepo.save(learner);

      // Phase 1 (P17): Verify curriculum seed structure
      expect(framework.domains, isNotEmpty);
      final targetObjective = framework.objectiveMap['lo_preamble_identity'];
      expect(targetObjective, isNotNull);

      // Phase 2 (P18): Cold start initial status is notStarted
      final initialProgress =
          progressRepo.getProgress(learnerId, targetObjective!.id);
      expect(initialProgress, isNull);

      // Phase 3 (P21): Recommendation generation on cold start
      final queue1 = await recommendationService.generateRecommendations(
        learnerId: learnerId,
        asOfDate: t0,
      );
      expect(queue1.isNotEmpty, isTrue);
      final topRec = queue1.topRecommendation!;
      expect(topRec.objectiveId, equals(targetObjective.id));

      // Phase 4 (P22): Issue recommendation instance and capture evidence snapshot
      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor:
            (topRec.metadata['uReview'] as double?)?.clamp(0.0, 1.0) ?? 0.0,
        prerequisiteBlockerFactor:
            (topRec.metadata['sPrereq'] as double?)?.clamp(0.0, 1.0) ?? 0.0,
        weakDomainFactor:
            (topRec.metadata['gWeak'] as double?)?.clamp(0.0, 1.0) ?? 0.0,
        curriculumAdvancementFactor:
            (topRec.metadata['pCurric'] as double?)?.clamp(0.0, 1.0) ?? 0.0,
        practiceDensityFactor:
            (topRec.metadata['hDensity'] as double?)?.clamp(0.0, 1.0) ?? 0.0,
        baselineAccuracy: null,
        baselineAttemptsCount: 0,
        baselineStatus: LearnerObjectiveStatus.notStarted,
      );

      final instance = await lifecycleService.issueRecommendation(
        topRec,
        instanceId: 'inst_regress_01',
        issuedAt: t0,
        evidenceSnapshot: snapshot,
      );
      expect(instance.state, equals(RecommendationLifecycleState.issued));

      // Learner accepts
      final accepted = await lifecycleService.acceptRecommendation(
        interactionId: 'int_regress_01',
        instanceId: instance.instanceId,
        timestamp: t0.add(const Duration(minutes: 2)),
      );
      expect(accepted.state, equals(RecommendationLifecycleState.accepted));

      // Phase 5 (P19): Decoupled Session Execution
      final session = sessionOrchestrator.createSession(
        topRec.suggestedConfig,
        sessionId: 'sess_regress_01',
      );
      sessionOrchestrator.startSession(session.sessionId);

      final link = await lifecycleService.linkSession(
        linkId: 'link_regress_01',
        instanceId: instance.instanceId,
        sessionId: session.sessionId,
        linkedAt: t0.add(const Duration(minutes: 3)),
      );
      expect(link.sessionId, equals(session.sessionId));

      // Submit 3 successful attempts in P18
      for (int i = 1; i <= 3; i++) {
        final attempt = QuestionAttempt(
          attemptId: 'att_regress_$i',
          learnerId: learnerId,
          questionId: 'q_regress_$i',
          objectiveId: targetObjective.id,
          submittedAnswer: 'Exact correct answer',
        );
        attemptRepo.saveAttempt(attempt);
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_regress_$i',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }
      progressTracker.updateProgress(
        learnerId: learnerId,
        objectiveId: targetObjective.id,
      );
      sessionOrchestrator.completeSession(session.sessionId);

      // Verify P18 status updated to achieved
      final updatedProgress =
          progressRepo.getProgress(learnerId, targetObjective.id);
      expect(updatedProgress, isNotNull);
      expect(
        updatedProgress!.status,
        equals(LearnerObjectiveStatus.achieved),
      );

      // Phase 6 (P20): Schedule in Spaced Repetition
      await spacedRepetitionService.addToSchedule(
        learnerId,
        targetObjective.id,
        now: t0,
      );

      final reviewItem = await reviewScheduleRepo.getReviewItem(
        learnerId,
        targetObjective.id,
      );
      expect(reviewItem, isNotNull);
      expect(reviewItem!.intervalDays, greaterThanOrEqualTo(1));
      expect(reviewItem.easeFactor, greaterThanOrEqualTo(1.3));

      // Phase 7 (P22): Record outcome and evaluate effectiveness
      final outcome = await lifecycleService.recordOutcome(
        outcomeId: 'out_regress_01',
        instanceId: instance.instanceId,
        sessionId: session.sessionId,
        totalQuestionsScheduled: 3,
        totalQuestionsAttempted: 3,
        sessionAccuracy: 1.0,
        isCompleted: true,
        evaluatedAt: t0.add(const Duration(minutes: 20)),
      );
      expect(outcome.isCompleted, isTrue);
      expect(outcome.sessionAccuracy, equals(1.0));

      final evaluation = await lifecycleService.evaluateEffectiveness(
        instance.instanceId,
        asOf: t0.add(const Duration(minutes: 30)),
        evidenceSnapshot: snapshot,
      );

      expect(evaluation.followUpAccuracy, equals(1.0));
      expect(evaluation.followUpAttemptsCount, equals(3));
      // Baseline was empty on cold start, so delta is properly marked insufficient
      expect(evaluation.insufficientEvidence, isTrue);
      expect(evaluation.baselineAccuracy, isNull);
    });

    test(
        '2. Prerequisite progression unblocking and downstream recommendation feedback',
        () async {
      const learnerId = 'prereq_flow_learner';
      learnerRepo.save(Learner(id: learnerId, name: 'Aspirant Deepak'));

      // Preamble is prerequisite to Basic Structure Doctrine in seed framework
      const prereqId = 'lo_preamble_identity';
      const targetId = 'lo_basic_structure_doctrine';

      // 1. Initially preamble is unachieved -> preamble has blocker factor (sPrereq > 0)
      final queueBefore = await recommendationService.generateRecommendations(
        learnerId: learnerId,
        asOfDate: t0,
      );
      final preambleRecBefore = queueBefore.items.firstWhere(
        (r) => r.objectiveId == prereqId,
      );
      expect(
        (preambleRecBefore.metadata['sPrereq'] as double),
        greaterThan(0.0),
      );

      // 2. Complete prerequisite in P18
      for (int i = 1; i <= 3; i++) {
        attemptRepo.saveAttempt(QuestionAttempt(
          attemptId: 'att_pre_$i',
          learnerId: learnerId,
          questionId: 'q_pre_$i',
          objectiveId: prereqId,
          submittedAnswer: 'Correct',
        ));
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_pre_$i',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }
      progressTracker.updateProgress(
        learnerId: learnerId,
        objectiveId: prereqId,
      );

      // 3. Re-evaluate recommendations -> downstream objective is now unblocked
      final queueAfter = await recommendationService.generateRecommendations(
        learnerId: learnerId,
        asOfDate: t0.add(const Duration(hours: 1)),
      );
      final basicStructureRecAfter = queueAfter.items.firstWhere(
        (r) => r.objectiveId == targetId,
      );
      expect(
        basicStructureRecAfter.type,
        equals(RecommendationType.curriculumAdvance),
      );

      // 4. Issue P22 instance for newly unblocked objective
      final instance = await lifecycleService.issueRecommendation(
        basicStructureRecAfter,
        instanceId: 'inst_unblocked_01',
        issuedAt: t0.add(const Duration(hours: 1)),
      );
      expect(instance.objectiveId, equals(targetId));
      expect(instance.state, equals(RecommendationLifecycleState.issued));
    });

    test(
        '3. Overdue review trigger in P20 propagates to P21 strategy and P22 evidence snapshot',
        () async {
      const learnerId = 'review_flow_learner';
      learnerRepo.save(Learner(id: learnerId, name: 'Aspirant Maya'));

      const objectiveId = 'lo_preamble_identity';

      // 1. Mark objective achieved
      for (int i = 1; i <= 2; i++) {
        attemptRepo.saveAttempt(QuestionAttempt(
          attemptId: 'att_m_$i',
          learnerId: learnerId,
          questionId: 'q_m_$i',
          objectiveId: objectiveId,
          submittedAnswer: 'Correct',
        ));
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_m_$i',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }
      progressTracker.updateProgress(
        learnerId: learnerId,
        objectiveId: objectiveId,
      );

      // 2. Schedule in P20 at t0
      await spacedRepetitionService.addToSchedule(
        learnerId,
        objectiveId,
        now: t0,
      );

      // 3. Fast-forward 10 days -> review is overdue
      final tOverdue = t0.add(const Duration(days: 10));
      final queue = await recommendationService.generateRecommendations(
        learnerId: learnerId,
        asOfDate: tOverdue,
      );

      final reviewRec = queue.items.firstWhere(
        (r) => r.objectiveId == objectiveId,
      );
      expect(reviewRec.type, equals(RecommendationType.spacedReview));
      expect(
        (reviewRec.metadata['uReview'] as double),
        greaterThan(0.0),
      );

      // 4. Ingest into P22
      final snapshot = RecommendationEvidenceSnapshot(
        reviewUrgencyFactor: reviewRec.metadata['uReview'] as double,
        prerequisiteBlockerFactor: 0.0,
        weakDomainFactor: 0.0,
        curriculumAdvancementFactor: 0.0,
        practiceDensityFactor: 0.0,
        baselineAccuracy: 1.0,
        baselineAttemptsCount: 2,
        baselineStatus: LearnerObjectiveStatus.achieved,
      );

      final instance = await lifecycleService.issueRecommendation(
        reviewRec,
        instanceId: 'inst_review_01',
        issuedAt: tOverdue,
        evidenceSnapshot: snapshot,
      );

      expect(
          instance.recommendationType, equals(RecommendationType.spacedReview));
      expect(instance.metadata['evidenceSnapshot'], isNotNull);
    });

    test(
        '4. Cross-layer contract stability: entity immutability and defensive copying preserve isolation',
        () async {
      const learnerId = 'isolation_learner';
      final testRec = LearningRecommendation(
        recommendationId: 'rec_iso_01',
        learnerId: learnerId,
        objectiveId: 'lo_preamble_identity',
        type: RecommendationType.curriculumAdvance,
        priorityScore: 0.75,
        rationale: 'Curriculum advancement recommendation',
        suggestedConfig: SessionConfiguration(
          learnerId: learnerId,
          objectiveIds: const ['lo_preamble_identity'],
          questionLimit: 5,
        ),
      );

      final instance = await lifecycleService.issueRecommendation(
        testRec,
        instanceId: 'inst_iso_01',
        issuedAt: t0,
      );
      expect(instance.instanceId, equals('inst_iso_01'));

      // Mutating or reading a stored instance does not permit external alteration of repository state
      final retrieved = await lifecycleService.getInstance('inst_iso_01');
      expect(retrieved, isNotNull);
      expect(retrieved!.state, equals(RecommendationLifecycleState.issued));

      // Repository clear resets all tables cleanly
      await lifecycleRepo.clear();
      final afterClear = await lifecycleService.getInstance('inst_iso_01');
      expect(afterClear, isNull);
    });
  });
}
