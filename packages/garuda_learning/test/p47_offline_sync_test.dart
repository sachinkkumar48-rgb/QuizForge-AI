/// P47 Offline-First Cloud Synchronization & Conflict Resolution Tests (TITAN-KO-047.0 P47).
///
/// Exhaustively verifies all 30 mandatory requirements:
/// 1. local state change creates pending sync
/// 2. offline learning succeeds
/// 3. remote unavailable
/// 4. pending queue retained
/// 5. successful synchronization
/// 6. synchronization acknowledgement
/// 7. retry
/// 8. idempotent retry
/// 9. stale revision rejection
/// 10. conflict detection
/// 11. deterministic conflict resolution
/// 12. newer remote state protected
/// 13. mastery cannot roll back
/// 14. attempt count cannot roll back
/// 15. progress cannot roll back
/// 16. learning history deduplication
/// 17. session checkpoint synchronization
/// 18. crash/restart recovery
/// 19. multi-device synchronization
/// 20. learner isolation
/// 21. exam isolation
/// 22. remote repository failure
/// 23. malformed remote state
/// 24. checksum/integrity failure where applicable
/// 25. sync status transitions
/// 26. eventual convergence
/// 27. duplicate synchronization request
/// 28. offline -> online transition
/// 29. local state survives remote failure
/// 30. complete end-to-end offline-to-online learner journey
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P47 Offline-First Cloud Synchronization & Conflict Resolution Tests',
      () {
    const String testLearner = 'learner_p47_test';
    const String testExam = 'upsc_prelims_gs1';
    const String testDeviceA = 'device_pixel_a';
    const String testDeviceB = 'device_ipad_b';
    final DateTime baseDate = DateTime.utc(2026, 9, 8, 12, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository localStateRepo;
    late InMemorySyncOutboxRepository outboxRepo;
    late InMemoryRemoteLearningStateRepository remoteRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late InMemoryLearningActivityCompletionRepository completionRepo;
    late LearnerStateConflictResolver conflictResolver;
    late LearnerStateSyncService syncService;

    setUp(() {
      localStateRepo = InMemoryAuthoritativeLearningStateRepository();
      outboxRepo = InMemorySyncOutboxRepository();
      remoteRepo = InMemoryRemoteLearningStateRepository();
      checkpointRepo = InMemorySessionCheckpointRepository();
      completionRepo = InMemoryLearningActivityCompletionRepository();
      conflictResolver = const LearnerStateConflictResolver();

      syncService = LearnerStateSyncService(
        localStateRepo: localStateRepo,
        outboxRepo: outboxRepo,
        remoteRepo: remoteRepo,
        conflictResolver: conflictResolver,
        checkpointRepo: checkpointRepo,
        completionRepo: completionRepo,
      );
    });

    AuthoritativeLearnerState buildState({
      required String learnerId,
      required String examId,
      required int revision,
      required Map<String, LearnerProgress> progressMap,
      Set<String>? processedSessionIds,
      DateTime? updatedAt,
    }) {
      return AuthoritativeLearnerState(
        learnerId: learnerId,
        examId: examId,
        revision: revision,
        progressMap: progressMap,
        processedSessionIds: processedSessionIds ?? const {},
        lastUpdatedAt: updatedAt ?? baseDate,
      );
    }

    // 1. local state change creates pending sync
    test('1. local state change creates pending sync in local outbox',
        () async {
      final state = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        progressMap: {
          'lo_preamble': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_preamble',
            attemptCount: 5,
            correctCount: 4,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      final envelope = await syncService.queueLocalStateChange(
        state,
        deviceId: testDeviceA,
        createdAt: baseDate,
      );

      expect(envelope.status, equals(SyncStatus.pendingSync));
      expect(envelope.revision, equals(1));
      expect(envelope.deviceId, equals(testDeviceA));

      final pending = await outboxRepo.peekPending(
          learnerId: testLearner, examId: testExam);
      expect(pending.length, equals(1));
      expect(pending.first.syncId, equals(envelope.syncId));
    });

    // 2. offline learning succeeds
    test('2. offline learning succeeds without remote connectivity', () async {
      remoteRepo.setOnline(false);

      final state = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        progressMap: {
          'lo_basic_structure': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_basic_structure',
            attemptCount: 3,
            correctCount: 2,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );

      // Must succeed without throwing
      await localStateRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(state),
      );
      final envelope = await syncService.queueLocalStateChange(
        state,
        deviceId: testDeviceA,
      );

      expect(envelope.status, equals(SyncStatus.pendingSync));
      final localPersisted =
          await localStateRepo.load(learnerId: testLearner, examId: testExam);
      expect(localPersisted?.revision, equals(2));
    });

    // 3. remote unavailable
    test('3. sync returns offline result when remote is unreachable', () async {
      remoteRepo.setOnline(false);

      final state = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        progressMap: {},
      );
      await syncService.queueLocalStateChange(state, deviceId: testDeviceA);

      final result = await syncService.sync(
        learnerId: testLearner,
        examId: testExam,
        deviceId: testDeviceA,
      );

      expect(result.isOffline, isTrue);
      expect(result.status, equals(SyncStatus.pendingSync));
      expect(result.itemsSynced, equals(0));
    });

    // 4. pending queue retained
    test('4. pending outbox queue retained across operations', () async {
      remoteRepo.setOnline(false);

      final state1 = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});
      final state2 = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 2,
          progressMap: {});

      await syncService.queueLocalStateChange(state1,
          deviceId: testDeviceA, createdAt: baseDate);
      await syncService.queueLocalStateChange(state2,
          deviceId: testDeviceA,
          createdAt: baseDate.add(const Duration(minutes: 5)));

      final pending = await outboxRepo.peekPending(
          learnerId: testLearner, examId: testExam);
      expect(pending.length, equals(2));
      expect(pending[0].revision, equals(1));
      expect(pending[1].revision, equals(2));
    });

    // 5. successful synchronization
    test('5. successful synchronization transfers state to remote', () async {
      final state = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        progressMap: {
          'lo_preamble': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_preamble',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );

      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));
      await syncService.queueLocalStateChange(state, deviceId: testDeviceA);

      final result = await syncService.sync(
        learnerId: testLearner,
        examId: testExam,
        deviceId: testDeviceA,
      );

      expect(result.status, equals(SyncStatus.synced));
      expect(result.itemsSynced, equals(1));

      final remoteFetch =
          await remoteRepo.fetchState(learnerId: testLearner, examId: testExam);
      expect(remoteFetch.exists, isTrue);
      expect(remoteFetch.state?.revision, equals(1));
      expect(remoteFetch.state?.progressMap['lo_preamble']?.attemptCount,
          equals(10));
    });

    // 6. synchronization acknowledgement
    test('6. synchronization acknowledgement updates outbox record to synced',
        () async {
      final state = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));
      final envelope =
          await syncService.queueLocalStateChange(state, deviceId: testDeviceA);

      await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);

      final updatedEnvelope = await outboxRepo.getBySyncId(envelope.syncId);
      expect(updatedEnvelope?.status, equals(SyncStatus.synced));
      expect(updatedEnvelope?.errorMessage, isNull);
    });

    // 7. retry
    test(
        '7. failed sync attempts are retried cleanly upon subsequent sync call',
        () async {
      remoteRepo.failNextRequestWith('Temporary connection drop');

      final state = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));
      final env =
          await syncService.queueLocalStateChange(state, deviceId: testDeviceA);

      // First sync fails
      await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);
      final failedEnv = await outboxRepo.getBySyncId(env.syncId);
      expect(failedEnv?.status, equals(SyncStatus.failed));
      expect(failedEnv?.retryCount, equals(1));

      // Second sync succeeds
      final retryResult = await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);
      expect(retryResult.status, equals(SyncStatus.synced));
      expect(retryResult.itemsSynced, equals(1));

      final syncedEnv = await outboxRepo.getBySyncId(env.syncId);
      expect(syncedEnv?.status, equals(SyncStatus.synced));
    });

    // 8. idempotent retry
    test('8. idempotent retry does not duplicate state or sessions', () async {
      final state = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        progressMap: {
          'lo_art21': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_art21',
            attemptCount: 2,
            correctCount: 2,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
        processedSessionIds: {'sess_01'},
      );

      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));
      await syncService.queueLocalStateChange(state, deviceId: testDeviceA);

      // Run sync multiple times
      await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);
      final secondSync = await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);

      expect(secondSync.status, equals(SyncStatus.synced));

      final remoteFetch =
          await remoteRepo.fetchState(learnerId: testLearner, examId: testExam);
      expect(remoteFetch.state?.processedSessionIds.length, equals(1));
      expect(
          remoteFetch.state?.progressMap['lo_art21']?.attemptCount, equals(2));
    });

    // 9. stale revision rejection
    test('9. remote repository rejects stale revision and flags conflict',
        () async {
      // Remote already at rev 5
      final remoteState = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 5,
          progressMap: {});
      remoteRepo.seedRemoteState(remoteState);

      // Local attempts to push rev 4
      final staleState = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 4,
          progressMap: {});
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(staleState);
      final envelope = SyncEnvelope(
        syncId: 'sync_stale',
        learnerId: testLearner,
        examId: testExam,
        revision: 4,
        deviceId: testDeviceA,
        payload: persisted.toJson(),
      );

      final result = await remoteRepo.pushState(envelope);
      expect(result.success, isFalse);
      expect(result.isConflict, isTrue);
      expect(result.conflict?.reason, equals(SyncConflictReason.staleRevision));
    });

    // 10. conflict detection
    test(
        '10. sync service detects conflict when remote has advanced concurrently',
        () async {
      // Remote advanced to rev 2
      final remoteState = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 2,
          progressMap: {});
      remoteRepo.seedRemoteState(remoteState);

      // Local has un-synced rev 2
      final localState = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 2,
          progressMap: {});
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(
              localState));
      await syncService.queueLocalStateChange(localState,
          deviceId: testDeviceA);

      final result = await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);
      expect(result.conflictsResolved, equals(1));
    });

    // 11. deterministic conflict resolution
    test('11. conflict resolver deterministically merges independent progress',
        () {
      final localState = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        progressMap: {
          'lo_obj_1': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_obj_1',
            attemptCount: 5,
            correctCount: 3,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
        processedSessionIds: {'sess_local_1'},
      );

      final remoteState = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        progressMap: {
          'lo_obj_2': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_obj_2',
            attemptCount: 4,
            correctCount: 4,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
        processedSessionIds: {'sess_remote_2'},
      );

      final conflict = SyncConflict(
        conflictId: 'test_conflict',
        learnerId: testLearner,
        examId: testExam,
        localRevision: 2,
        remoteRevision: 2,
        localFingerprint: localState.stateFingerprint,
        remoteFingerprint: remoteState.stateFingerprint,
        localState: localState,
        remoteState: remoteState,
        reason: SyncConflictReason.concurrentEdits,
      );

      final resolution = conflictResolver.resolve(conflict);
      final merged = resolution.resolvedState;

      expect(merged.revision, equals(3)); // max(2, 2) + 1
      expect(merged.progressMap.containsKey('lo_obj_1'), isTrue);
      expect(merged.progressMap.containsKey('lo_obj_2'), isTrue);
      expect(merged.processedSessionIds,
          containsAll(['sess_local_1', 'sess_remote_2']));
    });

    // 12. newer remote state protected
    test(
        '12. newer remote state cannot be overwritten by stale local candidate',
        () async {
      final newerRemote = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 10,
        progressMap: {
          'lo_obj_1': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_obj_1',
            attemptCount: 20,
            correctCount: 18,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );
      remoteRepo.seedRemoteState(newerRemote);

      final staleLocal = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 3,
        progressMap: {},
      );
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(staleLocal);
      final envelope = SyncEnvelope(
        syncId: 'stale_env',
        learnerId: testLearner,
        examId: testExam,
        revision: 3,
        deviceId: testDeviceA,
        payload: persisted.toJson(),
      );

      final result = await remoteRepo.pushState(envelope);
      expect(result.isConflict, isTrue);

      // Verify remote remains at revision 10
      final fetched =
          await remoteRepo.fetchState(learnerId: testLearner, examId: testExam);
      expect(fetched.state?.revision, equals(10));
      expect(fetched.state?.progressMap['lo_obj_1']?.attemptCount, equals(20));
    });

    // 13. mastery cannot roll back
    test(
        '13. conflict resolution guarantees achieved mastery status never rolls back',
        () {
      final local = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        progressMap: {
          'lo_obj_1': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_obj_1',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );
      final remote = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 3,
        progressMap: {
          'lo_obj_1': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_obj_1',
            attemptCount: 5,
            correctCount: 2,
            status:
                LearnerObjectiveStatus.inProgress, // older or divergent status
          ),
        },
      );

      final conflict = SyncConflict(
        conflictId: 'c1',
        learnerId: testLearner,
        examId: testExam,
        localRevision: 2,
        remoteRevision: 3,
        localFingerprint: local.stateFingerprint,
        remoteFingerprint: remote.stateFingerprint,
        localState: local,
        remoteState: remote,
        reason: SyncConflictReason.staleRevision,
      );

      final res = conflictResolver.resolve(conflict);
      expect(res.resolvedState.progressMap['lo_obj_1']?.status,
          equals(LearnerObjectiveStatus.achieved));
    });

    // 14. attempt count cannot roll back
    test('14. conflict resolution guarantees attempt counts never roll back',
        () {
      final local = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        progressMap: {
          'lo_obj_1': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_obj_1',
            attemptCount: 15,
            correctCount: 12,
            status: LearnerObjectiveStatus.achieved,
          ),
        },
      );
      final remote = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        progressMap: {
          'lo_obj_1': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_obj_1',
            attemptCount: 8,
            correctCount: 7,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );

      final conflict = SyncConflict(
        conflictId: 'c2',
        learnerId: testLearner,
        examId: testExam,
        localRevision: 2,
        remoteRevision: 2,
        localFingerprint: local.stateFingerprint,
        remoteFingerprint: remote.stateFingerprint,
        localState: local,
        remoteState: remote,
        reason: SyncConflictReason.concurrentEdits,
      );

      final res = conflictResolver.resolve(conflict);
      expect(
          res.resolvedState.progressMap['lo_obj_1']?.attemptCount, equals(15));
      expect(
          res.resolvedState.progressMap['lo_obj_1']?.correctCount, equals(12));
    });

    // 15. progress cannot roll back
    test(
        '15. progress cannot roll back: all objectives across snapshots are preserved',
        () {
      final local = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        progressMap: {
          'lo_a': LearnerProgress(
              learnerId: testLearner,
              objectiveId: 'lo_a',
              attemptCount: 1,
              correctCount: 1),
        },
      );
      final remote = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        progressMap: {
          'lo_b': LearnerProgress(
              learnerId: testLearner,
              objectiveId: 'lo_b',
              attemptCount: 2,
              correctCount: 1),
        },
      );

      final conflict = SyncConflict(
        conflictId: 'c3',
        learnerId: testLearner,
        examId: testExam,
        localRevision: 1,
        remoteRevision: 1,
        localFingerprint: local.stateFingerprint,
        remoteFingerprint: remote.stateFingerprint,
        localState: local,
        remoteState: remote,
        reason: SyncConflictReason.concurrentEdits,
      );

      final res = conflictResolver.resolve(conflict);
      expect(res.resolvedState.progressMap.keys, containsAll(['lo_a', 'lo_b']));
    });

    // 16. learning history deduplication
    test(
        '16. learning activity completion history is deduplicated idempotently across sync',
        () async {
      final act1 = LearningActivityCompletionRecord(
        idempotencyKey: 'act_uniq_001',
        learnerId: testLearner,
        examId: testExam,
        activityId: 'activity_quiz_1',
        planId: 'plan_1',
        planRevision: 1,
        outcome: LearningActivityOutcome.calculate(
          activityId: 'activity_quiz_1',
          activityType: LearningDecisionType.reinforcement,
          learnerId: testLearner,
          examId: testExam,
          questionsPresented: 1,
          questionsAttempted: 1,
          correctAnswers: 1,
          incorrectAnswers: 0,
          skippedAnswers: 0,
          completedAt: baseDate,
        ),
      );

      // Push same activity twice
      await remoteRepo.pushActivities([act1]);
      await remoteRepo.pushActivities([act1]);

      final remoteActs = await remoteRepo.fetchActivities(
          learnerId: testLearner, examId: testExam);
      expect(remoteActs.length, equals(1));
      expect(remoteActs.first.idempotencyKey, equals('act_uniq_001'));
    });

    // 17. session checkpoint synchronization
    test(
        '17. session checkpoints synchronize and protect newer cursor revisions',
        () async {
      final cp1 = SessionCheckpoint(
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        sessionId: 'sess_live_10',
        learnerId: testLearner,
        examId: testExam,
        questionIndex: 2,
        completedQuestionIds: const ['q1', 'q2'],
        activeObjectiveId: 'lo_art21',
        timestamp: baseDate,
        isCompleted: false,
      );

      final cp2 = SessionCheckpoint(
        checkpointRevision: 2,
        authoritativeStateRevision: 1,
        sessionId: 'sess_live_10',
        learnerId: testLearner,
        examId: testExam,
        questionIndex: 3,
        completedQuestionIds: const ['q1', 'q2', 'q3'],
        activeObjectiveId: 'lo_art21',
        timestamp: baseDate.add(const Duration(minutes: 1)),
        isCompleted: false,
      );

      // Push cp2 then stale cp1
      await remoteRepo.pushCheckpoint(cp2, deviceId: testDeviceA);
      await remoteRepo.pushCheckpoint(cp1, deviceId: testDeviceA);

      final fetched = await remoteRepo.fetchCheckpoint(
        sessionId: 'sess_live_10',
        learnerId: testLearner,
        examId: testExam,
      );

      expect(fetched?.checkpointRevision, equals(2));
      expect(fetched?.questionIndex, equals(3));
    });

    // 18. crash/restart recovery
    test('18. crash/restart recovery discovers pending outbox and resumes sync',
        () async {
      final state = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      // Simulate envelope placed in outbox before crash
      await outboxRepo.enqueue(
        SyncEnvelope(
          syncId: 'sync_crash_recover',
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          deviceId: testDeviceA,
          status: SyncStatus.pendingSync,
          payload:
              PersistedAuthoritativeLearnerState.fromAuthoritativeState(state)
                  .toJson(),
        ),
      );

      // Reinitialize sync service (simulating application restart)
      final restartedService = LearnerStateSyncService(
        localStateRepo: localStateRepo,
        outboxRepo: outboxRepo,
        remoteRepo: remoteRepo,
      );

      final result = await restartedService.sync(
        learnerId: testLearner,
        examId: testExam,
        deviceId: testDeviceA,
      );

      expect(result.status, equals(SyncStatus.synced));
      expect(result.itemsSynced, equals(1));

      final env = await outboxRepo.getBySyncId('sync_crash_recover');
      expect(env?.status, equals(SyncStatus.synced));
    });

    // 19. multi-device synchronization
    test(
        '19. multi-device synchronization converges states between Device A and Device B',
        () async {
      // Device A initializes remote at rev 1
      final stateA = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        progressMap: {
          'lo_obj_a': LearnerProgress(
              learnerId: testLearner,
              objectiveId: 'lo_obj_a',
              attemptCount: 5,
              correctCount: 5),
        },
      );
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateA));
      await syncService.queueLocalStateChange(stateA, deviceId: testDeviceA);
      await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);

      // Device B starts from empty and syncs
      final deviceBLocalRepo = InMemoryAuthoritativeLearningStateRepository();
      final deviceBOutboxRepo = InMemorySyncOutboxRepository();
      final deviceBSyncService = LearnerStateSyncService(
        localStateRepo: deviceBLocalRepo,
        outboxRepo: deviceBOutboxRepo,
        remoteRepo: remoteRepo,
      );

      await deviceBSyncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceB);

      final deviceBPersisted =
          await deviceBLocalRepo.load(learnerId: testLearner, examId: testExam);
      expect(deviceBPersisted?.revision, equals(1));
      expect(
          deviceBPersisted?.progressMap['lo_obj_a']?.attemptCount, equals(5));
    });

    // 20. learner isolation
    test('20. synchronization strictly isolates distinct learners', () async {
      const otherLearner = 'learner_other_999';

      final stateA = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});
      final stateB = buildState(
          learnerId: otherLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});

      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateA));
      await syncService.queueLocalStateChange(stateA, deviceId: testDeviceA);
      await syncService.queueLocalStateChange(stateB, deviceId: testDeviceA);

      // Sync only testLearner
      await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);

      final remoteA =
          await remoteRepo.fetchState(learnerId: testLearner, examId: testExam);
      final remoteB = await remoteRepo.fetchState(
          learnerId: otherLearner, examId: testExam);

      expect(remoteA.exists, isTrue);
      expect(remoteB.exists, isFalse); // Untouched
    });

    // 21. exam isolation
    test(
        '21. synchronization strictly isolates different exams for same learner',
        () async {
      const otherExam = 'bpsc_70th_prelims';

      final stateUpsc = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});
      final stateBpsc = buildState(
          learnerId: testLearner,
          examId: otherExam,
          revision: 1,
          progressMap: {});

      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateUpsc));
      await syncService.queueLocalStateChange(stateUpsc, deviceId: testDeviceA);
      await syncService.queueLocalStateChange(stateBpsc, deviceId: testDeviceA);

      // Sync only UPSC
      await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);

      final remoteUpsc =
          await remoteRepo.fetchState(learnerId: testLearner, examId: testExam);
      final remoteBpsc = await remoteRepo.fetchState(
          learnerId: testLearner, examId: otherExam);

      expect(remoteUpsc.exists, isTrue);
      expect(remoteBpsc.exists, isFalse); // BPSC untouched
    });

    // 22. remote repository failure
    test(
        '22. remote repository failure preserves local state and flags outbox as failed',
        () async {
      remoteRepo.failNextRequestWith('Database disk full');

      final state = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));
      final env =
          await syncService.queueLocalStateChange(state, deviceId: testDeviceA);

      final result = await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);
      expect(result.status, equals(SyncStatus.failed));

      final updatedEnv = await outboxRepo.getBySyncId(env.syncId);
      expect(updatedEnv?.status, equals(SyncStatus.failed));
      expect(updatedEnv?.errorMessage, contains('Database disk full'));
    });

    // 23. malformed remote state
    test(
        '23. malformed payload rejected by remote repository with structured failure',
        () async {
      final invalidEnvelope = SyncEnvelope(
        syncId: 'sync_invalid',
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        deviceId: testDeviceA,
        payload: const {'broken': 'schema'},
      );

      final res = await remoteRepo.pushState(invalidEnvelope);
      expect(res.success, isFalse);
      expect(res.errorMessage, contains('Malformed'));
    });

    // 24. checksum/integrity failure where applicable
    test('24. checksum integrity failure rejects tampered payload', () async {
      final state = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state);

      final tamperedEnvelope = SyncEnvelope(
        syncId: 'sync_tampered',
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        deviceId: testDeviceA,
        checksum: 'fake_sha256_hash_12345',
        payload: persisted.toJson(),
      );

      expect(tamperedEnvelope.verifyChecksum(), isFalse);
      final pushResult = await remoteRepo.pushState(tamperedEnvelope);
      expect(pushResult.success, isFalse);
      expect(pushResult.errorMessage, contains('checksum mismatch'));
    });

    // 25. sync status transitions
    test('25. sync status transitions through pendingSync -> syncing -> synced',
        () async {
      final state = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final env =
          await syncService.queueLocalStateChange(state, deviceId: testDeviceA);
      expect(env.status, equals(SyncStatus.pendingSync));

      await outboxRepo.markSyncing(env.syncId);
      final syncingEnv = await outboxRepo.getBySyncId(env.syncId);
      expect(syncingEnv?.status, equals(SyncStatus.syncing));

      await outboxRepo.markSynced(env.syncId,
          remoteRevision: 1, syncedAt: DateTime.now().toUtc());
      final syncedEnv = await outboxRepo.getBySyncId(env.syncId);
      expect(syncedEnv?.status, equals(SyncStatus.synced));
    });

    // 26. eventual convergence
    test(
        '26. divergent multi-step edits eventually converge to identical revision and state',
        () async {
      // Seed remote at rev 1
      final baseState = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 1,
        progressMap: {
          'lo_init': LearnerProgress(
              learnerId: testLearner,
              objectiveId: 'lo_init',
              attemptCount: 1,
              correctCount: 1)
        },
      );
      remoteRepo.seedRemoteState(baseState);

      // Device A performs edit offline at rev 2
      final stateA = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        progressMap: {
          'lo_init': LearnerProgress(
              learnerId: testLearner,
              objectiveId: 'lo_init',
              attemptCount: 2,
              correctCount: 2),
        },
      );
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateA));
      await syncService.queueLocalStateChange(stateA, deviceId: testDeviceA);
      await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);

      // Remote is now rev 2
      final remoteRev2 =
          await remoteRepo.fetchState(learnerId: testLearner, examId: testExam);
      expect(remoteRev2.state?.revision, equals(2));

      // Device B was offline and produced independent rev 2
      final deviceBRepo = InMemoryAuthoritativeLearningStateRepository();
      final deviceBOutbox = InMemorySyncOutboxRepository();
      final deviceBSync = LearnerStateSyncService(
        localStateRepo: deviceBRepo,
        outboxRepo: deviceBOutbox,
        remoteRepo: remoteRepo,
      );

      final stateB = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        progressMap: {
          'lo_init': LearnerProgress(
              learnerId: testLearner,
              objectiveId: 'lo_init',
              attemptCount: 3,
              correctCount: 1),
          'lo_extra': LearnerProgress(
              learnerId: testLearner,
              objectiveId: 'lo_extra',
              attemptCount: 4,
              correctCount: 4),
        },
      );
      await deviceBRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateB));
      await deviceBSync.queueLocalStateChange(stateB, deviceId: testDeviceB);

      // Device B syncs -> detects conflict, merges to rev 3
      final resultB = await deviceBSync.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceB);
      expect(resultB.conflictsResolved, equals(1));
      expect(resultB.localRevision, equals(3));

      // Now Device A syncs again -> pulls rev 3
      await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);
      final finalA =
          await localStateRepo.load(learnerId: testLearner, examId: testExam);
      final finalB =
          await deviceBRepo.load(learnerId: testLearner, examId: testExam);

      expect(finalA?.revision, equals(3));
      expect(finalB?.revision, equals(3));
      expect(finalA?.stateFingerprint, equals(finalB?.stateFingerprint));
    });

    // 27. duplicate synchronization request
    test('27. repeated duplicate synchronization requests do not mutate state',
        () async {
      final state = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));
      await syncService.queueLocalStateChange(state, deviceId: testDeviceA);

      final r1 = await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);
      final r2 = await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);

      expect(r1.status, equals(SyncStatus.synced));
      expect(r2.status, equals(SyncStatus.synced));
      expect(r2.itemsSynced, equals(0)); // Nothing new to push
    });

    // 28. offline -> online transition
    test('28. offline -> online transition flushes all pending outbox records',
        () async {
      remoteRepo.setOnline(false);

      final state = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));
      await syncService.queueLocalStateChange(state, deviceId: testDeviceA);

      // Check pending
      final pendingBefore = await outboxRepo.peekPending(
          learnerId: testLearner, examId: testExam);
      expect(pendingBefore.length, equals(1));

      // Transition online
      remoteRepo.setOnline(true);
      final result = await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);

      expect(result.status, equals(SyncStatus.synced));
      expect(result.itemsSynced, equals(1));

      final pendingAfter = await outboxRepo.peekPending(
          learnerId: testLearner, examId: testExam);
      expect(pendingAfter.isEmpty, isTrue);
    });

    // 29. local state survives remote failure
    test('29. local state survives remote fatal crash without progress loss',
        () async {
      final state = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        progressMap: {
          'lo_critical': LearnerProgress(
              learnerId: testLearner,
              objectiveId: 'lo_critical',
              attemptCount: 12,
              correctCount: 10),
        },
      );
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));
      await syncService.queueLocalStateChange(state, deviceId: testDeviceA);

      // Remote throws internal error
      remoteRepo.failNextRequestWith('Fatal Cloud Service Exception');
      await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);

      // Local state is untouched and completely valid
      final localPersisted =
          await localStateRepo.load(learnerId: testLearner, examId: testExam);
      expect(localPersisted?.revision, equals(2));
      expect(
          localPersisted?.progressMap['lo_critical']?.attemptCount, equals(12));
    });

    // 30. complete end-to-end offline-to-online learner journey
    test('30. complete end-to-end offline-to-online learner journey', () async {
      // 1. Initial online sync
      final init = buildState(
          learnerId: testLearner,
          examId: testExam,
          revision: 1,
          progressMap: {});
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(init));
      await syncService.queueLocalStateChange(init, deviceId: testDeviceA);
      await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);

      // 2. Disconnect remote
      remoteRepo.setOnline(false);

      // 3. Learner performs 3 practice objectives offline
      final offlineProg = {
        'lo_preamble': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_preamble',
            attemptCount: 5,
            correctCount: 5,
            status: LearnerObjectiveStatus.achieved),
        'lo_fr': LearnerProgress(
            learnerId: testLearner,
            objectiveId: 'lo_fr',
            attemptCount: 4,
            correctCount: 3,
            status: LearnerObjectiveStatus.inProgress),
      };
      final offlineState = buildState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        progressMap: offlineProg,
        processedSessionIds: {'session_offline_01'},
      );
      await localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(
              offlineState));
      await syncService.queueLocalStateChange(offlineState,
          deviceId: testDeviceA);

      // Offline sync reports pending
      final offlineResult = await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);
      expect(offlineResult.isOffline, isTrue);

      // 4. Remote reconnects
      remoteRepo.setOnline(true);

      // 5. Sync flushes outbox and updates remote
      final onlineResult = await syncService.sync(
          learnerId: testLearner, examId: testExam, deviceId: testDeviceA);
      expect(onlineResult.status, equals(SyncStatus.synced));
      expect(onlineResult.itemsSynced, equals(1));

      // 6. Verify remote state matches local offline learning exactly
      final remoteState =
          await remoteRepo.fetchState(learnerId: testLearner, examId: testExam);
      expect(remoteState.state?.revision, equals(2));
      expect(remoteState.state?.progressMap['lo_preamble']?.status,
          equals(LearnerObjectiveStatus.achieved));
      expect(remoteState.state?.processedSessionIds,
          contains('session_offline_01'));
    });
  });
}
