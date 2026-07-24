/// Base exception class for all domain repository errors in Project TITAN.
abstract class RepositoryException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const RepositoryException(this.message, [this.cause, this.stackTrace]);

  @override
  String toString() {
    final causeStr = cause != null ? ' (Cause: $cause)' : '';
    return '$runtimeType: $message$causeStr';
  }
}

/// Thrown when repository initialization or disposal fails.
class RepositoryInitializationException extends RepositoryException {
  const RepositoryInitializationException(super.message,
      [super.cause, super.stackTrace]);
}

/// Thrown when local cache or storage access fails.
class RepositoryCacheException extends RepositoryException {
  const RepositoryCacheException(super.message,
      [super.cause, super.stackTrace]);
}

/// Thrown when network connectivity, HTTP API, or remote requests fail.
class RepositoryNetworkException extends RepositoryException {
  final int? statusCode;

  const RepositoryNetworkException(
    super.message, [
    this.statusCode,
    super.cause,
    super.stackTrace,
  ]);
}

/// Thrown when LLM / AI service generation or provider calls fail.
class RepositoryAIException extends RepositoryException {
  const RepositoryAIException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when data parsing, schema validation, or domain conversion fails.
class RepositoryDataException extends RepositoryException {
  const RepositoryDataException(super.message, [super.cause, super.stackTrace]);
}
