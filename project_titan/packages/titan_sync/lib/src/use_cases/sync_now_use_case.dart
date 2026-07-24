import '../engine/sync_manager.dart';
import '../models/sync_result.dart';

/// Clean Architecture Use Case for initiating an immediate cloud synchronization.
class SyncNowUseCase {
  final SyncManager _syncManager;

  const SyncNowUseCase(this._syncManager);

  /// Triggers full push/pull sync.
  Future<SyncResult> execute() {
    return _syncManager.syncNow();
  }
}
