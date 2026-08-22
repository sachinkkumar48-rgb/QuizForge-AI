import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_encryption_options.dart';
import 'package:titan_reader/src/domain/entities/pdf_encryption_result.dart';

void main() {
  group('PdfEncryptionAlgorithm Domain Tests', () {
    test('verifies AES-128 algorithm metadata', () {
      const algo = PdfEncryptionAlgorithm.aes128;
      expect(algo.version, 4);
      expect(algo.revision, 4);
      expect(algo.keyLengthBits, 128);
      expect(algo.keyLengthBytes, 16);
    });

    test('verifies RC4-128 algorithm metadata', () {
      const algo = PdfEncryptionAlgorithm.rc4_128;
      expect(algo.version, 2);
      expect(algo.revision, 3);
      expect(algo.keyLengthBits, 128);
      expect(algo.keyLengthBytes, 16);
    });

    test('verifies RC4-40 algorithm metadata', () {
      const algo = PdfEncryptionAlgorithm.rc4_40;
      expect(algo.version, 1);
      expect(algo.revision, 2);
      expect(algo.keyLengthBits, 40);
      expect(algo.keyLengthBytes, 5);
    });
  });

  group('PdfPermissions Domain Tests', () {
    test('full permissions computes standard full mask (-4 / 0xFFFFFFFC)', () {
      final permissions = PdfPermissions.full();
      expect(permissions.allowPrinting, isTrue);
      expect(permissions.allowModifying, isTrue);
      expect(permissions.allowCopying, isTrue);
      expect(permissions.allowAnnotating, isTrue);
      expect(permissions.allowFormFilling, isTrue);

      final p = permissions.toInt();
      // -4 represents 0xFFFFFFFC in 32-bit signed two's complement
      expect(p, -4);
    });

    test('read-only permissions disables editing, copying, annotating', () {
      final permissions = PdfPermissions.readOnly();
      expect(permissions.allowPrinting, isTrue);
      expect(permissions.allowModifying, isFalse);
      expect(permissions.allowCopying, isFalse);
      expect(permissions.allowAnnotating, isFalse);
      expect(permissions.allowFormFilling, isFalse);
      expect(permissions.allowAccessibilityExtraction, isTrue);

      final p = permissions.toInt();
      expect(p, isNot(equals(-4)));
    });

    test('copyWith and equality work correctly', () {
      const p1 = PdfPermissions(allowPrinting: false);
      final p2 = const PdfPermissions().copyWith(allowPrinting: false);
      const p3 = PdfPermissions();

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });
  });

  group('PdfEncryptionConfig Domain Tests', () {
    test('effectiveOwnerPassword defaults to userPassword when owner is unset',
        () {
      const config = PdfEncryptionConfig(userPassword: 'secretUserPass');
      expect(config.effectiveOwnerPassword, 'secretUserPass');
      expect(config.hasPassword, isTrue);
    });

    test('effectiveOwnerPassword uses explicit owner password when provided',
        () {
      const config = PdfEncryptionConfig(
        userPassword: 'userPass',
        ownerPassword: 'ownerPass',
      );
      expect(config.effectiveOwnerPassword, 'ownerPass');
      expect(config.hasPassword, isTrue);
    });

    test('hasPassword returns false when both passwords are empty', () {
      const config = PdfEncryptionConfig(userPassword: '', ownerPassword: '');
      expect(config.hasPassword, isFalse);
    });
  });

  group('PdfEncryptionResult Domain Tests', () {
    test('constructs completed result correctly', () {
      final now = DateTime(2026, 8, 22, 10, 0);
      final result = PdfEncryptionResult.completed(
        outputPath: '/path/to/doc.protected.pdf',
        encryptedSizeBytes: 4096,
        algorithm: PdfEncryptionAlgorithm.aes128,
        timestamp: now,
      );

      expect(result.status, PdfEncryptionStatus.completed);
      expect(result.isSuccess, isTrue);
      expect(result.isCancelled, isFalse);
      expect(result.isFailure, isFalse);
      expect(result.outputPath, '/path/to/doc.protected.pdf');
      expect(result.encryptedSizeBytes, 4096);
      expect(result.algorithm, PdfEncryptionAlgorithm.aes128);
      expect(result.errorMessage, isNull);
      expect(result.timestamp, now);
      expect(result.toString(), contains('doc.protected.pdf'));
    });

    test('constructs cancelled and failed results correctly', () {
      const cancelled = PdfEncryptionResult.cancelled();
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isSuccess, isFalse);

      final failed = PdfEncryptionResult.failed('Disk full');
      expect(failed.isFailure, isTrue);
      expect(failed.errorMessage, 'Disk full');
      expect(failed.isSuccess, isFalse);
    });
  });
}
