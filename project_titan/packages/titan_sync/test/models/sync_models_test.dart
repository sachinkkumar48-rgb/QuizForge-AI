import 'package:flutter_test/flutter_test.dart';
import 'package:titan_sync/titan_sync.dart';

void main() {
  group('Sync Models Unit Tests', () {
    final now = DateTime(2026, 7, 24, 15, 0);

    test('SyncItem instantiation and copyWith', () {
      final item = SyncItem(
        id: 'item_1',
        entityId: 'note_100',
        entityType: SyncEntityType.notes,
        action: SyncAction.create,
        payload: const {'title': 'Polity Note'},
        timestamp: now,
      );

      expect(item.id, 'item_1');
      expect(item.entityId, 'note_100');
      expect(item.entityType, SyncEntityType.notes);
      expect(item.action, SyncAction.create);
      expect(item.status, SyncItemStatus.pending);

      final updated = item.copyWith(status: SyncItemStatus.synced);
      expect(updated.status, SyncItemStatus.synced);
      expect(updated.id, item.id);
    });

    test('SyncItem serialization toJson and fromJson', () {
      final item = SyncItem(
        id: 'item_ser',
        entityId: 'pref_1',
        entityType: SyncEntityType.userPreferences,
        action: SyncAction.update,
        payload: const {'darkMode': true},
        timestamp: now,
        version: 2,
        status: SyncItemStatus.failed,
        retryCount: 1,
        lastError: 'Timeout',
      );

      final json = item.toJson();
      final restored = SyncItem.fromJson(json);

      expect(restored.id, item.id);
      expect(restored.entityType, SyncEntityType.userPreferences);
      expect(restored.payload['darkMode'], isTrue);
      expect(restored.lastError, 'Timeout');
    });

    test('SyncBatch creation and serialization', () {
      final item = SyncItem(
        id: 'b_item_1',
        entityId: 'plan_1',
        entityType: SyncEntityType.planner,
        action: SyncAction.create,
        payload: const {'hours': 4},
        timestamp: now,
      );

      final batch = SyncBatch(
        batchId: 'batch_1',
        userId: 'user_titan',
        items: [item],
        createdAt: now,
      );

      expect(batch.items.length, 1);

      final json = batch.toJson();
      final restored = SyncBatch.fromJson(json);

      expect(restored.batchId, batch.batchId);
      expect(restored.items.first.entityId, 'plan_1');
    });

    test('SyncConflict serialization', () {
      final local = SyncItem(
        id: 'loc_1',
        entityId: 'ent_1',
        entityType: SyncEntityType.revision,
        action: SyncAction.update,
        payload: const {'score': 80},
        timestamp: now,
      );
      final remote = SyncItem(
        id: 'rem_1',
        entityId: 'ent_1',
        entityType: SyncEntityType.revision,
        action: SyncAction.update,
        payload: const {'score': 90},
        timestamp: now.add(const Duration(minutes: 5)),
      );

      final conflict = SyncConflict(
        conflictId: 'conf_1',
        localItem: local,
        remoteItem: remote,
        detectedAt: now,
      );

      final json = conflict.toJson();
      final restored = SyncConflict.fromJson(json);

      expect(restored.conflictId, 'conf_1');
      expect(restored.remoteItem.payload['score'], 90);
    });

    test('SyncResult initialization and copyWith', () {
      final result = SyncResult(
        isSuccess: true,
        itemsProcessed: 5,
        itemsFailed: 0,
        conflictsDetected: 1,
        completedAt: now,
      );

      expect(result.isSuccess, isTrue);
      expect(result.itemsProcessed, 5);
      expect(result.conflictsDetected, 1);
    });
  });
}
