import 'package:http/http.dart' as http;
import 'package:titan_core/titan_core.dart';

import 'connectivity_service.dart';
import 'http_network_service.dart';
import 'network_interceptor.dart';
import 'network_service.dart';
import 'retry_policy.dart';

/// Central startup bootstrap coordinator for Project TITAN networking layer.
abstract class TitanNetworkBootstrap {
  /// Initializes and registers [ConnectivityService], [RetryPolicy], and [NetworkService] in [TitanServiceLocator].
  static Future<NetworkService> initialize({
    NetworkService? networkService,
    http.Client? httpClient,
    ConnectivityService? connectivityService,
    RetryPolicy? retryPolicy,
    List<NetworkInterceptor>? interceptors,
    Duration? defaultTimeout,
    TitanServiceLocator? locator,
  }) async {
    final serviceLocator = locator ?? TitanServiceLocator();

    final connectivity = connectivityService ?? const AlwaysConnectedService();
    serviceLocator.registerSingleton<ConnectivityService>(
      connectivity,
      allowOverride: true,
    );

    final retry = retryPolicy ?? const NoRetryPolicy();
    serviceLocator.registerSingleton<RetryPolicy>(
      retry,
      allowOverride: true,
    );

    final timeout = defaultTimeout ?? const Duration(seconds: 30);

    final NetworkService service = networkService ??
        HttpNetworkService(
          client: httpClient,
          defaultTimeout: timeout,
          connectivityService: connectivity,
          retryPolicy: retry,
          interceptors: interceptors,
        );

    if (!service.isInitialized) {
      await service.initialize();
    }

    serviceLocator.registerSingleton<NetworkService>(
      service,
      allowOverride: true,
    );

    return service;
  }
}
