/// Authoritative Schema Migrator (TITAN-KO-039.0 P39).
///
/// Clean migration seam for deterministic schema evolution across versions of
/// persisted authoritative learner state.
library;

import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/authoritative_persistence_error.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/persisted_authoritative_learner_state.dart';

/// Contract for migrating persisted state payloads across schema versions.
abstract interface class AuthoritativeSchemaMigrator {
  /// Whether this migrator can upgrade from [sourceVersion] to [targetVersion].
  bool canMigrate(int sourceVersion, int targetVersion);

  /// Deterministically migrates [rawJson] payload from [sourceVersion] to [targetVersion].
  PersistedAuthoritativeLearnerState migrate(
    Map<String, dynamic> rawJson, {
    required int sourceVersion,
    int targetVersion = PersistedAuthoritativeLearnerState.currentSchemaVersion,
  });
}

/// Default implementation supporting migration of legacy schema version 0 to current schema 1.
class DefaultAuthoritativeSchemaMigrator
    implements AuthoritativeSchemaMigrator {
  const DefaultAuthoritativeSchemaMigrator();

  @override
  bool canMigrate(int sourceVersion, int targetVersion) {
    if (sourceVersion == 0 &&
        targetVersion ==
            PersistedAuthoritativeLearnerState.currentSchemaVersion) {
      return true;
    }
    return false;
  }

  @override
  PersistedAuthoritativeLearnerState migrate(
    Map<String, dynamic> rawJson, {
    required int sourceVersion,
    int targetVersion = PersistedAuthoritativeLearnerState.currentSchemaVersion,
  }) {
    if (!canMigrate(sourceVersion, targetVersion)) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.unsupportedSchemaVersion,
        message:
            'Cannot migrate persisted state schema from v$sourceVersion to v$targetVersion',
        details: {
          'sourceVersion': sourceVersion,
          'targetVersion': targetVersion,
        },
      );
    }

    // Migration from v0 to v1:
    // v0 payloads: legacy snapshots without schemaVersion or checksum, or having schemaVersion = 0.
    final learnerId = (rawJson['learnerId'] as String? ?? '').trim();
    final examId = (rawJson['examId'] as String? ?? '').trim().toLowerCase();
    if (learnerId.isEmpty || examId.isEmpty) {
      throw AuthoritativePersistenceException(
        code: AuthoritativePersistenceErrorCode.missingRequiredField,
        message: 'Cannot migrate v0 state missing learnerId or examId',
      );
    }

    final revision = rawJson['revision'] as int? ?? 1;
    final lastUpdatedAt = rawJson['lastUpdatedAt'] != null
        ? DateTime.parse(rawJson['lastUpdatedAt'] as String).toUtc()
        : DateTime.utc(2026, 1, 1);

    final rawProgress = rawJson['progressMap'] as Map? ?? const {};
    final progressMap = <String, LearnerProgress>{};
    for (final entry in rawProgress.entries) {
      final objId = entry.key.toString();
      final pMap = Map<String, dynamic>.from(entry.value as Map);
      progressMap[objId] = LearnerProgress.fromJson(pMap);
    }

    final rawSessions = rawJson['processedSessionIds'] as List? ?? const [];
    final sessions =
        Set<String>.from(rawSessions.map((s) => s.toString().trim()));

    // Construct valid AuthoritativeLearnerState to compute fingerprint
    final state = AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      progressMap: progressMap,
      processedSessionIds: sessions,
      lastUpdatedAt: lastUpdatedAt,
      revision: revision,
    );

    final metadata = Map<String, dynamic>.from(
      rawJson['metadata'] as Map? ?? const {},
    )..['migratedFromSchema'] = sourceVersion;

    return PersistedAuthoritativeLearnerState.fromAuthoritativeState(
      state,
      revision: revision,
      schemaVersion: targetVersion,
      metadata: metadata,
    );
  }
}
