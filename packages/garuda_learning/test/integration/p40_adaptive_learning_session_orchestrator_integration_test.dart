/// P40 Adaptive Learning Session Orchestrator Integration Test Suite (TITAN-KO-040.0 P40).
///
/// Exercises the complete production session lifecycle through [AdaptiveLearningSessionOrchestrator]:
/// Session Start -> Question Delivery -> Attempt Recording -> Deduplication Guard
/// -> Pause / Crash Simulation -> Recovery -> Resumption -> Completion Ordering
/// -> Multi-Tenant Isolation -> Monotonic Revisions.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P40 AdaptiveLearningSessionOrchestrator Integration Test', () {
    final baseTime = DateTime.utc(2026, 9, 16, 12, 0, 0);

    late InMemoryAdaptiveLearningSessionRepository sessionRepo;
    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late AdaptiveLearningSessionOrchestrator orchestrator;

    late List<NormalizedQuestion> testCorpus;
    late AdaptivePracticeSessionConfig sessionConfig;

    NormalizedQuestion makeQuestion({
      required String id,
      required String correctOption,
      String examId = 'upsc',
      String objectiveId = 'lo_polity_preamble',
    }) {
      return NormalizedQuestion(
        id: id,
        examId: examId,
        year: 2024,
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Fundamental Rights',
        normalizedText: 'Question text for $id',
        originalText: 'Question text for $id',
        options: [
          Option(key: 'A', text: 'Option A', isCorrect: correctOption == 'A'),
          Option(key: 'B', text: 'Option B', isCorrect: correctOption == 'B'),
          Option(key: 'C', text: 'Option C', isCorrect: correctOption == 'C'),
          Option(key: 'D', text: 'Option D', isCorrect: correctOption == 'D'),
        ],
        officialAnswer: Answer(
          correctOptionKeys: [correctOption],
          officialAnswerSource: 'Official Key',
        ),
        explanation: 'Explanation for $id',
        difficulty: 'Medium',
        source: PyqSourceReference.official(
          examId: examId,
          year: 2024,
          paper: 'GS1',
        ),
        objectiveIds: [objectiveId],
      );
    }

    setUp(() {
      sessionRepo = InMemoryAdaptiveLearningSessionRepository();
      authRepo = InMemoryAuthoritativeLearningStateRepository();

      authRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );

      orchestrator = AdaptiveLearningSessionOrchestrator(
        sessionRepository: sessionRepo,
        authoritativeRecoveryService: authRecoveryService,
        authoritativeRepository: authRepo,
      );

      sessionConfig = AdaptivePracticeSessionConfig(
        examId: 'upsc',
        learnerId: 'learner_p40_01',
        maxQuestions: 2,
      );

      testCorpus = [
        makeQuestion(
          id: 'q_polity_01',
          correctOption: 'A',
          objectiveId: 'lo_polity_preamble',
        ),
        makeQuestion(
          id: 'q_polity_02',
          correctOption: 'C',
          objectiveId: 'lo_polity_fr',
        ),
      ];
    });

    test(
        'executes complete crash-safe lifecycle: start -> answer -> pause -> crash -> recover -> resume -> complete',
        () async {
      // 1. Start Session
      final session = await orchestrator.startSession(
        sessionId: 'sess_live_40',
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        configuration: sessionConfig,
        corpus: testCorpus,
        startedAt: baseTime,
      );

      expect(session.sessionId, 'sess_live_40');
      expect(session.status, SessionStatus.active);
      expect(session.currentQuestionPosition, 0);
      expect(session.completedQuestions, isEmpty);
      expect(session.checkpointRevision, 1);

      // Check initial checkpoint was created
      final initialCp = await sessionRepo.getLatestCheckpoint(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_live_40',
      );
      expect(initialCp, isNotNull);
      expect(initialCp!.checkpointRevision, 1);
      expect(initialCp.isCompleted, isFalse);

      // 2. Fetch Question 0
      final delivery1 = await orchestrator.getNextQuestion(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_live_40',
        corpus: testCorpus,
      );
      expect(delivery1, isNotNull);
      expect(delivery1!.question.id, 'q_polity_01');
      expect(delivery1.questionIndex, 0);
      expect(delivery1.totalQuestions, 2);
      expect(delivery1.isLastQuestion, isFalse);

      // 3. Record First Attempt (Correct)
      final attempt1Time = baseTime.add(const Duration(seconds: 45));
      final attempt1Result = await orchestrator.recordAttempt(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_live_40',
        questionId: 'q_polity_01',
        submittedAnswer: 'A',
        question: delivery1.question,
        submittedAt: attempt1Time,
      );

      expect(attempt1Result.isCorrect, isTrue);
      expect(attempt1Result.isSessionCompleted, isFalse);
      expect(attempt1Result.session.currentQuestionPosition, 1);
      expect(attempt1Result.session.completedQuestions, ['q_polity_01']);
      expect(attempt1Result.session.checkpointRevision, 2);
      expect(attempt1Result.checkpoint.checkpointRevision, 2);
      expect(attempt1Result.checkpoint.completedQuestionIds, ['q_polity_01']);

      // Authoritative State updated
      final authAfterAttempt1 = await authRepo.load(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
      );
      expect(authAfterAttempt1, isNotNull);
      expect(authAfterAttempt1!.progressMap['lo_polity_preamble']?.attemptCount,
          1);
      expect(
          authAfterAttempt1.progressMap['lo_polity_preamble']?.correctCount, 1);

      // 4. Verify Duplicate Attempt Rejection Guard
      expect(
        () => orchestrator.recordAttempt(
          learnerId: 'learner_p40_01',
          examId: 'upsc',
          sessionId: 'sess_live_40',
          questionId: 'q_polity_01',
          submittedAnswer: 'A',
          question: delivery1.question,
          submittedAt: attempt1Time.add(const Duration(seconds: 5)),
        ),
        throwsA(isA<DuplicateAttemptException>()),
      );

      // 5. Pause Session
      final pauseTime = attempt1Time.add(const Duration(minutes: 1));
      final pausedSession = await orchestrator.pauseSession(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_live_40',
        pausedAt: pauseTime,
      );

      expect(pausedSession.status, SessionStatus.paused);
      expect(pausedSession.checkpointRevision, 3);

      final pausedCp = await sessionRepo.getLatestCheckpoint(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_live_40',
      );
      expect(pausedCp!.checkpointRevision, 3);

      // 6. Simulate Process Crash & Restart with new Orchestrator instance
      final restartTime = pauseTime.add(const Duration(hours: 2));
      final restartedOrchestrator = AdaptiveLearningSessionOrchestrator(
        sessionRepository: sessionRepo,
        authoritativeRecoveryService: authRecoveryService,
        authoritativeRepository: authRepo,
      );

      // 7. Recover Session
      final recovery = await restartedOrchestrator.recoverSession(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_live_40',
        requestedAt: restartTime,
      );

      expect(recovery.isSuccess, isTrue);
      expect(recovery.session, isNotNull);
      expect(recovery.session!.currentQuestionIndex, 1);
      expect(recovery.session!.completedQuestionIds, ['q_polity_01']);
      expect(recovery.checkpoint!.checkpointRevision, 3);

      // 8. Resume Session
      final resumedSession = await restartedOrchestrator.resumeSession(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_live_40',
        resumedAt: restartTime.add(const Duration(seconds: 10)),
      );

      expect(resumedSession.status, SessionStatus.active);
      expect(resumedSession.currentQuestionPosition, 1);
      expect(resumedSession.checkpointRevision, 4);

      // 9. Deliver Question 1 (second question, index 1)
      final delivery2 = await restartedOrchestrator.getNextQuestion(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_live_40',
        corpus: testCorpus,
      );

      expect(delivery2, isNotNull);
      expect(delivery2!.question.id, 'q_polity_02');
      expect(delivery2.questionIndex, 1);
      expect(delivery2.isLastQuestion, isTrue);

      // 10. Record Final Attempt (Incorrect) -> Triggers automatic session completion
      final attempt2Time = restartTime.add(const Duration(minutes: 1));
      final attempt2Result = await restartedOrchestrator.recordAttempt(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_live_40',
        questionId: 'q_polity_02',
        submittedAnswer: 'B', // Official is 'C'
        question: delivery2.question,
        submittedAt: attempt2Time,
      );

      expect(attempt2Result.isCorrect, isFalse);
      expect(attempt2Result.isSessionCompleted, isTrue);
      expect(attempt2Result.session.status, SessionStatus.completed);
      expect(attempt2Result.session.completedQuestions,
          ['q_polity_01', 'q_polity_02']);
      expect(attempt2Result.checkpoint.isCompleted, isTrue);

      // 11. Verify Post-Completion Invariants
      // Requesting getNextQuestion on completed session throws CompletedSessionMutationException
      expect(
        () => restartedOrchestrator.getNextQuestion(
          learnerId: 'learner_p40_01',
          examId: 'upsc',
          sessionId: 'sess_live_40',
          corpus: testCorpus,
        ),
        throwsA(isA<CompletedSessionMutationException>()),
      );

      // Attempting further mutation throws CompletedSessionMutationException
      expect(
        () => restartedOrchestrator.recordAttempt(
          learnerId: 'learner_p40_01',
          examId: 'upsc',
          sessionId: 'sess_live_40',
          questionId: 'q_polity_03',
          submittedAnswer: 'A',
          question: makeQuestion(id: 'q_polity_03', correctOption: 'A'),
          submittedAt: attempt2Time.add(const Duration(seconds: 10)),
        ),
        throwsA(isA<CompletedSessionMutationException>()),
      );

      // Subsequent completeSession call is an idempotent no-op
      final reCompleted = await restartedOrchestrator.completeSession(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_live_40',
      );
      expect(reCompleted.isCompleted, isTrue);

      // Recovery on completed session returns alreadyCompleted
      final recoveryOnCompleted = await restartedOrchestrator.recoverSession(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_live_40',
      );
      expect(recoveryOnCompleted.isSuccess, isFalse);
      expect(recoveryOnCompleted.error?.code,
          SessionRecoveryErrorCode.alreadyCompleted);
    });

    test('enforces strict multi-tenant boundary and ownership validation',
        () async {
      await orchestrator.startSession(
        sessionId: 'sess_tenant_test',
        learnerId: 'tenant_alpha',
        examId: 'upsc',
        configuration: sessionConfig,
        corpus: testCorpus,
        startedAt: baseTime,
      );

      // Wrong learner access to getNextQuestion cannot find session under tenant partition
      expect(
        () => orchestrator.getNextQuestion(
          learnerId: 'tenant_beta',
          examId: 'upsc',
          sessionId: 'sess_tenant_test',
          corpus: testCorpus,
        ),
        throwsA(isA<SessionNotFoundException>()),
      );

      // Wrong exam access to getNextQuestion cannot find session under exam partition
      expect(
        () => orchestrator.getNextQuestion(
          learnerId: 'tenant_alpha',
          examId: 'bpsc',
          sessionId: 'sess_tenant_test',
          corpus: testCorpus,
        ),
        throwsA(isA<SessionNotFoundException>()),
      );

      // Wrong learner access to recordAttempt cannot mutate session under another partition
      expect(
        () => orchestrator.recordAttempt(
          learnerId: 'tenant_beta',
          examId: 'upsc',
          sessionId: 'sess_tenant_test',
          questionId: 'q_polity_01',
          submittedAnswer: 'A',
          question: testCorpus.first,
        ),
        throwsA(isA<SessionNotFoundException>()),
      );

      // RecoverSession for non-existent session returns coldStart
      final coldRecovery = await orchestrator.recoverSession(
        learnerId: 'tenant_alpha',
        examId: 'upsc',
        sessionId: 'sess_nonexistent',
      );
      expect(coldRecovery.isSuccess, isFalse);
      expect(coldRecovery.error?.code, SessionRecoveryErrorCode.coldStart);
    });

    test('abandonSession transitions status and prevents further operations',
        () async {
      await orchestrator.startSession(
        sessionId: 'sess_abandon_test',
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        configuration: sessionConfig,
        corpus: testCorpus,
        startedAt: baseTime,
      );

      final abandoned = await orchestrator.abandonSession(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_abandon_test',
        reason: 'Learner manually quit session',
      );

      expect(abandoned.status, SessionStatus.abandoned);
      expect(abandoned.isTerminal, isTrue);

      // Recovery returns notRecoverable
      final recovery = await orchestrator.recoverSession(
        learnerId: 'learner_p40_01',
        examId: 'upsc',
        sessionId: 'sess_abandon_test',
      );
      expect(recovery.isSuccess, isFalse);
      expect(recovery.error?.code, SessionRecoveryErrorCode.notRecoverable);
    });
  });
}
