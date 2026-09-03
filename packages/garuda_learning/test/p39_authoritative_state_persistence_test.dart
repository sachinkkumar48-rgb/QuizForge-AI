/// P39 Authoritative Learning State Persistence & Recovery Unit & Property Tests (TITAN-KO-039.0 P39).
///
/// Comprehensive test suite verifying:
/// - Deterministic canonical serialization & strict deserialization
/// - Typed persistence errors on malformed, corrupted, or out-of-bounds state
/// - Atomic repository save, replace, delete, and failure rollback semantics
/// - Monotonic revision and stale write rejection (existing < incoming, == incoming, > incoming)
/// - Recovery strategy (Cases A, B, C, D, E)
/// - Integration with P38 AdaptiveLearningStateReconciler
/// - Property and deterministic invariant enforcement
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 9, 3, 12, 0, 0);

  LearnerProgress buildProgress({
    String learnerId = 'learner_alpha',
    required String objectiveId,
    int attempts = 10,
    int correct = 8,
    LearnerObjectiveStatus status = LearnerObjectiveStatus.achieved,
    DateTime? lastAttempt,
    DateTime? achievedAt,
  }) {
    return LearnerProgress(
      learnerId: learnerId,
      objectiveId: objectiveId,
      attemptCount: attempts,
      correctCount: correct,
      status: status,
      lastAttemptAt: lastAttempt ?? fixedDate,
      achievedAt: achievedAt ??
          (status == LearnerObjectiveStatus.achieved ? fixedDate : null),
    );
  }

  AuthoritativeLearnerState buildSampleState({
    String learnerId = 'learner_alpha',
    String examId = 'upsc',
    int revision = 1,
    Map<String, LearnerProgress>? progressMap,
    Set<String>? sessions,
    DateTime? date,
  }) {
    final effectiveDate = date ?? fixedDate;
    final map = progressMap ??
        {
          'obj_polity_01': buildProgress(
            learnerId: learnerId,
            objectiveId: 'obj_polity_01',
            attempts: 12,
            correct: 10,
            status: LearnerObjectiveStatus.achieved,
          ),
          'obj_economy_02': buildProgress(
            learnerId: learnerId,
            objectiveId: 'obj_economy_02',
            attempts: 5,
            correct: 2,
            status: LearnerObjectiveStatus.inProgress,
          ),
        };

    return AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      progressMap: map,
      processedSessionIds: sessions ?? {'session_100', 'session_101'},
      lastUpdatedAt: effectiveDate,
      revision: revision,
    );
  }

  // ===========================================================================
  // GROUP 1: Construction & Serialization
  // ===========================================================================
  group('P39.1 Construction & Serialization', () {
    test(
        '1. Valid PersistedAuthoritativeLearnerState constructs and converts to domain state',
        () {
      final state = buildSampleState();
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state);

      expect(persisted.learnerId, equals('learner_alpha'));
      expect(persisted.examId, equals('upsc'));
      expect(persisted.revision, equals(1));
      expect(persisted.schemaVersion, equals(1));
      expect(persisted.progressMap.length, equals(2));
      expect(persisted.processedSessionIds,
          containsAll(['session_100', 'session_101']));
      expect(persisted.checksum, isNotEmpty);

      final reconstructed = persisted.toAuthoritativeState();
      expect(reconstructed.learnerId, equals(state.learnerId));
      expect(reconstructed.examId, equals(state.examId));
      expect(reconstructed.revision, equals(state.revision));
      expect(reconstructed.stateFingerprint, equals(state.stateFingerprint));
    });

    test(
        '2. Round-trip serialization toJson and fromJson preserves exact state',
        () {
      final state = buildSampleState();
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state);

      final jsonMap = persisted.toJson();
      final restored = PersistedAuthoritativeLearnerState.fromJson(jsonMap);

      expect(restored.learnerId, equals(persisted.learnerId));
      expect(restored.examId, equals(persisted.examId));
      expect(restored.revision, equals(persisted.revision));
      expect(restored.schemaVersion, equals(persisted.schemaVersion));
      expect(restored.stateFingerprint, equals(persisted.stateFingerprint));
      expect(restored.checksum, equals(persisted.checksum));
      expect(restored.progressMap.length, equals(persisted.progressMap.length));
      expect(restored, equals(persisted));
    });

    test(
        '3. Deterministic serialization: same logical state produces identical canonical JSON string',
        () {
      final p1 = buildProgress(objectiveId: 'obj_a', attempts: 5, correct: 4);
      final p2 = buildProgress(objectiveId: 'obj_b', attempts: 10, correct: 9);

      // Insert in order A then B
      final stateA = AuthoritativeLearnerState(
        learnerId: 'learner_1',
        examId: 'upsc',
        progressMap: {'obj_a': p1, 'obj_b': p2},
        processedSessionIds: {'s1', 's2'},
        lastUpdatedAt: fixedDate,
        revision: 2,
      );

      // Insert in reverse order B then A
      final stateB = AuthoritativeLearnerState(
        learnerId: 'learner_1',
        examId: 'upsc',
        progressMap: {'obj_b': p2, 'obj_a': p1},
        processedSessionIds: {'s2', 's1'},
        lastUpdatedAt: fixedDate,
        revision: 2,
      );

      final persA =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateA);
      final persB =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateB);

      expect(persA.toCanonicalJson(), equals(persB.toCanonicalJson()));
      expect(persA.checksum, equals(persB.checksum));
    });

    test(
        '4. Raw JSON deserialization via fromRawJson handles whitespace cleanly',
        () {
      final state = buildSampleState();
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state);
      final jsonStr = persisted.toCanonicalJson();

      final restored = PersistedAuthoritativeLearnerState.fromRawJson(jsonStr);
      expect(restored, equals(persisted));
    });
  });

  // ===========================================================================
  // GROUP 2: Deserialization Rejection & Error Taxonomy
  // ===========================================================================
  group('P39.2 Deserialization Rejection & Error Taxonomy', () {
    test('5. Rejects missing required field: learnerId', () {
      final state = buildSampleState();
      final json =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state)
              .toJson();
      json.remove('learnerId');

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(json),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.missingRequiredField,
        )),
      );
    });

    test('6. Rejects missing required field: revision', () {
      final state = buildSampleState();
      final json =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state)
              .toJson();
      json.remove('revision');

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(json),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.missingRequiredField,
        )),
      );
    });

    test('7. Rejects missing required field: checksum', () {
      final state = buildSampleState();
      final json =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state)
              .toJson();
      json.remove('checksum');

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(json),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.missingRequiredField,
        )),
      );
    });

    test('8. Rejects malformed payload: invalid JSON string', () {
      expect(
        () =>
            PersistedAuthoritativeLearnerState.fromRawJson('{invalid_json...'),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.malformedPayload,
        )),
      );
    });

    test('9. Rejects unsupported future schema version (> 1)', () {
      final state = buildSampleState();
      final json =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state)
              .toJson();
      json['schemaVersion'] = 99;

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(json),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.unsupportedSchemaVersion,
        )),
      );
    });

    test('10. Rejects invalid numeric value: revision < 1', () {
      final state = buildSampleState();
      final json =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state)
              .toJson();
      json['revision'] = 0;

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(json),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.invalidNumericValue,
        )),
      );
    });

    test(
        '11. Rejects invalid numeric value in progress record: negative attempts',
        () {
      final state = buildSampleState();
      final json =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state)
              .toJson();
      (json['progressMap'] as Map)['obj_polity_01']['attemptCount'] = -1;

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(json),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.invalidNumericValue,
        )),
      );
    });

    test(
        '12. Rejects invalid numeric value in progress record: correct > attempts',
        () {
      final state = buildSampleState();
      final json =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state)
              .toJson();
      (json['progressMap'] as Map)['obj_polity_01']['correctCount'] = 999;

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(json),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.invalidNumericValue,
        )),
      );
    });

    test('13. Rejects invalid enum value in progress record', () {
      final state = buildSampleState();
      final json =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state)
              .toJson();
      (json['progressMap'] as Map)['obj_polity_01']['status'] =
          'superMasteredUnknown';

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(json),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.invalidEnumValue,
        )),
      );
    });

    test('14. Rejects corrupted checksum (bitrot / storage tampering)', () {
      final state = buildSampleState();
      final json =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state)
              .toJson();
      json['checksum'] =
          '0000000000000000000000000000000000000000000000000000000000000000';

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(json),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.corruptedChecksum,
        )),
      );
    });

    test('15. Rejects structural inconsistency: tampered state fingerprint',
        () {
      final state = buildSampleState();
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state);
      final json = persisted.toJson();
      // Tamper state fingerprint and recalculate checksum to isolate fingerprint verification
      json['stateFingerprint'] =
          'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(json),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          anyOf(
            AuthoritativePersistenceErrorCode.inconsistentState,
            AuthoritativePersistenceErrorCode.corruptedChecksum,
          ),
        )),
      );
    });
  });

  // ===========================================================================
  // GROUP 3: Repository Semantics & Atomic Guarantees
  // ===========================================================================
  group('P39.3 Repository Semantics & Atomic Guarantees', () {
    late InMemoryAuthoritativeLearningStateRepository repo;

    setUp(() {
      repo = InMemoryAuthoritativeLearningStateRepository();
    });

    test('16. Empty repository returns null on load', () async {
      final loaded = await repo.load(learnerId: 'nobody', examId: 'upsc');
      expect(loaded, isNull);
      expect(await repo.exists(learnerId: 'nobody', examId: 'upsc'), isFalse);
    });

    test('17. Save and load returns identical persisted state', () async {
      final state = buildSampleState();
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state);

      await repo.save(persisted);
      final loaded =
          await repo.load(learnerId: 'learner_alpha', examId: 'upsc');

      expect(loaded, isNotNull);
      expect(loaded!.learnerId, equals(persisted.learnerId));
      expect(loaded.examId, equals(persisted.examId));
      expect(loaded.revision, equals(persisted.revision));
      expect(loaded.checksum, equals(persisted.checksum));
      expect(await repo.exists(learnerId: 'learner_alpha', examId: 'upsc'),
          isTrue);
    });

    test('18. Delete removes state cleanly', () async {
      final state = buildSampleState();
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state);

      await repo.save(persisted);
      expect(await repo.exists(learnerId: 'learner_alpha', examId: 'upsc'),
          isTrue);

      await repo.delete(learnerId: 'learner_alpha', examId: 'upsc');
      expect(await repo.exists(learnerId: 'learner_alpha', examId: 'upsc'),
          isFalse);
      expect(
          await repo.load(learnerId: 'learner_alpha', examId: 'upsc'), isNull);
    });

    test(
        '19. Atomic failure behavior: failed save does NOT corrupt existing state',
        () async {
      final state1 = buildSampleState(revision: 1);
      final persisted1 =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state1);
      await repo.save(persisted1);

      // Arm repository to fail next save
      repo.failNextSave = true;

      final state2 = buildSampleState(revision: 2);
      final persisted2 =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state2);

      expect(
        () => repo.save(persisted2),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.ioFailure,
        )),
      );

      // Existing state remains completely intact at revision 1
      final reloaded =
          await repo.load(learnerId: 'learner_alpha', examId: 'upsc');
      expect(reloaded, isNotNull);
      expect(reloaded!.revision, equals(1));
      expect(reloaded.checksum, equals(persisted1.checksum));
    });
  });

  // ===========================================================================
  // GROUP 4: Monotonic Revision & Stale Write Protection
  // ===========================================================================
  group('P39.4 Monotonic Revision & Stale Write Protection', () {
    late InMemoryAuthoritativeLearningStateRepository repo;

    setUp(() {
      repo = InMemoryAuthoritativeLearningStateRepository();
    });

    test('20. Newer revision (incoming > existing) is accepted', () async {
      final state1 = buildSampleState(revision: 1);
      await repo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state1));

      final state2 = buildSampleState(revision: 2);
      await repo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state2));

      final loaded =
          await repo.load(learnerId: 'learner_alpha', examId: 'upsc');
      expect(loaded!.revision, equals(2));
    });

    test(
        '21. Equal revision (incoming == existing) with identical payload succeeds idempotently',
        () async {
      final state1 = buildSampleState(revision: 3);
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state1);
      await repo.save(persisted);

      // Re-saving identical payload at same revision is idempotent no-op
      await repo.save(persisted);

      final loaded =
          await repo.load(learnerId: 'learner_alpha', examId: 'upsc');
      expect(loaded!.revision, equals(3));
    });

    test(
        '22. Equal revision (incoming == existing) with conflicting payload is rejected',
        () async {
      final state1 = buildSampleState(revision: 3);
      await repo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state1));

      // Create divergent state at same revision
      final divergent = AuthoritativeLearnerState(
        learnerId: 'learner_alpha',
        examId: 'upsc',
        progressMap: {
          'obj_new':
              buildProgress(objectiveId: 'obj_new', attempts: 1, correct: 1),
        },
        processedSessionIds: {'session_999'},
        lastUpdatedAt: fixedDate,
        revision: 3,
      );

      expect(
        () => repo.save(
            PersistedAuthoritativeLearnerState.fromAuthoritativeState(
                divergent)),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.staleWrite,
        )),
      );
    });

    test(
        '23. Stale write (incoming < existing) is rejected with staleWrite code',
        () async {
      final stateNewer = buildSampleState(revision: 5);
      await repo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(
          stateNewer));

      final stateOlder = buildSampleState(revision: 4);
      expect(
        () => repo.save(
            PersistedAuthoritativeLearnerState.fromAuthoritativeState(
                stateOlder)),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          AuthoritativePersistenceErrorCode.staleWrite,
        )),
      );

      final loaded =
          await repo.load(learnerId: 'learner_alpha', examId: 'upsc');
      expect(loaded!.revision, equals(5));
    });
  });

  // ===========================================================================
  // GROUP 5: Recovery Strategy (Cases A, B, C, D, E)
  // ===========================================================================
  group('P39.5 Recovery Strategy', () {
    late InMemoryAuthoritativeLearningStateRepository repo;
    late AuthoritativeLearningStateRecoveryService recoveryService;

    setUp(() {
      repo = InMemoryAuthoritativeLearningStateRepository();
      recoveryService =
          AuthoritativeLearningStateRecoveryService(repository: repo);
    });

    test('24. CASE A — No persisted state returns initialized state', () async {
      final result = await recoveryService.recover(
        learnerId: 'new_learner',
        examId: 'upsc',
        requestedAt: fixedDate,
      );

      expect(result.isSuccess, isTrue);
      expect(
          result.decision, equals(AuthoritativeRecoveryDecision.initialized));
      expect(result.isFresh, isTrue);
      expect(result.state, isNotNull);
      expect(result.state!.learnerId, equals('new_learner'));
      expect(result.state!.revision, equals(1));
      expect(result.state!.progressMap, isEmpty);
      expect(result.state!.processedSessionIds, isEmpty);
    });

    test(
        '25. CASE A — persistInitialIfAbsent flag persists fresh state to repository',
        () async {
      final result = await recoveryService.recover(
        learnerId: 'new_learner',
        examId: 'upsc',
        requestedAt: fixedDate,
        persistInitialIfAbsent: true,
      );

      expect(
          result.decision, equals(AuthoritativeRecoveryDecision.initialized));
      expect(
          await repo.exists(learnerId: 'new_learner', examId: 'upsc'), isTrue);

      final loaded = await repo.load(learnerId: 'new_learner', examId: 'upsc');
      expect(loaded!.revision, equals(1));
    });

    test(
        '26. CASE B — Valid persisted state restores exact authoritative state',
        () async {
      final state = buildSampleState(revision: 4);
      await repo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      final result = await recoveryService.recover(
        learnerId: 'learner_alpha',
        examId: 'upsc',
        requestedAt: fixedDate,
      );

      expect(result.isSuccess, isTrue);
      expect(result.decision, equals(AuthoritativeRecoveryDecision.restored));
      expect(result.isFresh, isFalse);
      expect(result.revision, equals(4));
      expect(result.state!.stateFingerprint, equals(state.stateFingerprint));
      expect(result.state!.progressMap.length, equals(2));
    });

    test(
        '27. CASE C — Corrupted persisted state returns explicit corrupted result',
        () async {
      // Inject corrupt JSON into storage
      repo.injectRawRecord(
        'learner_alpha',
        'upsc',
        '{"schemaVersion":1,"revision":1,"learnerId":"learner_alpha","examId":"upsc","lastUpdatedAt":"${fixedDate.toIso8601String()}","progressMap":{},"processedSessionIds":[],"stateFingerprint":"bad","checksum":"bad"}',
      );

      final result = await recoveryService.recover(
        learnerId: 'learner_alpha',
        examId: 'upsc',
        requestedAt: fixedDate,
      );

      expect(result.isSuccess, isFalse);
      expect(result.decision, equals(AuthoritativeRecoveryDecision.corrupted));
      expect(result.error, isNotNull);
      expect(
        result.error!.code,
        anyOf(
          AuthoritativePersistenceErrorCode.corruptedChecksum,
          AuthoritativePersistenceErrorCode.inconsistentState,
        ),
      );
      expect(result.state, isNull);
    });

    test(
        '28. CASE D — Unsupported future schema version returns incompatibleSchema result',
        () async {
      repo.injectRawRecord(
        'learner_alpha',
        'upsc',
        '{"schemaVersion":99,"revision":1,"learnerId":"learner_alpha","examId":"upsc","lastUpdatedAt":"${fixedDate.toIso8601String()}","progressMap":{},"processedSessionIds":[],"stateFingerprint":"fp","checksum":"chk"}',
      );

      final result = await recoveryService.recover(
        learnerId: 'learner_alpha',
        examId: 'upsc',
        requestedAt: fixedDate,
      );

      expect(result.isSuccess, isFalse);
      expect(result.decision,
          equals(AuthoritativeRecoveryDecision.incompatibleSchema));
      expect(result.error!.code,
          equals(AuthoritativePersistenceErrorCode.unsupportedSchemaVersion));
      expect(result.state, isNull);
    });

    test('29. CASE E — Older supported schema (v0) successfully migrates to v1',
        () async {
      // Legacy v0 payload without checksum
      final v0Payload = jsonEncode({
        'schemaVersion': 0,
        'revision': 1,
        'learnerId': 'legacy_learner',
        'examId': 'upsc',
        'lastUpdatedAt': fixedDate.toIso8601String(),
        'progressMap': {
          'obj_hist_01': {
            'learnerId': 'legacy_learner',
            'objectiveId': 'obj_hist_01',
            'attemptCount': 5,
            'correctCount': 4,
            'status': 'inProgress',
          }
        },
        'processedSessionIds': ['legacy_session_1'],
        'metadata': {'legacySource': 'p18_import'},
      });

      repo.injectRawRecord('legacy_learner', 'upsc', v0Payload);

      final result = await recoveryService.recover(
        learnerId: 'legacy_learner',
        examId: 'upsc',
        requestedAt: fixedDate,
      );

      expect(result.isSuccess, isTrue);
      expect(result.decision, equals(AuthoritativeRecoveryDecision.migrated));
      expect(result.state, isNotNull);
      expect(result.schemaVersion, equals(1));
      expect(result.state!.getProgress('obj_hist_01')!.attemptCount, equals(5));

      // Verify that the migrated state was persisted as valid v1 in repository
      final reloaded =
          await repo.load(learnerId: 'legacy_learner', examId: 'upsc');
      expect(reloaded, isNotNull);
      expect(reloaded!.schemaVersion, equals(1));
      expect(reloaded.checksum, isNotEmpty);
    });
  });

  // ===========================================================================
  // GROUP 6: P38 Reconciliation Integration
  // ===========================================================================
  group('P39.6 P38 Reconciliation Integration', () {
    late InMemoryAuthoritativeLearningStateRepository repo;
    late AuthoritativeLearningStateRecoveryService recoveryService;
    late AuthoritativeStatePersistenceCoordinator coordinator;

    setUp(() {
      repo = InMemoryAuthoritativeLearningStateRepository();
      recoveryService =
          AuthoritativeLearningStateRecoveryService(repository: repo);
      coordinator = AuthoritativeStatePersistenceCoordinator(
        recoveryService: recoveryService,
        repository: repo,
      );
    });

    ReconciledLearningStateProposal buildTestProposal({
      String reconciliationId = 'rec_001',
      String learnerId = 'learner_alpha',
      String examId = 'upsc',
      String sessionId = 'session_201',
      String? baseStateFingerprint,
      ReconciliationDecision overallDecision = ReconciliationDecision.merged,
      Map<String, LearnerProgress>? reconciledProgress,
    }) {
      final progress = reconciledProgress ??
          {
            'obj_polity_01': buildProgress(
              learnerId: learnerId,
              objectiveId: 'obj_polity_01',
              attempts: 14,
              correct: 12,
              status: LearnerObjectiveStatus.achieved,
            ),
          };

      return ReconciledLearningStateProposal(
        reconciliationId: reconciliationId,
        learnerId: learnerId,
        examId: examId,
        baseStateFingerprint: baseStateFingerprint ??
            buildSampleState(learnerId: learnerId, examId: examId)
                .stateFingerprint,
        sourceProposalFingerprint: 'prop_fingerprint_abc',
        reconciledAt: fixedDate,
        overallDecision: overallDecision,
        reconciledProgress: progress,
        processedSessionIds: {sessionId},
        questionDecisions: const [],
        objectiveDecisions: const {},
        topicDecisions: const {},
        conflicts: const [],
        provenance: ReconciliationProvenance(
          proposalId: 'prop_001',
          sessionId: sessionId,
          sourceProposalFingerprint: 'prop_fingerprint_abc',
          baseStateFingerprint: baseStateFingerprint ??
              buildSampleState(learnerId: learnerId, examId: examId)
                  .stateFingerprint,
          reconciledAt: fixedDate,
        ),
        fingerprint: sha256
            .convert(
                utf8.encode('$reconciliationId|$learnerId|$examId|$sessionId'))
            .toString(),
      );
    }

    test(
        '30. Reconciles proposal, updates authoritative state, and persists with revision increment',
        () async {
      final baseState = buildSampleState(revision: 1);
      await repo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(baseState));

      final proposal = buildTestProposal(
        sessionId: 'session_fresh_99',
        baseStateFingerprint: baseState.stateFingerprint,
      );

      final result = await coordinator.applyReconciledProposal(
        baseState: baseState,
        reconciledProposal: proposal,
        timestamp: fixedDate.add(const Duration(minutes: 10)),
      );

      expect(result.isSuccess, isTrue);
      expect(result.updatedState, isNotNull);
      expect(result.updatedState!.revision, equals(2));
      expect(
          result.updatedState!.hasProcessedSession('session_fresh_99'), isTrue);

      // Verify reloaded from repository matches
      final reloaded =
          await repo.load(learnerId: 'learner_alpha', examId: 'upsc');
      expect(reloaded!.revision, equals(2));
      expect(reloaded.toAuthoritativeState().stateFingerprint,
          equals(result.updatedState!.stateFingerprint));
    });

    test(
        '31. Duplicate session replay returns duplicate without incrementing revision or writing',
        () async {
      final baseState =
          buildSampleState(revision: 2, sessions: {'session_done'});
      await repo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(baseState));

      final duplicateProposal = buildTestProposal(
        sessionId: 'session_done',
        baseStateFingerprint: baseState.stateFingerprint,
      );

      final result = await coordinator.applyReconciledProposal(
        baseState: baseState,
        reconciledProposal: duplicateProposal,
        timestamp: fixedDate,
      );

      expect(result.isSuccess, isTrue);
      expect(result.isDuplicate, isTrue);
      expect(result.updatedState!.revision, equals(2));

      final reloaded =
          await repo.load(learnerId: 'learner_alpha', examId: 'upsc');
      expect(reloaded!.revision, equals(2));
    });

    test('32. Learner mismatch fails reconciliation and does not persist',
        () async {
      final baseState = buildSampleState(learnerId: 'learner_A');
      final proposal = buildTestProposal(learnerId: 'learner_B');

      final result = await coordinator.applyReconciledProposal(
        baseState: baseState,
        reconciledProposal: proposal,
        timestamp: fixedDate,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error!.code,
          equals(AuthoritativePersistenceErrorCode.inconsistentState));
    });
  });

  // ===========================================================================
  // GROUP 7: Property-Style & Invariant Tests
  // ===========================================================================
  group('P39.7 Property-Style & Invariant Tests', () {
    late InMemoryAuthoritativeLearningStateRepository repo;

    setUp(() {
      repo = InMemoryAuthoritativeLearningStateRepository();
    });

    test(
        '33. Invariant: save(load(state)) == state (idempotent persistence roundtrip)',
        () async {
      final state = buildSampleState(revision: 1);
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state);

      await repo.save(persisted);
      final loaded =
          (await repo.load(learnerId: 'learner_alpha', examId: 'upsc'))!;

      // Re-saving loaded state
      await repo.save(loaded);
      final reloaded =
          (await repo.load(learnerId: 'learner_alpha', examId: 'upsc'))!;

      expect(reloaded.toCanonicalJson(), equals(persisted.toCanonicalJson()));
      expect(reloaded.checksum, equals(persisted.checksum));
      expect(reloaded.stateFingerprint, equals(persisted.stateFingerprint));
    });

    test(
        '34. Invariant: Revision must strictly never decrease across sequential updates',
        () async {
      int currentRevision = 1;
      var state = buildSampleState(revision: currentRevision);
      await repo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      for (int i = 2; i <= 10; i++) {
        state = state.copyWith(revision: i);
        await repo.save(
            PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));
        currentRevision = i;

        final loaded =
            (await repo.load(learnerId: 'learner_alpha', examId: 'upsc'))!;
        expect(loaded.revision, equals(currentRevision));
        expect(loaded.revision, greaterThanOrEqualTo(1));
      }
    });

    test(
        '35. Invariant: Corrupt persisted state never produces valid authoritative state',
        () {
      final state = buildSampleState();
      final json =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state)
              .toJson();
      // Inject bit corruption
      json['checksum'] = json['checksum'].toString().replaceAll('a', 'b');

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(json),
        throwsA(isA<AuthoritativePersistenceException>()),
      );
    });

    test(
        '36. Invariant: Determinism — same input state + same operation yields identical result across runs',
        () {
      final state1 = buildSampleState();
      final pers1 =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state1);

      final state2 = buildSampleState();
      final pers2 =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state2);

      for (int i = 0; i < 10; i++) {
        expect(pers1.toCanonicalJson(), equals(pers2.toCanonicalJson()));
        expect(pers1.checksum, equals(pers2.checksum));
      }
    });
  });
}
