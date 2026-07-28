import 'package:flutter_test/flutter_test.dart';
import 'package:titan_sync/titan_sync.dart';

void main() {
  group('Sync Models Unit Tests', () {
    test('SyncOperation serialization and copyWith', () {
      final op = SyncOperation(
        operationId: 'op_1',
        entityType: SyncEntityType.videoProgress,
        entityId: 'vid_101',
        action: SyncAction.update,
        payload: const {'positionSeconds': 420},
        timestamp: DateTime.now(),
        version: 1,
        deviceId: 'dev_phone',
      );

      expect(op.operationId, equals('op_1'));
      expect(op.entityType, equals(SyncEntityType.videoProgress));
      expect(op.payload['positionSeconds'], equals(420));

      final json = op.toJson();
      final deserialized = SyncOperation.fromJson(json);
      expect(deserialized.operationId, equals(op.operationId));
      expect(deserialized.entityType, equals(op.entityType));
    });

    test('SyncSnapshot serialization and entity counting', () {
      final snap = SyncSnapshot(
        snapshotId: 'snap_1',
        userId: 'u1',
        deviceId: 'dev_tablet',
        createdAt: DateTime.now(),
        entitySnapshots: const {
          SyncEntityType.notes: {
            'n1': {'title': 'Note 1'},
            'n2': {'title': 'Note 2'},
          },
          SyncEntityType.planner: {
            'p1': {'target': 6.0},
          },
        },
        checksum: 'chk_123',
      );

      expect(snap.totalEntityCount, equals(3));
      final json = snap.toJson();
      final deserialized = SyncSnapshot.fromJson(json);
      expect(deserialized.snapshotId, equals('snap_1'));
      expect(deserialized.totalEntityCount, equals(3));
    });

    test('SyncQueue enqueue and dequeue behavior', () {
      final queue = SyncQueue();
      final item = SyncItem(
        id: 's1',
        entityType: SyncEntityType.assessmentResults,
        entityId: 'ass_1',
        action: SyncAction.create,
        payload: const {'score': 90},
        version: 1,
        status: SyncItemStatus.pending,
        timestamp: DateTime.now(),
      );
      final op = SyncOperation(
        operationId: 'op_1',
        entityType: SyncEntityType.assessmentResults,
        entityId: 'ass_1',
        action: SyncAction.create,
        payload: const {'score': 90},
        timestamp: item.timestamp,
        version: 1,
        deviceId: 'dev_1',
      );

      queue.enqueue(op, item);
      expect(queue.length, equals(1));
      expect(queue.pendingItems.length, equals(1));

      final dequeued = queue.dequeue();
      expect(dequeued?.operationId, equals('op_1'));
      expect(queue.length, equals(0));
    });
  });
}
