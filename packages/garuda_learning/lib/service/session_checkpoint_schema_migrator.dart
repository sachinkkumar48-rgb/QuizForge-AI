/// Session Checkpoint Schema Migrator (TITAN-KO-040.0 P40).
///
/// Clean migration seam for deterministic schema evolution across versions of
/// persisted session checkpoints and snapshots.
library;

import '../domain/entities/resumable_session_snapshot.dart';
import '../domain/entities/resumable_session_status.dart';
import '../domain/entities/session_checkpoint_exceptions.dart';
import '../domain/entities/session_identity.dart';

/// Contract for migrating session checkpoint / snapshot payloads across schema versions.
abstract interface class SessionCheckpointSchemaMigrator {
  /// Whether this migrator can upgrade from [sourceVersion] to [targetVersion].
  bool canMigrate(int sourceVersion, int targetVersion);

  /// Deterministically migrates [rawJson] payload from [sourceVersion] to [targetVersion].
  ResumableSessionSnapshot migrate(
    Map<String, dynamic> rawJson, {
    required int sourceVersion,
    int targetVersion = ResumableSessionSnapshot.currentSchemaVersion,
  });
}

/// Default implementation supporting migration of legacy schema version 0 to current schema 1.
class DefaultSessionCheckpointSchemaMigrator
    implements SessionCheckpointSchemaMigrator {
  const DefaultSessionCheckpointSchemaMigrator();

  @override
  bool canMigrate(int sourceVersion, int targetVersion) {
    if (sourceVersion == 0 &&
        targetVersion == ResumableSessionSnapshot.currentSchemaVersion) {
      return true;
    }
    return false;
  }

  @override
  ResumableSessionSnapshot migrate(
    Map<String, dynamic> rawJson, {
    required int sourceVersion,
    int targetVersion = ResumableSessionSnapshot.currentSchemaVersion,
  }) {
    if (targetVersion < sourceVersion) {
      throw CheckpointSchemaException(
        message:
            'Schema downgrade is not permitted (from v$sourceVersion to v$targetVersion)',
        schemaVersion: sourceVersion,
      );
    }

    if (!canMigrate(sourceVersion, targetVersion)) {
      throw CheckpointSchemaException(
        message:
            'Cannot migrate checkpoint schema from v$sourceVersion to v$targetVersion',
        schemaVersion: sourceVersion,
      );
    }

    // Migration from v0 to v1:
    // v0 payloads: legacy unversioned checkpoints or raw snapshot dictionaries
    final sessionId = (rawJson['sessionId'] as String? ?? '').trim();
    final learnerId = (rawJson['learnerId'] as String? ?? '').trim();
    final examId = (rawJson['examId'] as String? ?? '').trim().toLowerCase();

    if (sessionId.isEmpty) {
      throw CheckpointIntegrityException(
        message: 'Cannot migrate v0 checkpoint missing sessionId',
      );
    }
    if (learnerId.isEmpty) {
      throw CheckpointIntegrityException(
        message: 'Cannot migrate v0 checkpoint missing learnerId',
      );
    }
    if (examId.isEmpty) {
      throw CheckpointIntegrityException(
        message: 'Cannot migrate v0 checkpoint missing examId',
      );
    }

    final checkpointRevision = rawJson['checkpointRevision'] as int? ?? 1;
    final authoritativeStateRevision =
        rawJson['authoritativeStateRevision'] as int? ?? 1;
    final currentQuestionIndex = rawJson['currentQuestionIndex'] as int? ??
        rawJson['questionIndex'] as int? ??
        0;
    final currentQuestionId = rawJson['currentQuestionId'] as String?;
    final activeObjectiveId =
        (rawJson['activeObjectiveId'] as String? ?? 'lo_general').trim();

    final completedList =
        (rawJson['completedQuestionIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();

    final attemptList =
        (rawJson['processedAttemptTokens'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();

    final completedObjList =
        (rawJson['completedObjectiveIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();

    final pendingObjList =
        (rawJson['pendingObjectiveIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();

    final isCompleted = rawJson['isCompleted'] as bool? ?? false;
    final statusStr = rawJson['status'] as String?;
    final status = statusStr != null
        ? ResumableSessionStatus.values.firstWhere(
            (s) => s.name == statusStr,
            orElse: () => isCompleted
                ? ResumableSessionStatus.completed
                : ResumableSessionStatus.active,
          )
        : (isCompleted
            ? ResumableSessionStatus.completed
            : ResumableSessionStatus.active);

    final timestampStr = rawJson['timestamp'] as String?;
    final timestamp = timestampStr != null
        ? DateTime.parse(timestampStr).toUtc()
        : DateTime.utc(2026, 1, 1);

    final startedAtStr = rawJson['startedAt'] as String?;
    final startedAt =
        startedAtStr != null ? DateTime.parse(startedAtStr).toUtc() : timestamp;

    final identity = SessionIdentity(
      sessionId: sessionId,
      learnerId: learnerId,
      examId: examId,
      startedAt: startedAt,
      lastCheckpointAt: timestamp,
      status: status,
    );

    final metadata = Map<String, dynamic>.from(
      rawJson['metadata'] as Map? ?? const {},
    )..['migratedFromSchema'] = sourceVersion;

    return ResumableSessionSnapshot(
      schemaVersion: targetVersion,
      identity: identity,
      currentQuestionIndex: currentQuestionIndex,
      currentQuestionId: currentQuestionId,
      completedQuestionIds: completedList,
      processedAttemptTokens: attemptList,
      accumulatedScore:
          (rawJson['accumulatedScore'] as num?)?.toDouble() ?? 0.0,
      correctCount: rawJson['correctCount'] as int? ?? 0,
      activeObjectiveId:
          activeObjectiveId.isEmpty ? 'lo_general' : activeObjectiveId,
      completedObjectiveIds: completedObjList,
      pendingObjectiveIds: pendingObjList,
      checkpointRevision: checkpointRevision,
      authoritativeStateRevision: authoritativeStateRevision,
      timestamp: timestamp,
      metadata: metadata,
    );
  }
}
