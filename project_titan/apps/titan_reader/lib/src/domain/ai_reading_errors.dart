library;

/// Base exception for AI reading assistant failures.
abstract class AIReadingException implements Exception {
  final String message;
  final Object? cause;

  const AIReadingException(this.message, [this.cause]);

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' ($cause)' : ''}';
}

/// Thrown when the selected local or remote AI provider is unreachable or not running.
class AIProviderUnavailableException extends AIReadingException {
  final String providerId;
  const AIProviderUnavailableException(String message,
      {required this.providerId, Object? cause})
      : super(message, cause);
}

/// Thrown when the specified model is not found or failed to load.
class AIModelUnavailableException extends AIReadingException {
  final String modelId;
  const AIModelUnavailableException(String message,
      {required this.modelId, Object? cause})
      : super(message, cause);
}

/// Thrown when an API key is missing or invalid.
class AIAuthenticationException extends AIReadingException {
  const AIAuthenticationException(super.message, [super.cause]);
}

/// Thrown when remote rate limits or token quotas are exceeded.
class AIQuotaExceededException extends AIReadingException {
  const AIQuotaExceededException(super.message, [super.cause]);
}

/// Thrown when prompt/context exceeds maximum context window.
class AIContextTooLargeException extends AIReadingException {
  const AIContextTooLargeException(super.message, [super.cause]);
}

/// Thrown when an AI generation request times out.
class AIRequestTimeoutException extends AIReadingException {
  const AIRequestTimeoutException(super.message, [super.cause]);
}

/// Thrown when an AI response payload is malformed or violates expected schema.
class AIResponseInvalidException extends AIReadingException {
  const AIResponseInvalidException(super.message, [super.cause]);
}

/// Thrown when network transport or socket failure occurs.
class AINetworkException extends AIReadingException {
  const AINetworkException(super.message, [super.cause]);
}
