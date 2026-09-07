/// P42 Content-to-Learning-Path Integration Tests (TITAN-KO-042.0 P42).
///
/// Exhaustively verifies the 15 core scenarios specified in P42 requirements:
/// 1. Learner opens content discovery
/// 2. Available exam is displayed
/// 3. Subject/topic is displayed
/// 4. Topic can be selected
/// 5. Learning objective resolves
/// 6. Existing learner progress is detected
/// 7. New learner can enter learning
/// 8. Existing learner can resume
/// 9. Diagnostic is invoked when required
/// 10. Adaptive practice starts
/// 11. Real PYQ-backed content is used where available
/// 12. Empty topic/content is handled
/// 13. Invalid selection is handled
/// 14. State remains consistent across navigation
/// 15. Completion returns learner to an appropriate next action
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P42 Content-to-Learning-Path Integration Tests', () {
    const String testLearner = 'learner_p42_titan';
    const String testExam = 'upsc_prelims_gs1';
    final baseDate = DateTime.utc(2026, 9, 7, 10, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late AdaptiveLearningDecisionEngine decisionEngine;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryRemedialLessonRepository remedialRepo;
    late DeterministicRemedialLessonService remedialService;
    late List<NormalizedQuestion> seedCorpus;
    late ContentLearningPathService service;

    NormalizedQuestion buildTestQuestion({
      required String id,
      required String subject,
      required String topic,
      required String objectiveId,
    }) {
      return NormalizedQuestion(
        id: id,
        examId: testExam,
        year: 2024,
        paper: 'GS1',
        subject: subject,
        topic: topic,
        normalizedText:
            'Question stem for $id: What is the constitutional significance?',
        originalText: 'Original stem for $id',
        options: const [
          Option(key: 'A', text: 'Constitutional Remedy', isCorrect: true),
          Option(key: 'B', text: 'Executive Discretion', isCorrect: false),
          Option(key: 'C', text: 'Legislative Rule', isCorrect: false),
          Option(key: 'D', text: 'Administrative Guideline', isCorrect: false),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['A'],
          officialAnswerSource: 'UPSC Official Answer Key',
        ),
        explanation:
            'Detailed explanation for $id grounded in constitutional jurisprudence.',
        difficulty: 'Medium',
        source: PyqSourceReference.official(
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
      decisionEngine = AdaptiveLearningDecisionEngine();
      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);

      remedialRepo = InMemoryRemedialLessonRepository();
      remedialRepo.saveLesson(RemedialLesson(
        lessonId: 'rem_art21_01',
        objectiveId: 'lo_article_21_foundations',
        title: 'Article 21 Jurisprudence Remedial Drill',
        summary:
            'Targeted remediation on substantive due process and personal liberty.',
        learningPoints: const [
          'Procedure Established by Law',
          'Substantive Due Process'
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
        ),
        buildTestQuestion(
          id: 'pyq_polity_fr_02',
          subject: 'Indian Polity',
          topic: 'Fundamental Rights',
          objectiveId: 'lo_article_21_foundations',
        ),
        buildTestQuestion(
          id: 'pyq_polity_ep_01',
          subject: 'Indian Polity',
          topic: 'Emergency Provisions',
          objectiveId: 'lo_emergency_provisions',
        ),
        buildTestQuestion(
          id: 'pyq_polity_dp_01',
          subject: 'Indian Polity',
          topic: 'Directive Principles',
          objectiveId: 'lo_dpsp',
        ),
        buildTestQuestion(
          id: 'pyq_econ_macro_01',
          subject: 'Economy',
          topic: 'Macroeconomics',
          objectiveId: 'lo_macroeconomics',
        ),
      ];

      service = ContentLearningPathService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        decisionEngine: decisionEngine,
        remedialService: remedialService,
        seedQuestions: seedCorpus,
      );
    });

    // -------------------------------------------------------------------------
    // 1. Learner opens content discovery
    // -------------------------------------------------------------------------
    test(
        '1. Learner opens content discovery: returns initial catalogue with available exams',
        () {
      final exams = service.getAvailableExams();
      expect(exams, isNotEmpty);
      expect(exams.any((e) => e.id == 'upsc_prelims_gs1'), isTrue);

      final initialState =
          ContentLearningPathState.initial(availableExams: exams);
      expect(initialState.status, equals(ContentPathStatus.initial));
      expect(initialState.availableExams.length, equals(exams.length));
      expect(initialState.selectedExam, isNull);
    });

    // -------------------------------------------------------------------------
    // 2. Available exam is displayed
    // -------------------------------------------------------------------------
    test(
        '2. Available exam is displayed: exposes real metadata and support status',
        () {
      final exams = service.getAvailableExams();
      final upscExam = exams.firstWhere((e) => e.id == 'upsc_prelims_gs1');

      expect(upscExam.code, equals('UPSC_PRELIMS_GS1'));
      expect(upscExam.name, contains('UPSC Civil Services'));
      expect(upscExam.category, equals('Central Civil Services'));
      expect(
          upscExam.conductingBody, equals('Union Public Service Commission'));
      expect(upscExam.isSupported, isTrue);
      expect(upscExam.subjectCount, greaterThan(0));

      final cdsExam = exams.firstWhere((e) => e.id == 'cds');
      expect(cdsExam.isSupported, isFalse);
    });

    // -------------------------------------------------------------------------
    // 3. Subject/topic is displayed
    // -------------------------------------------------------------------------
    test(
        '3. Subject/topic is displayed: lists valid subjects and topics for supported exam',
        () {
      final subjects = service.getSubjectsForExam('upsc_prelims_gs1');
      expect(subjects.length, equals(2));
      expect(
          subjects.map((s) => s.id), containsAll(['indian_polity', 'economy']));

      final polityTopics =
          service.getTopicsForSubject('upsc_prelims_gs1', 'indian_polity');
      expect(polityTopics.length, equals(5));
      expect(
        polityTopics.map((t) => t.id),
        containsAll([
          'fundamental_rights',
          'preamble_and_basic_structure',
          'emergency_provisions',
          'directive_principles',
          'parliament_and_state_legislature',
        ]),
      );
    });

    // -------------------------------------------------------------------------
    // 4. Topic can be selected
    // -------------------------------------------------------------------------
    test(
        '4. Topic can be selected: returns complete TopicContext with accurate metadata',
        () {
      final topic = service.getTopicById(
          'upsc_prelims_gs1', 'indian_polity', 'fundamental_rights');
      expect(topic, isNotNull);
      expect(topic!.id, equals('fundamental_rights'));
      expect(topic.name, equals('Fundamental Rights'));
      expect(topic.subjectId, equals('indian_polity'));
      expect(topic.examId, equals('upsc_prelims_gs1'));
      expect(topic.hasPyqContent, isTrue);
      expect(topic.questionCount, equals(2));
    });

    // -------------------------------------------------------------------------
    // 5. Learning objective resolves
    // -------------------------------------------------------------------------
    test(
        '5. Learning objective resolves: correctly binds topic to canonical curriculum objective',
        () async {
      final state = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.status, equals(ContentPathStatus.topicSelected));
      expect(state.resolvedObjective, isNotNull);
      expect(state.resolvedObjective!.id, equals('lo_article_21_foundations'));
      expect(state.resolvedObjective!.title,
          equals('Evaluate the Expansion of Article 21 Rights'));
      expect(state.resolvedObjective!.bloomLevel,
          equals(BloomTaxonomyLevel.evaluate));
    });

    // -------------------------------------------------------------------------
    // 6. Existing learner progress is detected
    // -------------------------------------------------------------------------
    test(
        '6. Existing learner progress is detected: loads authoritative progress metrics',
        () async {
      final existingProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_article_21_foundations',
        status: LearnerObjectiveStatus.inProgress,
        attemptCount: 5,
        correctCount: 4,
        lastAttemptAt: baseDate.subtract(const Duration(hours: 2)),
      );

      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {'lo_article_21_foundations': existingProgress},
        lastUpdatedAt: baseDate,
      );

      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      final state = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.authoritativeProgress, isNotNull);
      expect(state.authoritativeProgress!.attemptCount, equals(5));
      expect(state.authoritativeProgress!.correctCount, equals(4));
      expect(state.authoritativeProgress!.successRate, equals(0.8));
    });

    // -------------------------------------------------------------------------
    // 7. New learner can enter learning
    // -------------------------------------------------------------------------
    test(
        '7. New learner can enter learning: diagnostic required for cold-start',
        () async {
      final state = await service.resolveLearningPath(
        learnerId: 'brand_new_learner',
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.status, equals(ContentPathStatus.topicSelected));
      expect(state.isDiagnosticRequired, isTrue);
      expect(state.canResumeActiveSession, isFalse);
      expect(
          state.recommendedAction, equals(AdaptiveActionType.takeDiagnostic));
      expect(state.actionTitle, contains('Take Diagnostic Assessment'));
    });

    // -------------------------------------------------------------------------
    // 8. Existing learner can resume
    // -------------------------------------------------------------------------
    test(
        '8. Existing learner can resume: detects uncompleted in-flight checkpoint',
        () async {
      final checkpoint = SessionCheckpoint(
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        sessionId: 'session_in_flight_fr',
        examId: testExam,
        learnerId: testLearner,
        timestamp: baseDate.subtract(const Duration(minutes: 15)),
        questionIndex: 1,
        activeObjectiveId: 'lo_article_21_foundations',
        completedQuestionIds: const ['pyq_polity_fr_01'],
        isCompleted: false,
        schemaVersion: 1,
        metadata: const {
          'topic': 'Fundamental Rights',
          'topicId': 'fundamental_rights',
          'totalQuestions': 2,
        },
      );

      await checkpointRepo.saveCheckpoint(checkpoint);

      final state = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.canResumeActiveSession, isTrue);
      expect(state.activeSessionId, equals('session_in_flight_fr'));
      expect(state.activeSessionCursor, equals(1));
      expect(state.activeSessionTotal, equals(2));
      expect(
          state.recommendedAction, equals(AdaptiveActionType.continueSession));
      expect(state.actionTitle, contains('Resume Practice Session'));
      expect(state.actionDescription, contains('question 2 of 2'));
    });

    // -------------------------------------------------------------------------
    // 9. Diagnostic is invoked when required
    // -------------------------------------------------------------------------
    test(
        '9. Diagnostic is invoked when required: triggers diagnostic recommendation',
        () async {
      final state = await service.resolveLearningPath(
        learnerId: 'unassessed_aspirant',
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.isDiagnosticRequired, isTrue);
      expect(
          state.recommendedAction, equals(AdaptiveActionType.takeDiagnostic));
      expect(state.actionTitle, equals('Take Diagnostic Assessment'));
      expect(state.actionDescription,
          contains('Evaluate your baseline competency'));
    });

    // -------------------------------------------------------------------------
    // 10. Adaptive practice starts
    // -------------------------------------------------------------------------
    test(
        '10. Adaptive practice starts: healthy assessed learner starts adaptive practice',
        () async {
      final existingProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_article_21_foundations',
        status: LearnerObjectiveStatus.inProgress,
        attemptCount: 4,
        correctCount: 3,
        lastAttemptAt: baseDate.subtract(const Duration(days: 1)),
      );

      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {'lo_article_21_foundations': existingProgress},
        lastUpdatedAt: baseDate,
      );

      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      final state = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.isDiagnosticRequired, isFalse);
      expect(state.canResumeActiveSession, isFalse);
      expect(
          state.recommendedAction, equals(AdaptiveActionType.continuePractice));
      expect(state.actionTitle, equals('Start Adaptive Practice'));
      expect(state.actionDescription,
          contains('Begin adaptive PYQ-backed practice drill'));
    });

    // -------------------------------------------------------------------------
    // 11. Real PYQ-backed content is used where available
    // -------------------------------------------------------------------------
    test(
        '11. Real PYQ-backed content is used where available: verifies actual question corpus',
        () {
      final topics =
          service.getTopicsForSubject('upsc_prelims_gs1', 'indian_polity');
      final frTopic = topics.firstWhere((t) => t.id == 'fundamental_rights');

      expect(frTopic.hasPyqContent, isTrue);
      expect(frTopic.questionCount, equals(2));

      final matchedQuestions =
          seedCorpus.where((q) => q.topic == frTopic.name).toList();
      expect(matchedQuestions.length, equals(2));
      for (final q in matchedQuestions) {
        expect(q.source.sourceId, isNotEmpty);
        expect(q.examId, equals(testExam));
        expect(q.options, isNotEmpty);
      }
    });

    // -------------------------------------------------------------------------
    // 12. Empty topic/content is handled
    // -------------------------------------------------------------------------
    test(
        '12. Empty topic/content is handled: returns truthful empty content status and clear message',
        () async {
      final state = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'parliament_and_state_legislature',
        asOfDate: baseDate,
      );

      expect(state.status, equals(ContentPathStatus.emptyContent));
      expect(state.selectedTopic, isNotNull);
      expect(state.selectedTopic!.hasPyqContent, isFalse);
      expect(state.selectedTopic!.questionCount, equals(0));
      expect(state.recommendedAction, equals(AdaptiveActionType.none));
      expect(state.actionTitle, equals('No Practice Questions Available'));
      expect(state.actionDescription, contains('no verified PYQ questions'));
    });

    // -------------------------------------------------------------------------
    // 13. Invalid selection is handled
    // -------------------------------------------------------------------------
    test(
        '13. Invalid selection is handled: returns error state for unknown exam, subject, or topic',
        () async {
      final invalidExamState = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: 'invalid_exam_xyz',
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
      );
      expect(invalidExamState.status, equals(ContentPathStatus.error));
      expect(invalidExamState.errorMessage, contains('not supported'));

      final invalidSubjectState = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'unknown_subject',
        topicId: 'fundamental_rights',
      );
      expect(invalidSubjectState.status, equals(ContentPathStatus.error));
      expect(invalidSubjectState.errorMessage,
          contains('Subject "unknown_subject" not found'));

      final invalidTopicState = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'non_existent_topic',
      );
      expect(invalidTopicState.status, equals(ContentPathStatus.error));
      expect(invalidTopicState.errorMessage,
          contains('Topic "non_existent_topic" not found'));
    });

    // -------------------------------------------------------------------------
    // 14. State remains consistent across navigation
    // -------------------------------------------------------------------------
    test(
        '14. State remains consistent across navigation: updates topic and exam context cleanly',
        () async {
      // 1. Initial State
      var state = ContentLearningPathState.initial(
          availableExams: service.getAvailableExams());
      expect(state.status, equals(ContentPathStatus.initial));

      // 2. Select Exam
      final selectedExam =
          state.availableExams.firstWhere((e) => e.id == 'upsc_prelims_gs1');
      final subjects = service.getSubjectsForExam(selectedExam.id);
      state = state.copyWith(
        status: ContentPathStatus.examSelected,
        selectedExam: selectedExam,
        availableSubjects: subjects,
      );
      expect(state.status, equals(ContentPathStatus.examSelected));
      expect(state.availableSubjects.length, equals(2));

      // 3. Select Subject
      final selectedSubject =
          state.availableSubjects.firstWhere((s) => s.id == 'indian_polity');
      final topics =
          service.getTopicsForSubject(selectedExam.id, selectedSubject.id);
      state = state.copyWith(
        status: ContentPathStatus.subjectSelected,
        selectedSubject: selectedSubject,
        availableTopics: topics,
      );
      expect(state.status, equals(ContentPathStatus.subjectSelected));
      expect(state.availableTopics.length, equals(5));

      // 4. Select Topic
      final resolvedState = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: selectedExam.id,
        subjectId: selectedSubject.id,
        topicId: 'emergency_provisions',
        asOfDate: baseDate,
      );
      expect(resolvedState.status, equals(ContentPathStatus.topicSelected));
      expect(resolvedState.selectedTopic!.name, equals('Emergency Provisions'));
      expect(resolvedState.selectedTopic!.questionCount, equals(1));
    });

    // -------------------------------------------------------------------------
    // 15. Completion returns learner to an appropriate next action
    // -------------------------------------------------------------------------
    test(
        '15. Completion returns learner to an appropriate next action: weak topic prompts remediation',
        () async {
      // Set up learner with weak spot on Article 21 (attemptCount: 4, correctCount: 1 -> 25% < 60%)
      final weakProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_article_21_foundations',
        status: LearnerObjectiveStatus.inProgress,
        attemptCount: 4,
        correctCount: 1,
        lastAttemptAt: baseDate.subtract(const Duration(hours: 1)),
      );

      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {'lo_article_21_foundations': weakProgress},
        lastUpdatedAt: baseDate,
      );

      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      final state = await service.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'fundamental_rights',
        asOfDate: baseDate,
      );

      expect(state.recommendedAction,
          equals(AdaptiveActionType.startRemedialLesson));
      expect(state.actionTitle, contains('Start Remedial Lesson'));
      expect(state.actionDescription,
          contains('Persistent conceptual errors detected'));
    });
  });
}
