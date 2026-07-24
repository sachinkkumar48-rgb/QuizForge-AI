import 'sync_entity.dart';

/// Available conflict resolution strategies.
enum ConflictResolutionStrategy {
  lastWriteWins,
  remoteWins,
  localWins,
  smartMerge,
}

/// Result of resolving conflict between local and remote entity versions.
class ConflictResolutionResult {
  final SyncEntity<Map<String, dynamic>> resolvedEntity;
  final bool updatedLocal;
  final bool updatedRemote;
  final String resolutionNotes;

  ConflictResolutionResult({
    required this.resolvedEntity,
    required this.updatedLocal,
    required this.updatedRemote,
    required this.resolutionNotes,
  });
}

/// Conflict resolution engine for offline-first sync.
class ConflictResolver {
  /// Resolve conflict between local and remote entity wrappers.
  static ConflictResolutionResult resolve({
    required SyncEntity<Map<String, dynamic>> local,
    required SyncEntity<Map<String, dynamic>> remote,
    ConflictResolutionStrategy strategy =
        ConflictResolutionStrategy.lastWriteWins,
  }) {
    switch (strategy) {
      case ConflictResolutionStrategy.remoteWins:
        return ConflictResolutionResult(
          resolvedEntity: remote,
          updatedLocal: true,
          updatedRemote: false,
          resolutionNotes: 'Remote Wins strategy selected',
        );

      case ConflictResolutionStrategy.localWins:
        return ConflictResolutionResult(
          resolvedEntity: local,
          updatedLocal: false,
          updatedRemote: true,
          resolutionNotes: 'Local Wins strategy selected',
        );

      case ConflictResolutionStrategy.smartMerge:
        return _smartMerge(local, remote);

      case ConflictResolutionStrategy.lastWriteWins:
        return _lastWriteWins(local, remote);
    }
  }

  static ConflictResolutionResult _lastWriteWins(
    SyncEntity<Map<String, dynamic>> local,
    SyncEntity<Map<String, dynamic>> remote,
  ) {
    final localTime = local.metadata.updatedAt;
    final remoteTime = remote.metadata.updatedAt;

    if (remoteTime.isAfter(localTime)) {
      return ConflictResolutionResult(
        resolvedEntity: remote,
        updatedLocal: true,
        updatedRemote: false,
        resolutionNotes:
            'Remote timestamp ($remoteTime) is newer than local ($localTime)',
      );
    } else if (localTime.isAfter(remoteTime)) {
      return ConflictResolutionResult(
        resolvedEntity: local,
        updatedLocal: false,
        updatedRemote: true,
        resolutionNotes:
            'Local timestamp ($localTime) is newer than remote ($remoteTime)',
      );
    } else {
      // Deterministic tie-breaker using clientDeviceId comparison
      final localDev = local.metadata.clientDeviceId;
      final remoteDev = remote.metadata.clientDeviceId;

      if (remoteDev.compareTo(localDev) > 0) {
        return ConflictResolutionResult(
          resolvedEntity: remote,
          updatedLocal: true,
          updatedRemote: false,
          resolutionNotes:
              'Timestamps equal. Tie-breaker favored remote device ID ($remoteDev)',
        );
      } else {
        return ConflictResolutionResult(
          resolvedEntity: local,
          updatedLocal: false,
          updatedRemote: true,
          resolutionNotes:
              'Timestamps equal. Tie-breaker favored local device ID ($localDev)',
        );
      }
    }
  }

  static ConflictResolutionResult _smartMerge(
    SyncEntity<Map<String, dynamic>> local,
    SyncEntity<Map<String, dynamic>> remote,
  ) {
    // If one is tombstoned, higher version or newer timestamp wins tombstone
    if (local.metadata.isDeleted || remote.metadata.isDeleted) {
      final winner = _lastWriteWins(local, remote).resolvedEntity;
      return ConflictResolutionResult(
        resolvedEntity: winner,
        updatedLocal:
            winner.metadata.clientDeviceId != local.metadata.clientDeviceId,
        updatedRemote:
            winner.metadata.clientDeviceId != remote.metadata.clientDeviceId,
        resolutionNotes: 'Merged with tombstone check',
      );
    }

    // Shallow merge JSON payload properties, preferring newer fields
    final mergedPayload = Map<String, dynamic>.from(local.payload);
    mergedPayload.addAll(remote.payload);

    final mergedVersion = (local.metadata.version > remote.metadata.version
            ? local.metadata.version
            : remote.metadata.version) +
        1;

    final mergedMeta = local.metadata.copyWith(
      version: mergedVersion,
      updatedAt: DateTime.now().toUtc(),
    );

    final mergedEntity = SyncEntity<Map<String, dynamic>>(
      metadata: mergedMeta,
      payload: mergedPayload,
    );

    return ConflictResolutionResult(
      resolvedEntity: mergedEntity,
      updatedLocal: true,
      updatedRemote: true,
      resolutionNotes: 'Smart field-level payload merge performed',
    );
  }
}
