import 'package:meta/meta.dart';

/// Strongly typed key abstraction for storage entries in Project TITAN.
@immutable
class StorageKey {
  /// Unique string identifier for the storage key.
  final String rawKey;

  /// Optional namespace or domain partition for logical grouping.
  final String? namespace;

  const StorageKey(this.rawKey, {this.namespace});

  /// Full qualified key path combining namespace and raw key.
  String get qualifiedKey => namespace != null && namespace!.isNotEmpty
      ? '$namespace:$rawKey'
      : rawKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageKey &&
          runtimeType == other.runtimeType &&
          rawKey == other.rawKey &&
          namespace == other.namespace;

  @override
  int get hashCode => rawKey.hashCode ^ namespace.hashCode;

  @override
  String toString() => qualifiedKey;
}

/// Immutable model representing a single key-value record in storage with metadata.
@immutable
class StorageEntry<T> {
  final StorageKey key;
  final T value;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Generative constructor for [StorageEntry].
  StorageEntry({
    required this.key,
    required this.value,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  /// Const constructor requiring explicit timestamps.
  const StorageEntry.constEntry({
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this [StorageEntry] with an updated value and new [updatedAt] timestamp.
  StorageEntry<T> copyWithUpdatedValue(T newValue, [DateTime? updateTime]) {
    return StorageEntry<T>.constEntry(
      key: key,
      value: newValue,
      createdAt: createdAt,
      updatedAt: updateTime ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageEntry<T> &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          value == other.value &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      key.hashCode ^ value.hashCode ^ createdAt.hashCode ^ updatedAt.hashCode;

  @override
  String toString() =>
      'StorageEntry<$T>(key: $key, value: $value, createdAt: $createdAt, updatedAt: $updatedAt)';
}

/// Base exception class for all storage errors in Project TITAN.
abstract class StorageException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const StorageException(this.message, [this.cause, this.stackTrace]);

  @override
  String toString() {
    final causeStr = cause != null ? ' (Cause: $cause)' : '';
    return '$runtimeType: $message$causeStr';
  }
}

/// Thrown when storage initialization fails or service is accessed before initialization.
class StorageInitializationException extends StorageException {
  const StorageInitializationException(super.message,
      [super.cause, super.stackTrace]);
}

/// Thrown when reading a key from storage fails or type casting mismatches.
class StorageReadException extends StorageException {
  const StorageReadException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when writing a key-value entry to storage fails.
class StorageWriteException extends StorageException {
  const StorageWriteException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when deleting an entry or clearing storage fails.
class StorageDeleteException extends StorageException {
  const StorageDeleteException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when attempting operations on a closed storage instance.
class StorageClosedException extends StorageException {
  const StorageClosedException(super.message, [super.cause, super.stackTrace]);
}

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
