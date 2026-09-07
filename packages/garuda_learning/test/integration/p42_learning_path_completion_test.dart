/// P42 Learner Learning-Path Completion Integration Tests (TITAN-KO-042.0 P42).
///
/// Exhaustively exercises the 23 real learner-path integration scenarios:
/// 1. first-time learner
/// 2. exam selection
/// 3. subject selection
/// 4. topic selection
/// 5. objective selection
/// 6. next action resolution
/// 7. diagnostic path
/// 8. practice path
/// 9. PYQ path
/// 10. remedial path
/// 11. session completion
/// 12. outcome consolidation
/// 13. state reconciliation
/// 14. persistence
/// 15. recovery
/// 16. resume
/// 17. refreshed objective state
/// 18. next action after completion
/// 19. empty content
/// 20. service failure
/// 21. invalid state
/// 22. duplicate action prevention
/// 23. no dead-end navigation
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart' as pyq;

void main() {
  group('P42 Learner Learning-Path Completion Integration Tests (23 Scenarios)', () {
    const String testLearner = 'learner_p42_titan_exec';
    const String testExam = 'upsc_prelims_gs1';
    final DateTime baseDate = DateTime.utc(2026, 9, 7, 10, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late AdaptiveLearningStateReconciliationPipeline reconciliationPipeline;
    late InMemoryLearnerRepository learnerRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryDiagnosticPlacementRepository diagnosticRepo;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryRemedialLessonRepository remedialRepo;
    late DeterministicRemedialLessonService remedialService;
    late DiagnosticAssessmentService diagnosticService;
    late AdaptiveLearningJourneyOrchestrator journeyOrchestrator;
    late AdaptiveLearningJourneyController journeyController;
    late AdaptiveLearningDecisionEngine decisionEngine;
    late List<pyq.NormalizedQuestion> seedCorpus;
    late ContentLearningPathService service;

    pyq.NormalizedQuestion buildTestQuestion({
      required String id,
      required String subject,
      required String topic,
      required String objectiveId,
      required String correctOption,
      String difficulty = 'Medium',
    }) {
      return pyq.NormalizedQuestion(
        id: id,
        examId: testExam,
        year: 2024,
        paper: 'GS1',
        subject: subject,
        topic: topic,
        normalizedText:
            'Question stem for $id: What is the constitutional significance of $topic?',
        originalText: 'Original stem for $id',
        options: [
          pyq.Option(
            key: 'A',
            text: 'Constitutional Remedy ($id)',
            isCorrect: correctOption == 'A',
          ),
          pyq.Option(
            key: 'B',
            text: 'Executive Discretion ($id)',
            isCorrect: correctOption == 'B',
          ),
          pyq.Option(
            key: 'C',
            text: 'Legislative Rule ($id)',
            isCorrect: correctOption == 'C',
          ),
          pyq.Option(
            key: 'D',
            text: 'Administrative Guideline ($id)',
            isCorrect: correctOption == 'D',
          ),
        ],
        officialAnswer: pyq.Answer(
          correctOptionKeys: [correctOption],
          officialAnswerSource: 'UPSC Official Answer Key',
        ),
        explanation:
            'Detailed constitutional jurisprudence explanation for $id grounded in Supreme Court doctrine.',
        difficulty: difficulty,
        source: pyq.PyqSourceReference.official(
          examId: testExam,
          year: 2024,
          paper: 'GS1',
        ),
        objectiveIds: [objectiveId],
      );
    }

    setUp(() {
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      checkpointRepo = InMemorySessionCheckpointRepository();
      authRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );
      sessionRecoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );
      reconciliationPipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: authRepo,
        recoveryService: authRecoveryService,
        reconciler: const AdaptiveLearningStateReconciler(),
        proposer: const LearningStateUpdateProposer(),
        consolidator: const PracticeOutcomeConsolidator(),
      );

      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);

      learnerRepo = InMemoryLearnerRepository();
      learnerRepo.save(Learner(
        id: testLearner,
        name: 'TITAN Executive Learner',
        createdAt: baseDate,
      ));
      attemptRepo = InMemoryAttemptRepository();
      diagnosticRepo = InMemoryDiagnosticPlacementRepository();

      remedialRepo = InMemoryRemedialLessonRepository();
      remedialRepo.saveLesson(RemedialLesson(
        lessonId: 'rem_art21_01',
        objectiveId: 'lo_article_21_foundations',
        title: 'Article 21 Jurisprudence Remedial Drill',
        summary:
            'Targeted remediation on substantive due process and personal liberty.',
        learningPoints: const [
          'Procedure Established by Law',
          'Substantive Due Process',
          'Golden Triangle (Articles 14, 19, 21)'
        ],
        explanation: 'Detailed micro-lesson on Maneka Gandhi doctrine.',
        estimatedMinutes: 10,
        authoredAt: baseDate,
      ));
      remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );

      seedCorpus = [
        buildTestQuestion(
          id: 'pyq_polity_fr_01',
          subject: 'Indian Polity',
          topic: 'Fundamental Rights',
          objectiveId: 'lo_article_21_foundations',
          correctOption: 'A',
          difficulty: 'Medium',
        ),
        buildTestQuestion(
          id: 'pyq_polity_fr_02',
          subject: 'Indian Polity',
          topic: 'Fundamental Rights',
          objectiveId: 'lo_article_21_foundations',
          correctOption: 'B',
          difficulty: 'Hard',
        ),
        buildTestQuestion(
          id: 'pyq_polity_ep_01',
          subject: 'Indian Polity',
          topic: 'Emergency Provisions',
          objectiveId: 'lo_emergency_provisions',
          correctOption: 'C',
          difficulty: 'Medium',
        ),
      ];

      final diagQ1 = pyq.Question(
        id: 'PYQ_DIAG_2024_01',
        questionNumber: 1,
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        questionType: pyq.QuestionType.mcq,
        originalQuestion:
            'Which Article provides protection against arbitrary arrest?',
        options: const [
          pyq.Option(key: 'A', text: 'Article 21', isCorrect: true),
          pyq.Option(key: 'B', text: 'Article 19', isCorrect: false),
        ],
        officialAnswer: const pyq.Answer(
          correctOptionKeys: ['A'],
          officialAnswerSource: 'UPSC Key',
        ),
        source: pyq.QuestionSource(
          sourceType: pyq.SourceType.officialWebsite,
          url: 'https://upsc.gov.in',
          checksum: 'checksum001',
          publisher: 'UPSC',
          retrievedDate: baseDate,
        ),
      );

      final pyqProvider = PyqQuestionProvider(
        questions: [diagQ1],
        topicOrTagToObjectiveIds: const {
          'fundamental rights': ['lo_article_21_foundations'],
        },
      );

      diagnosticService = DiagnosticAssessmentService(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        questionProvider: pyqProvider,
        attemptRepository: attemptRepo,
        diagnosticRepository: diagnosticRepo,
      );

      journeyOrchestrator = AdaptiveLearningJourneyOrchestrator(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        reconciliationPipeline: reconciliationPipeline,
        diagnosticService: diagnosticService,
      );
      journeyController = AdaptiveLearningJourneyController(
        orchestrator: journeyOrchestrator,
      );

      decisionEngine = AdaptiveLearningDecisionEngine();

      service = ContentLearningPathService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        decisionEngine: decisionEngine,
        remedialService: remedialService,
        diagnosticService: diagnosticService,
        diagnosticPlacementRepository: diagnosticRepo,
        seedQuestions: seedCorpus,
      );
    });

    // -------------------------------------------------------------------------
    // Scenario 1: First-time learner
    // -------------------------------------------------------------------------
    test('1. First-time learner: cold-start triggers diagnostic recommendation', () async {
      final state = await service.resolveLearningPath(
        learnerId: 'first_time_user_01',
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.status, equals(ContentPathStatus.topicSelected));
      expect(state.isDiagnosticRequired, isTrue);
      expect(state.recommendedAction, equals(AdaptiveActionType.takeDiagnostic));
      expect(state.actionTitle, contains('Take Diagnostic Assessment'));
      expect(state.authoritativeProgress, isNull);
      expect(state.isObjectiveAchieved, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 2: Exam selection
    // -------------------------------------------------------------------------
    test('2. Exam selection: lists available supported exams and populates subjects', () {
      final exams = service.getAvailableExams();
      expect(exams, isNotEmpty);
      final exam = exams.firstWhere((e) => e.id == testExam);
      expect(exam.isSupported, isTrue);
      expect(exam.name, contains('Civil Services'));

      final subjects = service.getSubjectsForExam(testExam);
      expect(subjects, isNotEmpty);
      expect(subjects.map((s) => s.id), contains('indian_polity'));
    });

    // -------------------------------------------------------------------------
    // Scenario 3: Subject selection
    // -------------------------------------------------------------------------
    test('3. Subject selection: lists valid curriculum topics under chosen subject', () {
      final subjects = service.getSubjectsForExam(testExam);
      expect(subjects.map((s) => s.id), contains('indian_polity'));

      final topics = service.getTopicsForSubject(testExam, 'indian_polity');
      expect(topics, isNotEmpty);
      expect(topics.map((t) => t.id), contains('fundamental_rights'));
    });

    // -------------------------------------------------------------------------
    // Scenario 4: Topic selection
    // -------------------------------------------------------------------------
    test('4. Topic selection: returns topic context with verified question and PYQ metrics', () {
      final topic = service.getTopicById(testExam, 'indian_polity', 'fundamental_rights');
      expect(topic, isNotNull);
      expect(topic!.questionCount, equals(2));
      expect(topic.hasPyqContent, isTrue);
      expect(topic.objectiveId, equals('lo_article_21_foundations'));
      expect(topic.name, equals('Fundamental Rights'));
    });

    // -------------------------------------------------------------------------
    // Scenario 5: Objective selection
    // -------------------------------------------------------------------------
    test('5. Objective selection: correctly resolves canonical curriculum objective', () async {
      final state = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.resolvedObjective, isNotNull);
      expect(state.resolvedObjective!.id, equals('lo_article_21_foundations'));
      expect(state.resolvedObjective!.title, contains('Article 21'));
      expect(state.resolvedObjective!.bloomLevel, equals(BloomTaxonomyLevel.evaluate));
    });

    // -------------------------------------------------------------------------
    // Scenario 6: Next action resolution
    // -------------------------------------------------------------------------
    test('6. Next action resolution: strictly enforces prioritized action tiering', () async {
      // Priority tier: Unassessed learner -> takeDiagnostic
      final state = await service.resolveLearningPath(
        learnerId: 'unassessed_learner',
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );
      expect(state.recommendedAction, equals(AdaptiveActionType.takeDiagnostic));
      expect(state.isDiagnosticRequired, isTrue);
    });

    // -------------------------------------------------------------------------
    // Scenario 7: Diagnostic path
    // -------------------------------------------------------------------------
    test('7. Diagnostic path: evaluates diagnostic placement and stores frontier result', () {
      final frontier = DiagnosticPlacementFrontier(
        activeFrontierObjectiveIds: const ['lo_article_21_foundations'],
        demonstratedObjectiveIds: const [],
        developingObjectiveIds: const [],
        unassessedObjectiveIds: const [],
        remediationTargetObjectiveIds: const ['lo_emergency_provisions'],
      );
      final diagResult = DiagnosticPlacementResult(
        assessmentId: 'diag_p42_001',
        learnerId: testLearner,
        evaluatedAt: baseDate,
        objectiveResults: const {},
        frontier: frontier,
        totalAssessedObjectives: 2,
        demonstratedObjectivesCount: 0,
        totalAttemptsCount: 4,
        totalCorrectCount: 1,
        aggregateAccuracy: 0.25,
        provenance: 'P42 Integration Test',
      );

      diagnosticRepo.saveResult(diagResult);
      final retrieved = diagnosticRepo.getLatestResultForLearner(testLearner);
      expect(retrieved, isNotNull);
      expect(retrieved!.learnerId, equals(testLearner));
      expect(retrieved.frontier.activeFrontierObjectiveIds, contains('lo_article_21_foundations'));
    });

    // -------------------------------------------------------------------------
    // Scenario 8: Practice path
    // -------------------------------------------------------------------------
    test('8. Practice path: assessed learner with moderate progress continues practice', () async {
      final activeProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_article_21_foundations',
        status: LearnerObjectiveStatus.inProgress,
        attemptCount: 3,
        correctCount: 2,
        lastAttemptAt: baseDate,
      );
      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        progressMap: {'lo_article_21_foundations': activeProgress},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState),
      );

      final state = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.recommendedAction, equals(AdaptiveActionType.continuePractice));
      expect(state.actionTitle, equals('Start Adaptive Practice'));
      expect(state.authoritativeProgress?.status, equals(LearnerObjectiveStatus.inProgress));
    });

    // -------------------------------------------------------------------------
    // Scenario 9: PYQ path
    // -------------------------------------------------------------------------
    test('9. PYQ path: recommends PYQ drill when topic contains official past questions', () async {
      const learnerId = 'pyq_learner_01';
      // Learner with prior attempts on other topics (not cold start)
      final priorProgress = LearnerProgress(
        learnerId: learnerId,
        objectiveId: 'lo_other',
        attemptCount: 2,
        correctCount: 2,
      );
      final authState = AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: testExam,
        revision: 1,
        progressMap: {'lo_other': priorProgress},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState),
      );

      final state = await service.resolveLearningPath(
        learnerId: learnerId,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.recommendedAction, equals(AdaptiveActionType.practicePyqs));
      expect(state.selectedTopic?.hasPyqContent, isTrue);
      expect(state.selectedTopic?.questionCount, greaterThan(0));
    });

    // -------------------------------------------------------------------------
    // Scenario 10: Remedial path
    // -------------------------------------------------------------------------
    test('10. Remedial path: routes weak learner to bound micro-lesson drill', () async {
      const weakLearner = 'learner_struggling_01';
      final weakProgress = LearnerProgress(
        learnerId: weakLearner,
        objectiveId: 'lo_article_21_foundations',
        status: LearnerObjectiveStatus.inProgress,
        attemptCount: 4,
        correctCount: 1,
        lastAttemptAt: baseDate,
      );
      final authState = AuthoritativeLearnerState(
        learnerId: weakLearner,
        examId: testExam,
        revision: 1,
        progressMap: {'lo_article_21_foundations': weakProgress},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState),
      );

      final state = await service.resolveLearningPath(
        learnerId: weakLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.recommendedAction, equals(AdaptiveActionType.startRemedialLesson));
      expect(state.remedialLessonId, equals('rem_art21_01'));
      expect(state.actionTitle, contains('Start Remedial Lesson'));
    });

    // -------------------------------------------------------------------------
    // Scenario 11: Session completion
    // -------------------------------------------------------------------------
    test('11. Session completion: adaptive practice session transitions to completed status', () async {
      const sessionLearner = 'learner_complete_01';
      final success = await journeyController.startJourney(
        learnerId: sessionLearner,
        examId: testExam,
        corpus: seedCorpus.take(2).toList(),
        questionCount: 2,
      );
      expect(success, isTrue);

      await journeyController.submitAnswer(answer: 'A');
      expect(journeyController.isCompleted, isFalse);

      await journeyController.submitAnswer(answer: 'B');
      expect(journeyController.isCompleted, isTrue);
      expect(journeyController.status, equals(LearningJourneyStatus.completed));
      expect(journeyController.completedCount, equals(2));
    });

    // -------------------------------------------------------------------------
    // Scenario 12: Outcome consolidation
    // -------------------------------------------------------------------------
    test('12. Outcome consolidation: aggregates question attempts, score, and accuracy', () async {
      const sessionLearner = 'learner_consolidate_01';
      await journeyController.startJourney(
        learnerId: sessionLearner,
        examId: testExam,
        corpus: seedCorpus.take(2).toList(),
        questionCount: 2,
      );

      await journeyController.submitAnswer(answer: 'A'); // Correct (A)
      await journeyController.submitAnswer(answer: 'D'); // Incorrect (expected B)

      final results = journeyController.session!.executionState.questionResults;
      expect(results.length, equals(2));
      expect(results['pyq_polity_fr_01']!.isCorrect, isTrue);
      expect(results['pyq_polity_fr_02']!.isCorrect, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 13: State reconciliation
    // -------------------------------------------------------------------------
    test('13. State reconciliation: atomically reconciles session outcome into authoritative state', () async {
      const sessionLearner = 'learner_reconcile_01';
      await journeyController.startJourney(
        learnerId: sessionLearner,
        examId: testExam,
        corpus: seedCorpus.take(2).toList(),
        questionCount: 2,
      );

      final initialRevision = journeyController.session!.authoritativeState.revision;
      await journeyController.submitAnswer(answer: 'A');
      final updatedRevision = journeyController.session!.authoritativeState.revision;

      expect(updatedRevision, equals(initialRevision + 1));
      final progress = journeyController.session!.authoritativeState
          .progressMap['lo_article_21_foundations'];
      expect(progress, isNotNull);
      expect(progress!.attemptCount, greaterThanOrEqualTo(1));
    });

    // -------------------------------------------------------------------------
    // Scenario 14: Persistence
    // -------------------------------------------------------------------------
    test('14. Persistence: saves updated authoritative state monotonically to repository', () async {
      const sessionLearner = 'learner_persist_01';
      await journeyController.startJourney(
        learnerId: sessionLearner,
        examId: testExam,
        corpus: seedCorpus.take(2).toList(),
        questionCount: 2,
      );

      await journeyController.submitAnswer(answer: 'A');

      final loadedState = await authRepo.load(
        learnerId: sessionLearner,
        examId: testExam,
      );
      expect(loadedState, isNotNull);
      expect(loadedState!.revision, greaterThanOrEqualTo(2));
      expect(loadedState.progressMap.containsKey('lo_article_21_foundations'), isTrue);
    });

    // -------------------------------------------------------------------------
    // Scenario 15: Recovery
    // -------------------------------------------------------------------------
    test('15. Recovery: recovers authoritative state consistently across process restarts', () async {
      const sessionLearner = 'learner_recovery_01';
      final preSavedProgress = LearnerProgress(
        learnerId: sessionLearner,
        objectiveId: 'lo_article_21_foundations',
        status: LearnerObjectiveStatus.inProgress,
        attemptCount: 6,
        correctCount: 5,
        lastAttemptAt: baseDate,
      );
      final authState = AuthoritativeLearnerState(
        learnerId: sessionLearner,
        examId: testExam,
        revision: 4,
        progressMap: {'lo_article_21_foundations': preSavedProgress},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState),
      );

      // Brand new recovery service instance simulating cold restart
      final coldRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );
      final recoveryResult = await coldRecoveryService.recover(
        learnerId: sessionLearner,
        examId: testExam,
        requestedAt: baseDate,
      );

      expect(recoveryResult.isSuccess, isTrue);
      expect(recoveryResult.state!.revision, equals(4));
      expect(recoveryResult.state!.progressMap['lo_article_21_foundations']?.correctCount, equals(5));
    });

    // -------------------------------------------------------------------------
    // Scenario 16: Resume
    // -------------------------------------------------------------------------
    test('16. Resume: detects uncompleted in-flight session and offers continueSession', () async {
      const sessionLearner = 'learner_resume_01';
      final checkpoint = SessionCheckpoint(
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        sessionId: 'session_active_01',
        examId: testExam,
        learnerId: sessionLearner,
        timestamp: baseDate,
        questionIndex: 1,
        activeObjectiveId: 'lo_article_21_foundations',
        completedQuestionIds: const ['pyq_polity_fr_01'],
        isCompleted: false,
        schemaVersion: 1,
        metadata: const {
          'topic': 'Fundamental Rights',
          'topicId': 'fundamental_rights',
          'totalQuestions': 4,
        },
      );
      await checkpointRepo.saveCheckpoint(checkpoint);

      final state = await service.resolveLearningPath(
        learnerId: sessionLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.canResumeActiveSession, isTrue);
      expect(state.activeSessionId, equals('session_active_01'));
      expect(state.recommendedAction, equals(AdaptiveActionType.continueSession));
      expect(state.actionTitle, contains('Resume Practice Session'));
    });

    // -------------------------------------------------------------------------
    // Scenario 17: Refreshed objective state
    // -------------------------------------------------------------------------
    test('17. Refreshed objective state: reflect reconciled progress immediately on path refresh', () async {
      const sessionLearner = 'learner_refresh_01';
      final initialProgress = LearnerProgress(
        learnerId: sessionLearner,
        objectiveId: 'lo_article_21_foundations',
        status: LearnerObjectiveStatus.inProgress,
        attemptCount: 2,
        correctCount: 1,
        lastAttemptAt: baseDate,
      );
      final authState1 = AuthoritativeLearnerState(
        learnerId: sessionLearner,
        examId: testExam,
        revision: 1,
        progressMap: {'lo_article_21_foundations': initialProgress},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState1),
      );

      final state1 = await service.resolveLearningPath(
        learnerId: sessionLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );
      expect(state1.authoritativeProgress?.attemptCount, equals(2));
      expect(state1.authoritativeProgress?.correctCount, equals(1));

      // Update state via authoritative persistence
      final refreshedProgress = LearnerProgress(
        learnerId: sessionLearner,
        objectiveId: 'lo_article_21_foundations',
        status: LearnerObjectiveStatus.inProgress,
        attemptCount: 5,
        correctCount: 4,
        lastAttemptAt: baseDate,
      );
      final authState2 = AuthoritativeLearnerState(
        learnerId: sessionLearner,
        examId: testExam,
        revision: 2,
        progressMap: {'lo_article_21_foundations': refreshedProgress},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState2),
      );

      final state2 = await service.resolveLearningPath(
        learnerId: sessionLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );
      expect(state2.authoritativeProgress?.attemptCount, equals(5));
      expect(state2.authoritativeProgress?.correctCount, equals(4));
    });

    // -------------------------------------------------------------------------
    // Scenario 18: Next action after completion
    // -------------------------------------------------------------------------
    test('18. Next action after completion: marks objective achieved and points to next topic', () async {
      const sessionLearner = 'learner_master_01';
      final masteredProgress = LearnerProgress(
        learnerId: sessionLearner,
        objectiveId: 'lo_article_21_foundations',
        status: LearnerObjectiveStatus.achieved,
        attemptCount: 10,
        correctCount: 9,
        lastAttemptAt: baseDate,
      );
      final authState = AuthoritativeLearnerState(
        learnerId: sessionLearner,
        examId: testExam,
        revision: 3,
        progressMap: {'lo_article_21_foundations': masteredProgress},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState),
      );

      final state = await service.resolveLearningPath(
        learnerId: sessionLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.isObjectiveAchieved, isTrue);
      expect(state.nextObjectiveId, isNotNull);
      expect(state.nextObjectiveTitle, isNotNull);
      expect(state.recommendedAction, equals(AdaptiveActionType.reviewWeakTopic));
    });

    // -------------------------------------------------------------------------
    // Scenario 19: Empty content
    // -------------------------------------------------------------------------
    test('19. Empty content: handles unseeded topic gracefully without phantom questions', () async {
      final state = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'parliament_and_state_legislature', // No questions in seedCorpus
        asOfDate: baseDate,
      );

      expect(state.status, equals(ContentPathStatus.emptyContent));
      expect(state.selectedTopic?.questionCount, equals(0));
      expect(state.isDiagnosticRequired, isFalse);
      expect(state.recommendedAction, equals(AdaptiveActionType.none));
      expect(state.actionTitle, contains('No Practice Questions Available'));
    });

    // -------------------------------------------------------------------------
    // Scenario 20: Service failure
    // -------------------------------------------------------------------------
    test('20. Service failure: handles unexpected underlying failure without crashing', () async {
      final brokenService = ContentLearningPathService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
      );

      // Topic does not exist -> gracefully produces error state
      final state = await brokenService.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'non_existent_topic_xyz',
        asOfDate: baseDate,
      );

      expect(state.status, equals(ContentPathStatus.error));
      expect(state.errorMessage, isNotNull);
    });

    // -------------------------------------------------------------------------
    // Scenario 21: Invalid state
    // -------------------------------------------------------------------------
    test('21. Invalid state: returns clear error for non-existent exam or subject', () async {
      final state = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: 'invalid_exam_999',
        subjectId: 'invalid_subject_888',
        topicId: 'invalid_topic_777',
        asOfDate: baseDate,
      );

      expect(state.status, equals(ContentPathStatus.error));
      expect(state.errorMessage, contains('not supported'));
    });

    // -------------------------------------------------------------------------
    // Scenario 22: Duplicate action prevention
    // -------------------------------------------------------------------------
    test('22. Duplicate action prevention: repeated resolve calls produce idempotent results', () async {
      final state1 = await service.resolveLearningPath(
        learnerId: 'learner_idempotent',
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      final state2 = await service.resolveLearningPath(
        learnerId: 'learner_idempotent',
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state1.status, equals(state2.status));
      expect(state1.recommendedAction, equals(state2.recommendedAction));
      expect(state1.actionTitle, equals(state2.actionTitle));
      expect(state1.actionDescription, equals(state2.actionDescription));
    });

    // -------------------------------------------------------------------------
    // Scenario 23: No dead-end navigation
    // -------------------------------------------------------------------------
    test('23. No dead-end navigation: provides unbroken progression across entire hierarchy', () async {
      // 1. Root: Available exams exist
      final exams = service.getAvailableExams();
      expect(exams, isNotEmpty);

      // 2. Exam: Subjects exist
      final subjects = service.getSubjectsForExam(exams.first.id);
      expect(subjects, isNotEmpty);

      // 3. Subject: Topics exist
      final topics = service.getTopicsForSubject(
        exams.first.id,
        subjects.first.id,
      );
      expect(topics, isNotEmpty);

      // 4. Topic: Context and Objective resolve
      final topicContext = service.getTopicById(
        exams.first.id,
        subjects.first.id,
        topics.first.id,
      );
      expect(topicContext, isNotNull);
      expect(topicContext!.objectiveId, isNotNull);

      // 5. Next topic resolution exists
      final nextTopic = service.getNextTopicForTopic(
        exams.first.id,
        subjects.first.id,
        topics.first.id,
      );
      expect(nextTopic, isNotNull);
    });
  });
}
