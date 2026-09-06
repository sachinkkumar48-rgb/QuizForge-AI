/// P41 Learner Dashboard & Control Center Integration Tests (TITAN-KO-041.0 P41).
///
/// Exhaustively verifies the 15 core scenarios specified in P41 requirements:
/// 1. First-time learner dashboard
/// 2. Dashboard with active session
/// 3. Continue-learning action
/// 4. Dashboard reflects real learner state
/// 5. Dashboard after completed session
/// 6. Next learning action
/// 7. History display
/// 8. Recovered state appears after restart
/// 9. Continue after recovery
/// 10. No-content state
/// 11. Loading state
/// 12. Recovery failure
/// 13. Persistence failure
/// 14. Invalid state
/// 15. No recommendation available
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P41 Learner Dashboard & Control Center Integration Tests', () {
    const String testLearner = 'learner_p41_titan';
    const String testExam = 'upsc_prelims_gs1';
    final baseDate = DateTime.utc(2026, 9, 6, 12, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late AdaptiveLearningDecisionEngine decisionEngine;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryRemedialLessonRepository remedialRepo;
    late DeterministicRemedialLessonService remedialService;
    late LearnerDashboardController controller;

    NormalizedQuestion buildTestQuestion({
      required String id,
      String topic = 'Fundamental Rights',
      String objectiveId = 'lo_const_fr_01',
    }) {
      return NormalizedQuestion(
        id: id,
        examId: testExam,
        year: 2024,
        paper: 'GS1',
        subject: 'Polity',
        topic: topic,
        normalizedText: 'Question stem for $id',
        originalText: 'Original stem for $id',
        options: const [
          Option(key: 'A', text: 'Option A', isCorrect: true),
          Option(key: 'B', text: 'Option B', isCorrect: false),
          Option(key: 'C', text: 'Option C', isCorrect: false),
          Option(key: 'D', text: 'Option D', isCorrect: false),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['A'],
          officialAnswerSource: 'Official Key',
        ),
        explanation: 'Explanation for $id',
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
      sessionRecoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );
      decisionEngine = AdaptiveLearningDecisionEngine();
      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);

      remedialRepo = InMemoryRemedialLessonRepository();
      remedialRepo.saveLesson(RemedialLesson(
        lessonId: 'rem_fr_01',
        objectiveId: 'lo_const_fr_01',
        title: 'Fundamental Rights Micro-Review',
        summary: 'Targeted drill on Article 14 to Article 32.',
        learningPoints: const ['Article 14-18 Equality', 'Article 19-22 Freedom'],
        explanation: 'Detailed micro-lesson on fundamental rights jurisprudence.',
        estimatedMinutes: 10,
        authoredAt: baseDate,
      ));
      remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );

      controller = LearnerDashboardController(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        decisionEngine: decisionEngine,
        curriculumService: curriculumService,
        remedialService: remedialService,
      );
    });

    // -------------------------------------------------------------------------
    // Scenario 1: First-Time Learner Dashboard
    // -------------------------------------------------------------------------
    test('1. First-time learner dashboard: presents unassessed state without fabricated metrics', () async {
      await controller.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      final state = controller.state;
      expect(state.status, equals(LearnerDashboardStatus.empty));
      expect(state.continueLearning.hasRecoverableSession, isFalse);
      expect(state.continueLearning.canStartLearning, isTrue);
      expect(state.continueLearning.canContinue, isFalse);

      // No fake numbers
      expect(state.progressSummary.isAssessed, isFalse);
      expect(state.progressSummary.totalQuestionsAttempted, equals(0));
      expect(state.progressSummary.totalCorrectAnswers, equals(0));
      expect(state.progressSummary.totalIncorrectAnswers, equals(0));
      expect(state.progressSummary.averageAccuracy, isNull);
      expect(state.progressSummary.overallMasteryPercentage, isNull);
      expect(state.progressSummary.learningStatus, equals('New Aspirant'));

      // Recommended next action is diagnostic placement
      expect(state.nextAction.actionType, equals(AdaptiveActionType.takeDiagnostic));
      expect(state.nextAction.isAvailable, isTrue);
      expect(state.history, isEmpty);
    });

    // -------------------------------------------------------------------------
    // Scenario 2: Dashboard with Active Session
    // -------------------------------------------------------------------------
    test('2. Dashboard with active session: detects uncompleted session and shows continuation', () async {
      final checkpoint = SessionCheckpoint(
        checkpointRevision: 2,
        authoritativeStateRevision: 1,
        sessionId: 'session_active_01',
        learnerId: testLearner,
        examId: testExam,
        questionIndex: 2,
        completedQuestionIds: const ['q1', 'q2'],
        activeObjectiveId: 'lo_const_fr_01',
        timestamp: baseDate,
        isCompleted: false,
        metadata: {'totalQuestions': 5, 'topic': 'Fundamental Rights'},
      );
      await checkpointRepo.saveCheckpoint(checkpoint);

      await controller.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      final state = controller.state;
      expect(state.status, equals(LearnerDashboardStatus.ready));
      expect(state.continueLearning.hasRecoverableSession, isTrue);
      expect(state.continueLearning.sessionId, equals('session_active_01'));
      expect(state.continueLearning.questionIndex, equals(2));
      expect(state.continueLearning.totalQuestions, equals(5));
      expect(state.continueLearning.progressPercentage, equals(0.4));
      expect(state.continueLearning.canContinue, isTrue);
      expect(state.continueLearning.canStartLearning, isFalse);
      expect(state.continueLearning.topic, equals('Fundamental Rights'));

      // Next Best Action should point to resume
      expect(state.nextAction.actionType, equals(AdaptiveActionType.continueSession));
      expect(state.nextAction.targetId, equals('session_active_01'));
    });

    // -------------------------------------------------------------------------
    // Scenario 3: Continue-Learning Action
    // -------------------------------------------------------------------------
    test('3. Continue-learning action: exposes valid resumption parameters', () async {
      final checkpoint = SessionCheckpoint(
        checkpointRevision: 3,
        authoritativeStateRevision: 2,
        sessionId: 'session_continue_02',
        learnerId: testLearner,
        examId: testExam,
        questionIndex: 3,
        completedQuestionIds: const ['q1', 'q2', 'q3'],
        activeObjectiveId: 'lo_const_fr_01',
        timestamp: baseDate,
        isCompleted: false,
      );
      await checkpointRepo.saveCheckpoint(checkpoint);

      await controller.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      final continueCard = controller.state.continueLearning;
      expect(continueCard.canContinue, isTrue);
      expect(continueCard.sessionId, equals('session_continue_02'));
      expect(continueCard.examId, equals(testExam));
      expect(continueCard.questionIndex, equals(3));
    });

    // -------------------------------------------------------------------------
    // Scenario 4: Dashboard Reflects Real Learner State
    // -------------------------------------------------------------------------
    test('4. Dashboard reflects real learner state: aggregates attempts, correct count, and accuracy', () async {
      final progress1 = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_const_fr_01',
        attemptCount: 5,
        correctCount: 4,
        status: LearnerObjectiveStatus.achieved,
        lastAttemptAt: baseDate.subtract(const Duration(hours: 2)),
      );
      final progress2 = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_const_dpsp_01',
        attemptCount: 5,
        correctCount: 3,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate.subtract(const Duration(hours: 1)),
      );

      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {
          'lo_const_fr_01': progress1,
          'lo_const_dpsp_01': progress2,
        },
        lastUpdatedAt: baseDate,
        revision: 2,
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      await controller.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      final summary = controller.state.progressSummary;
      expect(summary.isAssessed, isTrue);
      expect(summary.totalQuestionsAttempted, equals(10));
      expect(summary.totalCorrectAnswers, equals(7));
      expect(summary.totalIncorrectAnswers, equals(3));
      expect(summary.averageAccuracy, equals(70.0));
      expect(summary.learningStatus, equals('Active Practice'));
    });

    // -------------------------------------------------------------------------
    // Scenario 5: Dashboard After Completed Session
    // -------------------------------------------------------------------------
    test('5. Dashboard after completed session: transitions active session to completed history', () async {
      final completedCheckpoint = SessionCheckpoint(
        checkpointRevision: 6,
        authoritativeStateRevision: 3,
        sessionId: 'session_done_01',
        learnerId: testLearner,
        examId: testExam,
        questionIndex: 5,
        completedQuestionIds: const ['q1', 'q2', 'q3', 'q4', 'q5'],
        activeObjectiveId: 'lo_const_fr_01',
        timestamp: baseDate,
        isCompleted: true,
      );
      await checkpointRepo.saveCheckpoint(completedCheckpoint);

      await controller.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      final state = controller.state;
      expect(state.continueLearning.hasRecoverableSession, isFalse);
      expect(state.continueLearning.canStartLearning, isTrue);
      expect(state.history, hasLength(1));
      expect(state.history.first.sessionId, equals('session_done_01'));
      expect(state.history.first.isCompleted, isTrue);
      expect(state.history.first.canResume, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 6: Next Learning Action Formulation
    // -------------------------------------------------------------------------
    test('6. Next learning action: recommends remedial lesson when weak spot is detected', () async {
      // 4 attempts, only 1 correct -> weak spot trigger
      final weakProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_const_fr_01',
        attemptCount: 4,
        correctCount: 1,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate,
      );

      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {'lo_const_fr_01': weakProgress},
        lastUpdatedAt: baseDate,
        revision: 2,
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));

      await controller.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      final next = controller.state.nextAction;
      expect(next.actionType, equals(AdaptiveActionType.startRemedialLesson));
      expect(next.targetObjectiveId, equals('lo_const_fr_01'));
      expect(next.title, contains('Remedial Lesson'));
    });

    // -------------------------------------------------------------------------
    // Scenario 7: History Display
    // -------------------------------------------------------------------------
    test('7. History display: lists historical sessions in reverse chronological order', () async {
      final cp1 = SessionCheckpoint(
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        sessionId: 'sess_1',
        learnerId: testLearner,
        examId: testExam,
        questionIndex: 5,
        completedQuestionIds: const ['q1'],
        activeObjectiveId: 'lo_const_fr_01',
        timestamp: baseDate.subtract(const Duration(days: 2)),
        isCompleted: true,
      );
      final cp2 = SessionCheckpoint(
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        sessionId: 'sess_2',
        learnerId: testLearner,
        examId: testExam,
        questionIndex: 5,
        completedQuestionIds: const ['q2'],
        activeObjectiveId: 'lo_const_dpsp_01',
        timestamp: baseDate.subtract(const Duration(days: 1)),
        isCompleted: true,
      );
      await checkpointRepo.saveCheckpoint(cp1);
      await checkpointRepo.saveCheckpoint(cp2);

      await controller.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      final history = controller.state.history;
      expect(history, hasLength(2));
      expect(history.first.sessionId, equals('sess_2'));
      expect(history.last.sessionId, equals('sess_1'));
    });

    // -------------------------------------------------------------------------
    // Scenario 8: Recovered State Appears After Restart
    // -------------------------------------------------------------------------
    test('8. Recovered state appears after restart: restores persisted checkpoint into brand new controller', () async {
      final cp = SessionCheckpoint(
        checkpointRevision: 4,
        authoritativeStateRevision: 2,
        sessionId: 'sess_restart_test',
        learnerId: testLearner,
        examId: testExam,
        questionIndex: 3,
        completedQuestionIds: const ['q1', 'q2', 'q3'],
        activeObjectiveId: 'lo_const_fr_01',
        timestamp: baseDate,
        isCompleted: false,
      );
      await checkpointRepo.saveCheckpoint(cp);

      // Recreate completely new controller instance
      final freshController = LearnerDashboardController(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        curriculumService: curriculumService,
      );

      await freshController.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(freshController.state.continueLearning.hasRecoverableSession, isTrue);
      expect(freshController.state.continueLearning.sessionId, equals('sess_restart_test'));
      expect(freshController.state.continueLearning.questionIndex, equals(3));
    });

    // -------------------------------------------------------------------------
    // Scenario 9: Continue After Recovery
    // -------------------------------------------------------------------------
    test('9. Continue after recovery: journey orchestrator resumes from recovered cursor', () async {
      final q1 = buildTestQuestion(id: 'q1');
      final q2 = buildTestQuestion(id: 'q2');
      final q3 = buildTestQuestion(id: 'q3');
      final corpus = [q1, q2, q3];

      final orchestrator = AdaptiveLearningJourneyOrchestrator(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
      );

      // Start initial journey and answer first question
      final startRes = await orchestrator.startJourney(
        learnerId: testLearner,
        examId: testExam,
        corpus: corpus,
        questionCount: 3,
        startedAt: baseDate,
      );
      expect(startRes.isSuccess, isTrue);

      final ansRes = await orchestrator.submitAnswer(
        session: startRes.session!,
        questionId: 'q1',
        answer: 'A',
        submittedAt: baseDate.add(const Duration(seconds: 10)),
      );
      expect(ansRes.isSuccess, isTrue);
      final sessionId = ansRes.session!.sessionId;

      // Dashboard detects recovered session
      await controller.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );
      expect(controller.state.continueLearning.hasRecoverableSession, isTrue);
      expect(controller.state.continueLearning.sessionId, equals(sessionId));
      expect(controller.state.continueLearning.questionIndex, equals(1));

      // Resume journey from orchestrator
      final resumeRes = await orchestrator.recoverAndResumeJourney(
        learnerId: testLearner,
        examId: testExam,
        sessionId: sessionId,
        corpus: corpus,
        resumedAt: baseDate.add(const Duration(minutes: 5)),
      );
      expect(resumeRes.isSuccess, isTrue);
      expect(resumeRes.session!.currentQuestionIndex, equals(1));
      expect(resumeRes.session!.completedQuestionIds, equals(['q1']));
    });

    // -------------------------------------------------------------------------
    // Scenario 10: No-Content State
    // -------------------------------------------------------------------------
    test('10. No-content state: empty curriculum handles gracefully without crashes', () async {
      final emptyFramework = CurriculumFramework(
        id: 'empty_fw',
        title: 'Empty Framework',
        description: 'No domains or objectives',
        version: CurriculumVersion(
          version: '1.0.0',
          effectiveDate: '2026-09-01',
          provenance: 'TITAN P41 Test',
        ),
        domains: const [],
        provenance: 'TITAN P41 Test',
      );
      final emptyCurriculumService = CurriculumService(framework: emptyFramework);

      final emptyController = LearnerDashboardController(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        curriculumService: emptyCurriculumService,
      );

      await emptyController.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(emptyController.state.status, equals(LearnerDashboardStatus.empty));
      expect(emptyController.state.progressSummary.isAssessed, isFalse);
    });

    // -------------------------------------------------------------------------
    // Scenario 11: Loading State
    // -------------------------------------------------------------------------
    test('11. Loading state: sets status to loading and notifies listeners', () async {
      bool sawLoading = false;
      controller.addListener(() {
        if (controller.state.status == LearnerDashboardStatus.loading) {
          sawLoading = true;
        }
      });

      await controller.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(sawLoading, isTrue);
    });

    // -------------------------------------------------------------------------
    // Scenario 12: Recovery Failure
    // -------------------------------------------------------------------------
    test('12. Recovery failure: surfaces error status when corrupted payload is detected', () async {
      // Intentionally insert a tampered persisted state with invalid checksum
      final validState = AuthoritativeLearnerState.empty(
        learnerId: testLearner,
        examId: testExam,
        createdAt: baseDate,
      );
      final validPersisted = PersistedAuthoritativeLearnerState.fromAuthoritativeState(validState);

      final corruptPersisted = PersistedAuthoritativeLearnerState(
        schemaVersion: validPersisted.schemaVersion,
        learnerId: validPersisted.learnerId,
        examId: validPersisted.examId,
        revision: validPersisted.revision,
        stateFingerprint: validPersisted.stateFingerprint,
        progressMap: validPersisted.progressMap,
        processedSessionIds: validPersisted.processedSessionIds,
        lastUpdatedAt: validPersisted.lastUpdatedAt,
        checksum: 'tampered_bad_checksum',
      );
      await authRepo.save(corruptPersisted);

      await controller.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(controller.state.status, equals(LearnerDashboardStatus.error));
      expect(controller.state.errorMessage, contains('integrity check failed'));
    });

    // -------------------------------------------------------------------------
    // Scenario 13: Persistence Failure
    // -------------------------------------------------------------------------
    test('13. Persistence failure: handles underlying repository failure without unhandled throw', () async {
      // Use faulty repository that throws on load
      final faultyRepo = _FaultyCheckpointRepository();
      final faultyController = LearnerDashboardController(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: faultyRepo,
        sessionRecoveryService: sessionRecoveryService,
      );

      await faultyController.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      expect(faultyController.state.status, equals(LearnerDashboardStatus.error));
      expect(faultyController.state.errorMessage, contains('Simulated storage IO error'));
    });

    // -------------------------------------------------------------------------
    // Scenario 14: Invalid State
    // -------------------------------------------------------------------------
    test('14. Invalid state: rejects blank learner ID and blank exam ID with error', () async {
      await controller.loadDashboard(
        learnerId: '   ',
        examId: '',
      );

      expect(controller.state.status, equals(LearnerDashboardStatus.error));
      expect(controller.state.errorMessage, equals('learnerId and examId cannot be empty'));
    });

    // -------------------------------------------------------------------------
    // Scenario 15: No Recommendation Available
    // -------------------------------------------------------------------------
    test('15. No recommendation available: curriculum fully mastered produces completion action', () async {
      final allObjectives = framework.allObjectives;
      final completedMap = <String, LearnerProgress>{};

      for (final obj in allObjectives) {
        completedMap[obj.id] = LearnerProgress(
          learnerId: testLearner,
          objectiveId: obj.id,
          attemptCount: 10,
          correctCount: 9,
          status: LearnerObjectiveStatus.achieved,
          achievedAt: baseDate,
          lastAttemptAt: baseDate,
        );
      }

      final masteredState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: completedMap,
        lastUpdatedAt: baseDate,
        revision: 5,
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(masteredState));

      await controller.loadDashboard(
        learnerId: testLearner,
        examId: testExam,
        asOfDate: baseDate,
      );

      final next = controller.state.nextAction;
      expect(next.actionType, equals(AdaptiveActionType.none));
      expect(next.isAvailable, isFalse);
      expect(next.title, equals('All Caught Up'));
      expect(controller.state.progressSummary.overallMasteryPercentage, equals(100.0));
      expect(controller.state.progressSummary.learningStatus, equals('Proficient'));
    });
  });
}

class _FaultyCheckpointRepository implements SessionCheckpointRepository {
  @override
  Future<List<SessionCheckpoint>> listCheckpoints({
    required String learnerId,
    required String examId,
  }) async {
    throw Exception('Simulated storage IO error in checkpoint repository');
  }

  @override
  Future<void> clear() async {}

  @override
  Future<void> deleteCheckpoint({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {}

  @override
  Future<bool> exists({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async => false;

  @override
  Future<SessionCheckpoint?> loadCheckpoint({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async => null;

  @override
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async {}
}
