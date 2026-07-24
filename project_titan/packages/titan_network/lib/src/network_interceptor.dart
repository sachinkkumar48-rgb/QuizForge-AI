import 'network_exception.dart';
import 'network_request.dart';
import 'network_response.dart';

/// Contract for intercepting network requests, responses, and errors.
abstract class NetworkInterceptor {
  /// Intercepts a request before it is sent over the network.
  Future<NetworkRequest> onRequest(NetworkRequest request) async => request;

  /// Intercepts a response after it is received from the network.
  Future<NetworkResponse<dynamic>> onResponse(
          NetworkResponse<dynamic> response) async =>
      response;

  /// Intercepts an exception when a network error occurs.
  Future<NetworkException> onError(NetworkException exception) async =>
      exception;
}
