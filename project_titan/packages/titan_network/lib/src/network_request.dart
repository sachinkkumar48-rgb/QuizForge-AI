import 'package:meta/meta.dart';
import 'http_method.dart';

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
