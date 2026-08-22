import 'package:meta/meta.dart';

/// Supported cryptographic algorithms for PDF encryption (ISO 32000-1 §7.6).
enum PdfEncryptionAlgorithm {
  /// AES-128 cipher in CBC mode with PKCS#7 padding (Revision 4 / AESV2). Recommended modern standard.
  aes128,

  /// RC4 stream cipher with 128-bit key (Revision 3).
  rc4_128,

  /// RC4 stream cipher with 40-bit key (Revision 2 - legacy).
  rc4_40;

  /// Returns the PDF standard security revision number (R).
  int get revision {
    switch (this) {
      case PdfEncryptionAlgorithm.aes128:
        return 4;
      case PdfEncryptionAlgorithm.rc4_128:
        return 3;
      case PdfEncryptionAlgorithm.rc4_40:
        return 2;
    }
  }

  /// Returns the PDF standard security version number (V).
  int get version {
    switch (this) {
      case PdfEncryptionAlgorithm.aes128:
        return 4;
      case PdfEncryptionAlgorithm.rc4_128:
        return 2;
      case PdfEncryptionAlgorithm.rc4_40:
        return 1;
    }
  }

  /// Returns the key length in bits.
  int get keyLengthBits {
    switch (this) {
      case PdfEncryptionAlgorithm.aes128:
        return 128;
      case PdfEncryptionAlgorithm.rc4_128:
        return 128;
      case PdfEncryptionAlgorithm.rc4_40:
        return 40;
    }
  }

  /// Returns the key length in bytes.
  int get keyLengthBytes => keyLengthBits ~/ 8;
}

/// User permission flags encoded into the 32-bit `/P` integer (ISO 32000-1 §7.6.3.2 Table 22).
@immutable
class PdfPermissions {
  /// Bit 3 & 12: Print document (low or high resolution).
  final bool allowPrinting;

  /// Bit 4: Modify contents of the document.
  final bool allowModifying;

  /// Bit 5: Copy or extract text and graphics.
  final bool allowCopying;

  /// Bit 6: Add or modify text annotations and interactive form fields.
  final bool allowAnnotating;

  /// Bit 9: Fill in existing interactive form fields (including signature fields).
  final bool allowFormFilling;

  /// Bit 10: Extract text and graphics in support of accessibility to users with disabilities.
  final bool allowAccessibilityExtraction;

  /// Bit 11: Assemble the document (insert, rotate, or delete pages and create bookmarks).
  final bool allowAssembly;

  /// Bit 12: Print high-quality representation of the document.
  final bool allowHighQualityPrinting;

  const PdfPermissions({
    this.allowPrinting = true,
    this.allowModifying = true,
    this.allowCopying = true,
    this.allowAnnotating = true,
    this.allowFormFilling = true,
    this.allowAccessibilityExtraction = true,
    this.allowAssembly = true,
    this.allowHighQualityPrinting = true,
  });

  /// Full permissions (all features allowed).
  factory PdfPermissions.full() => const PdfPermissions();

  /// Read-only permissions: allow printing and accessibility extraction, prohibit edits, copying, and annotations.
  factory PdfPermissions.readOnly() => const PdfPermissions(
        allowPrinting: true,
        allowModifying: false,
        allowCopying: false,
        allowAnnotating: false,
        allowFormFilling: false,
        allowAccessibilityExtraction: true,
        allowAssembly: false,
        allowHighQualityPrinting: true,
      );

