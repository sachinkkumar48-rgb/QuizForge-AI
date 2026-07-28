/// Base exception class for all AI foundation errors in Project TITAN.
abstract class AIException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const AIException(this.message, [this.cause, this.stackTrace]);

  @override
  String toString() {
    final causeStr = cause != null ? ' (Cause: $cause)' : '';
    return '$runtimeType: $message$causeStr';
  }
}

/// Thrown when AI service or provider initialization fails.
class AIInitializationException extends AIException {
  const AIInitializationException(super.message,
      [super.cause, super.stackTrace]);
}

/// Thrown when an AI request payload is invalid or rejected prior to execution.
class AIRequestException extends AIException {
  const AIRequestException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when network connectivity or socket errors occur during AI requests.
class AINetworkException extends AIException {
  const AINetworkException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when safety validation (prompt injection, XSS, credential leaks) fails.
class AISafetyException extends AIException {
  final String? flaggedCategory;

  const AISafetyException(
    super.message, [
    this.flaggedCategory,
    super.cause,
    super.stackTrace,
  ]);
}

/// Thrown when a requested feature or provider operation is unsupported.
class AIUnsupportedException extends AIException {
  const AIUnsupportedException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when an AI provider returns an error response or unparseable output.
class AIResponseException extends AIException {
  final int? statusCode;

  const AIResponseException(
    super.message, [
    this.statusCode,
    super.cause,
    super.stackTrace,
  ]);
}

/// Thrown when a requested provider is not found or fails to execute.
class AIProviderException extends AIException {
  final String? providerName;

  const AIProviderException(
    super.message, [
    this.providerName,
    super.cause,
    super.stackTrace,
  ]);
}

/// Thrown when an invalid or unsupported AI model is specified.
class AIModelException extends AIException {
  final String? modelId;

  const AIModelException(
    super.message, [
    this.modelId,
    super.cause,
    super.stackTrace,
  ]);
}
