/// P40 Learning Session Recovery Test Suite (TITAN-KO-040.0 P40).
///
/// Comprehensive unit tests covering session lifecycle state transitions,
/// session checkpoint domain validation, deterministic serialization with SHA-256
/// checksums, in-memory repository monotonicity, recovery service orchestration,
/// cold starts, and failure safety.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 10, 12, 0, 0);

  AuthoritativeLearnerState buildSampleState({
    String learnerId = 'learner_p40',
    String examId = 'upsc',
    int revision = 1,
    Map<String, LearnerProgress>? progressMap,
    Set<String>? sessions,
  }) {
    return AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      revision: revision,
      progressMap: progressMap ??
          {
            'obj_polity_01': LearnerProgress(
              learnerId: learnerId,
              objectiveId: 'obj_polity_01',
              attemptCount: 10,
              correctCount: 8,
              status: LearnerObjectiveStatus.inProgress,
              lastAttemptAt: fixedDate,
            ),
          },
      processedSessionIds: sessions ?? {'session_prev_01'},
      lastUpdatedAt: fixedDate,
    );
  }

  SessionCheckpoint buildSampleCheckpoint({
    String sessionId = 'session_p40_001',
    String learnerId = 'learner_p40',
    String examId = 'upsc',
    int questionIndex = 2,
    List<String>? completedQuestionIds,
    String activeObjectiveId = 'obj_polity_01',
    int checkpointRevision = 2,
    int authoritativeStateRevision = 1,
    bool isCompleted = false,
    DateTime? timestamp,
  }) {
    return SessionCheckpoint(
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      questionIndex: questionIndex,
      completedQuestionIds: completedQuestionIds ?? const ['q_0', 'q_1'],
      activeObjectiveId: activeObjectiveId,
      checkpointRevision: checkpointRevision,
      authoritativeStateRevision: authoritativeStateRevision,
      isCompleted: isCompleted,
      timestamp: timestamp ?? fixedDate,
    );
  }

  // ===========================================================================
  // GROUP 1: ResumableSessionStatus Lifecycle Transitions
  // ===========================================================================
  group('P40.1 ResumableSessionStatus Lifecycle Transitions', () {
    test('1. Valid transition matrix from created state', () {
      expect(
          ResumableSessionStatus.created
              .canTransitionTo(ResumableSessionStatus.active),
          isTrue);
      expect(
          ResumableSessionStatus.created
              .canTransitionTo(ResumableSessionStatus.abandoned),
          isTrue);
      expect(
          ResumableSessionStatus.created
              .canTransitionTo(ResumableSessionStatus.failed),
          isTrue);
      expect(
          ResumableSessionStatus.created
              .canTransitionTo(ResumableSessionStatus.completed),
          isFalse);
      expect(
          ResumableSessionStatus.created
              .canTransitionTo(ResumableSessionStatus.paused),
          isFalse);
    });

    test('2. Valid transition matrix from active state', () {
      expect(
          ResumableSessionStatus.active
              .canTransitionTo(ResumableSessionStatus.paused),
          isTrue);
      expect(
          ResumableSessionStatus.active
              .canTransitionTo(ResumableSessionStatus.interrupted),
          isTrue);
      expect(
          ResumableSessionStatus.active
              .canTransitionTo(ResumableSessionStatus.completed),
          isTrue);
      expect(
          ResumableSessionStatus.active
              .canTransitionTo(ResumableSessionStatus.abandoned),
          isTrue);
      expect(
          ResumableSessionStatus.active
              .canTransitionTo(ResumableSessionStatus.failed),
          isTrue);
      expect(
          ResumableSessionStatus.active
              .canTransitionTo(ResumableSessionStatus.created),
          isFalse);
    });

    test('3. Valid transition matrix from interrupted and recoverable states',
        () {
      expect(
          ResumableSessionStatus.interrupted
              .canTransitionTo(ResumableSessionStatus.recoverable),
          isTrue);
      expect(
          ResumableSessionStatus.interrupted
              .canTransitionTo(ResumableSessionStatus.resumed),
          isTrue);
      expect(
          ResumableSessionStatus.recoverable
              .canTransitionTo(ResumableSessionStatus.resumed),
          isTrue);
      expect(
          ResumableSessionStatus.recoverable
              .canTransitionTo(ResumableSessionStatus.active),
          isFalse);
    });

    test('4. Terminal states forbid any further transitions', () {
      for (final terminal in [
        ResumableSessionStatus.completed,
        ResumableSessionStatus.abandoned,
        ResumableSessionStatus.failed,
      ]) {
        expect(terminal.isTerminal, isTrue);
        for (final target in ResumableSessionStatus.values) {
          expect(terminal.canTransitionTo(target), isFalse);
        }
      }
    });
  });

  // ===========================================================================
  // GROUP 2: SessionCheckpoint Domain & Deterministic Serialization
  // ===========================================================================
  group('P40.2 SessionCheckpoint Domain & Serialization', () {
    test('5. Valid construction with cryptographic checksum', () {
      final checkpoint = buildSampleCheckpoint();
      expect(checkpoint.sessionId, equals('session_p40_001'));
      expect(checkpoint.learnerId, equals('learner_p40'));
      expect(checkpoint.examId, equals('upsc'));
      expect(checkpoint.checkpointRevision, equals(2));
      expect(checkpoint.authoritativeStateRevision, equals(1));
      expect(checkpoint.questionIndex, equals(2));
      expect(checkpoint.completedCount, equals(2));
      expect(checkpoint.checksum, isNotEmpty);
    });

    test('6. Invariant validation rejects blank or invalid fields', () {
      expect(
        () => SessionCheckpoint(
          sessionId: '',
          learnerId: 'learner_1',
          examId: 'upsc',
          questionIndex: 0,
          completedQuestionIds: const [],
          activeObjectiveId: 'obj_1',
          checkpointRevision: 1,
          authoritativeStateRevision: 1,
          timestamp: fixedDate,
        ),
        throwsA(isA<SessionRecoveryException>()),
      );

      expect(
        () => SessionCheckpoint(
          sessionId: 'sess_1',
          learnerId: '',
          examId: 'upsc',
          questionIndex: 0,
          completedQuestionIds: const [],
          activeObjectiveId: 'obj_1',
          checkpointRevision: 1,
          authoritativeStateRevision: 1,
          timestamp: fixedDate,
        ),
        throwsA(isA<SessionRecoveryException>()),
      );

      expect(
        () => SessionCheckpoint(
          sessionId: 'sess_1',
          learnerId: 'learner_1',
          examId: 'upsc',
          questionIndex: -1,
          completedQuestionIds: const [],
          activeObjectiveId: 'obj_1',
          checkpointRevision: 1,
          authoritativeStateRevision: 1,
          timestamp: fixedDate,
        ),
        throwsA(isA<SessionRecoveryException>()),
      );

      expect(
        () => SessionCheckpoint(
          sessionId: 'sess_1',
          learnerId: 'learner_1',
          examId: 'upsc',
          questionIndex: 0,
          completedQuestionIds: const [],
          activeObjectiveId: 'obj_1',
          checkpointRevision: 0,
          authoritativeStateRevision: 1,
          timestamp: fixedDate,
        ),
        throwsA(isA<SessionRecoveryException>()),
      );
    });

    test('7. Deterministic canonical JSON and SHA-256 round-trip', () {
      final chk1 = buildSampleCheckpoint();
      final jsonString = chk1.toCanonicalJson();
      final chk2 = SessionCheckpoint.fromRawJson(jsonString);

      expect(chk2.sessionId, equals(chk1.sessionId));
      expect(chk2.checkpointRevision, equals(chk1.checkpointRevision));
      expect(chk2.authoritativeStateRevision,
          equals(chk1.authoritativeStateRevision));
      expect(chk2.questionIndex, equals(chk1.questionIndex));
      expect(chk2.completedQuestionIds, equals(chk1.completedQuestionIds));
      expect(chk2.checksum, equals(chk1.checksum));
      expect(chk2.toCanonicalJson(), equals(jsonString));
    });

    test('8. Rejects corrupted checksum (bitrot / payload tampering)', () {
      final chk = buildSampleCheckpoint();
      final map = chk.toJson();
      // Inject tampering in payload without updating checksum
      map['questionIndex'] = 99;

      expect(
        () => SessionCheckpoint.fromJson(map),
        throwsA(
          isA<SessionRecoveryException>().having(
            (e) => e.code,
            'code',
            equals(SessionRecoveryErrorCode.corruptedCheckpoint),
          ),
        ),
      );
    });

    test('9. Rejects unsupported future schema version', () {
      final chk = buildSampleCheckpoint();
      final map = chk.toJson();
      map['schemaVersion'] = 999;

      expect(
        () => SessionCheckpoint.fromJson(map),
        throwsA(
          isA<SessionRecoveryException>().having(
            (e) => e.code,
            'code',
            equals(SessionRecoveryErrorCode.incompatibleVersion),
          ),
        ),
      );
    });
  });

  // ===========================================================================
  // GROUP 3: ResumableLearningSession Domain Validation & Checkpointing
  // ===========================================================================
  group('P40.3 ResumableLearningSession Domain Validation', () {
    test('10. Instantiates valid resumable session', () {
      final session = ResumableLearningSession(
        sessionId: 'sess_101',
        learnerId: 'learner_p40',
        examId: 'upsc',
        currentObjectiveId: 'obj_polity_01',
        currentQuestionIndex: 0,
        createdAt: fixedDate,
        lastActivityTimestamp: fixedDate,
      );

      expect(session.status, equals(ResumableSessionStatus.created));
      expect(session.currentQuestionIndex, equals(0));
      expect(session.completedQuestionCount, equals(0));
      expect(session.isCompleted, isFalse);
    });

    test('11. TransitionTo enforces legal state transitions', () {
      final session = ResumableLearningSession(
        sessionId: 'sess_101',
        learnerId: 'learner_p40',
        examId: 'upsc',
        currentObjectiveId: 'obj_polity_01',
        createdAt: fixedDate,
        lastActivityTimestamp: fixedDate,
      );

      final active = session.transitionTo(ResumableSessionStatus.active);
      expect(active.status, equals(ResumableSessionStatus.active));

      final paused = active.transitionTo(ResumableSessionStatus.paused);
      expect(paused.status, equals(ResumableSessionStatus.paused));

      final resumed = paused.transitionTo(ResumableSessionStatus.resumed);
      expect(resumed.status, equals(ResumableSessionStatus.resumed));

      // Illegal transition from resumed back to created
      expect(
        () => resumed.transitionTo(ResumableSessionStatus.created),
        throwsA(isA<SessionRecoveryException>()),
      );
    });

    test('12. AdvanceQuestion increments cursor and appends completed question',
        () {
      final session = ResumableLearningSession(
        sessionId: 'sess_101',
        learnerId: 'learner_p40',
        examId: 'upsc',
        currentObjectiveId: 'obj_01',
        currentQuestionIndex: 0,
        createdAt: fixedDate,
        lastActivityTimestamp: fixedDate,
      );

      final advanced = session.advanceQuestion(
        completedQuestionId: 'q_alpha',
        nextObjectiveId: 'obj_02',
        timestamp: fixedDate.add(const Duration(seconds: 30)),
      );

      expect(advanced.currentQuestionIndex, equals(1));
      expect(advanced.completedQuestionIds, equals(['q_alpha']));
      expect(advanced.currentObjectiveId, equals('obj_02'));
    });

    test('13. CreateCheckpoint enforces strictly increasing revision', () {
      final session = ResumableLearningSession(
        sessionId: 'sess_101',
        learnerId: 'learner_p40',
        examId: 'upsc',
        currentObjectiveId: 'obj_01',
        lastPersistedRevision: 3,
        createdAt: fixedDate,
        lastActivityTimestamp: fixedDate,
      );

      // Revision <= lastPersistedRevision throws staleCheckpoint
      expect(
        () => session.createCheckpoint(
          nextCheckpointRevision: 3,
          nextAuthoritativeRevision: 2,
        ),
        throwsA(
          isA<SessionRecoveryException>().having(
            (e) => e.code,
            'code',
            equals(SessionRecoveryErrorCode.staleCheckpoint),
          ),
        ),
      );

      // Revision > lastPersistedRevision succeeds
      final checkpoint = session.createCheckpoint(
        nextCheckpointRevision: 4,
        nextAuthoritativeRevision: 2,
      );
      expect(checkpoint.checkpointRevision, equals(4));
    });
  });

  // ===========================================================================
  // GROUP 4: InMemorySessionCheckpointRepository Operations & Monotonicity
  // ===========================================================================
  group('P40.4 InMemorySessionCheckpointRepository Operations', () {
    late InMemorySessionCheckpointRepository repo;

    setUp(() {
      repo = InMemorySessionCheckpointRepository();
    });

    test('14. Saves and loads checkpoint with multi-tenant isolation',
        () async {
      final chk1 = buildSampleCheckpoint(
        sessionId: 'sess_01',
        learnerId: 'learner_A',
        examId: 'upsc',
      );
      final chk2 = buildSampleCheckpoint(
        sessionId: 'sess_01',
        learnerId: 'learner_B',
        examId: 'upsc',
      );

      await repo.saveCheckpoint(chk1);
      await repo.saveCheckpoint(chk2);

      final loadedA = await repo.loadCheckpoint(
        learnerId: 'learner_A',
        examId: 'upsc',
        sessionId: 'sess_01',
      );
      final loadedB = await repo.loadCheckpoint(
        learnerId: 'learner_B',
        examId: 'upsc',
        sessionId: 'sess_01',
      );

      expect(loadedA!.learnerId, equals('learner_A'));
      expect(loadedB!.learnerId, equals('learner_B'));
    });

    test('15. Monotonic revision check rejects stale write', () async {
      final chkRev3 = buildSampleCheckpoint(checkpointRevision: 3);
      await repo.saveCheckpoint(chkRev3);

      final chkRev2 = buildSampleCheckpoint(checkpointRevision: 2);
      expect(
        () => repo.saveCheckpoint(chkRev2),
        throwsA(
          isA<SessionRecoveryException>().having(
            (e) => e.code,
            'code',
            equals(SessionRecoveryErrorCode.staleCheckpoint),
          ),
        ),
      );
    });

    test('16. Idempotent save with identical payload succeeds as no-op',
        () async {
      final chk = buildSampleCheckpoint(checkpointRevision: 2);
      await repo.saveCheckpoint(chk);
      // Re-saving identical checkpoint succeeds
      await repo.saveCheckpoint(chk);

      final loaded = await repo.loadCheckpoint(
        learnerId: chk.learnerId,
        examId: chk.examId,
        sessionId: chk.sessionId,
      );
      expect(loaded!.checkpointRevision, equals(2));
    });

    test('17. Delete removes checkpoint cleanly', () async {
      final chk = buildSampleCheckpoint();
      await repo.saveCheckpoint(chk);
      expect(
          await repo.exists(
            learnerId: chk.learnerId,
            examId: chk.examId,
            sessionId: chk.sessionId,
          ),
          isTrue);

      await repo.deleteCheckpoint(
        learnerId: chk.learnerId,
        examId: chk.examId,
        sessionId: chk.sessionId,
      );
      expect(
          await repo.exists(
            learnerId: chk.learnerId,
            examId: chk.examId,
            sessionId: chk.sessionId,
          ),
          isFalse);
    });

    test('18. Fault injection simulates IO failure', () async {
      final chk = buildSampleCheckpoint();
      repo.failNextSave = true;

      expect(
        () => repo.saveCheckpoint(chk),
        throwsA(
          isA<SessionRecoveryException>().having(
            (e) => e.code,
            'code',
            equals(SessionRecoveryErrorCode.ioFailure),
          ),
        ),
      );
    });
  });

  // ===========================================================================
  // GROUP 5: LearningSessionRecoveryService Recovery Scenarios
  // ===========================================================================
  group('P40.5 LearningSessionRecoveryService Orchestration', () {
    late InMemorySessionCheckpointRepository checkpointRepo;
    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService recoveryService;

    setUp(() {
      checkpointRepo = InMemorySessionCheckpointRepository();
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      authRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );
      recoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );
    });

    test('19. Cold start returns coldStart status without corruption',
        () async {
      final result = await recoveryService.recoverSession(
        learnerId: 'learner_p40',
        examId: 'upsc',
        sessionId: 'unseen_session',
      );

      expect(result.isColdStart, isTrue);
      expect(result.status, equals(SessionRecoveryResultStatus.coldStart));
      expect(result.session, isNull);
    });

    test('20. Valid recovery restores session positioned at checkpoint cursor',
        () async {
      final authState = buildSampleState(revision: 2);
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState),
      );

      final checkpoint = buildSampleCheckpoint(
        sessionId: 'session_active_01',
        questionIndex: 3,
        completedQuestionIds: ['q_0', 'q_1', 'q_2'],
        checkpointRevision: 4,
        authoritativeStateRevision: 2,
      );
      await checkpointRepo.saveCheckpoint(checkpoint);

      final result = await recoveryService.recoverSession(
        learnerId: 'learner_p40',
        examId: 'upsc',
        sessionId: 'session_active_01',
      );

      expect(result.isSuccess, isTrue);
      expect(result.session, isNotNull);
      expect(result.session!.currentQuestionIndex, equals(3));
      expect(result.session!.completedQuestionCount, equals(3));
      expect(result.session!.status, equals(ResumableSessionStatus.resumed));
      expect(result.authoritativeState!.revision, equals(2));
    });

    test('21. Already completed session returns alreadyCompleted status',
        () async {
      final authState = buildSampleState(revision: 2);
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState),
      );

      final completedCheckpoint = buildSampleCheckpoint(
        sessionId: 'session_done_01',
        questionIndex: 10,
        isCompleted: true,
      );
      await checkpointRepo.saveCheckpoint(completedCheckpoint);

      final result = await recoveryService.recoverSession(
        learnerId: 'learner_p40',
        examId: 'upsc',
        sessionId: 'session_done_01',
      );

      expect(result.isAlreadyCompleted, isTrue);
      expect(
          result.status, equals(SessionRecoveryResultStatus.alreadyCompleted));
      expect(result.session, isNull);
    });

    test('22. Corrupted checkpoint payload returns corrupt status', () async {
      checkpointRepo.injectRawPayload(
        learnerId: 'learner_p40',
        examId: 'upsc',
        sessionId: 'session_corrupted',
        rawPayload: '{"invalid_json": true, "corrupted": true}',
      );

      final result = await recoveryService.recoverSession(
        learnerId: 'learner_p40',
        examId: 'upsc',
        sessionId: 'session_corrupted',
      );

      expect(result.status, equals(SessionRecoveryResultStatus.corrupt));
    });

    test(
        '23. Stale checkpoint (authRev higher than stored) returns stale status',
        () async {
      // Authoritative state is at rev 1
      final authState = buildSampleState(revision: 1);
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState),
      );

      // Checkpoint claims authoritative state was at rev 3 (out of sync)
      final checkpoint = buildSampleCheckpoint(
        sessionId: 'session_stale_chk',
        authoritativeStateRevision: 3,
      );
      await checkpointRepo.saveCheckpoint(checkpoint);

      final result = await recoveryService.recoverSession(
        learnerId: 'learner_p40',
        examId: 'upsc',
        sessionId: 'session_stale_chk',
      );

      expect(result.status, equals(SessionRecoveryResultStatus.stale));
    });

    test('24. Tenant identity mismatch is rejected explicitly', () async {
      final checkpoint = buildSampleCheckpoint(
        learnerId: 'learner_alice',
        sessionId: 'session_tenant_mismatch',
      );
      // Simulate storage record containing mismatched internal tenant identity
      checkpointRepo.injectRawPayload(
        learnerId: 'learner_bob',
        examId: 'upsc',
        sessionId: 'session_tenant_mismatch',
        rawPayload: checkpoint.toCanonicalJson(),
      );

      // Attempt to recover Alice's session under Bob
      final result = await recoveryService.recoverSession(
        learnerId: 'learner_bob',
        examId: 'upsc',
        sessionId: 'session_tenant_mismatch',
      );

      expect(
          result.status, equals(SessionRecoveryResultStatus.identityMismatch));
    });
  });

  // ===========================================================================
  // GROUP 6: Idempotency & Repeated Recovery Guarantees
  // ===========================================================================
  group('P40.6 Recovery Idempotency & Invariants', () {
    late InMemorySessionCheckpointRepository checkpointRepo;
    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService recoveryService;

    setUp(() {
      checkpointRepo = InMemorySessionCheckpointRepository();
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      authRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );
      recoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );
    });

    test('25. Repeated recovery of same checkpoint is strictly idempotent',
        () async {
      final authState = buildSampleState(revision: 2);
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState),
      );

      final checkpoint = buildSampleCheckpoint(
        sessionId: 'session_idem',
        questionIndex: 2,
        checkpointRevision: 2,
        authoritativeStateRevision: 2,
      );
      await checkpointRepo.saveCheckpoint(checkpoint);

      final res1 = await recoveryService.recoverSession(
        learnerId: 'learner_p40',
        examId: 'upsc',
        sessionId: 'session_idem',
      );

      final res2 = await recoveryService.recoverSession(
        learnerId: 'learner_p40',
        examId: 'upsc',
        sessionId: 'session_idem',
      );

      expect(res1.isSuccess, isTrue);
      expect(res2.isSuccess, isTrue);
      expect(res1.session!.currentQuestionIndex,
          equals(res2.session!.currentQuestionIndex));
      expect(res1.session!.completedQuestionIds,
          equals(res2.session!.completedQuestionIds));
      expect(res1.checkpoint!.checksum, equals(res2.checkpoint!.checksum));
    });
  });
}
