import '../models/sync_conflict.dart';
import '../models/sync_item.dart';

/// Abstract repository interface for managing local offline sync queue and conflicts.
abstract class SyncRepository {
  /// Enqueues a new item or updates an existing item in the offline queue.
  Future<void> queueItem(SyncItem item);

  /// Retrieves all pending items waiting for cloud sync.
  Future<List<SyncItem>> getPendingItems();

  /// Retrieves all queued items regardless of status.
  Future<List<SyncItem>> getAllItems();

  /// Updates status and details of a sync item.
  Future<void> updateItem(SyncItem item);

  /// Removes an item from the sync queue.
  Future<void> removeItem(String itemId);

  /// Stores a detected sync conflict.
  Future<void> saveConflict(SyncConflict conflict);

  /// Retrieves all unresolved sync conflicts.
  Future<List<SyncConflict>> getConflicts();

  /// Resolves a conflict and updates the sync queue.
  Future<void> resolveConflict(String conflictId, SyncItem resolvedItem);

  /// Clears items that have successfully synced.
  Future<void> clearSyncedItems();
}
