import '../core/sync_snapshot.dart';
import 'cloud_sync_provider.dart';

/// Generic Custom REST API sync provider architecture.
class CustomBackendSyncProvider implements CloudSyncProvider {
  final String serverUrl;
  final String authToken;
  bool _isAuthenticated = false;
  SyncSnapshot? _remoteSnapshotStore;

  CustomBackendSyncProvider({
    required this.serverUrl,
    required this.authToken,
  });

  @override
  CloudProviderType get providerType => CloudProviderType.customBackend;

  @override
  String get name => 'Custom Server API';

  @override
  Future<bool> authenticate() async {
    _isAuthenticated = serverUrl.isNotEmpty && authToken.isNotEmpty;
    return _isAuthenticated;
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
