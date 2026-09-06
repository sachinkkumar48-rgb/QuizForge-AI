/// Session Checkpoint Service (TITAN-KO-040.0 P40).
///
/// Production service managing durable checkpoint persistence, schema migration,
/// cryptographic integrity verification, and monotonic revision checks for
/// resumable adaptive learning sessions.
library;

import '../domain/entities/checkpoint_policy.dart';
import '../domain/entities/resumable_session_snapshot.dart';
import '../domain/entities/session_checkpoint.dart';
import '../domain/entities/session_checkpoint_exceptions.dart';
import '../domain/entities/session_recovery_error.dart';
import '../repository/session_checkpoint_repository.dart';
import 'session_checkpoint_schema_migrator.dart';

/// Service managing checkpoint persistence, schema evolution, and integrity protection.
class SessionCheckpointService {
  final SessionCheckpointRepository _repository;
  final SessionCheckpointSchemaMigrator _migrator;
  final CheckpointPolicy _defaultPolicy;

  const SessionCheckpointService({
    required SessionCheckpointRepository repository,
    SessionCheckpointSchemaMigrator migrator =
        const DefaultSessionCheckpointSchemaMigrator(),
    CheckpointPolicy defaultPolicy = const CheckpointPolicy.everyAttempt(),
  })  : _repository = repository,
        _migrator = migrator,
        _defaultPolicy = defaultPolicy;

  /// Default checkpoint policy configured for this service.
  CheckpointPolicy get defaultPolicy => _defaultPolicy;

  /// Underlying checkpoint repository.
  SessionCheckpointRepository get repository => _repository;

  /// Underlying schema migrator.
  SessionCheckpointSchemaMigrator get migrator => _migrator;

  /// Loads and integrity-verifies the session snapshot for given coordinates.
  ///
  /// Returns `null` if no checkpoint exists for this session.
  /// Throws [CheckpointIntegrityException] if the stored checkpoint is corrupted or checksum fails.
  /// Throws [CheckpointSchemaException] if the stored checkpoint version is unsupported.
  Future<ResumableSessionSnapshot?> loadSnapshot({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {
    final normalizedLearnerId = learnerId.trim();
    final normalizedExamId = examId.trim().toLowerCase();
    final normalizedSessionId = sessionId.trim();

    if (normalizedLearnerId.isEmpty ||
        normalizedExamId.isEmpty ||
        normalizedSessionId.isEmpty) {
      throw CheckpointIntegrityException(
        message:
            'learnerId, examId, and sessionId must be non-empty when loading snapshot',
      );
    }

    SessionCheckpoint? checkpoint;
    try {
      checkpoint = await _repository.loadCheckpoint(
        learnerId: normalizedLearnerId,
        examId: normalizedExamId,
        sessionId: normalizedSessionId,
      );
    } on SessionRecoveryException catch (e) {
      if (e.code == SessionRecoveryErrorCode.corruptedCheckpoint) {
        throw CheckpointIntegrityException(
          message: 'Checkpoint storage corrupted: ${e.message}',
          details: e.details,
        );
      } else if (e.code == SessionRecoveryErrorCode.incompatibleVersion) {
        throw CheckpointSchemaException(
          message: 'Unsupported checkpoint schema: ${e.message}',
          schemaVersion: e.details['schemaVersion'] as int? ?? 0,
          details: e.details,
        );
      }
      rethrow;
    }

    if (checkpoint == null) {
      return null;
    }

    final snapshot = ResumableSessionSnapshot.fromCheckpoint(checkpoint);

    // Validate cryptographic integrity
    if (!snapshot.verifyChecksum()) {
      throw CheckpointIntegrityException(
        message:
            'Cryptographic checksum mismatch on loaded snapshot for session $sessionId',
        foundChecksum: snapshot.checksum,
      );
    }

    return snapshot;
  }

  /// Atomically saves [snapshot] with integrity and monotonic revision enforcement.
  ///
  /// Throws [CheckpointIntegrityException] if snapshot fails checksum verification.
  /// Throws [StaleCheckpointException] if the write is stale or causes a revision conflict.
  Future<void> saveSnapshot(ResumableSessionSnapshot snapshot) async {
    if (!snapshot.verifyChecksum()) {
      throw CheckpointIntegrityException(
        message:
            'Cannot save corrupted snapshot with invalid checksum for session ${snapshot.sessionId}',
        foundChecksum: snapshot.checksum,
      );
    }

    final checkpoint = snapshot.toCheckpoint();

    try {
      await _repository.saveCheckpoint(checkpoint);
    } on SessionRecoveryException catch (e) {
      if (e.code == SessionRecoveryErrorCode.staleCheckpoint) {
        throw StaleCheckpointException(
          message: e.message,
          incomingRevision: snapshot.checkpointRevision,
          existingRevision: (e.details['existingRevision'] as int?) ??
              snapshot.checkpointRevision,
          details: {
            'sessionId': snapshot.sessionId,
            ...e.details,
          },
        );
      }
      rethrow;
    }
  }

  /// Deletes checkpoint for the specified session coordinates.
  Future<void> deleteSnapshot({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {
    await _repository.deleteCheckpoint(
      learnerId: learnerId.trim(),
      examId: examId.trim().toLowerCase(),
      sessionId: sessionId.trim(),
    );
  }

  /// Checks if a snapshot exists for the specified session coordinates.
  Future<bool> hasSnapshot({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {
    return _repository.exists(
      learnerId: learnerId.trim(),
      examId: examId.trim().toLowerCase(),
      sessionId: sessionId.trim(),
    );
  }

  /// Parses a raw JSON snapshot, performing automatic migration if payload is v0.
  ResumableSessionSnapshot parseRawSnapshot(Map<String, dynamic> rawJson) {
    final schema = rawJson['schemaVersion'] as int? ?? 0;
    if (schema == 0) {
      return _migrator.migrate(
        rawJson,
        sourceVersion: 0,
        targetVersion: ResumableSessionSnapshot.currentSchemaVersion,
      );
    } else if (schema == ResumableSessionSnapshot.currentSchemaVersion) {
      return ResumableSessionSnapshot.fromJson(rawJson);
    } else if (schema > ResumableSessionSnapshot.currentSchemaVersion) {
      throw CheckpointSchemaException(
        message: 'Unsupported future schema version: $schema',
        schemaVersion: schema,
      );
    } else {
      throw CheckpointSchemaException(
        message: 'Unsupported checkpoint schema version: $schema',
        schemaVersion: schema,
      );
    }
  }

  /// Evaluates whether a checkpoint should be persisted according to [policy].
  bool shouldCheckpoint({
    CheckpointPolicy? policy,
    required int attemptCount,
    bool isCompleted = false,
    bool isPaused = false,
  }) {
    final effectivePolicy = policy ?? _defaultPolicy;
    return effectivePolicy.shouldCheckpoint(
      attemptCount: attemptCount,
      isCompleted: isCompleted,
      isPaused: isPaused,
    );
  }
}
