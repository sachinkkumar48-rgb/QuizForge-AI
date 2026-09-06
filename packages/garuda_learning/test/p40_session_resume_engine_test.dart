/// P40 Adaptive Learning Session Resume Engine Unit Test Suite (TITAN-KO-040.0 P40).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final baseTime = DateTime.utc(2026, 9, 6, 10, 0, 0);

  group('SessionIdentity', () {
    test('creates valid immutable identity and serializes to JSON', () {
      final identity = SessionIdentity(
        sessionId: 'sess_100',
        learnerId: 'learner_1',
        examId: 'upsc',
        startedAt: baseTime,
        lastCheckpointAt: baseTime,
        status: ResumableSessionStatus.active,
      );

      expect(identity.sessionId, 'sess_100');
      expect(identity.learnerId, 'learner_1');
      expect(identity.examId, 'upsc');
      expect(identity.status, ResumableSessionStatus.active);

      final json = identity.toJson();
      final restored = SessionIdentity.fromJson(json);

      expect(restored, equals(identity));
    });

    test('validates non-empty coordinates', () {
      expect(
        () => SessionIdentity(
          sessionId: '',
          learnerId: 'l1',
          examId: 'upsc',
          startedAt: baseTime,
          lastCheckpointAt: baseTime,
        ),
        throwsA(isA<SessionRecoveryException>()),
      );
    });

    test('copyWith preserves unmodified fields', () {
      final identity = SessionIdentity(
        sessionId: 'sess_1',
        learnerId: 'l1',
        examId: 'upsc',
        startedAt: baseTime,
        lastCheckpointAt: baseTime,
      );

      final updated = identity.copyWith(
        status: ResumableSessionStatus.paused,
      );

      expect(updated.sessionId, 'sess_1');
      expect(updated.status, ResumableSessionStatus.paused);
    });
  });

  group('AttemptIdentity', () {
    test('formats deterministic token with sessionId, questionId, sequence',
        () {
      final attempt = AttemptIdentity(
        sessionId: 'sess_abc',
        questionId: 'q_polity_01',
        attemptSequence: 1,
      );

      expect(attempt.token, 'sess_abc:q_polity_01:1');
      expect(attempt.sessionId, 'sess_abc');
      expect(attempt.questionId, 'q_polity_01');
      expect(attempt.attemptSequence, 1);
    });

    test('parses successfully from token string', () {
      final parsed = AttemptIdentity.fromToken('sess_xyz:q_history_05:3');

      expect(parsed.sessionId, 'sess_xyz');
      expect(parsed.questionId, 'q_history_05');
      expect(parsed.attemptSequence, 3);
      expect(parsed.token, 'sess_xyz:q_history_05:3');
    });

    test('rejects malformed token strings', () {
      expect(
        () => AttemptIdentity.fromToken('invalid_token_without_enough_parts'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AttemptIdentity.fromToken('sess:q:not_a_number'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects negative attempt sequence', () {
      expect(
        () => AttemptIdentity(
          sessionId: 's',
          questionId: 'q',
          attemptSequence: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ResumableSessionSnapshot', () {
    late SessionIdentity testIdentity;

    setUp(() {
      testIdentity = SessionIdentity(
        sessionId: 'sess_snap_1',
        learnerId: 'learner_1',
        examId: 'upsc',
        startedAt: baseTime,
        lastCheckpointAt: baseTime,
        status: ResumableSessionStatus.active,
      );
    });

    test('computes cryptographic SHA-256 checksum and verifies integrity', () {
      final snapshot = ResumableSessionSnapshot(
        identity: testIdentity,
        currentQuestionIndex: 2,
        currentQuestionId: 'q_3',
        completedQuestionIds: ['q_1', 'q_2'],
        processedAttemptTokens: ['sess_snap_1:q_1:1', 'sess_snap_1:q_2:1'],
        accumulatedScore: 1.5,
        correctCount: 2,
        activeObjectiveId: 'lo_polity_01',
        checkpointRevision: 3,
        authoritativeStateRevision: 2,
        timestamp: baseTime,
      );

      expect(snapshot.checksum.isNotEmpty, isTrue);
      expect(snapshot.verifyChecksum(), isTrue);

      final json = snapshot.toJson();
      final restored = ResumableSessionSnapshot.fromJson(json);

      expect(restored, equals(snapshot));
      expect(restored.verifyChecksum(), isTrue);
    });

    test('throws CheckpointIntegrityException when checksum is tampered', () {
      final snapshot = ResumableSessionSnapshot(
        identity: testIdentity,
        currentQuestionIndex: 0,
        completedQuestionIds: const [],
        processedAttemptTokens: const [],
        activeObjectiveId: 'lo_polity_01',
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        timestamp: baseTime,
      );

      final map = snapshot.toJson();
      map['accumulatedScore'] =
          999.0; // Tamper score without recalculating checksum

      expect(
        () => ResumableSessionSnapshot.fromJson(map),
        throwsA(isA<CheckpointIntegrityException>()),
      );
    });

    test('converts to and from SessionCheckpoint preserving metadata', () {
      final snapshot = ResumableSessionSnapshot(
        identity: testIdentity,
        currentQuestionIndex: 1,
        completedQuestionIds: ['q_1'],
        processedAttemptTokens: ['sess_snap_1:q_1:1'],
        accumulatedScore: 1.0,
        correctCount: 1,
        activeObjectiveId: 'lo_polity_01',
        checkpointRevision: 2,
        authoritativeStateRevision: 1,
        timestamp: baseTime,
      );

      final checkpoint = snapshot.toCheckpoint();
      expect(checkpoint.sessionId, snapshot.sessionId);
      expect(checkpoint.checkpointRevision, snapshot.checkpointRevision);
      expect(checkpoint.authoritativeStateRevision,
          snapshot.authoritativeStateRevision);

      final fromCheckpoint =
          ResumableSessionSnapshot.fromCheckpoint(checkpoint);
      expect(fromCheckpoint.sessionId, snapshot.sessionId);
      expect(fromCheckpoint.checkpointRevision, snapshot.checkpointRevision);
      expect(fromCheckpoint.accumulatedScore, snapshot.accumulatedScore);
      expect(fromCheckpoint.processedAttemptTokens,
          snapshot.processedAttemptTokens);
    });

    test('copyWith recalculates checksum and preserves consistency', () {
      final snapshot = ResumableSessionSnapshot(
        identity: testIdentity,
        currentQuestionIndex: 0,
        completedQuestionIds: const [],
        processedAttemptTokens: const [],
        activeObjectiveId: 'lo_polity_01',
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        timestamp: baseTime,
      );

      final updated = snapshot.copyWith(
        currentQuestionIndex: 1,
        checkpointRevision: 2,
      );

      expect(updated.currentQuestionIndex, 1);
      expect(updated.checkpointRevision, 2);
      expect(updated.verifyChecksum(), isTrue);
      expect(updated.checksum, isNot(equals(snapshot.checksum)));
    });
  });

  group('CheckpointPolicy', () {
    test('everyAttempt checkpoints after every attempt', () {
      const policy = CheckpointPolicy.everyAttempt();

      expect(policy.shouldCheckpoint(attemptCount: 0), isFalse);
      expect(policy.shouldCheckpoint(attemptCount: 1), isTrue);
      expect(policy.shouldCheckpoint(attemptCount: 2), isTrue);
    });

    test('everyNAttempts checkpoints periodically', () {
      final policy = CheckpointPolicy.everyNAttempts(3);

      expect(policy.shouldCheckpoint(attemptCount: 1), isFalse);
      expect(policy.shouldCheckpoint(attemptCount: 2), isFalse);
      expect(policy.shouldCheckpoint(attemptCount: 3), isTrue);
      expect(policy.shouldCheckpoint(attemptCount: 4), isFalse);
      expect(policy.shouldCheckpoint(attemptCount: 6), isTrue);
    });

    test('onPauseOrComplete triggers only when completed or paused', () {
      const policy = CheckpointPolicy.onPauseOrComplete();

      expect(policy.shouldCheckpoint(attemptCount: 1), isFalse);
      expect(policy.shouldCheckpoint(attemptCount: 5), isFalse);
      expect(policy.shouldCheckpoint(attemptCount: 1, isPaused: true), isTrue);
      expect(
          policy.shouldCheckpoint(attemptCount: 5, isCompleted: true), isTrue);
    });

    test('manual triggers only when explicit', () {
      const policy = CheckpointPolicy.manual();

      expect(policy.shouldCheckpoint(attemptCount: 1), isFalse);
      expect(
          policy.shouldCheckpoint(attemptCount: 1, isExplicit: true), isTrue);
    });
  });

  group('SessionCheckpointSchemaMigrator', () {
    const migrator = DefaultSessionCheckpointSchemaMigrator();

    test('canMigrate allows v0 to v1 upgrade and disallows others', () {
      expect(migrator.canMigrate(0, 1), isTrue);
      expect(migrator.canMigrate(1, 0), isFalse);
      expect(migrator.canMigrate(1, 2), isFalse);
    });

    test('migrates v0 legacy JSON map to v1 ResumableSessionSnapshot', () {
      final legacyV0 = {
        'sessionId': 'legacy_sess_1',
        'learnerId': 'learner_v0',
        'examId': 'upsc',
        'questionIndex': 3,
        'completedQuestionIds': ['q_1', 'q_2', 'q_3'],
        'processedAttemptTokens': ['t1', 't2', 't3'],
        'accumulatedScore': 2.5,
        'correctCount': 2,
        'activeObjectiveId': 'lo_polity_01',
        'checkpointRevision': 4,
        'authoritativeStateRevision': 3,
        'timestamp': baseTime.toIso8601String(),
        'isCompleted': false,
      };

      final migrated = migrator.migrate(legacyV0, sourceVersion: 0);

      expect(migrated.schemaVersion, 1);
      expect(migrated.sessionId, 'legacy_sess_1');
      expect(migrated.learnerId, 'learner_v0');
      expect(migrated.currentQuestionIndex, 3);
      expect(migrated.completedQuestionIds.length, 3);
      expect(migrated.checkpointRevision, 4);
      expect(migrated.verifyChecksum(), isTrue);
      expect(migrated.metadata['migratedFromSchema'], 0);
    });

    test('rejects schema downgrade attempt', () {
      expect(
        () => migrator.migrate(
          {'sessionId': 's', 'learnerId': 'l', 'examId': 'e'},
          sourceVersion: 1,
          targetVersion: 0,
        ),
        throwsA(isA<CheckpointSchemaException>()),
      );
    });

    test('rejects migration with missing coordinates', () {
      expect(
        () => migrator.migrate(
          {'sessionId': '', 'learnerId': 'l', 'examId': 'e'},
          sourceVersion: 0,
        ),
        throwsA(isA<CheckpointIntegrityException>()),
      );
    });
  });

  group('SessionCheckpointService', () {
    late InMemorySessionCheckpointRepository repo;
    late SessionCheckpointService service;

    setUp(() {
      repo = InMemorySessionCheckpointRepository();
      service = SessionCheckpointService(repository: repo);
    });

    test('saves and loads snapshot with integrity validation', () async {
      final snapshot = ResumableSessionSnapshot(
        identity: SessionIdentity(
          sessionId: 'sess_srv_1',
          learnerId: 'l1',
          examId: 'upsc',
          startedAt: baseTime,
          lastCheckpointAt: baseTime,
        ),
        currentQuestionIndex: 0,
        completedQuestionIds: const [],
        processedAttemptTokens: const [],
        activeObjectiveId: 'lo_general',
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        timestamp: baseTime,
      );

      await service.saveSnapshot(snapshot);
      final exists = await service.hasSnapshot(
        learnerId: 'l1',
        examId: 'upsc',
        sessionId: 'sess_srv_1',
      );
      expect(exists, isTrue);

      final loaded = await service.loadSnapshot(
        learnerId: 'l1',
        examId: 'upsc',
        sessionId: 'sess_srv_1',
      );

      expect(loaded, isNotNull);
      expect(loaded!.sessionId, snapshot.sessionId);
      expect(loaded.checkpointRevision, 1);
      expect(loaded.verifyChecksum(), isTrue);
    });

    test('rejects saving snapshot with corrupted checksum', () async {
      final corrupted = ResumableSessionSnapshot(
        identity: SessionIdentity(
          sessionId: 'sess_corrupted',
          learnerId: 'l1',
          examId: 'upsc',
          startedAt: baseTime,
          lastCheckpointAt: baseTime,
        ),
        currentQuestionIndex: 0,
        completedQuestionIds: const [],
        processedAttemptTokens: const [],
        activeObjectiveId: 'lo_general',
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        timestamp: baseTime,
        checksum: 'corrupted_hash_value',
      );

      expect(
        () => service.saveSnapshot(corrupted),
        throwsA(isA<CheckpointIntegrityException>()),
      );
    });

    test('detects and rejects stale checkpoint writes', () async {
      final initial = ResumableSessionSnapshot(
        identity: SessionIdentity(
          sessionId: 'sess_stale',
          learnerId: 'l1',
          examId: 'upsc',
          startedAt: baseTime,
          lastCheckpointAt: baseTime,
        ),
        currentQuestionIndex: 1,
        completedQuestionIds: ['q1'],
        processedAttemptTokens: ['sess_stale:q1:1'],
        activeObjectiveId: 'lo_general',
        checkpointRevision: 2,
        authoritativeStateRevision: 1,
        timestamp: baseTime,
      );

      await service.saveSnapshot(initial);

      // Attempt to save older revision 1
      final stale = initial.copyWith(
        checkpointRevision: 1,
      );

      expect(
        () => service.saveSnapshot(stale),
        throwsA(isA<StaleCheckpointException>()),
      );
    });
  });

  group('AdaptiveSessionResumeEngine', () {
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
        'starts session, establishes coordinates, and creates initial checkpoint',
        () async {
      final result = await engine.startSession(
        sessionId: 'session_e1',
        learnerId: 'learner_10',
        examId: 'upsc',
        firstObjectiveId: 'lo_polity_01',
        firstQuestionId: 'q_polity_01',
        startedAt: baseTime,
      );

      expect(result.sessionId, 'session_e1');
      expect(result.checkpointRevision, 1);
      expect(result.status, ResumableSessionStatus.active);
      expect(result.isCheckpointSaved, isTrue);

      final hasStored = await checkpointService.hasSnapshot(
        learnerId: 'learner_10',
        examId: 'upsc',
        sessionId: 'session_e1',
      );
      expect(hasStored, isTrue);
    });

    test(
        'submits attempt and rejects duplicate attempt submissions with DuplicateAttemptException',
        () async {
      await engine.startSession(
        sessionId: 'session_dedup',
        learnerId: 'learner_10',
        examId: 'upsc',
        firstObjectiveId: 'lo_polity_01',
        startedAt: baseTime,
      );

      final attempt = AttemptIdentity(
        sessionId: 'session_dedup',
        questionId: 'q_polity_01',
        attemptSequence: 1,
      );

      final res1 = await engine.submitAttempt(
        attemptIdentity: attempt,
        submittedAnswer: 'A',
        isCorrect: true,
        score: 1.0,
        submittedAt: baseTime.add(const Duration(minutes: 1)),
      );

      expect(res1.checkpointRevision, 2);
      expect(res1.snapshot.processedAttemptTokens, contains(attempt.token));

      // Attempt duplicate submission
      expect(
        () => engine.submitAttempt(
          attemptIdentity: attempt,
          submittedAnswer: 'A',
          isCorrect: true,
          score: 1.0,
          submittedAt: baseTime.add(const Duration(minutes: 2)),
        ),
        throwsA(isA<DuplicateAttemptException>()),
      );
    });

    test('strict reconciliation: classifies aligned, stale, and ahead states',
        () async {
      await engine.startSession(
        sessionId: 'session_recon',
        learnerId: 'learner_recon',
        examId: 'upsc',
        firstObjectiveId: 'lo_polity_01',
        startedAt: baseTime,
      );

      // In initial state: chkRev = 1, authRev = 1 -> aligned
      final recovery = await engine.recoverSession(
        learnerId: 'learner_recon',
        examId: 'upsc',
        sessionId: 'session_recon',
        recoveredAt: baseTime.add(const Duration(minutes: 5)),
      );

      expect(recovery.alignment, CheckpointReconciliationAlignment.aligned);
      expect(recovery.snapshot.status, ResumableSessionStatus.recovered);
    });

    test('pause and interruption safely persist checkpoint', () async {
      await engine.startSession(
        sessionId: 'session_crash',
        learnerId: 'learner_crash',
        examId: 'upsc',
        firstObjectiveId: 'lo_polity_01',
        startedAt: baseTime,
      );

      final paused = await engine.pauseSession(
        sessionId: 'session_crash',
        pausedAt: baseTime.add(const Duration(minutes: 1)),
      );
      expect(paused.status, ResumableSessionStatus.paused);

      final interrupted = await engine.interruptSession(
        sessionId: 'session_crash',
        interruptedAt: baseTime.add(const Duration(minutes: 2)),
      );
      expect(interrupted.status, ResumableSessionStatus.interrupted);

      // Resuming restores session at exact point
      final resumed = await engine.resumeSession(
        learnerId: 'learner_crash',
        examId: 'upsc',
        sessionId: 'session_crash',
        resumedAt: baseTime.add(const Duration(minutes: 3)),
      );

      expect(resumed.status, ResumableSessionStatus.resumed);
      expect(resumed.isCheckpointSaved, isTrue);
    });

    test(
        'enforces completion ordering guarantee and rejects subsequent attempts',
        () async {
      await engine.startSession(
        sessionId: 'session_comp',
        learnerId: 'learner_comp',
        examId: 'upsc',
        firstObjectiveId: 'lo_polity_01',
        startedAt: baseTime,
      );

      final attempt = AttemptIdentity(
        sessionId: 'session_comp',
        questionId: 'q_polity_01',
        attemptSequence: 1,
      );

      await engine.submitAttempt(
        attemptIdentity: attempt,
        submittedAnswer: 'A',
        isCorrect: true,
        score: 1.0,
        submittedAt: baseTime.add(const Duration(minutes: 1)),
      );

      final completed = await engine.completeSession(
        sessionId: 'session_comp',
        completedAt: baseTime.add(const Duration(minutes: 5)),
      );

      expect(completed.status, ResumableSessionStatus.completed);
      expect(completed.authoritativeState.processedSessionIds,
          contains('session_comp'));

      // Attempt submission after completion must throw SessionCompletionException
      final postAttempt = AttemptIdentity(
        sessionId: 'session_comp',
        questionId: 'q_polity_02',
        attemptSequence: 2,
      );

      expect(
        () => engine.submitAttempt(
          attemptIdentity: postAttempt,
          submittedAnswer: 'B',
          isCorrect: false,
          score: 0.0,
          submittedAt: baseTime.add(const Duration(minutes: 6)),
        ),
        throwsA(isA<SessionCompletionException>()),
      );
    });
  });
}
