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
