import '../models/sync_conflict.dart';
import '../models/sync_item.dart';

/// Configurable conflict resolution strategies supported by Project TITAN.
enum ConflictStrategy {
  lastWriteWins,
  serverWins,
  localWins,
  manual,
  merge,
}

/// Domain service responsible for detecting and resolving sync conflicts.
class ConflictResolver {
  final ConflictStrategy defaultStrategy;

  const ConflictResolver({
    this.defaultStrategy = ConflictStrategy.lastWriteWins,
  });

  /// Resolves a [SyncConflict] using the provided [strategy] (or fallback to [defaultStrategy]).
  SyncConflict resolve(
    SyncConflict conflict, {
    ConflictStrategy? strategy,
  }) {
    final effectiveStrategy = strategy ?? defaultStrategy;

    switch (effectiveStrategy) {
      case ConflictStrategy.lastWriteWins:
        final localTime = conflict.localItem.timestamp;
        final remoteTime = conflict.remoteItem.timestamp;
        final winner = localTime.isAfter(remoteTime)
            ? conflict.localItem
            : conflict.remoteItem;
        return conflict.copyWith(
          isResolved: true,
          resolvedItem: winner.copyWith(status: SyncItemStatus.pending),
        );

      case ConflictStrategy.serverWins:
        return conflict.copyWith(
          isResolved: true,
          resolvedItem:
              conflict.remoteItem.copyWith(status: SyncItemStatus.synced),
        );

      case ConflictStrategy.localWins:
        return conflict.copyWith(
          isResolved: true,
          resolvedItem:
              conflict.localItem.copyWith(status: SyncItemStatus.pending),
        );

      case ConflictStrategy.manual:
        // Leaves conflict unresolved for UI interaction
        return conflict;

      case ConflictStrategy.merge:
        final mergedPayload =
            Map<String, dynamic>.from(conflict.remoteItem.payload)
              ..addAll(conflict.localItem.payload);
        final mergedItem = conflict.localItem.copyWith(
          payload: mergedPayload,
          version: (conflict.localItem.version > conflict.remoteItem.version
                  ? conflict.localItem.version
                  : conflict.remoteItem.version) +
              1,
          status: SyncItemStatus.pending,
        );
        return conflict.copyWith(
          isResolved: true,
          resolvedItem: mergedItem,
        );
    }
  }
}
