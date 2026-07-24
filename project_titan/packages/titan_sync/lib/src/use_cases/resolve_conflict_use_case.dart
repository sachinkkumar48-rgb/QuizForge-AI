import '../conflict/conflict_resolver.dart';
import '../engine/sync_manager.dart';
import '../models/sync_item.dart';

/// Clean Architecture Use Case for resolving data sync conflicts.
class ResolveConflictUseCase {
  final SyncManager _syncManager;

  const ResolveConflictUseCase(this._syncManager);

  /// Resolves conflict with a specified strategy or custom merged item.
  Future<void> execute(
    String conflictId, {
    ConflictStrategy strategy = ConflictStrategy.lastWriteWins,
    SyncItem? customItem,
  }) {
    return _syncManager.resolveConflict(
      conflictId,
      strategy: strategy,
      customItem: customItem,
    );
  }
}
