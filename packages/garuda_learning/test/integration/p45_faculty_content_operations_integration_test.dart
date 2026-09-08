import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group(
      'P45 Faculty Content Operations Integration Tests (Section 14 E2E Acceptance)',
      () {
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryFacultyContentRepository contentRepo;
    late InMemoryRemedialLessonRepository remedialRepo;
    late FacultyContentService facultyService;

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late LearningSessionRecoveryService sessionRecoveryService;
    late ContentLearningPathService contentService;
    late PracticeOutcomeConsolidator outcomeConsolidator;
    late AdaptiveLearningStateReconciler reconciler;
    late LearningStateUpdateProposer proposer;
    late AdaptiveLearningStateReconciliationPipeline pipeline;
    late AdaptiveLearningJourneyOrchestrator journeyOrchestrator;
    late AdaptiveLearningJourneyController journeyController;

    const String learnerId = 'learner_faculty_e2e';
    const String examId = 'upsc_prelims_gs1';
    const String subjectId = 'indian_polity';
    const String topicId = 'fundamental_rights';
    const String objectiveId = 'lo_article_21_foundations';
    final DateTime baseDate = DateTime.utc(2026, 9, 8);

    setUp(() {
      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
      contentRepo = InMemoryFacultyContentRepository();
      remedialRepo = InMemoryRemedialLessonRepository();

      facultyService = FacultyContentService(
        contentRepository: contentRepo,
        curriculumService: curriculumService,
        remedialRepository: remedialRepo,
      );

      authRepo = InMemoryAuthoritativeLearningStateRepository();
      authRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );
      checkpointRepo = InMemorySessionCheckpointRepository();
      sessionRecoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );

      outcomeConsolidator = const PracticeOutcomeConsolidator();
      reconciler = const AdaptiveLearningStateReconciler();
      proposer = const LearningStateUpdateProposer();
      pipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: authRepo,
        recoveryService: authRecoveryService,
        reconciler: reconciler,
        proposer: proposer,
        consolidator: outcomeConsolidator,
      );

      journeyOrchestrator = AdaptiveLearningJourneyOrchestrator(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        reconciliationPipeline: pipeline,
      );
      journeyController = AdaptiveLearningJourneyController(
        orchestrator: journeyOrchestrator,
      );

      contentService = ContentLearningPathService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        remedialService: DeterministicRemedialLessonService(
          lessonRepository: remedialRepo,
        ),
        facultyContentRepository: contentRepo,
        seedQuestions: const [],
      );
    });

    test(
        'Section 14 End-to-End Acceptance: Create -> Validate -> Save -> Preview -> Publish -> Discover -> Learn -> Unpublish -> Versioning',
        () async {
      // -------------------------------------------------------------
      // 1. FACULTY -> CREATE CONTENT -> VALIDATE -> SAVE DRAFT
      // -------------------------------------------------------------
      final draftItem = await facultyService.createDraft(
        id: 'q_fac_e2e_accepted',
        title: 'Article 21 Extended Scope in Francis Coralie',
        examId: examId,
        subjectId: subjectId,
        topicId: 'Fundamental Rights',
        objectiveId: objectiveId,
        contentType: ManagedContentType.question,
        authorId: 'prof_e2e',
        authorName: 'Prof. E2E Acceptance',
        provenance: 'Francis Coralie Mullin v UT of Delhi (1981) 1 SCC 608',
        prompt:
            'In Francis Coralie, what does the right to life include beyond animal existence?',
        options: const [
          'Right to live with human dignity and bare necessities of life',
          'Right to unlimited commercial trade',
          'Absolute immunity from criminal investigation',
          'Right to statutory arbitration without judicial review',
        ],
        correctAnswer: 'A',
        explanation:
            'Bhagwati J. affirmed right to life includes human dignity.',
      );

      expect(draftItem.id, equals('q_fac_e2e_accepted'));
      expect(draftItem.status, equals(ContentLifecycleStatus.draft));
      expect(draftItem.version, equals(1));

      // VALIDATE
      final validationResult = facultyService.validateContent(draftItem);
      expect(validationResult.isValid, isTrue);
      expect(validationResult.errors, isEmpty);

      // PREVIEW
      final previewQuestion = draftItem.toNormalizedQuestion();
      expect(previewQuestion.id, equals('q_fac_e2e_accepted'));
      expect(previewQuestion.normalizedText, contains('Francis Coralie'));
      expect(previewQuestion.officialAnswer.correctOptionKeys, contains('A'));

      // Before publishing, verify learner does NOT discover draft item
      final prePublishDetail = await contentService.resolveLearningPath(
        learnerId: learnerId,
        examId: examId,
        subjectId: subjectId,
        topicId: topicId,
        asOfDate: baseDate,
      );
      expect(prePublishDetail.selectedTopic?.questionCount ?? 0, equals(0));

      final prePublishObj =
          await contentService.getPublishedContentForObjective(objectiveId);
      expect(prePublishObj.any((i) => i.id == 'q_fac_e2e_accepted'), isFalse);

      // -------------------------------------------------------------
      // 2. FACULTY -> PUBLISH
      // -------------------------------------------------------------
      final publishedItem = await facultyService.publishContent(draftItem.id);
      expect(publishedItem.status, equals(ContentLifecycleStatus.published));
      expect(publishedItem.isPublished, isTrue);

      // -------------------------------------------------------------
      // 3. LEARNER OPENS CURRICULUM -> SELECTS OBJECTIVE -> DISCOVERS NEW CONTENT
      // -------------------------------------------------------------
      final postPublishDetail = await contentService.resolveLearningPath(
        learnerId: learnerId,
        examId: examId,
        subjectId: subjectId,
        topicId: topicId,
        asOfDate: baseDate,
      );

      expect(postPublishDetail.selectedTopic?.questionCount, equals(1));

      final publishedObjContent =
          await contentService.getPublishedContentForObjective(objectiveId);
      expect(
          publishedObjContent.any((i) => i.id == 'q_fac_e2e_accepted'), isTrue);

      // -------------------------------------------------------------
      // 4. LEARNER OPENS CONTENT -> EXISTING LEARNING FLOW CONTINUES
      // -------------------------------------------------------------
      final publishedNormalized = publishedItem.toNormalizedQuestion();
      final startOk = await journeyController.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: [publishedNormalized],
        questionCount: 1,
      );
      expect(startOk, isTrue);

      await journeyController.submitAnswer(answer: 'A');
      expect(journeyController.isCompleted, isTrue);

      // Verify authoritative learning state pipeline was updated
      final recoveredMastery = await authRecoveryService.recover(
        learnerId: learnerId,
        examId: examId,
        requestedAt: baseDate,
      );
      expect(recoveredMastery.state, isNotNull);
      final progress = recoveredMastery.state!.progressMap[objectiveId]!;
      expect(progress.attemptCount, equals(1));
      expect(progress.correctCount, equals(1));

      // -------------------------------------------------------------
      // 5. FACULTY -> UNPUBLISH -> LEARNER REFRESHES -> CONTENT NO LONGER AVAILABLE
      // -------------------------------------------------------------
      final unpubItem =
          await facultyService.unpublishContent('q_fac_e2e_accepted');
      expect(unpubItem.status, equals(ContentLifecycleStatus.unpublished));
      expect(unpubItem.isPublished, isFalse);

      final unpubDetail = await contentService.resolveLearningPath(
        learnerId: learnerId,
        examId: examId,
        subjectId: subjectId,
        topicId: topicId,
        asOfDate: baseDate,
      );
      expect(unpubDetail.selectedTopic?.questionCount ?? 0, equals(0));

      final unpubObj =
          await contentService.getPublishedContentForObjective(objectiveId);
      expect(unpubObj.any((i) => i.id == 'q_fac_e2e_accepted'), isFalse);

      // -------------------------------------------------------------
      // 6. FACULTY -> EDIT -> CREATE/PUBLISH NEW VERSION -> LEARNER RECEIVES NEW VERSION
      // -------------------------------------------------------------
      // Re-publish v1 first
      await facultyService.publishContent('q_fac_e2e_accepted');

      final v2Draft = await facultyService.updateDraft(draftItem.copyWith(
        prompt:
            'In Francis Coralie Mullin (1981), what fundamental component of life was recognized?',
        explanation:
            'Bhagwati J. held that life encompasses human dignity and faculties.',
      ));

      expect(v2Draft.version, equals(2));
      expect(v2Draft.status, equals(ContentLifecycleStatus.draft));

      // While v2 is draft, learner still sees published v1
      final v1Content =
          await contentService.getPublishedContentForObjective(objectiveId);
      expect(v1Content.firstWhere((i) => i.id == 'q_fac_e2e_accepted').prompt,
          equals(draftItem.prompt));

      // Faculty publishes v2
      final v2Published = await facultyService.publishContent(v2Draft.id);
      expect(v2Published.version, equals(2));
      expect(v2Published.isPublished, isTrue);

      // Learner refreshes and receives v2
      final v2Content =
          await contentService.getPublishedContentForObjective(objectiveId);
      final activeLearnerItem =
          v2Content.firstWhere((i) => i.id == 'q_fac_e2e_accepted');
      expect(activeLearnerItem.version, equals(2));
      expect(
          activeLearnerItem.prompt,
          equals(
              'In Francis Coralie Mullin (1981), what fundamental component of life was recognized?'));

      // Historical v1 preserved intact in repository
      final historicalV1 =
          await contentRepo.getById('q_fac_e2e_accepted', version: 1);
      expect(historicalV1, isNotNull);
      expect(historicalV1!.version, equals(1));
      expect(historicalV1.prompt, equals(draftItem.prompt));
    });
  });
}
