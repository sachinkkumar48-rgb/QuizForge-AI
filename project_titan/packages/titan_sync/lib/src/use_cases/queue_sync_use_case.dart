import '../engine/sync_manager.dart';
import '../models/sync_item.dart';

/// Clean Architecture Use Case for enqueueing an offline item for sync.
class QueueSyncUseCase {
  final SyncManager _syncManager;

  const QueueSyncUseCase(this._syncManager);

  /// Enqueues item to sync queue.
  Future<void> execute(SyncItem item) {
    return _syncManager.queueItem(item);
  }
}
