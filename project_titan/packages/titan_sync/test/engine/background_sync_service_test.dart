import 'package:flutter_test/flutter_test.dart';
import 'package:titan_sync/titan_sync.dart';

void main() {
  group('BackgroundSyncService Tests', () {
    late SyncRepository repository;
    late MockCloudProvider cloudProvider;
    late SyncManager syncManager;
    late BackgroundSyncService service;

    setUp(() {
      repository = SyncRepositoryImpl();
      cloudProvider = MockCloudProvider();
      syncManager = SyncManager(
        repository: repository,
        cloudProvider: cloudProvider,
      );
      service = BackgroundSyncService(
        syncManager: syncManager,
        interval: const Duration(milliseconds: 100),
      );
    });

    tearDown(() async {
      service.stop();
      await syncManager.dispose();
    });

    test('start and stop background periodic scheduling', () {
      expect(service.isRunning, isFalse);
      service.start();
      expect(service.isRunning, isTrue);
      service.stop();
      expect(service.isRunning, isFalse);
    });

    test('triggerNow executes immediate sync', () async {
      await service.triggerNow();
      expect(syncManager.lastSyncTime, isNotNull);
    });
  });
}
