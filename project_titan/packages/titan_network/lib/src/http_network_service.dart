import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'connectivity_service.dart';
import 'http_method.dart';
import 'network_exception.dart';
import 'network_interceptor.dart';
import 'network_request.dart';
import 'network_response.dart';
import 'network_service.dart';
import 'retry_policy.dart';

/// Concrete implementation of [NetworkService] wrapping `package:http`.
class HttpNetworkService implements NetworkService {
  final http.Client _client;
  final Duration defaultTimeout;
  final ConnectivityService _connectivityService;
  final RetryPolicy _retryPolicy;
  final List<NetworkInterceptor> _interceptors;
  bool _isInitialized = false;
  bool _isClosed = false;

  HttpNetworkService({
    http.Client? client,
    this.defaultTimeout = const Duration(seconds: 30),
    ConnectivityService? connectivityService,
    RetryPolicy? retryPolicy,
    List<NetworkInterceptor>? interceptors,
  })  : _client = client ?? http.Client(),
        _connectivityService =
            connectivityService ?? const AlwaysConnectedService(),
        _retryPolicy = retryPolicy ?? const NoRetryPolicy(),
        _interceptors = List.unmodifiable(interceptors ?? []);

  @override
  bool get isInitialized => _isInitialized && !_isClosed;

  void _checkState() {
    if (_isClosed) {
      throw const NetworkInitializationException(
          'HttpNetworkService has been closed.');
    }
    if (!_isInitialized) {
      throw const NetworkInitializationException(
          'HttpNetworkService is not initialized.');
    }
  }

  @override
  Future<void> initialize() async {
    if (_isClosed) {
      throw const NetworkInitializationException(
          'Cannot initialize closed HttpNetworkService.');
    }
    _isInitialized = true;
  }

  @override
  Future<NetworkResponse<T>> request<T>(NetworkRequest rawRequest) async {
    _checkState();

    if (!await _connectivityService.isConnected()) {
      throw const NetworkConnectionException(
          'No active internet connection available.');
    }

    var currentRequest = rawRequest;
    for (final interceptor in _interceptors) {
      currentRequest = await interceptor.onRequest(currentRequest);
    }

    final effectiveTimeout = currentRequest.timeout ?? defaultTimeout;

    int attempt = 0;

    while (true) {
      attempt++;
      try {
        final uri =
            _buildUri(currentRequest.url, currentRequest.queryParameters);
        final headers = Map<String, String>.from(currentRequest.headers);

        http.Response httpResponse;
        final httpRequest =
            http.Request(currentRequest.method.nameUpperCase, uri);
        httpRequest.headers.addAll(headers);

        if (currentRequest.body != null) {
          if (currentRequest.body is String) {
            httpRequest.body = currentRequest.body as String;
          } else {
            httpRequest.body = jsonEncode(currentRequest.body);
            if (!headers.keys.any((k) => k.toLowerCase() == 'content-type')) {
              httpRequest.headers['content-type'] = 'application/json';
            }
          }
        }

        final streamedResponse =
            await _client.send(httpRequest).timeout(effectiveTimeout);
        httpResponse = await http.Response.fromStream(streamedResponse);

        final receivedAt = DateTime.now();

        T? parsedBody;
        if (httpResponse.body.isNotEmpty) {
          try {
            if (T == String) {
              parsedBody = httpResponse.body as T;
            } else {
              final jsonDecoded = jsonDecode(httpResponse.body);
              parsedBody = jsonDecoded as T?;
            }
          } catch (e, st) {
            if (T != String && T != dynamic) {
              throw NetworkSerializationException(
                  'Failed to parse response body as $T', e, st);
            }
            parsedBody = httpResponse.body as T?;
          }
        }

        var response = NetworkResponse<T>(
          statusCode: httpResponse.statusCode,
          headers: httpResponse.headers,
          body: parsedBody,
          request: currentRequest,
          receivedAt: receivedAt,
        );

        for (final interceptor in _interceptors) {
          final intercepted = await interceptor.onResponse(response);
          response = NetworkResponse<T>(
            statusCode: intercepted.statusCode,
            headers: intercepted.headers,
            body: intercepted.body as T?,
            request: intercepted.request,
            receivedAt: intercepted.receivedAt,
          );
        }

        return response;
      } catch (e, st) {
        NetworkException mappedException;
        if (e is TimeoutException) {
          mappedException = NetworkTimeoutException(
              'Request timed out after ${effectiveTimeout.inSeconds}s',
              effectiveTimeout,
              e,
              st);
        } else if (e is SocketException) {
          mappedException = NetworkConnectionException(
              'Failed to establish network connection', e, st);
        } else if (e is http.ClientException) {
          mappedException = NetworkConnectionException(
              'HTTP client error: ${e.message}', e, st);
        } else if (e is NetworkException) {
          mappedException = e;
        } else {
          mappedException =
              NetworkConnectionException('Network request failed', e, st);
        }

        for (final interceptor in _interceptors) {
          mappedException = await interceptor.onError(mappedException);
        }

        if (_retryPolicy.shouldRetry(mappedException, attempt)) {
          continue;
        }

        throw mappedException;
      }
    }
  }

  Uri _buildUri(String url, Map<String, String>? queryParameters) {
    final uri = Uri.parse(url);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    final mergedQuery = Map<String, String>.from(uri.queryParameters)
      ..addAll(queryParameters);
    return uri.replace(queryParameters: mergedQuery);
  }

  @override
  Future<NetworkResponse<T>> get<T>(NetworkRequest request) =>
      this.request<T>(request.copyWith(method: HttpMethod.get));

  @override
  Future<NetworkResponse<T>> post<T>(NetworkRequest request) =>
      this.request<T>(request.copyWith(method: HttpMethod.post));

  @override
  Future<NetworkResponse<T>> put<T>(NetworkRequest request) =>
      this.request<T>(request.copyWith(method: HttpMethod.put));

  @override
  Future<NetworkResponse<T>> patch<T>(NetworkRequest request) =>
      this.request<T>(request.copyWith(method: HttpMethod.patch));

  @override
  Future<NetworkResponse<T>> delete<T>(NetworkRequest request) =>
      this.request<T>(request.copyWith(method: HttpMethod.delete));

  @override
  Future<NetworkResponse<T>> head<T>(NetworkRequest request) =>
      this.request<T>(request.copyWith(method: HttpMethod.head));

  @override
  Future<void> close() async {
    _client.close();
    _isInitialized = false;
    _isClosed = true;
  }
}
