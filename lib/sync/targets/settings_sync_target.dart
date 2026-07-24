import '../core/sync_entity.dart';
import '../core/sync_metadata.dart';
import '../core/sync_target.dart';

/// Sync target adapter for Application Settings & Preferences domain.
class SettingsSyncTarget implements SyncTarget {
  final Map<String, dynamic> _localSettingsStore = {};
  final String deviceId;
  DateTime? _lastSyncTime;

  SettingsSyncTarget({
    required this.deviceId,
    Map<String, dynamic>? initialSettings,
  }) {
    if (initialSettings != null) {
      _localSettingsStore.addAll(initialSettings);
    }
  }

  @override
  SyncEntityType get targetType => SyncEntityType.settings;

  @override
  Future<List<SyncEntity<Map<String, dynamic>>>> getPendingEntities(
      {DateTime? sinceTimestamp}) async {
    if (_localSettingsStore.isEmpty) return [];

    final meta = SyncMetadata(
      entityId: 'app_user_settings',
      entityType: SyncEntityType.settings,
      version: 1,
      updatedAt: DateTime.now().toUtc(),
      clientDeviceId: deviceId,
      checksum: SyncMetadata.computeChecksum(_localSettingsStore),
    );

    return [
      SyncEntity(
        metadata: meta,
        payload: Map<String, dynamic>.from(_localSettingsStore),
      ),
    ];
  }

  @override
  Future<int> applyRemoteEntities(
      List<SyncEntity<Map<String, dynamic>>> entities) async {
    int appliedCount = 0;
    for (final entity in entities) {
      if (!entity.metadata.isDeleted) {
        _localSettingsStore.addAll(entity.payload);
      }
      appliedCount++;
    }
    return appliedCount;
  }

  @override
  Future<List<SyncEntity<Map<String, dynamic>>>> exportLocalEntities() async {
    return getPendingEntities();
  }

  @override
  Future<DateTime?> getLastSyncTime() async => _lastSyncTime;

  @override
  Future<void> updateLastSyncTime(DateTime timestamp) async {
    _lastSyncTime = timestamp;
  }

  /// Helper to get local setting key.
  dynamic getSetting(String key) => _localSettingsStore[key];

  /// Helper to update local setting key.
  void setSetting(String key, dynamic value) {
    _localSettingsStore[key] = value;
  }
}
