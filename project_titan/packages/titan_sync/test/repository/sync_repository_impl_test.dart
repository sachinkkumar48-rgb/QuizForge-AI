import 'package:flutter_test/flutter_test.dart';
import 'package:titan_storage/titan_storage.dart';
import 'package:titan_sync/titan_sync.dart';

void main() {
  group('SyncRepositoryImpl Tests', () {
    late SyncRepository repository;
    final now = DateTime.now();

    final item = SyncItem(
      id: 'repo_item_1',
      entityId: 'note_repo',
      entityType: SyncEntityType.notes,
      action: SyncAction.create,
      payload: const {'text': 'Queue Note'},
      timestamp: now,
    );

    setUp(() {
      repository = SyncRepositoryImpl();
    });

    test('Queue item and retrieve pending items', () async {
      expect(await repository.getPendingItems(), isEmpty);

      await repository.queueItem(item);
      final pending = await repository.getPendingItems();

      expect(pending.length, 1);
      expect(pending.first.id, item.id);
    });

    test('Update item status and clear synced items', () async {
      await repository.queueItem(item);

      final syncedItem = item.copyWith(status: SyncItemStatus.synced);
      await repository.updateItem(syncedItem);

      expect(await repository.getPendingItems(), isEmpty);

      await repository.clearSyncedItems();
      expect(await repository.getAllItems(), isEmpty);
    });

    test('Save and resolve conflicts', () async {
      final remoteItem = item.copyWith(id: 'repo_item_remote');
      final conflict = SyncConflict(
        conflictId: 'c_repo',
        localItem: item,
        remoteItem: remoteItem,
        detectedAt: now,
      );

      await repository.saveConflict(conflict);
      final conflicts = await repository.getConflicts();
      expect(conflicts.length, 1);

      final resolvedItem = item.copyWith(status: SyncItemStatus.synced);
      await repository.resolveConflict('c_repo', resolvedItem);

      expect(await repository.getConflicts(), isEmpty);
    });

    test('Persistent storage backed by InMemoryStorageService', () async {
      final storageService = InMemoryStorageService();
      await storageService.initialize();

      final repo1 = SyncRepositoryImpl(storageService: storageService);
      await repo1.queueItem(item);

      final repo2 = SyncRepositoryImpl(storageService: storageService);
      final pending = await repo2.getPendingItems();

      expect(pending.length, 1);
      expect(pending.first.id, item.id);
    });
  });
}
