/// P40 Adaptive Learning Session Resume Integration Test Suite (TITAN-KO-040.0 P40).
///
/// End-to-end integration tests verifying crash safety, attempt deduplication,
/// policy-driven checkpointing, strict revision reconciliation, and completion ordering
/// across application restarts.
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final baseTime = DateTime.utc(2026, 9, 6, 11, 0, 0);

  group('P40 Adaptive Session Resume Engine E2E Integration', () {
    late InMemorySessionCheckpointRepository checkpointRepo;
    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late AuthoritativeLearningStateRecoveryService authRecovery;
    late SessionCheckpointService checkpointService;
    late AdaptiveSessionResumeEngine engine;

    setUp(() {
      checkpointRepo = InMemorySessionCheckpointRepository();
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      authRecovery =
          AuthoritativeLearningStateRecoveryService(repository: authRepo);
      checkpointService = SessionCheckpointService(repository: checkpointRepo);

      engine = AdaptiveSessionResumeEngine(
        checkpointService: checkpointService,
        authoritativeRecoveryService: authRecovery,
        authoritativeRepository: authRepo,
      );
    });

    test(
        'executes complete 20-step adaptive lifecycle across simulated application crash',
        () async {
      const sessionId = 'session_e2e_20step';
      const learnerId = 'learner_e2e_01';
      const examId = 'upsc';
      const objectiveId = 'lo_polity_fundamental_rights';

      // -----------------------------------------------------------------------
      // Step 1: Session Start
      // -----------------------------------------------------------------------
      final startRes = await engine.startSession(
        sessionId: sessionId,
        learnerId: learnerId,
        examId: examId,
        firstObjectiveId: objectiveId,
        firstQuestionId: 'q_fr_01',
        startedAt: baseTime,
      );

      expect(startRes.checkpointRevision, 1);
      expect(startRes.authoritativeStateRevision, 1);
      expect(startRes.status, ResumableSessionStatus.active);

      // -----------------------------------------------------------------------
      // Step 2-7: Attempt 1 Submission, Deduplication, Reconcile, Checkpoint
      // -----------------------------------------------------------------------
      final attempt1 = AttemptIdentity(
        sessionId: sessionId,
        questionId: 'q_fr_01',
        attemptSequence: 1,
      );

      final attempt1Res = await engine.submitAttempt(
        attemptIdentity: attempt1,
        submittedAnswer: 'A',
        isCorrect: true,
        score: 1.0,
        objectiveId: objectiveId,
        nextQuestionId: 'q_fr_02',
        submittedAt: baseTime.add(const Duration(minutes: 1)),
      );

      expect(attempt1Res.checkpointRevision, 2);
      expect(attempt1Res.authoritativeStateRevision, 2);
      expect(attempt1Res.snapshot.currentQuestionIndex, 1);
      expect(attempt1Res.snapshot.completedQuestionIds, ['q_fr_01']);
      expect(attempt1Res.snapshot.accumulatedScore, 1.0);
      expect(attempt1Res.snapshot.correctCount, 1);

      // Deduplication guard for attempt 1
      expect(
        () => engine.submitAttempt(
          attemptIdentity: attempt1,
          submittedAnswer: 'A',
          isCorrect: true,
          score: 1.0,
          submittedAt: baseTime.add(const Duration(minutes: 1, seconds: 30)),
        ),
        throwsA(isA<DuplicateAttemptException>()),
      );

      // -----------------------------------------------------------------------
      // Step 8-13: Attempt 2 Submission, Deduplication, Reconcile, Checkpoint
      // -----------------------------------------------------------------------
      final attempt2 = AttemptIdentity(
        sessionId: sessionId,
        questionId: 'q_fr_02',
        attemptSequence: 2,
      );

      final attempt2Res = await engine.submitAttempt(
        attemptIdentity: attempt2,
        submittedAnswer: 'B',
        isCorrect: true,
        score: 1.0,
        objectiveId: objectiveId,
        nextQuestionId: 'q_fr_03',
        submittedAt: baseTime.add(const Duration(minutes: 3)),
      );

      expect(attempt2Res.checkpointRevision, 3);
      expect(attempt2Res.authoritativeStateRevision, 3);
      expect(attempt2Res.snapshot.currentQuestionIndex, 2);
      expect(attempt2Res.snapshot.completedQuestionIds, ['q_fr_01', 'q_fr_02']);
      expect(attempt2Res.snapshot.accumulatedScore, 2.0);
      expect(attempt2Res.snapshot.correctCount, 2);

      // -----------------------------------------------------------------------
      // Step 14: Simulate Sudden Crash / Hard Process Termination
      // -----------------------------------------------------------------------
      // Instantiate completely fresh engine and recovery service instances
      // sharing only durable repositories (simulating app relaunch)
      final restartedAuthRecovery =
          AuthoritativeLearningStateRecoveryService(repository: authRepo);
      final restartedCheckpointService =
          SessionCheckpointService(repository: checkpointRepo);
      final restartedEngine = AdaptiveSessionResumeEngine(
        checkpointService: restartedCheckpointService,
        authoritativeRecoveryService: restartedAuthRecovery,
        authoritativeRepository: authRepo,
      );

      // -----------------------------------------------------------------------
      // Step 15-16: Recovery & Strict Reconciliation Analysis
      // -----------------------------------------------------------------------
      final recovery = await restartedEngine.recoverSession(
        learnerId: learnerId,
        examId: examId,
        sessionId: sessionId,
        recoveredAt: baseTime.add(const Duration(minutes: 10)),
      );

      expect(recovery.isSuccess, isTrue);
      expect(recovery.snapshot.currentQuestionIndex, 2);
      expect(recovery.checkpointRevision, 3);
      expect(recovery.authoritativeStateRevision, 3);
      expect(recovery.alignment, CheckpointReconciliationAlignment.aligned);
      expect(recovery.snapshot.status, ResumableSessionStatus.recovered);

      // -----------------------------------------------------------------------
      // Step 17: Resumption at Exact Cursor
      // -----------------------------------------------------------------------
      final resumeRes = await restartedEngine.resumeSession(
        learnerId: learnerId,
        examId: examId,
        sessionId: sessionId,
        resumedAt: baseTime.add(const Duration(minutes: 11)),
      );

      expect(resumeRes.status, ResumableSessionStatus.resumed);
      expect(resumeRes.snapshot.currentQuestionIndex, 2);

      // Verify cross-crash attempt deduplication (attempt 1 and 2 still rejected)
      expect(
        () => restartedEngine.submitAttempt(
          attemptIdentity: attempt1,
          submittedAnswer: 'A',
          isCorrect: true,
          score: 1.0,
        ),
        throwsA(isA<DuplicateAttemptException>()),
      );
      expect(
        () => restartedEngine.submitAttempt(
          attemptIdentity: attempt2,
          submittedAnswer: 'B',
          isCorrect: true,
          score: 1.0,
        ),
        throwsA(isA<DuplicateAttemptException>()),
      );

      // -----------------------------------------------------------------------
      // Step 18: Final Question Attempt 3 Submission
      // -----------------------------------------------------------------------
      final attempt3 = AttemptIdentity(
        sessionId: sessionId,
        questionId: 'q_fr_03',
        attemptSequence: 3,
      );

      final attempt3Res = await restartedEngine.submitAttempt(
        attemptIdentity: attempt3,
        submittedAnswer: 'C',
        isCorrect: true,
        score: 1.0,
        objectiveId: objectiveId,
        submittedAt: baseTime.add(const Duration(minutes: 12)),
      );

      expect(attempt3Res.checkpointRevision, 5);
      expect(attempt3Res.authoritativeStateRevision, 4);
      expect(attempt3Res.snapshot.currentQuestionIndex, 3);
      expect(attempt3Res.snapshot.completedQuestionIds,
          ['q_fr_01', 'q_fr_02', 'q_fr_03']);
      expect(attempt3Res.snapshot.accumulatedScore, 3.0);
      expect(attempt3Res.snapshot.correctCount, 3);

      // -----------------------------------------------------------------------
      // Step 19-20: Final Completion Ordering Guarantee & Final Audit
      // -----------------------------------------------------------------------
      final completedRes = await restartedEngine.completeSession(
        sessionId: sessionId,
        completedAt: baseTime.add(const Duration(minutes: 15)),
      );

      expect(completedRes.status, ResumableSessionStatus.completed);
      expect(completedRes.snapshot.isCompleted, isTrue);
      expect(completedRes.authoritativeState.processedSessionIds,
          contains(sessionId));
      expect(completedRes.checkpointRevision, 6);
      expect(completedRes.authoritativeStateRevision, 5);

      // Verify objective achieved in authoritative state (3 correct answers)
      final progress = completedRes.authoritativeState.progressMap[objectiveId];
      expect(progress, isNotNull);
      expect(progress!.attemptCount, 3);
      expect(progress.correctCount, 3);
      expect(progress.isAchieved, isTrue);

      // Subsequent attempt on completed session is strictly forbidden
      final postAttempt = AttemptIdentity(
        sessionId: sessionId,
        questionId: 'q_fr_04',
        attemptSequence: 4,
      );

      expect(
        () => restartedEngine.submitAttempt(
          attemptIdentity: postAttempt,
          submittedAnswer: 'D',
          isCorrect: false,
          score: 0.0,
        ),
        throwsA(isA<SessionCompletionException>()),
      );
    });

    test('migrates legacy v0 checkpoint seamlessly during recovery', () async {
      const sessionId = 'legacy_migrated_sess';
      const learnerId = 'learner_migrated';
      const examId = 'upsc';

      final legacyPayload = {
        'schemaVersion': 0,
        'sessionId': sessionId,
        'learnerId': learnerId,
        'examId': examId,
        'questionIndex': 2,
        'completedQuestionIds': ['q_1', 'q_2'],
        'processedAttemptTokens': ['$sessionId:q_1:1', '$sessionId:q_2:1'],
        'accumulatedScore': 2.0,
        'correctCount': 2,
        'activeObjectiveId': 'lo_general',
        'checkpointRevision': 3,
        'authoritativeStateRevision': 2,
        'timestamp': baseTime.toIso8601String(),
        'isCompleted': false,
      };

      checkpointRepo.injectRawPayload(
        learnerId: learnerId,
        examId: examId,
        sessionId: sessionId,
        rawPayload: jsonEncode(legacyPayload),
      );

      // Parse and migrate legacy raw JSON map
      final migrated = checkpointService.parseRawSnapshot(legacyPayload);
      expect(migrated.schemaVersion, 1);
      expect(migrated.sessionId, sessionId);
      expect(migrated.currentQuestionIndex, 2);
      expect(migrated.verifyChecksum(), isTrue);

      // Save upgraded snapshot with advanced revision to persist cleanly
      final upgraded = migrated.copyWith(checkpointRevision: 4);
      await checkpointService.saveSnapshot(upgraded);

      // Recover via engine
      final recovery = await engine.recoverSession(
        learnerId: learnerId,
        examId: examId,
        sessionId: sessionId,
      );

      expect(recovery.isSuccess, isTrue);
      expect(recovery.snapshot.currentQuestionIndex, 2);
      expect(recovery.snapshot.completedQuestionIds, ['q_1', 'q_2']);
    });
  });
}
