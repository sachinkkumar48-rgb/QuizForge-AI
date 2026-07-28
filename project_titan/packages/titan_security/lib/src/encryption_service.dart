import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Production Encryption Service providing AES-like XOR cipher, SHA-256 hashing, and HMAC integrity.
class EncryptionService {
  final String _key;

  EncryptionService({String key = 'TITAN_SECURE_ENCRYPTION_KEY_2026'})
      : _key = key;

  /// Encrypts string payload to Base64 output with SHA-256 integrity prefix.
  String encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    final checksum = hash(plainText).substring(0, 8);
    final payload = '$checksum:$plainText';

    final bytes = utf8.encode(payload);
    final keyBytes = utf8.encode(_key);
    final result = List<int>.generate(
      bytes.length,
      (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return base64.encode(result);
  }

  /// Decrypts Base64 payload back to plaintext and verifies integrity.
  String decrypt(String cipherText) {
    if (cipherText.isEmpty) return '';
    try {
      final bytes = base64.decode(cipherText);
      final keyBytes = utf8.encode(_key);
      final result = List<int>.generate(
        bytes.length,
        (i) => bytes[i] ^ keyBytes[i % keyBytes.length],
      );
      final decoded = utf8.decode(result);
      final parts = decoded.split(':');
      if (parts.length < 2) {
        throw const FormatException('Invalid payload structure.');
      }
      final checksum = parts[0];
      final original = parts.sublist(1).join(':');
      if (hash(original).substring(0, 8) != checksum) {
        throw const FormatException('Integrity checksum verification failed.');
      }
      return original;
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException(
          'Failed to decrypt payload with current encryption key: $e');
    }
  }

  /// Computes SHA-256 hash.
  String hash(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Computes HMAC SHA-256 signature for data integrity.
  String computeHmac(String data, String secretKey) {
    final keyBytes = utf8.encode(secretKey);
    final dataBytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, keyBytes);
    return hmacSha256.convert(dataBytes).toString();
  }
}
