/// Offline-First Synchronization Status Enum (TITAN-KO-047.0 P47).
///
/// Models discrete states of synchronizable learner progress across local
/// outbox, network transmission, and remote persistence.
library;

/// Discrete lifecycle states of a synchronizable learner-state record.
enum SyncStatus {
  /// Fresh local state not yet marked or queued for remote synchronization.
  localOnly,

  /// Durable in local outbox awaiting remote transmission.
  pendingSync,

  /// In-flight to remote backend.
  syncing,

  /// Confirmed and acknowledged by remote backend with matched/monitored revision.
  synced,

  /// Concurrent edit or stale revision detected requiring deterministic resolution.
  conflict,

  /// Network or server error encountered during sync attempt; retained in outbox for retry.
  failed;

  bool get isLocalOnly => this == SyncStatus.localOnly;
  bool get isPending => this == SyncStatus.pendingSync;
  bool get isSyncing => this == SyncStatus.syncing;
  bool get isSynced => this == SyncStatus.synced;
  bool get hasConflict => this == SyncStatus.conflict;
  bool get isFailed => this == SyncStatus.failed;

  /// User-facing human-readable status name.
  String get displayName {
    switch (this) {
      case SyncStatus.localOnly:
        return 'Local Only';
      case SyncStatus.pendingSync:
        return 'Pending Sync';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.conflict:
        return 'Sync Conflict';
      case SyncStatus.failed:
        return 'Sync Failed';
    }
  }
}
