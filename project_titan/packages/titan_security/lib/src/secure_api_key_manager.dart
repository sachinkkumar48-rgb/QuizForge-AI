import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure API Key Manager integrating with system keychain/keystore.
class SecureApiKeyManager {
  final FlutterSecureStorage _storage;

  SecureApiKeyManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Saves an API key securely.
  Future<void> saveApiKey(String provider, String apiKey) async {
    await _storage.write(key: 'api_key_$provider', value: apiKey);
  }

  /// Reads a securely stored API key.
  Future<String?> getApiKey(String provider) async {
    return await _storage.read(key: 'api_key_$provider');
  }

  /// Checks whether an API key exists for a provider.
  Future<bool> hasApiKey(String provider) async {
    final key = await getApiKey(provider);
    return isValidApiKey(key);
  }

  /// Deletes an API key.
  Future<void> deleteApiKey(String provider) async {
    await _storage.delete(key: 'api_key_$provider');
  }

  /// Clears all API keys.
  Future<void> clearAllApiKeys() async {
    await _storage.deleteAll();
  }

  /// Validates API key formatting and non-empty status.
  bool isValidApiKey(String? apiKey) {
    if (apiKey == null || apiKey.trim().isEmpty) return false;
    return apiKey.trim().length >= 10;
  }
}
