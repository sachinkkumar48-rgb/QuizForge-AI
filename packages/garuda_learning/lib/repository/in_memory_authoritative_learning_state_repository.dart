/// In-Memory Authoritative Learning State Repository (TITAN-KO-039.0 P39).
///
/// Deterministic, zero-dependency in-memory implementation of
/// [AuthoritativeLearningStateRepository] with strict atomic save semantics,
/// deep memory isolation via canonical JSON serialization, and test fault injection.
library;

import 'dart:convert';

import '../domain/entities/authoritative_persistence_error.dart';
import '../domain/entities/persisted_authoritative_learner_state.dart';
import 'authoritative_learning_state_repository.dart';

/// In-memory repository storing authoritative learner state as serialized raw payloads.
class InMemoryAuthoritativeLearningStateRepository
    implements AuthoritativeLearningStateRepository {
  /// Internal storage mapping "$learnerId:$examId" to canonical JSON strings.
  final Map<String, String> _storage = {};

  /// Test hook: if true, the next save operation will simulate an IO failure.
  bool failNextSave = false;

  /// Test hook: if true, all read operations simulate an IO failure.
  bool failNextLoad = false;

  InMemoryAuthoritativeLearningStateRepository();

  static String _key(String learnerId, String examId) =>
      '${learnerId.trim()}:${examId.trim().toLowerCase()}';

  @override
  Future<PersistedAuthoritativeLearnerState?> load({
    required String learnerId,
    required String examId,
  }) async {
    if (failNextLoad) {
      failNextLoad = false;
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.ioFailure,
        message: 'Simulated IO failure during state load',
      );
    }

    final key = _key(learnerId, examId);
    final rawPayload = _storage[key];
    if (rawPayload == null) {
      return null;
    }

    // Deserialization performs strict verification (missing fields, enums, numbers, checksum, fingerprint)
    return PersistedAuthoritativeLearnerState.fromRawJson(rawPayload);
  }

  @override
  Future<void> save(PersistedAuthoritativeLearnerState state) async {
    final key = _key(state.learnerId, state.examId);

    // 1. Validate and serialize incoming state to canonical JSON string
    final canonicalJson = state.toCanonicalJson();

    // 2. Check existing record for revision conflicts and stale writes
    final existingRaw = _storage[key];
    if (existingRaw != null) {
      int? existingRevision;
      final isIdentical = (canonicalJson == existingRaw);
      bool isLegacySchema = false;

      try {
        final existing =
            PersistedAuthoritativeLearnerState.fromRawJson(existingRaw);
        existingRevision = existing.revision;
      } on AuthoritativePersistenceException catch (e) {
        if (e.code ==
            AuthoritativePersistenceErrorCode.unsupportedSchemaVersion) {
          isLegacySchema = true;
        }
        // If existing record is in an older schema or unparseable as current schema,
        // safely extract revision from raw json for revision comparison
        try {
          final decoded = jsonDecode(existingRaw);
          if (decoded is Map) {
            existingRevision = decoded['revision'] as int? ?? 1;
          }
        } catch (_) {
          // Unparseable JSON allows atomic overwrite during recovery
          isLegacySchema = true;
        }
      }

      if (existingRevision != null) {
        if (state.revision < existingRevision) {
          throw AuthoritativePersistenceException(
            code: AuthoritativePersistenceErrorCode.staleWrite,
            message:
                'Stale write rejected for "${state.learnerId}:${state.examId}": incoming revision ${state.revision} < existing revision $existingRevision',
            details: {
              'incomingRevision': state.revision,
              'existingRevision': existingRevision,
            },
          );
        } else if (state.revision == existingRevision) {
          // Equal revision: idempotent no-op if identical payload;
          // allow migration overwrite if upgrading from an older legacy schema;
          // otherwise reject as revision conflict.
          if (isIdentical) {
            return;
          } else if (isLegacySchema) {
            // Proceed with atomic replacement to persist migrated schema
          } else {
            throw AuthoritativePersistenceException(
              code: AuthoritativePersistenceErrorCode.staleWrite,
              message:
                  'Stale write rejected: identical revision ${state.revision} with diverging state payload',
              details: {
                'incomingRevision': state.revision,
                'existingRevision': existingRevision,
              },
            );
          }
        }
      }
    }

    // 3. Atomicity & simulated failure check
    if (failNextSave) {
      failNextSave = false;
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.ioFailure,
        message: 'Simulated IO failure during atomic state save',
      );
    }

    // 4. Atomic commit: replaces previous complete state
    _storage[key] = canonicalJson;
  }

  @override
  Future<void> delete({
    required String learnerId,
    required String examId,
  }) async {
    _storage.remove(_key(learnerId, examId));
  }

  @override
  Future<bool> exists({
    required String learnerId,
    required String examId,
  }) async {
    return _storage.containsKey(_key(learnerId, examId));
  }

  @override
  Future<void> clear() async {
    _storage.clear();
    failNextSave = false;
    failNextLoad = false;
  }

  // ---------------------------------------------------------------------------
  // Test Instrumentation Hooks
  // ---------------------------------------------------------------------------

  /// Injects a raw string record directly into storage (to test corruption, legacy schemas, etc.).
  void injectRawRecord(String learnerId, String examId, String rawPayload) {
    _storage[_key(learnerId, examId)] = rawPayload;
  }

  /// Retrieves the raw string representation directly from storage.
  String? getRawRecord(String learnerId, String examId) {
    return _storage[_key(learnerId, examId)];
  }

  /// Current number of stored state records.
  int get recordCount => _storage.length;
}
