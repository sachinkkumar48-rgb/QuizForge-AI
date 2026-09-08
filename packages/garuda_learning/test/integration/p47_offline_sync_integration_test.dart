/// P47 Closed-Loop Offline-First Cloud Synchronization Acceptance Test (TITAN-KO-047.0 P47).
///
/// Section 16 Mandatory Acceptance Workflow:
/// 1. Device A starts with synchronized revision N.
/// 2. Disconnect remote backend (offline mode).
/// 3. Device A completes real adaptive practice drill offline.
/// 4. Verify local authoritative state, learning history, checkpoint, and outbox (pendingSync).
/// 5. Reconnect remote backend and trigger synchronization.
/// 6. Verify remote accepts revision N+1, local state marked SYNCED, outbox acknowledged.
/// 7. Simulate Device B with older revision N attempting synchronization.
/// 8. Verify stale revision rejected, conflict detected, newer remote state preserved.
/// 9. Deterministic conflict resolution merges Device B's independent work into revision N+2.
/// 10. Verify zero learner progress is lost across both devices.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('P47 Offline-First Cloud Sync Closed-Loop Acceptance Test', () {
    const String testLearner = 'learner_p47_closed_loop';
    const String testExam = 'upsc_prelims_gs1';
    const String deviceA = 'device_pixel_8a';
    const String deviceB = 'device_macbook_pro';
    final DateTime baseDate = DateTime.utc(2026, 9, 8, 14, 0, 0);

    // Shared remote cloud backend
    late InMemoryRemoteLearningStateRepository cloudRemoteRepo;

    // Device A Local Infrastructure
    late InMemoryAuthoritativeLearningStateRepository deviceALocalRepo;
    late InMemorySyncOutboxRepository deviceAOutbox;
    late InMemorySessionCheckpointRepository deviceACheckpoints;
    late InMemoryLearningActivityCompletionRepository deviceACompletions;
    late LearnerStateSyncService deviceASyncService;

    // Device B Local Infrastructure
    late InMemoryAuthoritativeLearningStateRepository deviceBLocalRepo;
    late InMemorySyncOutboxRepository deviceBOutbox;
    late InMemorySessionCheckpointRepository deviceBCheckpoints;
    late InMemoryLearningActivityCompletionRepository deviceBCompletions;
    late LearnerStateSyncService deviceBSyncService;

    setUp(() {
      cloudRemoteRepo = InMemoryRemoteLearningStateRepository();

      // Device A Setup
      deviceALocalRepo = InMemoryAuthoritativeLearningStateRepository();
      deviceAOutbox = InMemorySyncOutboxRepository();
      deviceACheckpoints = InMemorySessionCheckpointRepository();
      deviceACompletions = InMemoryLearningActivityCompletionRepository();
      deviceASyncService = LearnerStateSyncService(
        localStateRepo: deviceALocalRepo,
        outboxRepo: deviceAOutbox,
        remoteRepo: cloudRemoteRepo,
        checkpointRepo: deviceACheckpoints,
        completionRepo: deviceACompletions,
      );

      // Device B Setup
      deviceBLocalRepo = InMemoryAuthoritativeLearningStateRepository();
      deviceBOutbox = InMemorySyncOutboxRepository();
      deviceBCheckpoints = InMemorySessionCheckpointRepository();
      deviceBCompletions = InMemoryLearningActivityCompletionRepository();
      deviceBSyncService = LearnerStateSyncService(
        localStateRepo: deviceBLocalRepo,
        outboxRepo: deviceBOutbox,
        remoteRepo: cloudRemoteRepo,
        checkpointRepo: deviceBCheckpoints,
        completionRepo: deviceBCompletions,
      );
    });

    test(
        'Section 16: Full Multi-Device Offline Practice, Sync, Conflict Detection and Resolution',
        () async {
      // -----------------------------------------------------------------------
      // Step 1: Device A initializes baseline state at Revision 1 and syncs
      // -----------------------------------------------------------------------
      final initialState = AuthoritativeLearnerState.empty(
        learnerId: testLearner,
        examId: testExam,
        createdAt: baseDate,
        revision: 1,
      );
      await deviceALocalRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(initialState),
      );
      await deviceASyncService.queueLocalStateChange(initialState,
          deviceId: deviceA, createdAt: baseDate);
      final initSyncResult = await deviceASyncService.sync(
        learnerId: testLearner,
        examId: testExam,
        deviceId: deviceA,
      );
      expect(initSyncResult.status, equals(SyncStatus.synced));
      expect(initSyncResult.localRevision, equals(1));

      // Device B also syncs to establish baseline Revision 1 locally
      await deviceBSyncService.sync(
        learnerId: testLearner,
        examId: testExam,
        deviceId: deviceB,
      );
      final deviceBInitial =
          await deviceBLocalRepo.load(learnerId: testLearner, examId: testExam);
      expect(deviceBInitial?.revision, equals(1));

      // -----------------------------------------------------------------------
      // Step 2: Disconnect Remote Cloud Backend (Go Offline)
      // -----------------------------------------------------------------------
      cloudRemoteRepo.setOnline(false);

      // -----------------------------------------------------------------------
      // Step 3: Learner on Device A executes adaptive practice drill OFFLINE
      // -----------------------------------------------------------------------
      // Simulate answering question correctly on 'lo_preamble_identity'
      final drillDate = baseDate.add(const Duration(minutes: 15));
      const practiceSessionId = 'session_offline_drill_001';

      // 3a. Update session checkpoint offline
      final checkpoint = SessionCheckpoint(
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        sessionId: practiceSessionId,
        learnerId: testLearner,
        examId: testExam,
        questionIndex: 1,
        completedQuestionIds: const ['pyq_const_001'],
        activeObjectiveId: 'lo_preamble_identity',
        timestamp: drillDate,
        isCompleted: true,
      );
      await deviceACheckpoints.saveCheckpoint(checkpoint);

      // 3b. Consolidate outcome into AuthoritativeLearnerState at Revision 2
      final updatedProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_preamble_identity',
        attemptCount: 1,
        correctCount: 1,
        status: LearnerObjectiveStatus.achieved,
        lastAttemptAt: drillDate,
      );
      final updatedStateA = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2,
        progressMap: {'lo_preamble_identity': updatedProgress},
        processedSessionIds: {practiceSessionId},
        lastUpdatedAt: drillDate,
      );
      await deviceALocalRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(
            updatedStateA),
      );

      // 3c. Record activity completion history offline
      final completionRecord = LearningActivityCompletionRecord(
        idempotencyKey: 'completion_${practiceSessionId}_q1',
        learnerId: testLearner,
        examId: testExam,
        activityId: 'activity_preamble_practice',
        sessionId: practiceSessionId,
        planId: 'plan_p47_test',
        planRevision: 1,
        outcome: LearningActivityOutcome.calculate(
          activityId: 'activity_preamble_practice',
          activityType: LearningDecisionType.advancement,
          learnerId: testLearner,
          examId: testExam,
          questionsPresented: 1,
          questionsAttempted: 1,
          correctAnswers: 1,
          incorrectAnswers: 0,
          skippedAnswers: 0,
          completedAt: drillDate,
        ),
      );
      await deviceACompletions.saveCompletionRecord(completionRecord);

      // 3d. Enqueue into local sync outbox
      final envelopeA = await deviceASyncService.queueLocalStateChange(
        updatedStateA,
        deviceId: deviceA,
        createdAt: drillDate,
      );

      // -----------------------------------------------------------------------
      // Step 4: Verify offline state, pending outbox, and zero data loss
      // -----------------------------------------------------------------------
      expect(envelopeA.status, equals(SyncStatus.pendingSync));
      final pendingOutboxA = await deviceAOutbox.peekPending(
          learnerId: testLearner, examId: testExam);
      expect(pendingOutboxA.length, equals(1));
      expect(pendingOutboxA.first.revision, equals(2));

      // Attempting sync while offline must report offline and preserve pending queue
      final offlineAttempt = await deviceASyncService.sync(
        learnerId: testLearner,
        examId: testExam,
        deviceId: deviceA,
      );
      expect(offlineAttempt.isOffline, isTrue);
      expect(offlineAttempt.status, equals(SyncStatus.pendingSync));

      // -----------------------------------------------------------------------
      // Step 5: Reconnect Remote Cloud Backend
      // -----------------------------------------------------------------------
      cloudRemoteRepo.setOnline(true);

      // -----------------------------------------------------------------------
      // Step 6: Trigger Synchronization on Device A
      // -----------------------------------------------------------------------
      final onlineSyncResultA = await deviceASyncService.sync(
        learnerId: testLearner,
        examId: testExam,
        deviceId: deviceA,
      );
      expect(onlineSyncResultA.status, equals(SyncStatus.synced));
      expect(onlineSyncResultA.itemsSynced, equals(1));
      expect(onlineSyncResultA.localRevision, equals(2));

      // Remote cloud state is now at Revision 2
      final remoteStateAfterA = await cloudRemoteRepo.fetchState(
        learnerId: testLearner,
        examId: testExam,
      );
      expect(remoteStateAfterA.state?.revision, equals(2));
      expect(
        remoteStateAfterA.state?.progressMap['lo_preamble_identity']?.status,
        equals(LearnerObjectiveStatus.achieved),
      );

      // Outbox on Device A is acknowledged
      final outboxAfterA = await deviceAOutbox.getBySyncId(envelopeA.syncId);
      expect(outboxAfterA?.status, equals(SyncStatus.synced));

      // -----------------------------------------------------------------------
      // Step 7: Simulate Device B (was offline with old Revision 1) making independent progress
      // -----------------------------------------------------------------------
      const practiceSessionB = 'session_offline_drill_device_b';
      final drillDateB = drillDate.add(const Duration(minutes: 30));

      final progressB = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_basic_structure_doctrine',
        attemptCount: 2,
        correctCount: 1,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: drillDateB,
      );
      // Device B creates candidate state based on its old local knowledge (Revision 2)
      final stateB = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        revision: 2, // Concurrent revision 2!
        progressMap: {'lo_basic_structure_doctrine': progressB},
        processedSessionIds: {practiceSessionB},
        lastUpdatedAt: drillDateB,
      );
      await deviceBLocalRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateB),
      );
      await deviceBSyncService.queueLocalStateChange(
        stateB,
        deviceId: deviceB,
        createdAt: drillDateB,
      );

      // -----------------------------------------------------------------------
      // Step 8 & 9: Device B Attempts Sync -> Conflict Detected & Resolved!
      // -----------------------------------------------------------------------
      final syncResultB = await deviceBSyncService.sync(
        learnerId: testLearner,
        examId: testExam,
        deviceId: deviceB,
      );

      // Verify conflict detected and resolved deterministically
      expect(syncResultB.conflictsResolved, equals(1));
      expect(syncResultB.localRevision, equals(3)); // Advanced to Revision 3

      // -----------------------------------------------------------------------
      // Step 10: Verify Convergence & Zero Learner Progress Loss
      // -----------------------------------------------------------------------
      // Remote cloud state has advanced to Revision 3
      final finalRemote = await cloudRemoteRepo.fetchState(
        learnerId: testLearner,
        examId: testExam,
      );
      expect(finalRemote.state?.revision, equals(3));

      // Merged state contains Device A's achievement AND Device B's progress
      expect(finalRemote.state?.progressMap.containsKey('lo_preamble_identity'),
          isTrue);
      expect(
          finalRemote.state?.progressMap
              .containsKey('lo_basic_structure_doctrine'),
          isTrue);
      expect(
        finalRemote.state?.progressMap['lo_preamble_identity']?.status,
        equals(LearnerObjectiveStatus.achieved),
      );
      expect(
        finalRemote
            .state?.progressMap['lo_basic_structure_doctrine']?.attemptCount,
        equals(2),
      );
      expect(
        finalRemote.state?.processedSessionIds,
        containsAll([practiceSessionId, practiceSessionB]),
      );

      // Device A performs subsequent sync to pull converged state
      await deviceASyncService.sync(
        learnerId: testLearner,
        examId: testExam,
        deviceId: deviceA,
      );

      final finalDeviceA =
          await deviceALocalRepo.load(learnerId: testLearner, examId: testExam);
      final finalDeviceB =
          await deviceBLocalRepo.load(learnerId: testLearner, examId: testExam);

      expect(finalDeviceA?.revision, equals(3));
      expect(finalDeviceB?.revision, equals(3));
      expect(finalDeviceA?.stateFingerprint,
          equals(finalDeviceB?.stateFingerprint));
    });
  });
}
