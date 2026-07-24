import 'package:flutter_test/flutter_test.dart';
import 'package:titan_sync/titan_sync.dart';

void main() {
  group('Sync Use Cases Unit Tests', () {
    late SyncRepository repository;
    late MockCloudProvider cloudProvider;
    late SyncManager syncManager;
    final now = DateTime.now();

    setUp(() {
      repository = SyncRepositoryImpl();
      cloudProvider = MockCloudProvider();
      syncManager = SyncManager(
        repository: repository,
        cloudProvider: cloudProvider,
      );
    });

    tearDown(() async {
      await syncManager.dispose();
    });

    test('QueueSyncUseCase enqueues item', () async {
      final useCase = QueueSyncUseCase(syncManager);
      final item = SyncItem(
        id: 'uc_q1',
        entityId: 'ent_q',
        entityType: SyncEntityType.revision,
        action: SyncAction.create,
        payload: const {'card': 'Flashcard'},
        timestamp: now,
      );

      await useCase.execute(item);
      final pending = await repository.getPendingItems();

      expect(pending.length, 1);
      expect(pending.first.id, 'uc_q1');
    });

    test('SyncNowUseCase triggers sync operation', () async {
      final useCase = SyncNowUseCase(syncManager);
      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
    });

    test('RetryFailedSyncUseCase retries failed sync items', () async {
      final item = SyncItem(
        id: 'uc_fail',
        entityId: 'ent_uc',
        entityType: SyncEntityType.knowledgeGraph,
        action: SyncAction.update,
        payload: const {'node': 'History'},
        timestamp: now,
        status: SyncItemStatus.failed,
      );
      await repository.queueItem(item);

      final useCase = RetryFailedSyncUseCase(syncManager);
      final result = await useCase.execute();

      expect(result.isSuccess, isTrue);
    });

    test('ResolveConflictUseCase resolves conflict', () async {
      final local = SyncItem(
        id: 'c_loc',
        entityId: 'ent_conf',
        entityType: SyncEntityType.notes,
        action: SyncAction.update,
        payload: const {'v': 1},
        timestamp: now,
      );
      final remote = SyncItem(
        id: 'c_rem',
        entityId: 'ent_conf',
        entityType: SyncEntityType.notes,
        action: SyncAction.update,
        payload: const {'v': 2},
        timestamp: now.add(const Duration(minutes: 1)),
      );
      final conflict = SyncConflict(
        conflictId: 'conf_uc',
        localItem: local,
        remoteItem: remote,
        detectedAt: now,
      );
      await repository.saveConflict(conflict);

      final useCase = ResolveConflictUseCase(syncManager);
      await useCase.execute('conf_uc', strategy: ConflictStrategy.serverWins);

      final conflicts = await repository.getConflicts();
      expect(conflicts, isEmpty);
    });
  });
}
