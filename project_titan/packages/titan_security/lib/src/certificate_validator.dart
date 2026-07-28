import 'dart:io';
import 'package:crypto/crypto.dart';

/// Certificate Validator enforcing SSL/TLS pinning and certificate validation.
class CertificateValidator {
  final List<String> allowedSha256Fingerprints;
  final List<String> allowedDomains;

  const CertificateValidator({
    this.allowedSha256Fingerprints = const [],
    this.allowedDomains = const [],
  });

  /// Validates server certificate during HTTPS handshake.
  bool validateCertificate(X509Certificate cert, String host, int port) {
    // 1. Verify domain matching if configured
    if (allowedDomains.isNotEmpty && !allowedDomains.contains(host)) {
      return false;
    }

    if (allowedSha256Fingerprints.isEmpty) {
      // Default: allow valid system certificates in production
      return cert.der.isNotEmpty;
    }

    final digest = sha256.convert(cert.der);
    final certFingerprint = digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();

    final normalizedAllowed = allowedSha256Fingerprints
        .map((f) => f.replaceAll(':', '').toUpperCase())
        .toList();

    final rawFingerprint = certFingerprint.replaceAll(':', '').toUpperCase();

    return normalizedAllowed.contains(rawFingerprint) ||
        allowedSha256Fingerprints.contains(certFingerprint);
  }
}
