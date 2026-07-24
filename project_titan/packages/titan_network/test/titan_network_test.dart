import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:titan_core/titan_core.dart';
import 'package:titan_network/titan_network.dart';

class _TestInterceptor extends NetworkInterceptor {
  final List<String> log = [];

  @override
  Future<NetworkRequest> onRequest(NetworkRequest request) async {
    log.add('onRequest:${request.url}');
    return request.copyWith(headers: {'X-Test-Header': 'Intercepted'});
  }

  @override
  Future<NetworkResponse<dynamic>> onResponse(
      NetworkResponse<dynamic> response) async {
    log.add('onResponse:${response.statusCode}');
    return response;
  }

  @override
  Future<NetworkException> onError(NetworkException exception) async {
    log.add('onError:${exception.runtimeType}');
    return exception;
  }
}

class _CountingRetryPolicy implements RetryPolicy {
  int retriedCount = 0;
  final int maxRetries;

  _CountingRetryPolicy({this.maxRetries = 2});

  @override
  bool shouldRetry(NetworkException exception, int attemptCount) {
    if (attemptCount <= maxRetries) {
      retriedCount++;
      return true;
    }
    return false;
  }
}

class _DisconnectedService implements ConnectivityService {
  @override
  Future<bool> isConnected() async => false;
}

