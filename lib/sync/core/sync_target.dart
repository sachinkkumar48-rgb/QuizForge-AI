import 'sync_entity.dart';
import 'sync_metadata.dart';

/// Contract for a syncable local domain repository (e.g. Bookmarks, Notes, Statistics, Revision, Settings).
abstract class SyncTarget {
  /// Unique identifier of the sync target entity type.
  SyncEntityType get targetType;

  /// Fetch all entities that have been modified locally since [sinceTimestamp].
  Future<List<SyncEntity<Map<String, dynamic>>>> getPendingEntities(
      {DateTime? sinceTimestamp});

  /// Apply resolved remote entities into the local database repository.
  Future<int> applyRemoteEntities(
      List<SyncEntity<Map<String, dynamic>>> entities);

  /// Retrieve full local state as sync entities.
  Future<List<SyncEntity<Map<String, dynamic>>>> exportLocalEntities();

  /// Retrieve last synchronization timestamp for this target.
  Future<DateTime?> getLastSyncTime();

  /// Update last synchronization timestamp for this target.
  Future<void> updateLastSyncTime(DateTime timestamp);
}
