/// P39 Learner State Persistence & Recovery Test Suite.
///
/// Comprehensive tests covering domain models, deterministic serialization,
/// repository contracts, persistence service orchestration, recovery semantics,
/// and failure safety.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final fixedTimestamp = DateTime.utc(2026, 9, 15, 10, 0, 0);

  late InMemoryAuthoritativeLearningStateRepository repository;
  late LearnerStatePersistenceService persistenceService;

  setUp(() {
    repository = InMemoryAuthoritativeLearningStateRepository();
    persistenceService = LearnerStatePersistenceService(
      repository: repository,
    );
  });

  LearnerProgress createProgress({
    required String objectiveId,
    String learnerId = 'learner_alpha',
    int attemptCount = 3,
    int correctCount = 2,
    LearnerObjectiveStatus status = LearnerObjectiveStatus.inProgress,
  }) {
    return LearnerProgress(
      learnerId: learnerId,
      objectiveId: objectiveId,
      attemptCount: attemptCount,
      correctCount: correctCount,
      successRate: attemptCount > 0 ? correctCount / attemptCount : 0.0,
      status: status,
      lastAttemptAt: fixedTimestamp,
    );
  }

  AuthoritativeLearnerState createSampleState({
    String learnerId = 'learner_alpha',
    String examId = 'upsc',
    int revision = 1,
    Map<String, LearnerProgress>? progressMap,
    Set<String>? sessions,
    DateTime? timestamp,
  }) {
    return AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      progressMap: progressMap ??
          {
            'obj_preamble': createProgress(
                objectiveId: 'obj_preamble', learnerId: learnerId),
            'obj_rights':
                createProgress(objectiveId: 'obj_rights', learnerId: learnerId),
          },
      processedSessionIds: sessions ?? {'sess_init_1'},
      lastUpdatedAt: timestamp ?? fixedTimestamp,
      revision: revision,
    );
  }

  group('Group 1: Domain Construction & Validation', () {
    test(
        '1. Valid AuthoritativeLearnerState constructs with default revision 1',
        () {
      final state = AuthoritativeLearnerState.empty(
        learnerId: 'learner_1',
        examId: 'upsc',
        createdAt: fixedTimestamp,
      );

      expect(state.learnerId, equals('learner_1'));
      expect(state.examId, equals('upsc'));
      expect(state.revision, equals(1));
      expect(state.progressMap, isEmpty);
      expect(state.processedSessionIds, isEmpty);
      expect(state.stateFingerprint, isNotEmpty);
    });

    test('2. Rejects empty learnerId or examId with ArgumentError', () {
      expect(
        () => AuthoritativeLearnerState(
          learnerId: '',
          examId: 'upsc',
          progressMap: const {},
          lastUpdatedAt: fixedTimestamp,
        ),
        throwsArgumentError,
      );

      expect(
        () => AuthoritativeLearnerState(
          learnerId: 'learner_1',
          examId: '',
          progressMap: const {},
          lastUpdatedAt: fixedTimestamp,
        ),
        throwsArgumentError,
      );
    });

    test('3. Rejects invalid revision < 1 with ArgumentError', () {
      expect(
        () => AuthoritativeLearnerState(
          learnerId: 'learner_1',
          examId: 'upsc',
          progressMap: const {},
          lastUpdatedAt: fixedTimestamp,
          revision: 0,
        ),
        throwsArgumentError,
      );
    });

    test('4. copyWith accurately updates attributes and recomputes fingerprint',
        () {
      final original = createSampleState();
      final updated = original.copyWith(
        revision: 2,
        processedSessionIds: {'sess_init_1', 'sess_new_2'},
      );

      expect(updated.revision, equals(2));
      expect(updated.processedSessionIds.length, equals(2));
      expect(
          updated.stateFingerprint, isNot(equals(original.stateFingerprint)));
    });
  });

  group('Group 2: Deterministic Serialization & Deserialization', () {
    test(
        '5. Serialization and deserialization round-trip preserves exact state',
        () {
      final state = createSampleState(revision: 3);
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(
        state,
        revision: 3,
      );

      final canonicalJson = persisted.toCanonicalJson();
      final restored =
          PersistedAuthoritativeLearnerState.fromRawJson(canonicalJson);

      expect(restored.learnerId, equals(state.learnerId));
      expect(restored.examId, equals(state.examId));
      expect(restored.revision, equals(3));
      expect(restored.schemaVersion, equals(1));
      expect(restored.stateFingerprint, equals(state.stateFingerprint));
      expect(restored.checksum, equals(persisted.checksum));

      final domainRestored = restored.toAuthoritativeState();
      expect(domainRestored.learnerId, equals(state.learnerId));
      expect(domainRestored.revision, equals(state.revision));
      expect(domainRestored.stateFingerprint, equals(state.stateFingerprint));
    });

    test(
        '6. Deterministic serialization: same logical state produces identical canonical JSON',
        () {
      final state1 = createSampleState();
      final state2 = createSampleState();

      final p1 =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state1);
      final p2 =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state2);

      expect(p1.toCanonicalJson(), equals(p2.toCanonicalJson()));
      expect(p1.checksum, equals(p2.checksum));
    });

    test('7. Deserialization rejects malformed non-JSON payload', () {
      expect(
        () => PersistedAuthoritativeLearnerState.fromRawJson('not-valid-json'),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          equals(AuthoritativePersistenceErrorCode.malformedPayload),
        )),
      );
    });

    test('8. Deserialization rejects missing required fields', () {
      final validJson =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(
        createSampleState(),
      ).toJson();

      final missingLearner = Map<String, dynamic>.from(validJson)
        ..remove('learnerId');
      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(missingLearner),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          equals(AuthoritativePersistenceErrorCode.missingRequiredField),
        )),
      );

      final missingRevision = Map<String, dynamic>.from(validJson)
        ..remove('revision');
      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(missingRevision),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          equals(AuthoritativePersistenceErrorCode.missingRequiredField),
        )),
      );
    });

    test('9. Deserialization rejects unsupported future schema versions', () {
      final validJson =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(
        createSampleState(),
      ).toJson();
      validJson['schemaVersion'] = 999;

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(validJson),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          equals(AuthoritativePersistenceErrorCode.unsupportedSchemaVersion),
        )),
      );
    });

    test(
        '10. Deserialization rejects corrupted checksum (data tampering/bitrot)',
        () {
      final validJson =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(
        createSampleState(),
      ).toJson();
      validJson['checksum'] =
          '0000000000000000000000000000000000000000000000000000000000000000';

      expect(
        () => PersistedAuthoritativeLearnerState.fromJson(validJson),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          equals(AuthoritativePersistenceErrorCode.corruptedChecksum),
        )),
      );
    });
  });

  group('Group 3: Repository Contract & Atomic Replacement', () {
    test('11. Repository save and load round-trip', () async {
      final state = createSampleState(revision: 1);
      final persisted =
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state);

      await repository.save(persisted);
      final loaded =
          await repository.load(learnerId: 'learner_alpha', examId: 'upsc');

      expect(loaded, isNotNull);
      expect(loaded!.revision, equals(1));
      expect(loaded.learnerId, equals('learner_alpha'));
      expect(loaded.examId, equals('upsc'));
    });

    test('12. Missing state returns null gracefully', () async {
      final loaded =
          await repository.load(learnerId: 'non_existent', examId: 'upsc');
      expect(loaded, isNull);
    });

    test('13. Deleting state removes it cleanly', () async {
      final state = createSampleState();
      await repository.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      expect(
          await repository.exists(learnerId: 'learner_alpha', examId: 'upsc'),
          isTrue);
      await repository.delete(learnerId: 'learner_alpha', examId: 'upsc');
      expect(
          await repository.exists(learnerId: 'learner_alpha', examId: 'upsc'),
          isFalse);
      expect(await repository.load(learnerId: 'learner_alpha', examId: 'upsc'),
          isNull);
    });

    test('14. Multi-learner and multi-exam isolation', () async {
      final stateUpsc =
          createSampleState(learnerId: 'learner_1', examId: 'upsc');
      final stateBpsc =
          createSampleState(learnerId: 'learner_1', examId: 'bpsc');
      final state2Upsc =
          createSampleState(learnerId: 'learner_2', examId: 'upsc');

      await repository.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateUpsc));
      await repository.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateBpsc));
      await repository.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(
              state2Upsc));

      final loadedUpsc =
          await repository.load(learnerId: 'learner_1', examId: 'upsc');
      final loadedBpsc =
          await repository.load(learnerId: 'learner_1', examId: 'bpsc');
      final loaded2 =
          await repository.load(learnerId: 'learner_2', examId: 'upsc');

      expect(loadedUpsc!.examId, equals('upsc'));
      expect(loadedBpsc!.examId, equals('bpsc'));
      expect(loaded2!.learnerId, equals('learner_2'));
    });

    test(
        '15. Monotonic revision check rejects stale write (incoming < existing)',
        () async {
      final rev2 = createSampleState(revision: 2);
      await repository.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(rev2,
              revision: 2));

      final staleRev1 = createSampleState(revision: 1);
      expect(
        () => repository.save(
            PersistedAuthoritativeLearnerState.fromAuthoritativeState(staleRev1,
                revision: 1)),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          equals(AuthoritativePersistenceErrorCode.staleWrite),
        )),
      );
    });
  });

  group('Group 4: Persistence Service Orchestration', () {
    test(
        '16. Persistence service saves and loads AuthoritativeLearnerState cleanly',
        () async {
      final state = createSampleState(revision: 1);
      await persistenceService.save(state);

      final loaded = await persistenceService.load(
        learnerId: 'learner_alpha',
        examId: 'upsc',
      );

      expect(loaded, isNotNull);
      expect(loaded!.learnerId, equals('learner_alpha'));
      expect(loaded.examId, equals('upsc'));
      expect(loaded.revision, equals(1));
      expect(loaded.stateFingerprint, equals(state.stateFingerprint));
    });

    test(
        '17. Persistence service rejects save when expectedRevision mismatches',
        () async {
      final state = createSampleState(revision: 3);

      expect(
        () => persistenceService.save(state, expectedRevision: 2),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          equals(AuthoritativePersistenceErrorCode.staleWrite),
        )),
      );
    });

    test(
        '18. Persistence service surfaces repository IO failure without crashing unhandled',
        () async {
      final state = createSampleState();
      repository.failNextSave = true;

      expect(
        () => persistenceService.save(state),
        throwsA(isA<AuthoritativePersistenceException>().having(
          (e) => e.code,
          'code',
          equals(AuthoritativePersistenceErrorCode.ioFailure),
        )),
      );
    });
  });

  group('Group 5: Recovery Lifecycle & State Transitions', () {
    test(
        '19. recoverOrCreate on first session returns clean initial state at rev 1',
        () async {
      final recovered = await persistenceService.recoverOrCreate(
        learnerId: 'learner_new',
        examId: 'upsc',
        timestamp: fixedTimestamp,
      );

      expect(recovered.learnerId, equals('learner_new'));
      expect(recovered.examId, equals('upsc'));
      expect(recovered.revision, equals(1));
      expect(recovered.progressMap, isEmpty);
      expect(recovered.processedSessionIds, isEmpty);

      // Verify not yet persisted if persistIfCreated is false
      expect(
          await persistenceService.exists(
              learnerId: 'learner_new', examId: 'upsc'),
          isFalse);
    });

    test('20. recoverOrCreate with persistIfCreated=true saves initial state',
        () async {
      final recovered = await persistenceService.recoverOrCreate(
        learnerId: 'learner_persisted_boot',
        examId: 'upsc',
        timestamp: fixedTimestamp,
        persistIfCreated: true,
      );

      expect(recovered.revision, equals(1));
      expect(
          await persistenceService.exists(
              learnerId: 'learner_persisted_boot', examId: 'upsc'),
          isTrue);
    });

    test('21. recoverOrCreate restores existing persisted state with progress',
        () async {
      final initial = createSampleState(
        learnerId: 'learner_returning',
        revision: 4,
      );
      await persistenceService.save(initial);

      final recovered = await persistenceService.recoverOrCreate(
        learnerId: 'learner_returning',
        examId: 'upsc',
      );

      expect(recovered.revision, equals(4));
      expect(recovered.progressMap.length, equals(2));
      expect(recovered.progressMap['obj_preamble']!.correctCount, equals(2));
    });

    test('22. Recovery throws typed exception on corrupted persisted storage',
        () async {
      // Inject raw corrupted record
      repository.injectRawRecord(
        'learner_corrupt',
        'upsc',
        '{"corrupted": true, "checksum": "invalid"}',
      );

      expect(
        () => persistenceService.recoverOrCreate(
          learnerId: 'learner_corrupt',
          examId: 'upsc',
        ),
        throwsA(isA<AuthoritativePersistenceException>()),
      );
    });
  });
}
