import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P22 Closed-Loop Feedback Integration Tests (TITAN-KO-022.0)', () {
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

    final t0 = DateTime.utc(2026, 8, 20, 9, 0, 0);

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
        '1. Complete closed loop: P21 recommendation -> P22 issuance -> interaction -> P19 session -> P18 attempts -> P22 outcome & observed effectiveness',
        () async {
      const learnerId = 'closed_loop_learner_1';
      final learner = Learner(id: learnerId, name: 'Aspirant Meera');
      learnerRepo.save(learner);

      // --- PHASE A: Baseline performance recording in P18 ---
      // Learner had earlier attempts with 40% accuracy (2/5) on 'lo_preamble_identity'
      const targetObjectiveId = 'lo_preamble_identity';
      for (int i = 1; i <= 5; i++) {
        final attempt = QuestionAttempt(
          attemptId: 'att_baseline_$i',
          learnerId: learnerId,
          questionId: 'q_preamble_$i',
          objectiveId: targetObjectiveId,
          submittedAnswer: i <= 2 ? 'Correct' : 'Incorrect',
        );
        attemptRepo.saveAttempt(attempt);
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_baseline_$i',
          isCorrect: i <= 2,
          score: i <= 2 ? 1.0 : 0.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }
      progressTracker.updateProgress(
        learnerId: learnerId,
        objectiveId: targetObjectiveId,
      );

      final baselineProgress =
          progressRepo.getProgress(learnerId, targetObjectiveId);
      expect(baselineProgress, isNotNull);
      expect(
        baselineProgress!.status,
        equals(LearnerObjectiveStatus.inProgress),
      );

      // --- PHASE B: P21 Recommendation Generation ---
      final tIssuance = t0.add(const Duration(hours: 1));
      final queue = await recommendationService.generateRecommendations(
        learnerId: learnerId,
        asOfDate: tIssuance,
      );
      expect(queue.isNotEmpty, isTrue);

      final topRec = queue.items.firstWhere(
        (r) => r.objectiveId == targetObjectiveId,
      );
      expect(topRec.objectiveId, equals(targetObjectiveId));

      // Capture issuance evidence snapshot
      final evidenceSnapshot = RecommendationEvidenceSnapshot(
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
        baselineAccuracy: 0.40,
        baselineAttemptsCount: 5,
        baselineStatus: baselineProgress.status,
      );

      // --- PHASE C: P22 Recommendation Issuance ---
      final instance = await lifecycleService.issueRecommendation(
        topRec,
        instanceId: 'inst_p22_001',
        issuedAt: tIssuance,
        evidenceSnapshot: evidenceSnapshot,
      );
      expect(instance.state, equals(RecommendationLifecycleState.issued));
      expect(instance.learnerId, equals(learnerId));
      expect(instance.objectiveId, equals(targetObjectiveId));

      // --- PHASE D: Learner Interaction Telemetry ---
      final tView = tIssuance.add(const Duration(minutes: 5));
      final viewedInstance = await lifecycleService.markViewed(
        interactionId: 'int_view_001',
        instanceId: instance.instanceId,
        timestamp: tView,
      );
      expect(
        viewedInstance.state,
        equals(RecommendationLifecycleState.viewed),
      );

      final tAccept = tView.add(const Duration(minutes: 2));
      final acceptedInstance = await lifecycleService.acceptRecommendation(
        interactionId: 'int_accept_001',
        instanceId: instance.instanceId,
        timestamp: tAccept,
      );
      expect(
        acceptedInstance.state,
        equals(RecommendationLifecycleState.accepted),
      );

      // --- PHASE E: P19 Practice Session Provenance Linking ---
      final tSessionStart = tAccept.add(const Duration(minutes: 1));
      final session = sessionOrchestrator.createSession(
        topRec.suggestedConfig,
        sessionId: 'sess_closed_loop_01',
      );
      sessionOrchestrator.startSession(session.sessionId);

      final link = await lifecycleService.linkSession(
        linkId: 'link_001',
        instanceId: instance.instanceId,
        sessionId: session.sessionId,
        linkedAt: tSessionStart,
      );
      expect(link.instanceId, equals(instance.instanceId));
      expect(link.sessionId, equals(session.sessionId));

      final startedInstance =
          await lifecycleService.getInstance(instance.instanceId);
      expect(
        startedInstance!.state,
        equals(RecommendationLifecycleState.started),
      );

      // --- PHASE F: P19 Session Execution & P18 Assessment Recording ---
      // Learner answers 5 follow-up questions during practice session with 80% accuracy (4/5)
      for (int i = 1; i <= 5; i++) {
        final attempt = QuestionAttempt(
          attemptId: 'att_post_$i',
          learnerId: learnerId,
          questionId: 'q_post_$i',
          objectiveId: targetObjectiveId,
          submittedAnswer: i <= 4 ? 'Correct' : 'Incorrect',
        );
        attemptRepo.saveAttempt(attempt);
        attemptRepo.saveResult(AttemptResult(
          attemptId: 'att_post_$i',
          isCorrect: i <= 4,
          score: i <= 4 ? 1.0 : 0.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }
      progressTracker.updateProgress(
        learnerId: learnerId,
        objectiveId: targetObjectiveId,
      );
      sessionOrchestrator.completeSession(session.sessionId);

      // --- PHASE G: P22 Outcome Recording ---
      final tSessionEnd = tSessionStart.add(const Duration(minutes: 15));
      final outcome = await lifecycleService.recordOutcome(
        outcomeId: 'out_001',
        instanceId: instance.instanceId,
        sessionId: session.sessionId,
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 5,
        sessionAccuracy: 0.80,
        isCompleted: true,
        evaluatedAt: tSessionEnd,
      );
      expect(outcome.isCompleted, isTrue);
      expect(outcome.completionRate, equals(1.0));
      expect(outcome.sessionAccuracy, equals(0.80));

      final completedInstance =
          await lifecycleService.getInstance(instance.instanceId);
      expect(
        completedInstance!.state,
        equals(RecommendationLifecycleState.completed),
      );

      // --- PHASE H: P22 Observed Effectiveness Evaluation ---
      final tEval = tSessionEnd.add(const Duration(minutes: 5));
      final effectiveness = await lifecycleService.evaluateEffectiveness(
        instance.instanceId,
        asOf: tEval,
        evidenceSnapshot: evidenceSnapshot,
      );

      expect(effectiveness.insufficientEvidence, isFalse);
      expect(effectiveness.baselineAccuracy, equals(0.40));
      expect(effectiveness.baselineAttemptsCount, equals(5));
      expect(effectiveness.followUpAccuracy, equals(0.80));
      expect(effectiveness.followUpAttemptsCount, equals(5));
      expect(
        effectiveness.observedPerformanceDelta,
        closeTo(0.40, 0.0001),
      );
      expect(
        effectiveness.category,
        equals(EffectivenessCategory.observedImprovement),
      );

      // --- PHASE I: Full Provenance & Persistence Verification ---
      final storedOutcome =
          await lifecycleService.getOutcome(instance.instanceId);
      expect(storedOutcome, isNotNull);
      expect(storedOutcome!.sessionId, equals(session.sessionId));

      final storedLinks = await lifecycleService.getLinks(instance.instanceId);
      expect(storedLinks.length, equals(1));
      expect(storedLinks.first.sessionId, equals(session.sessionId));

      final storedInteractions =
          await lifecycleService.getInteractions(instance.instanceId);
      expect(storedInteractions.length, equals(2)); // viewed, accepted

      final storedEffectiveness =
          await lifecycleService.getEffectiveness(instance.instanceId);
      expect(storedEffectiveness, isNotNull);
      expect(
        storedEffectiveness!.category,
        equals(EffectivenessCategory.observedImprovement),
      );
    });

    test(
        '2. Multi-session lifecycle: recommendation linked to multiple practice sessions preserves provenance',
        () async {
      const learnerId = 'multi_session_learner';
      learnerRepo.save(Learner(id: learnerId, name: 'Aspirant Vikram'));

      final testRec = LearningRecommendation(
        recommendationId: 'rec_multi_001',
        learnerId: learnerId,
        objectiveId: 'lo_basic_structure_doctrine',
        type: RecommendationType.prerequisiteGap,
        priorityScore: 0.85,
        rationale: 'Review landmark doctrine prerequisites',
        suggestedConfig: SessionConfiguration(
          learnerId: learnerId,
          objectiveIds: const ['lo_basic_structure_doctrine'],
          questionLimit: 5,
        ),
      );

      final instance = await lifecycleService.issueRecommendation(
        testRec,
        instanceId: 'inst_multi_001',
        issuedAt: t0,
      );

      // Learner accepts recommendation
      await lifecycleService.acceptRecommendation(
        interactionId: 'int_multi_accept',
        instanceId: instance.instanceId,
        timestamp: t0.add(const Duration(minutes: 5)),
      );

      // Session 1: Started and cancelled (abandoned)
      final session1 = sessionOrchestrator.createSession(
        testRec.suggestedConfig,
        sessionId: 'sess_multi_01',
      );
      await lifecycleService.linkSession(
        linkId: 'link_multi_1',
        instanceId: instance.instanceId,
        sessionId: session1.sessionId,
        linkedAt: t0.add(const Duration(minutes: 10)),
      );

      await lifecycleService.recordOutcome(
        outcomeId: 'out_multi_1',
        instanceId: instance.instanceId,
        sessionId: session1.sessionId,
        totalQuestionsScheduled: 5,
        totalQuestionsAttempted: 2,
        sessionAccuracy: 0.50,
        isCompleted: false,
        evaluatedAt: t0.add(const Duration(minutes: 20)),
      );

      // Session 2: Resumed / Retried second session linked to same instance
      final session2 = sessionOrchestrator.createSession(
        testRec.suggestedConfig,
        sessionId: 'sess_multi_02',
      );
      await lifecycleService.linkSession(
        linkId: 'link_multi_2',
        instanceId: instance.instanceId,
        sessionId: session2.sessionId,
        linkedAt: t0.add(const Duration(hours: 2)),
      );

      final links = await lifecycleService.getLinks(instance.instanceId);
      expect(links.length, equals(2));
      expect(links[0].sessionId, equals(session1.sessionId));
      expect(links[1].sessionId, equals(session2.sessionId));
    });
  });
}
