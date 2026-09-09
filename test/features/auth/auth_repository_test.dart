import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:quizforge_upsc/core/config/app_config.dart';
import 'package:quizforge_upsc/core/network/api_client.dart';
import 'package:quizforge_upsc/features/auth/data/auth_repository_impl.dart';
import 'package:quizforge_upsc/features/auth/domain/auth_repository.dart';
import 'package:quizforge_upsc/features/auth/services/token_manager.dart';
import 'package:quizforge_upsc/features/auth/storage/secure_storage.dart';

class FakeSecureStorage extends SecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> saveAccessToken(String token) async => _data['access_token'] = token;

  @override
  Future<void> saveRefreshToken(String token) async => _data['refresh_token'] = token;

  @override
  Future<String?> loadAccessToken() async => _data['access_token'];

  @override
  Future<String?> loadRefreshToken() async => _data['refresh_token'];

  @override
  Future<void> clearTokens() async => _data.clear();
}

void main() {
  group('AuthRepository Production Implementation Tests', () {
    late FakeSecureStorage fakeStorage;
    late TokenManager tokenManager;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      tokenManager = TokenManager(storage: fakeStorage);
    });

    test('login authenticates user, acquires tokens, and stores them', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/login');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'student@titan.internal');
        expect(body['password'], 'securePass123');

        return http.Response(
          jsonEncode({
            'access_token': 'jwt_access_abc123',
            'token_type': 'bearer',
            'refresh_token': 'jwt_refresh_xyz789',
          }),
          200,
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepositoryImpl(apiClient: apiClient, tokenManager: tokenManager);

      await repo.login('student@titan.internal', 'securePass123');

      expect(await tokenManager.getAccessToken(), equals('jwt_access_abc123'));
      expect(await tokenManager.getRefreshToken(), equals('jwt_refresh_xyz789'));
    });

    test('register posts user data and saves returned tokens', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/register');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['email'], 'newuser@titan.internal');
        expect(body['full_name'], 'New Student');

        return http.Response(
          jsonEncode({
            'access_token': 'jwt_access_new_1',
            'token_type': 'bearer',
            'refresh_token': 'jwt_refresh_new_2',
          }),
          201,
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepositoryImpl(apiClient: apiClient, tokenManager: tokenManager);

      await repo.register('newuser@titan.internal', 'securePass123', fullName: 'New Student');

      expect(await tokenManager.getAccessToken(), equals('jwt_access_new_1'));
      expect(await tokenManager.getRefreshToken(), equals('jwt_refresh_new_2'));
    });

    test('refresh uses stored refresh token to obtain new tokens', () async {
      await tokenManager.saveRefreshToken('existing_refresh_token');

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/refresh');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['refresh_token'], 'existing_refresh_token');

        return http.Response(
          jsonEncode({
            'access_token': 'renewed_access_token',
            'refresh_token': 'renewed_refresh_token',
          }),
          200,
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepositoryImpl(apiClient: apiClient, tokenManager: tokenManager);

      await repo.refresh();

      expect(await tokenManager.getAccessToken(), equals('renewed_access_token'));
      expect(await tokenManager.getRefreshToken(), equals('renewed_refresh_token'));
    });

    test('refresh throws Exception if no refresh token exists', () async {
      final repo = AuthRepositoryImpl(tokenManager: tokenManager);

      await expectLater(
        () => repo.refresh(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('No refresh token'))),
      );
    });

    test('getCurrentUser retrieves authenticated user profile via Bearer token', () async {
      await tokenManager.saveAccessToken('valid_user_jwt');

      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/me');
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer valid_user_jwt');

        return http.Response(
          jsonEncode({
            'id': 'usr_titan_42',
            'email': 'student@titan.internal',
            'full_name': 'Titan Learner',
            'is_active': true,
          }),
          200,
        );
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepositoryImpl(apiClient: apiClient, tokenManager: tokenManager);

      final user = await repo.getCurrentUser() as Map<String, dynamic>;
      expect(user['id'], equals('usr_titan_42'));
      expect(user['email'], equals('student@titan.internal'));
      expect(user['full_name'], equals('Titan Learner'));
    });

    test('getCurrentUser throws if user is not authenticated', () async {
      final repo = AuthRepositoryImpl(tokenManager: tokenManager);

      await expectLater(
        () => repo.getCurrentUser(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('not authenticated'))),
      );
    });

    test('logout notifies server and clears stored tokens', () async {
      await tokenManager.saveTokens(accessToken: 'token_to_clear', refreshToken: 'refresh_to_clear');

      bool serverNotified = false;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v1/auth/logout') {
          serverNotified = true;
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = AuthRepositoryImpl(apiClient: apiClient, tokenManager: tokenManager);

      await repo.logout();

      expect(serverNotified, isTrue);
      expect(await tokenManager.getAccessToken(), isNull);
      expect(await tokenManager.getRefreshToken(), isNull);
    });

    test('login handles 401 Unauthorized by throwing ApiException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Invalid email or password'}), 401);
      });

      final apiClient = ApiClient(
        config: const AppConfig(maxRetries: 1, initialRetryDelay: Duration.zero),
        client: mockClient,
      );
      final repo = AuthRepositoryImpl(apiClient: apiClient, tokenManager: tokenManager);

      await expectLater(
        () => repo.login('wrong@titan.internal', 'badpass'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });
  });
}
