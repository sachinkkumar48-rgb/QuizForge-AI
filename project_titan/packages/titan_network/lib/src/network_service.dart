import 'network_request.dart';
import 'network_response.dart';

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
