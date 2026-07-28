import '../models/sync_conflict.dart';
import '../models/sync_item.dart';

/// Pure Dart field-level merger performing field-level conflict resolution,
/// Last Write Wins (LWW), and timestamp validation for TITAN sync items.
class FieldLevelMerger {
  const FieldLevelMerger();

  /// Merges local and remote payloads at the field level using Last Write Wins (LWW).
  Map<String, dynamic> mergePayloads({
    required Map<String, dynamic> localPayload,
    required DateTime localTimestamp,
    required Map<String, dynamic> remotePayload,
    required DateTime remoteTimestamp,
  }) {
    final merged = Map<String, dynamic>.from(localPayload);

    for (final entry in remotePayload.entries) {
      final key = entry.key;
      final remoteVal = entry.value;

      if (!merged.containsKey(key)) {
        // Field exists only in remote - adopt remote field
        merged[key] = remoteVal;
      } else {
        final localVal = merged[key];
        if (localVal != remoteVal) {
          // Conflict on specific field - apply Last Write Wins (LWW) based on timestamp
          if (remoteTimestamp.isAfter(localTimestamp)) {
            merged[key] = remoteVal;
          }
        }
      }
    }

    return merged;
  }

  /// Performs full conflict resolution between local and remote items.
  SyncConflict resolveFieldLevel(SyncConflict conflict) {
    final local = conflict.localItem;
    final remote = conflict.remoteItem;

    final mergedPayload = mergePayloads(
      localPayload: local.payload,
      localTimestamp: local.timestamp,
      remotePayload: remote.payload,
      remoteTimestamp: remote.timestamp,
    );

    final winningTimestamp = remote.timestamp.isAfter(local.timestamp)
        ? remote.timestamp
        : local.timestamp;
    final winningVersion =
        remote.version > local.version ? remote.version + 1 : local.version + 1;

    final resolvedItem = local.copyWith(
      payload: mergedPayload,
      timestamp: winningTimestamp,
      version: winningVersion,
      status: SyncItemStatus.synced,
      retryCount: 0,
    );

    return conflict.copyWith(
      isResolved: true,
      resolvedItem: resolvedItem,
    );
  }
}