void main() {
  group('Titan Networking Foundation Tests', () {
    late TitanServiceLocator locator;

    setUp(() {
      locator = TitanServiceLocator();
      locator.reset();
      TitanBootstrap.reset();
    });

    tearDown(() {
      locator.reset();
      TitanBootstrap.reset();
    });

    test('1. HttpNetworkService initialization and closure lifecycle',
        () async {
      final mockClient = MockClient((req) async => http.Response('{}', 200));
      final service = HttpNetworkService(client: mockClient);

      expect(service.isInitialized, isFalse);

      await service.initialize();
      expect(service.isInitialized, isTrue);

      await service.close();
      expect(service.isInitialized, isFalse);

      expect(
        () => service.get<String>(NetworkRequest(
            method: HttpMethod.get, url: 'https://api.titan.ai/test')),
        throwsA(isA<NetworkInitializationException>()),
      );
    });

    test('2. NetworkRequest and NetworkResponse model properties', () {
      final req = NetworkRequest(
        method: HttpMethod.post,
        url: 'https://api.titan.ai/v1/quiz',
        headers: const {'Authorization': 'Bearer token'},
        queryParameters: const {'page': '1'},
        body: {'query': 'upsc'},
      );

      expect(req.method, equals(HttpMethod.post));
      expect(req.url, equals('https://api.titan.ai/v1/quiz'));
      expect(req.headers['Authorization'], equals('Bearer token'));
      expect(req.queryParameters['page'], equals('1'));

      final res = NetworkResponse<String>(
        statusCode: 200,
        body: 'Success',
        request: req,
      );

      expect(res.isSuccess, isTrue);
      expect(res.isClientError, isFalse);
      expect(res.isServerError, isFalse);
      expect(res.body, equals('Success'));
    });

    test('3. HTTP GET request with query parameters and JSON response parsing',
        () async {
      final mockClient = MockClient((req) async {
        expect(req.method, equals('GET'));
        expect(req.url.queryParameters['page'], equals('2'));
        return http.Response('{"status": "ok", "items": [1, 2, 3]}', 200,
            headers: {'content-type': 'application/json'});
      });

      final service = HttpNetworkService(client: mockClient);
      await service.initialize();

      final request = NetworkRequest(
        method: HttpMethod.get,
        url: 'https://api.titan.ai/data',
        queryParameters: const {'page': '2'},
      );

      final response = await service.get<Map<String, dynamic>>(request);

      expect(response.isSuccess, isTrue);
      expect(response.statusCode, equals(200));
      expect(response.body, isA<Map<String, dynamic>>());
      expect(response.body!['status'], equals('ok'));
    });

    test('4. HTTP POST request with JSON body serialization', () async {
      final mockClient = MockClient((req) async {
        expect(req.method, equals('POST'));
        expect(req.headers['content-type'], contains('application/json'));
        expect(req.body, equals('{"title":"New Quiz"}'));
        return http.Response('{"id": "q123"}', 201);
      });

      final service = HttpNetworkService(client: mockClient);
      await service.initialize();

      final request = NetworkRequest(
        method: HttpMethod.post,
        url: 'https://api.titan.ai/quiz',
        body: {'title': 'New Quiz'},
      );

      final response = await service.post<Map<String, dynamic>>(request);

      expect(response.statusCode, equals(201));
      expect(response.body!['id'], equals('q123'));
    });

    test('5. HTTP PUT, PATCH, DELETE, and HEAD request methods', () async {
      final mockClient = MockClient((req) async {
        return http.Response('{"method": "${req.method}"}', 200);
      });

      final service = HttpNetworkService(client: mockClient);
      await service.initialize();

      final req = NetworkRequest(
          method: HttpMethod.get, url: 'https://api.titan.ai/resource');

      final putRes = await service.put<Map<String, dynamic>>(req);
      expect(putRes.body!['method'], equals('PUT'));

      final patchRes = await service.patch<Map<String, dynamic>>(req);
      expect(patchRes.body!['method'], equals('PATCH'));

      final deleteRes = await service.delete<Map<String, dynamic>>(req);
      expect(deleteRes.body!['method'], equals('DELETE'));

      final headRes = await service.head<Map<String, dynamic>>(req);
      expect(headRes.statusCode, equals(200));
    });

    test('6. Interceptor pipeline execution order (onRequest, onResponse)',
        () async {
      final interceptor = _TestInterceptor();
      final mockClient = MockClient((req) async {
        expect(req.headers['X-Test-Header'], equals('Intercepted'));
        return http.Response('{"ok": true}', 200);
      });

      final service = HttpNetworkService(
        client: mockClient,
        interceptors: [interceptor],
      );
      await service.initialize();

      final request = NetworkRequest(
          method: HttpMethod.get, url: 'https://api.titan.ai/intercept');
      final response = await service.get<Map<String, dynamic>>(request);

      expect(response.statusCode, equals(200));
      expect(interceptor.log.length, equals(2));
      expect(interceptor.log[0],
          equals('onRequest:https://api.titan.ai/intercept'));
      expect(interceptor.log[1], equals('onResponse:200'));
    });

    test('7. Network exception mapping (TimeoutException & SocketException)',
        () async {
      final timeoutClient = MockClient((req) async {
        throw TimeoutException('Request timeout');
      });

      final timeoutService = HttpNetworkService(client: timeoutClient);
      await timeoutService.initialize();

      expect(
        () => timeoutService.get<String>(NetworkRequest(
            method: HttpMethod.get, url: 'https://api.titan.ai/timeout')),
        throwsA(isA<NetworkTimeoutException>()),
      );

      final socketClient = MockClient((req) async {
        throw const SocketException('No route to host');
      });

      final socketService = HttpNetworkService(client: socketClient);
      await socketService.initialize();

      expect(
        () => socketService.get<String>(NetworkRequest(
            method: HttpMethod.get, url: 'https://api.titan.ai/socket')),
        throwsA(isA<NetworkConnectionException>()),
      );
    });

    test('8. Retry policy execution on network exception', () async {
      int attempts = 0;
      final mockClient = MockClient((req) async {
        attempts++;
        if (attempts < 3) {
          throw const SocketException('Flaky network');
        }
        return http.Response('{"status": "recovered"}', 200);
      });

      final retryPolicy = _CountingRetryPolicy(maxRetries: 2);
      final service = HttpNetworkService(
        client: mockClient,
        retryPolicy: retryPolicy,
      );
      await service.initialize();

      final response = await service.get<Map<String, dynamic>>(NetworkRequest(
          method: HttpMethod.get, url: 'https://api.titan.ai/retry'));

      expect(response.statusCode, equals(200));
      expect(attempts, equals(3));
      expect(retryPolicy.retriedCount, equals(2));
    });

    test('9. ConnectivityService abstraction handles offline state', () async {
      final mockClient = MockClient((req) async => http.Response('{}', 200));
      final service = HttpNetworkService(
        client: mockClient,
        connectivityService: _DisconnectedService(),
      );
      await service.initialize();

      expect(
        () => service.get<String>(NetworkRequest(
            method: HttpMethod.get, url: 'https://api.titan.ai/offline')),
        throwsA(isA<NetworkConnectionException>()),
      );
    });

    test('10. TitanNetworkBootstrap registers services in TitanServiceLocator',
        () async {
      final mockClient = MockClient((req) async => http.Response('{}', 200));

      final service = await TitanNetworkBootstrap.initialize(
        httpClient: mockClient,
      );

      expect(service.isInitialized, isTrue);
      expect(locator.isRegistered<NetworkService>(), isTrue);
      expect(locator.isRegistered<ConnectivityService>(), isTrue);
      expect(locator.isRegistered<RetryPolicy>(), isTrue);

      final resolvedNetwork = locator.get<NetworkService>();
      expect(identical(resolvedNetwork, service), isTrue);
    });
  });
}
