import 'storage_entry.dart';
import 'storage_key.dart';

/// Abstract storage service contract defining framework-independent persistence operations.
abstract class StorageService {
  /// Initializes the storage engine.
  Future<void> initialize();

  /// Returns true if the storage service has been initialized and is ready for use.
  bool get isInitialized;

  /// Returns true if the storage engine contains an entry for [key].
  Future<bool> contains(StorageKey key);

  /// Reads a value associated with [key]. Returns null if key is not found.
  /// Throws [StorageReadException] on read failure or type mismatch.
  Future<T?> read<T>(StorageKey key);

  /// Reads the full [StorageEntry] associated with [key] including metadata.
  Future<StorageEntry<T>?> readEntry<T>(StorageKey key);

  /// Writes a value associated with [key].
  /// Throws [StorageWriteException] on write failure.
  Future<void> write<T>(StorageKey key, T value);

  /// Deletes the entry associated with [key].
  /// Throws [StorageDeleteException] on delete failure.
  Future<void> delete(StorageKey key);

  /// Clears all entries in storage.
  /// Throws [StorageDeleteException] on clear failure.
  Future<void> clear();

  /// Returns all stored [StorageKey]s (optionally filtered by [namespace]).
  Future<List<StorageKey>> keys({String? namespace});

  /// Closes the storage service and releases underlying resources.
  Future<void> close();
}
