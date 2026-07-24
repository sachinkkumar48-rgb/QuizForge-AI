import '../models/sync_batch.dart';
import '../models/sync_item.dart';

/// Abstract contract for cloud synchronization providers.
abstract class CloudProvider {
  /// Pushes a [SyncBatch] of items to cloud backend.
  Future<List<SyncItem>> pushBatch(SyncBatch batch);

  /// Pulls remote sync changes since [since] timestamp for [userId].
  Future<List<SyncItem>> pullChanges({
    required String userId,
    DateTime? since,
  });

  /// Retrieves current server time for timestamp reconciliation.
  Future<DateTime> getServerTime();
}

/// Offline-aware Mock Cloud Provider for testing and demonstration.
class MockCloudProvider implements CloudProvider {
  final Map<String, SyncItem> _remoteDatabase = {};
  bool isOnline;
  bool shouldFailNetwork;

  MockCloudProvider({
    this.isOnline = true,
    this.shouldFailNetwork = false,
  });

  @override
  Future<List<SyncItem>> pushBatch(SyncBatch batch) async {
    if (!isOnline || shouldFailNetwork) {
      throw StateError('Cloud push failed: Network unavailable.');
    }

    final confirmedItems = <SyncItem>[];
    for (final item in batch.items) {
      final updated = item.copyWith(
        status: SyncItemStatus.synced,
        retryCount: 0,
      );
      _remoteDatabase[item.entityId] = updated;
      confirmedItems.add(updated);
    }

    return confirmedItems;
  }

  @override
  Future<List<SyncItem>> pullChanges({
    required String userId,
    DateTime? since,
  }) async {
    if (!isOnline || shouldFailNetwork) {
      throw StateError('Cloud pull failed: Network unavailable.');
    }

    if (since == null) {
      return _remoteDatabase.values.toList();
    }

    return _remoteDatabase.values
        .where((item) => item.timestamp.isAfter(since))
        .toList();
  }

  @override
  Future<DateTime> getServerTime() async {
    return DateTime.now();
  }

  /// Helper to clear mock remote state in tests.
  void clearRemoteDatabase() {
    _remoteDatabase.clear();
  }

  /// Helper to insert mock remote data in tests.
  void seedRemoteItem(SyncItem item) {
    _remoteDatabase[item.entityId] = item;
  }
}
