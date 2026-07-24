import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quizforge_upsc/repositories/impl/secure_api_key_repository.dart';

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage.containsKey(key);
  }
}

void main() {
  late FakeSecureStorage fakeStorage;

  setUp(() {
    fakeStorage = FakeSecureStorage();
  });

  group('ApiKeyRepository - Storage Tests', () {
    test('saveKey and loadKey work as expected', () async {
      final repo = SecureApiKeyRepository(storage: fakeStorage);
      await repo.saveKey('AIzaSyTestKey123');
      final loaded = await repo.loadKey();
      expect(loaded, equals('AIzaSyTestKey123'));
    });

    test('deleteKey removes the key', () async {
      final repo = SecureApiKeyRepository(storage: fakeStorage);
      await repo.saveKey('AIzaSyTestKey123');
      await repo.deleteKey();
      final loaded = await repo.loadKey();
      expect(loaded, isNull);
    });

    test('hasKey returns true when key exists and false when missing',
        () async {
      final repo = SecureApiKeyRepository(storage: fakeStorage);
      expect(await repo.hasKey(), isFalse);
      await repo.saveKey('AIzaSyTestKey123');
      expect(await repo.hasKey(), isTrue);
      await repo.deleteKey();
      expect(await repo.hasKey(), isFalse);
    });
  });

  group('ApiKeyRepository - Validation Tests', () {
    test('validateKey returns true when status code is 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
            jsonEncode({
              "candidates": [
                {
                  "content": {
                    "parts": [
                      {"text": "pong"}
                    ]
                  }
                }
              ]
            }),
            200);
      });

      final repo =
          SecureApiKeyRepository(storage: fakeStorage, client: mockClient);
      final isValid = await repo.validateKey('valid_key');
      expect(isValid, isTrue);
    });

    test('validateKey throws Exception on 401 or 403 (Invalid Key)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
            jsonEncode({
              "error": {
                "code": 401,
                "message": "API key not valid",
                "status": "INVALID_ARGUMENT"
              }
            }),
            401);
      });

      final repo =
          SecureApiKeyRepository(storage: fakeStorage, client: mockClient);
      expect(
        () => repo.validateKey('invalid_key'),
        throwsA(
            predicate((e) => e.toString().contains("Invalid Gemini API Key"))),
      );
    });

    test('validateKey throws Exception on 401/403 with expired message',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
            jsonEncode({
              "error": {
                "code": 400,
                "message": "API key expired",
                "status": "INVALID_ARGUMENT"
              }
            }),
            400);
      });

      final repo =
          SecureApiKeyRepository(storage: fakeStorage, client: mockClient);
      expect(
        () => repo.validateKey('expired_key'),
        throwsA(predicate(
            (e) => e.toString().contains("Gemini API Key has expired"))),
      );
    });

    test('validateKey throws Exception on 429 (Quota Exceeded)', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
            jsonEncode({
              "error": {
                "code": 429,
                "message": "Resource has been exhausted",
                "status": "RESOURCE_EXHAUSTED"
              }
            }),
            429);
      });

      final repo =
          SecureApiKeyRepository(storage: fakeStorage, client: mockClient);
      expect(
        () => repo.validateKey('quota_key'),
        throwsA(predicate(
            (e) => e.toString().contains("Gemini API quota exceeded"))),
      );
    });
  });
}
