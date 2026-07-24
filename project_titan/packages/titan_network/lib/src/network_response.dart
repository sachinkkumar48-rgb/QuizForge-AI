import 'package:meta/meta.dart';
import 'network_request.dart';

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
