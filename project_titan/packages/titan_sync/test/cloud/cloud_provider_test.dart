import 'package:flutter_test/flutter_test.dart';
import 'package:titan_sync/titan_sync.dart';

void main() {
  group('MockCloudProvider Tests', () {
    late MockCloudProvider provider;
    final now = DateTime.now();

    setUp(() {
      provider = MockCloudProvider();
    });

    test('Pushes batch successfully when online', () async {
      final item = SyncItem(
        id: 'cp_1',
        entityId: 'ent_cp1',
        entityType: SyncEntityType.analytics,
        action: SyncAction.create,
        payload: const {'score': 95},
        timestamp: now,
      );

      final batch = SyncBatch(
        batchId: 'b_cp',
        userId: 'user_1',
        items: [item],
        createdAt: now,
      );

      final confirmed = await provider.pushBatch(batch);
      expect(confirmed.length, 1);
      expect(confirmed.first.status, SyncItemStatus.synced);
    });

    test('Throws StateError when offline or network fails', () async {
      provider.isOnline = false;

      final batch = SyncBatch(
        batchId: 'b_fail',
        userId: 'user_1',
        items: const [],
        createdAt: now,
      );

      expect(
        () => provider.pushBatch(batch),
        throwsA(isA<StateError>()),
      );
    });

    test('Pulls changes correctly', () async {
      final item = SyncItem(
        id: 'seed_1',
        entityId: 'kg_10',
        entityType: SyncEntityType.knowledgeGraph,
        action: SyncAction.create,
        payload: const {'node': 'Polity'},
        timestamp: now,
      );

      provider.seedRemoteItem(item);

      final pulled = await provider.pullChanges(userId: 'user_1');
      expect(pulled.length, 1);
      expect(pulled.first.entityId, 'kg_10');
    });
  });
}