  /// Computes the 32-bit signed integer value for the `/P` entry per ISO 32000-1 Table 22.
  int toInt() {
    // Unused/reserved bits (bits 1, 2, 7, 8, 13-32) must be 1.
    // Base mask with reserved bits set to 1:
    // 0xFFFFF0C0 = 11111111 11111111 11110000 11000000
    // Unsigned 32-bit mask:
    var p = 0xFFFFF0C0;

    if (allowPrinting) p |= (1 << 2); // Bit 3 (0-indexed bit 2)
    if (allowModifying) p |= (1 << 3); // Bit 4 (0-indexed bit 3)
    if (allowCopying) p |= (1 << 4); // Bit 5 (0-indexed bit 4)
    if (allowAnnotating) p |= (1 << 5); // Bit 6 (0-indexed bit 5)
    if (allowFormFilling) p |= (1 << 8); // Bit 9 (0-indexed bit 8)
    if (allowAccessibilityExtraction) p |= (1 << 9); // Bit 10 (0-indexed bit 9)
    if (allowAssembly) p |= (1 << 10); // Bit 11 (0-indexed bit 10)
    if (allowHighQualityPrinting) p |= (1 << 11); // Bit 12 (0-indexed bit 11)

    // Convert unsigned 32-bit integer to 32-bit signed two's complement integer
    if ((p & 0x80000000) != 0) {
      return -((~p & 0xFFFFFFFF) + 1);
    }
    return p;
  }

  PdfPermissions copyWith({
    bool? allowPrinting,
    bool? allowModifying,
    bool? allowCopying,
    bool? allowAnnotating,
    bool? allowFormFilling,
    bool? allowAccessibilityExtraction,
    bool? allowAssembly,
    bool? allowHighQualityPrinting,
  }) {
    return PdfPermissions(
      allowPrinting: allowPrinting ?? this.allowPrinting,
      allowModifying: allowModifying ?? this.allowModifying,
      allowCopying: allowCopying ?? this.allowCopying,
      allowAnnotating: allowAnnotating ?? this.allowAnnotating,
      allowFormFilling: allowFormFilling ?? this.allowFormFilling,
      allowAccessibilityExtraction:
          allowAccessibilityExtraction ?? this.allowAccessibilityExtraction,
      allowAssembly: allowAssembly ?? this.allowAssembly,
      allowHighQualityPrinting:
          allowHighQualityPrinting ?? this.allowHighQualityPrinting,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfPermissions &&
          other.allowPrinting == allowPrinting &&
          other.allowModifying == allowModifying &&
          other.allowCopying == allowCopying &&
          other.allowAnnotating == allowAnnotating &&
          other.allowFormFilling == allowFormFilling &&
          other.allowAccessibilityExtraction == allowAccessibilityExtraction &&
          other.allowAssembly == allowAssembly &&
          other.allowHighQualityPrinting == allowHighQualityPrinting;

  @override
  int get hashCode => Object.hash(
        allowPrinting,
        allowModifying,
        allowCopying,
        allowAnnotating,
        allowFormFilling,
        allowAccessibilityExtraction,
        allowAssembly,
        allowHighQualityPrinting,
      );
}

/// Configuration options for encrypting a PDF document.
@immutable
class PdfEncryptionConfig {
  /// Open/User password required to view the document. Can be empty if only permissions/owner password is set.
  final String userPassword;

  /// Owner/Permissions password required to change security settings and permissions.
  /// If null or empty, defaults to [userPassword].
  final String? ownerPassword;

  /// Permissions granted to users who open the document with the [userPassword].
  final PdfPermissions permissions;

  /// Cryptographic algorithm used for object and stream encryption.
  final PdfEncryptionAlgorithm algorithm;

  /// Whether document metadata streams (e.g. `/Info` or XMP) are encrypted.
  final bool encryptMetadata;

  const PdfEncryptionConfig({
    required this.userPassword,
    this.ownerPassword,
    this.permissions = const PdfPermissions(),
    this.algorithm = PdfEncryptionAlgorithm.aes128,
    this.encryptMetadata = true,
  });

  /// The effective owner password.
  String get effectiveOwnerPassword =>
      (ownerPassword != null && ownerPassword!.isNotEmpty)
          ? ownerPassword!
          : userPassword;

  /// Checks if at least one password is non-empty.
  bool get hasPassword =>
      userPassword.isNotEmpty ||
      (ownerPassword != null && ownerPassword!.isNotEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfEncryptionConfig &&
          other.userPassword == userPassword &&
          other.ownerPassword == ownerPassword &&
          other.permissions == permissions &&
          other.algorithm == algorithm &&
          other.encryptMetadata == encryptMetadata;

  @override
  int get hashCode => Object.hash(
        userPassword,
        ownerPassword,
        permissions,
        algorithm,
        encryptMetadata,
      );
}
