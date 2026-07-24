/// Abstract lifecycle interface for all repositories in Project TITAN.
abstract class Repository<T> {
  /// Initializes the repository and its underlying connections or caches.
  Future<void> initialize();

  /// Returns true if the repository has been initialized.
  bool get isInitialized;

  /// Disposes of the repository and releases backing resources.
  Future<void> dispose();
}
