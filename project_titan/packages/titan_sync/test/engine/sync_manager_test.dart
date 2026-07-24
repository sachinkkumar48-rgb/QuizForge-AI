import 'package:flutter_test/flutter_test.dart';
import 'package:titan_identity/titan_identity.dart';
import 'package:titan_sync/titan_sync.dart';

void main() {
  group('SyncManager Tests', () {
    late SyncRepository repository;
    late MockCloudProvider cloudProvider;
    late SessionManager sessionManager;
    late SyncManager syncManager;
    final now = DateTime.now();

    setUp(() async {
      repository = SyncRepositoryImpl();
      cloudProvider = MockCloudProvider();

      final user = User(
        id: 'usr_sync_mgr',
        email: 'mgr@titan.ai',
        displayName: 'Mgr Learner',
        providerType: AuthProviderType.google,
        createdAt: now,
      );
      final session = UserSession(
        sessionId: 'sess_mgr',
        user: user,
        accessToken: 'tok_mgr',
        expiresAt: now.add(const Duration(hours: 5)),
      );
      sessionManager = SessionManager(initialSession: session);

      syncManager = SyncManager(
        repository: repository,
        cloudProvider: cloudProvider,
        sessionManager: sessionManager,
      );
    });

    tearDown(() async {
      await syncManager.dispose();
      await sessionManager.dispose();
    });

    test('queueItem and syncNow pushes pending items', () async {
      final item = SyncItem(
        id: 'sm_1',
        entityId: 'note_sm1',
        entityType: SyncEntityType.notes,
        action: SyncAction.create,
        payload: const {'text': 'Sync Manager Note'},
        timestamp: now,
      );

      await syncManager.queueItem(item);

      final result = await syncManager.syncNow();
      expect(result.isSuccess, isTrue);
      expect(result.itemsProcessed, 1);
      expect(syncManager.status, SyncEngineStatus.success);
    });

    test('syncNow fails when user is unauthenticated', () async {
      await sessionManager.clearSession();

      final result = await syncManager.syncNow();
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'User is not authenticated.');
      expect(syncManager.status, SyncEngineStatus.failed);
    });

    test('retryFailedSync re-attempts failed items', () async {
      final item = SyncItem(
        id: 'fail_1',
        entityId: 'ent_fail',
        entityType: SyncEntityType.planner,
        action: SyncAction.update,
        payload: const {'task': 'Plan'},
        timestamp: now,
        status: SyncItemStatus.failed,
      );

      await repository.queueItem(item);

      final result = await syncManager.retryFailedSync();
      expect(result.isSuccess, isTrue);
    });
  });
}
