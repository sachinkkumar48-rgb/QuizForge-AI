import 'package:flutter_test/flutter_test.dart';
import 'package:titan_sync/titan_sync.dart';

class MockSyncRepository implements SyncRepository {
  final List<SyncItem> _items = [];
  final List<SyncConflict> _conflicts = [];

  @override
  Future<void> queueItem(SyncItem item) async {
    _items.removeWhere(
        (i) => i.syncId == item.syncId || i.entityId == item.entityId);
    _items.add(item);
  }

  @override
  Future<List<SyncItem>> getPendingItems() async {
    return _items.where((i) => i.status == SyncItemStatus.pending).toList();
  }

  @override
  Future<List<SyncItem>> getAllItems() async => List.unmodifiable(_items);

  @override
  Future<void> updateItem(SyncItem item) async {
    final idx = _items.indexWhere((i) => i.entityId == item.entityId);
    if (idx >= 0) {
      _items[idx] = item;
    } else {
      _items.add(item);
    }
  }

  @override
  Future<void> clearSyncedItems() async {
    _items.removeWhere((i) => i.status == SyncItemStatus.synced);
  }

  @override
  Future<List<SyncConflict>> getConflicts() async =>
      List.unmodifiable(_conflicts);

  @override
  Future<void> saveConflict(SyncConflict conflict) async {
    _conflicts.add(conflict);
  }

  @override
  Future<void> resolveConflict(String conflictId, SyncItem resolvedItem) async {
    _conflicts.removeWhere((c) => c.conflictId == conflictId);
    await updateItem(resolvedItem);
  }

  @override
  Future<void> removeItem(String itemId) async {
    _items.removeWhere((i) => i.id == itemId || i.entityId == itemId);
  }
}

class MockCloudProvider implements CloudProvider {
  bool shouldFail = false;
  List<SyncItem> remoteChanges = [];

  @override
  Future<DateTime> getServerTime() async => DateTime.now();

  @override
  Future<List<SyncItem>> pushBatch(SyncBatch batch) async {
    if (shouldFail) {
      throw Exception('Network push failure');
    }
    return batch.items
        .map((i) => i.copyWith(status: SyncItemStatus.synced))
        .toList();
  }

  @override
  Future<List<SyncItem>> pullChanges(
      {required String userId, DateTime? since}) async {
    if (shouldFail) {
      throw Exception('Network pull failure');
    }
    return remoteChanges;
  }
}

void main() {
  group('SyncOrchestrator Tests', () {
    late MockSyncRepository repository;
    late MockCloudProvider cloudProvider;
    late SyncOrchestrator orchestrator;

    setUp(() {
      repository = MockSyncRepository();
      cloudProvider = MockCloudProvider();
      orchestrator = SyncOrchestrator(
        repository: repository,
        cloudProvider: cloudProvider,
      );
    });

    tearDown(() async {
      await orchestrator.close();
    });

    test('queues local mutation and updates state', () async {
      await orchestrator.queueMutation(
        entityType: SyncEntityType.notes,
        entityId: 'note_101',
        action: SyncAction.create,
        payload: {'title': 'Polity Note'},
      );

      expect(orchestrator.queue.length, equals(1));
      expect(orchestrator.state.pendingOperationsCount, equals(1));
    });

    test('executes successful push/pull synchronization', () async {
      await orchestrator.queueMutation(
        entityType: SyncEntityType.planner,
        entityId: 'plan_1',
        action: SyncAction.update,
        payload: {'hours': 6.0},
      );

      final result = await orchestrator.synchronize();

      expect(result.isSuccess, isTrue);
      expect(result.itemsProcessed, equals(1));
      expect(orchestrator.state.phase, equals(SyncPhase.success));
      expect(orchestrator.telemetryCollector.computeSummary().totalSyncRuns,
          equals(1));
    });

    test('defers sync and queues items when offline', () async {
      orchestrator.setOnlineStatus(false);

      await orchestrator.queueMutation(
        entityType: SyncEntityType.bookmarks,
        entityId: 'bm_1',
        action: SyncAction.create,
        payload: {'url': 'https://quizforge.ai'},
      );

      final result = await orchestrator.synchronize();
      expect(result.errorMessage, contains('offline'));
    });

    test('creates full system snapshot', () async {
      await orchestrator.queueMutation(
        entityType: SyncEntityType.identity,
        entityId: 'user_1',
        action: SyncAction.update,
        payload: {'userName': 'Aspirant'},
      );

      final snapshot = await orchestrator.createSnapshot(deviceId: 'dev_1');
      expect(snapshot.deviceId, equals('dev_1'));
      expect(snapshot.totalEntityCount, equals(1));
    });
  });
}
