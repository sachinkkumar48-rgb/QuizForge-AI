import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P45 Faculty Content Management Integration Tests (Rule 15 Closed-Loop)', () {
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

    test('Authoritative Rule 15 End-to-End Scenario: Faculty Authoring to Learner Mastery Pipeline', () async {
      const learnerId = 'learner_e2e_01';
      const examId = 'upsc_prelims_gs1';
      const subjectId = 'indian_polity';
      const topicId = 'fundamental_rights';
      const objectiveId = 'lo_article_21_foundations';
      final baseDate = DateTime.utc(2026, 9, 8);

      // ----------------------------------------------------
      // STEP 1: Faculty creates Question & Remedial Lesson
      // ----------------------------------------------------
      final draftQuestion = await facultyService.createDraft(
        id: 'q_fac_e2e_01',
        title: 'Maneka Gandhi Case Expansion',
        examId: examId,
        subjectId: subjectId,
        topicId: 'Fundamental Rights',
        objectiveId: objectiveId,
        contentType: ManagedContentType.question,
        authorId: 'prof_e2e',
        provenance: 'Supreme Court Reports 1978',
        prompt: 'Which element is essential to Article 21 post-Maneka Gandhi?',
        options: const [
          'Procedure must be just, fair and reasonable',
          'Only literal procedure established by law',
          'Executive discretion is absolute',
          'Fundamental rights are mutually exclusive',
        ],
        correctAnswer: 'A',
      );

      final draftLesson = await facultyService.createDraft(
        id: 'rem_fac_e2e_01',
        title: 'Substantive Due Process Micro-Lesson',
        examId: examId,
        subjectId: subjectId,
        topicId: 'Fundamental Rights',
        objectiveId: objectiveId,
        contentType: ManagedContentType.remedialLesson,
        authorId: 'prof_e2e',
        provenance: 'Constitutional Law Faculty Board',
        summary: 'Golden Triangle doctrine connecting Articles 14, 19, and 21.',
        lessonExplanation:
            'In Maneka Gandhi, the Supreme Court held that procedure must not be arbitrary, fanciful or oppressive.',
        learningPoints: const [
          'Substantive Due Process',
          'Golden Triangle Doctrine',
        ],
        estimatedMinutes: 8,
      );

      expect(draftQuestion.status, equals(ContentLifecycleStatus.draft));
      expect(draftLesson.status, equals(ContentLifecycleStatus.draft));

      // ----------------------------------------------------
      // STEP 2: Validate Content
      // ----------------------------------------------------
      final qValidation = facultyService.validateContent(draftQuestion);
      expect(qValidation.isValid, isTrue);

      final lValidation = facultyService.validateContent(draftLesson);
      expect(lValidation.isValid, isTrue);

      // ----------------------------------------------------
      // STEP 3: Preview Content
      // ----------------------------------------------------
      final normalizedQ = draftQuestion.toNormalizedQuestion();
      expect(normalizedQ.normalizedText, contains('Maneka Gandhi'));
      expect(normalizedQ.officialAnswer.correctOptionKeys, contains('A'));

      final normalizedLesson = draftLesson.toRemedialLesson();
      expect(normalizedLesson.summary, contains('Golden Triangle'));

      // ----------------------------------------------------
      // STEP 4: Verify Learner CANNOT see Draft Content
      // ----------------------------------------------------
      final prePublishDetail = await contentService.resolveLearningPath(
        learnerId: learnerId,
        examId: examId,
        subjectId: subjectId,
        topicId: topicId,
        asOfDate: baseDate,
      );
      expect(prePublishDetail.selectedTopic?.questionCount ?? 0, equals(0));

      // ----------------------------------------------------
      // STEP 5: Faculty Publishes Content
      // ----------------------------------------------------
      final publishedQ = await facultyService.publishContent(draftQuestion.id);
      final publishedL = await facultyService.publishContent(draftLesson.id);

      expect(publishedQ.isPublished, isTrue);
      expect(publishedL.isPublished, isTrue);

      // Verify Remedial Repository sync
      final syncedLesson = await remedialRepo.getLesson(draftLesson.id);
      expect(syncedLesson, isNotNull);
      expect(syncedLesson!.lessonId, equals(draftLesson.id));

      // ----------------------------------------------------
      // STEP 6: Learner Discovers Published Content
      // ----------------------------------------------------
      final postPublishDetail = await contentService.resolveLearningPath(
        learnerId: learnerId,
        examId: examId,
        subjectId: subjectId,
        topicId: topicId,
        asOfDate: baseDate,
      );

      // Learner discovers the newly published question in topic metrics!
      expect(postPublishDetail.selectedTopic?.questionCount, equals(1));

      // Learner also discovers published materials for this objective
      final publishedContentForObj =
          await contentService.getPublishedContentForObjective(objectiveId);
      expect(publishedContentForObj.any((i) => i.id == draftQuestion.id), isTrue);
      expect(publishedContentForObj.any((i) => i.id == draftLesson.id), isTrue);

      // ----------------------------------------------------
      // STEP 7: Learner with Persistent Difficulty Gets Faculty Lesson
      // ----------------------------------------------------
      final weakState = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          objectiveId: LearnerProgress(
            learnerId: learnerId,
            objectiveId: objectiveId,
            attemptCount: 4,
            correctCount: 1,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(weakState));

      final weakPathDetail = await contentService.resolveLearningPath(
        learnerId: learnerId,
        examId: examId,
        subjectId: subjectId,
        topicId: topicId,
        asOfDate: baseDate,
      );

      expect(weakPathDetail.recommendedAction,
          equals(AdaptiveActionType.startRemedialLesson));
      expect(weakPathDetail.remedialLessonId, equals(draftLesson.id));

      // ----------------------------------------------------
      // STEP 8: Learner Completes Learning Drill with Faculty Question
      // ----------------------------------------------------
      final startOk = await journeyController.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: [publishedQ.toNormalizedQuestion()],
        questionCount: 1,
      );
      expect(startOk, isTrue);

      await journeyController.submitAnswer(answer: 'A');
      expect(journeyController.isCompleted, isTrue);

      // ----------------------------------------------------
      // STEP 9: Existing Outcome / Mastery Pipeline Confirms Update
      // ----------------------------------------------------
      final recoveredMastery = await authRecoveryService.recover(
        learnerId: learnerId,
        examId: examId,
        requestedAt: baseDate,
      );

      final finalProgress = recoveredMastery.state!.progressMap[objectiveId]!;
      expect(finalProgress.attemptCount, equals(5));
      expect(finalProgress.correctCount, equals(2));
    });
  });
}
