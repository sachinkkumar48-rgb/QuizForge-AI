import '../engine/sync_manager.dart';
import '../models/sync_result.dart';

/// Clean Architecture Use Case for retrying failed sync items.
class RetryFailedSyncUseCase {
  final SyncManager _syncManager;

  const RetryFailedSyncUseCase(this._syncManager);

  /// Triggers a retry of all failed sync items.
  Future<SyncResult> execute() {
    return _syncManager.retryFailedSync();
  }
}
