import '../core/sync_snapshot.dart';

/// Identifier for supported cloud sync backends.
enum CloudProviderType {
  none,
  googleDrive,
  firebase,
  customBackend,
}

/// Abstract contract for cloud storage sync providers.
abstract class CloudSyncProvider {
  /// Provider type.
  CloudProviderType get providerType;

  /// Human readable display name of the provider.
  String get name;

  /// Authenticate or connect with the cloud provider backend.
  Future<bool> authenticate();

  /// Check if active connection to cloud backend is available.
  Future<bool> isConnected();

  /// Download the latest snapshot or delta changes from cloud storage.
  Future<SyncSnapshot?> downloadSnapshot();

  /// Upload local snapshot or delta changes to cloud storage.
  Future<bool> uploadSnapshot(SyncSnapshot snapshot);

  /// Disconnect or log out from cloud provider.
  Future<void> disconnect();
}
