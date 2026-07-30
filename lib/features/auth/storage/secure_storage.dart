import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Storage wrapper encapsulating [FlutterSecureStorage] with fallback mechanism.
class SecureStorage {
  final FlutterSecureStorage _storage;
  final Map<String, String> _inMemoryFallback;

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _inMemoryFallback = {};

  static const String _kAccessTokenKey = 'access_token';
  static const String _kRefreshTokenKey = 'refresh_token';

  /// Saves the JWT access token securely.
  Future<void> saveAccessToken(String token) async {
    try {
      await _storage.write(key: _kAccessTokenKey, value: token);
    } catch (_) {
      _inMemoryFallback[_kAccessTokenKey] = token;
    }
  }

  /// Saves the JWT refresh token securely.
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _kRefreshTokenKey, value: token);
    } catch (_) {
      _inMemoryFallback[_kRefreshTokenKey] = token;
    }
  }

  /// Loads the stored access token.
  Future<String?> loadAccessToken() async {
    try {
      return await _storage.read(key: _kAccessTokenKey);
    } catch (_) {
      return _inMemoryFallback[_kAccessTokenKey];
    }
  }

  /// Loads the stored refresh token.
  Future<String?> loadRefreshToken() async {
    try {
      return await _storage.read(key: _kRefreshTokenKey);
    } catch (_) {
      return _inMemoryFallback[_kRefreshTokenKey];
    }
  }

  /// Restores both access and refresh tokens.
  Future<Map<String, String?>> loadTokens() async {
    final access = await loadAccessToken();
    final refresh = await loadRefreshToken();
    return {
      'accessToken': access,
      'refreshToken': refresh,
    };
  }

  /// Clears stored access and refresh tokens.
  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _kAccessTokenKey);
      await _storage.delete(key: _kRefreshTokenKey);
    } catch (_) {}
    _inMemoryFallback.clear();
  }
}
