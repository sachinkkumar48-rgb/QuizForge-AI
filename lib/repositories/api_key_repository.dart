import 'impl/secure_api_key_repository.dart';

abstract class ApiKeyRepository {
  static ApiKeyRepository? _instance;

  static ApiKeyRepository get instance {
    _instance ??= SecureApiKeyRepository();
    return _instance!;
  }

  static set instance(ApiKeyRepository mock) {
    _instance = mock;
  }

  factory ApiKeyRepository() => instance;

  Future<void> saveKey(String key);
  Future<String?> loadKey();
  Future<void> deleteKey();
  Future<bool> hasKey();
  Future<bool> validateKey(String key);
}
