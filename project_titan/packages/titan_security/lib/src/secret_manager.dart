import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Production secret manager handling environment variables, API tokens, and obfuscated secrets.
class SecretManager {
  final Map<String, String> _inMemorySecrets = {};

  SecretManager([Map<String, String>? initialSecrets]) {
    if (initialSecrets != null) {
      _inMemorySecrets.addAll(initialSecrets);
    }
  }

  /// Obfuscates a raw string value for safe logging or transient storage.
  static String obfuscate(String secret) {
    if (secret.isEmpty) return '';
    if (secret.length <= 4) return '****';
    return '${secret.substring(0, 2)}****${secret.substring(secret.length - 2)}';
  }

  /// Hashes a sensitive string payload using SHA-256.
  static String hashSecret(String secret) {
    final bytes = utf8.encode(secret);
    return sha256.convert(bytes).toString();
  }

  /// Sets a secret in memory.
  void setSecret(String key, String value) {
    _inMemorySecrets[key] = value;
  }

  /// Gets a secret from memory.
  String? getSecret(String key) {
    return _inMemorySecrets[key];
  }

  /// Checks whether a secret exists.
  bool hasSecret(String key) {
    return _inMemorySecrets.containsKey(key) &&
        _inMemorySecrets[key]!.isNotEmpty;
  }

  /// Verifies if a secret exists and matches expected hash or value.
  bool verifySecret(String key, String rawValue) {
    final stored = _inMemorySecrets[key];
    if (stored == null) return false;
    return hashSecret(rawValue) == hashSecret(stored);
  }

  /// Bulk loads secrets into memory.
  void loadFromMap(Map<String, String> secrets) {
    _inMemorySecrets.addAll(secrets);
  }

  /// Clears stored secrets.
  void clear() {
    _inMemorySecrets.clear();
  }
}
