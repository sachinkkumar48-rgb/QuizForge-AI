import '../storage/secure_storage.dart';

/// Token Manager utility for storing, retrieving, and restoring authentication tokens.
class TokenManager {
  final SecureStorage _storage;

  TokenManager({SecureStorage? storage})
      : _storage = storage ?? SecureStorage();

  /// Persists both access and refresh tokens.
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.saveAccessToken(accessToken);
    await _storage.saveRefreshToken(refreshToken);
  }

  /// Persists the access token.
  Future<void> saveAccessToken(String token) async {
    await _storage.saveAccessToken(token);
  }

  /// Persists the refresh token.
  Future<void> saveRefreshToken(String token) async {
    await _storage.saveRefreshToken(token);
  }

  /// Restores both access and refresh tokens.
  Future<Map<String, String?>> loadTokens() async {
    return await _storage.loadTokens();
  }

  /// Retrieves the current access token.
  Future<String?> getAccessToken() async {
    return await _storage.loadAccessToken();
  }

  /// Retrieves the current refresh token.
  Future<String?> getRefreshToken() async {
    return await _storage.loadRefreshToken();
  }

  /// Clears stored authentication tokens.
  Future<void> clearTokens() async {
    await _storage.clearTokens();
  }
}
