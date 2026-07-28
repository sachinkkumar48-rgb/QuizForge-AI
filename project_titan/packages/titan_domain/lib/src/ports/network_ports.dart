import 'package:meta/meta.dart';

/// Strongly typed HTTP request methods supported in Project TITAN.
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
  head;

  /// Uppercase string representation (e.g. "GET", "POST").
  String get nameUpperCase => name.toUpperCase();
}

/// Immutable model representing an HTTP request in Project TITAN.
@immutable
class NetworkRequest {
  final HttpMethod method;
  final String url;
  final Map<String, String> headers;
  final Map<String, String> queryParameters;
  final Object? body;
  final Duration? timeout;

  NetworkRequest({
    required this.method,
    required this.url,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    this.body,
    this.timeout,
  })  : headers = Map<String, String>.unmodifiable(headers ?? const {}),
        queryParameters =
            Map<String, String>.unmodifiable(queryParameters ?? const {});

  /// Creates a copy of this [NetworkRequest] with modified values.
  NetworkRequest copyWith({
    HttpMethod? method,
    String? url,
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
    Duration? timeout,
  }) {
    return NetworkRequest(
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      queryParameters: queryParameters ?? this.queryParameters,
      body: body ?? this.body,
      timeout: timeout ?? this.timeout,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkRequest &&
          runtimeType == other.runtimeType &&
          method == other.method &&
          url == other.url &&
          headers == other.headers &&
          queryParameters == other.queryParameters &&
          body == other.body &&
          timeout == other.timeout;

  @override
  int get hashCode =>
      method.hashCode ^
      url.hashCode ^
      headers.hashCode ^
      queryParameters.hashCode ^
      body.hashCode ^
      timeout.hashCode;

  @override
  String toString() =>
      'NetworkRequest(${method.nameUpperCase} $url, headers: $headers, params: $queryParameters)';
}

/// Immutable generic model representing an HTTP response in Project TITAN.
@immutable
class NetworkResponse<T> {
  final int statusCode;
  final Map<String, String> headers;
  final T? body;
  final NetworkRequest request;
  final DateTime receivedAt;

  NetworkResponse({
    required this.statusCode,
    Map<String, String>? headers,
    this.body,
    required this.request,
    DateTime? receivedAt,
  })  : headers = Map<String, String>.unmodifiable(headers ?? const {}),
        receivedAt = receivedAt ?? DateTime.now();

  const NetworkResponse.constResponse({
    required this.statusCode,
    required this.headers,
    this.body,
    required this.request,
    required this.receivedAt,
  });

  /// Returns true if HTTP status code indicates success (200-299).
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Returns true if HTTP status code indicates a redirect (300-399).
  bool get isRedirect => statusCode >= 300 && statusCode < 400;

  /// Returns true if HTTP status code indicates client error (400-499).
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Returns true if HTTP status code indicates server error (500-599).
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkResponse<T> &&
          runtimeType == other.runtimeType &&
          statusCode == other.statusCode &&
          headers == other.headers &&
          body == other.body &&
          request == other.request &&
          receivedAt == other.receivedAt;

  @override
  int get hashCode =>
      statusCode.hashCode ^
      headers.hashCode ^
      body.hashCode ^
      request.hashCode ^
      receivedAt.hashCode;

  @override
  String toString() =>
      'NetworkResponse<$T>(statusCode: $statusCode, isSuccess: $isSuccess, url: ${request.url})';
}

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

/// Abstract network service contract for Project TITAN.
abstract class NetworkService {
  /// Initializes the networking client.
  Future<void> initialize();

  /// Returns true if network service is initialized.
  bool get isInitialized;

  /// Executes an HTTP GET request.
  Future<NetworkResponse<T>> get<T>(NetworkRequest request);

  /// Executes an HTTP POST request.
  Future<NetworkResponse<T>> post<T>(NetworkRequest request);

  /// Executes an HTTP PUT request.
  Future<NetworkResponse<T>> put<T>(NetworkRequest request);

  /// Executes an HTTP PATCH request.
  Future<NetworkResponse<T>> patch<T>(NetworkRequest request);

  /// Executes an HTTP DELETE request.
  Future<NetworkResponse<T>> delete<T>(NetworkRequest request);

  /// Executes an HTTP HEAD request.
  Future<NetworkResponse<T>> head<T>(NetworkRequest request);

  /// Executes a generic [NetworkRequest].
  Future<NetworkResponse<T>> request<T>(NetworkRequest request);

  /// Closes the network client and releases resources.
  Future<void> close();
}
