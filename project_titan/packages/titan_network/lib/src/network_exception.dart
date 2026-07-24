import 'network_response.dart';

/// Base exception class for all networking errors in Project TITAN.
abstract class NetworkException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const NetworkException(this.message, [this.cause, this.stackTrace]);

  @override
  String toString() {
    final causeStr = cause != null ? ' (Cause: $cause)' : '';
    return '$runtimeType: $message$causeStr';
  }
}

/// Thrown when network client initialization fails or operations occur on uninitialized service.
class NetworkInitializationException extends NetworkException {
  const NetworkInitializationException(super.message,
      [super.cause, super.stackTrace]);
}

/// Thrown when a network request times out.
class NetworkTimeoutException extends NetworkException {
  final Duration? timeout;

  const NetworkTimeoutException(
    super.message, [
    this.timeout,
    super.cause,
    super.stackTrace,
  ]);
}

/// Thrown when device has no connectivity or network socket fails.
class NetworkConnectionException extends NetworkException {
  const NetworkConnectionException(super.message,
      [super.cause, super.stackTrace]);
}

/// Thrown when an HTTP status code indicates an error response.
class NetworkResponseException extends NetworkException {
  final int statusCode;
  final NetworkResponse<dynamic>? response;

  const NetworkResponseException(
    String message, {
    required this.statusCode,
    this.response,
    Object? cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);
}

/// Thrown when response parsing or JSON serialization fails.
class NetworkSerializationException extends NetworkException {
  const NetworkSerializationException(super.message,
      [super.cause, super.stackTrace]);
}
