/// In-Memory Session Checkpoint Repository (TITAN-KO-040.0 P40).
///
/// Deterministic, zero-dependency in-memory implementation of
/// [SessionCheckpointRepository] storing checkpoints as serialized canonical
/// JSON payloads with monotonic revision checks, multi-tenant isolation,
/// and test fault injection hooks.
library;

import 'dart:convert';

import '../domain/entities/session_checkpoint.dart';
import '../domain/entities/session_recovery_error.dart';
import 'session_checkpoint_repository.dart';

/// Deterministic in-memory repository for session checkpoints.
class InMemorySessionCheckpointRepository
    implements SessionCheckpointRepository {
  /// Internal storage mapping "$learnerId:$examId:$sessionId" to canonical JSON strings.
  final Map<String, String> _storage = {};

  /// Test hook: if true, the next save operation simulates an IO failure.
  bool failNextSave = false;

  /// Test hook: if true, the next load operation simulates an IO failure.
  bool failNextLoad = false;

  InMemorySessionCheckpointRepository();

  static String _key(String learnerId, String examId, String sessionId) =>
      '${learnerId.trim()}:${examId.trim().toLowerCase()}:${sessionId.trim()}';

  static String _prefix(String learnerId, String examId) =>
      '${learnerId.trim()}:${examId.trim().toLowerCase()}:';

  @override
  Future<SessionCheckpoint?> loadCheckpoint({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {
    if (failNextLoad) {
      failNextLoad = false;
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.ioFailure,
        message: 'Simulated IO failure during checkpoint load',
      );
    }

    final key = _key(learnerId, examId, sessionId);
    final rawPayload = _storage[key];
    if (rawPayload == null) {
      return null;
    }

    return SessionCheckpoint.fromRawJson(rawPayload);
  }

  @override
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async {
    if (failNextSave) {
      failNextSave = false;
      throw const SessionRecoveryException(
        code: SessionRecoveryErrorCode.ioFailure,
        message: 'Simulated IO failure during checkpoint save',
      );
    }

    final key =
        _key(checkpoint.learnerId, checkpoint.examId, checkpoint.sessionId);
    final canonicalJson = checkpoint.toCanonicalJson();

    final existingRaw = _storage[key];
    if (existingRaw != null) {
      int? existingRevision;
      final isIdentical = (canonicalJson == existingRaw);

      try {
        final existing = SessionCheckpoint.fromRawJson(existingRaw);
        existingRevision = existing.checkpointRevision;
      } catch (_) {
        try {
          final decoded = jsonDecode(existingRaw);
          if (decoded is Map) {
            existingRevision = decoded['checkpointRevision'] as int?;
          }
        } catch (_) {}
      }

      if (existingRevision != null) {
        if (checkpoint.checkpointRevision < existingRevision) {
          throw SessionRecoveryException(
            code: SessionRecoveryErrorCode.staleCheckpoint,
            message:
                'Stale checkpoint write rejected: incoming revision ${checkpoint.checkpointRevision} < existing revision $existingRevision',
            details: {
              'incomingRevision': checkpoint.checkpointRevision,
              'existingRevision': existingRevision,
              'sessionId': checkpoint.sessionId,
            },
          );
        } else if (checkpoint.checkpointRevision == existingRevision) {
          if (isIdentical) {
            return;
          } else {
            throw SessionRecoveryException(
              code: SessionRecoveryErrorCode.staleCheckpoint,
              message:
                  'Stale checkpoint write rejected: identical revision ${checkpoint.checkpointRevision} with diverging checkpoint payload',
              details: {
                'incomingRevision': checkpoint.checkpointRevision,
                'existingRevision': existingRevision,
                'sessionId': checkpoint.sessionId,
              },
            );
          }
        }
      }
    }

    _storage[key] = canonicalJson;
  }

  @override
  Future<void> deleteCheckpoint({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {
    final key = _key(learnerId, examId, sessionId);
    _storage.remove(key);
  }

  @override
  Future<bool> exists({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {
    final key = _key(learnerId, examId, sessionId);
    return _storage.containsKey(key);
  }

  @override
  Future<List<SessionCheckpoint>> listCheckpoints({
    required String learnerId,
    required String examId,
  }) async {
    final prefix = _prefix(learnerId, examId);
    final checkpoints = <SessionCheckpoint>[];

    for (final entry in _storage.entries) {
      if (entry.key.startsWith(prefix)) {
        try {
          checkpoints.add(SessionCheckpoint.fromRawJson(entry.value));
        } catch (_) {}
      }
    }

    return checkpoints;
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }

  /// Test helper: directly injects raw payload to simulate corrupted storage.
  void injectRawPayload({
    required String learnerId,
    required String examId,
    required String sessionId,
    required String rawPayload,
  }) {
    final key = _key(learnerId, examId, sessionId);
    _storage[key] = rawPayload;
  }
}
