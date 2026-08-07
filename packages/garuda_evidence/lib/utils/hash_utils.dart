import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Hashing utilities for evidence objects and content integrity verification.
class EvidenceHashUtils {
  /// Generate SHA-256 hash string from string content.
  static String sha256String(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate fingerprint hash for evidence uniqueness verification.
  static String generateEvidenceFingerprint({
    required String title,
    required String sourceName,
    required String originalUrl,
  }) {
    final raw = '$title|$sourceName|$originalUrl'.toLowerCase();
    return sha256String(raw);
  }
}
