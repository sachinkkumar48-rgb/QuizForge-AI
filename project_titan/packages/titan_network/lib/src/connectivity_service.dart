/// Contract for querying device network connectivity.
abstract class ConnectivityService {
  /// Returns true if device currently has active network connectivity.
  Future<bool> isConnected();
}

/// Default implementation assuming network is always connected.
class AlwaysConnectedService implements ConnectivityService {
  const AlwaysConnectedService();

  @override
  Future<bool> isConnected() async => true;
}
