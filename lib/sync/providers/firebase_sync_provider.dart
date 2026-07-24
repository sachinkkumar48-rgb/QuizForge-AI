import '../core/sync_snapshot.dart';
import 'cloud_sync_provider.dart';

/// Firebase Firestore collection & document sync provider architecture.
class FirebaseSyncProvider implements CloudSyncProvider {
  bool _isAuthenticated = false;
  SyncSnapshot? _remoteSnapshotStore;

  @override
  CloudProviderType get providerType => CloudProviderType.firebase;

  @override
  String get name => 'Firebase Cloud Firestore';

  @override
  Future<bool> authenticate() async {
    _isAuthenticated = true;
    return true;
  }

  @override
  Future<bool> isConnected() async => _isAuthenticated;

  @override
  Future<SyncSnapshot?> downloadSnapshot() async {
    if (!_isAuthenticated) return null;
    return _remoteSnapshotStore;
  }

  @override
  Future<bool> uploadSnapshot(SyncSnapshot snapshot) async {
    if (!_isAuthenticated) return false;
    _remoteSnapshotStore = snapshot;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _isAuthenticated = false;
  }
}
