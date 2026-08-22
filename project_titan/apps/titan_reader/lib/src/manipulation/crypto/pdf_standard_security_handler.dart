import 'dart:convert';
import 'dart:typed_data';

import '../../domain/entities/pdf_encryption_options.dart';
import '../ast/pdf_primitive.dart';
import 'pdf_crypto_primitives.dart';

/// Implements ISO 32000-1 §7.6 PDF Standard Security Handler algorithms for PDF Password Protection.
class PdfStandardSecurityHandler {
  final PdfEncryptionConfig config;
  final List<int> fileId;

  late final Uint8List documentKey;
  late final Uint8List ownerValueO;
  late final Uint8List userValueU;
  late final int permissionsP;

  PdfStandardSecurityHandler({
    required this.config,
    required this.fileId,
  }) {
    permissionsP = config.permissions.toInt();
    _initializeKeys();
  }

  void _initializeKeys() {
    // 1. Compute /O (Owner password verification string, 32 bytes)
    ownerValueO = _computeOwnerValueO(
      userPassword: config.userPassword,
      ownerPassword: config.effectiveOwnerPassword,
      algorithm: config.algorithm,
    );

    // 2. Compute Document Encryption Key K (16 bytes for 128-bit, 5 bytes for 40-bit)
    documentKey = _computeDocumentEncryptionKey(
      userPassword: config.userPassword,
      ownerValueO: ownerValueO,
      permissionsP: permissionsP,
      fileId: fileId,
      algorithm: config.algorithm,
      encryptMetadata: config.encryptMetadata,
    );

    // 3. Compute /U (User password verification string, 32 bytes)
    userValueU = _computeUserValueU(
      documentKey: documentKey,
      fileId: fileId,
      algorithm: config.algorithm,
    );
  }

  /// Encrypts stream or string data belonging to indirect object ([objId], [gen]).
  Uint8List encryptData({
    required int objId,
    required int gen,
    required List<int> plainData,
  }) {
    if (plainData.isEmpty) return Uint8List(0);

    final objKey = _computeObjectKey(
      documentKey: documentKey,
      objId: objId,
      gen: gen,
      algorithm: config.algorithm,
    );

    if (config.algorithm == PdfEncryptionAlgorithm.aes128) {
      return PdfAes128Cbc.encryptWithIv(key: objKey, plaintext: plainData);
    } else {
      return PdfRc4.encrypt(objKey, plainData);
    }
  }

  /// Builds the `/Encrypt` PDF dictionary object for inclusion in the document.
  PdfDict createEncryptionDictionary() {
    final dict = PdfDict({
      'Filter': const PdfName('Standard'),
      'V': PdfNumber(config.algorithm.version),
      'R': PdfNumber(config.algorithm.revision),
      'Length': PdfNumber(config.algorithm.keyLengthBits),
      'P': PdfNumber(permissionsP),
      'O': PdfString(ownerValueO, isHex: true),
      'U': PdfString(userValueU, isHex: true),
    });

    if (config.algorithm == PdfEncryptionAlgorithm.aes128) {
      final stdCfDict = PdfDict(const {
        'Type': PdfName('CryptFilter'),
        'CFM': PdfName('AESV2'),
        'AuthEvent': PdfName('DocOpen'),
        'Length': PdfNumber(16),
      });

      dict['CF'] = PdfDict({'StdCF': stdCfDict});
      dict['StrF'] = const PdfName('StdCF');
      dict['StmF'] = const PdfName('StdCF');
      if (!config.encryptMetadata) {
        dict['EncryptMetadata'] = const PdfBoolean(false);
      }
    }

    return dict;
  }

  // ---------------------------------------------------------------------------
  // ISO 32000-1 §7.6.3.3 Algorithm Implementations
  // ---------------------------------------------------------------------------

  /// Algorithm 3 / 4: Computing Owner Password Value `/O` (32 bytes).
  static Uint8List _computeOwnerValueO({
    required String userPassword,
    required String ownerPassword,
    required PdfEncryptionAlgorithm algorithm,
  }) {
    // a) Pad or truncate owner password to 32 bytes
    final paddedOwner = _padPassword(ownerPassword);

    // b) Compute MD5 hash of owner password
    var digest = PdfMd5.digest(paddedOwner);

    // c) For Revision 3 or 4: iterate MD5 50 times
    final keyLen = algorithm.keyLengthBytes;
    if (algorithm.revision >= 3) {
      for (var i = 0; i < 50; i++) {
        digest = PdfMd5.digest(digest.sublist(0, keyLen));
      }
    }

    final key = digest.sublist(0, keyLen);

    // d) Pad user password to 32 bytes
    final paddedUser = _padPassword(userPassword);

    // e) Encrypt padded user password with RC4 using key
    var cipher = PdfRc4.encrypt(key, paddedUser);

    // f) For Revision 3 or 4: iterate RC4 19 times with XORed key
    if (algorithm.revision >= 3) {
      final iterKey = Uint8List(key.length);
      for (var i = 1; i <= 19; i++) {
        for (var j = 0; j < key.length; j++) {
          iterKey[j] = key[j] ^ i;
        }
        cipher = PdfRc4.encrypt(iterKey, cipher);
      }
    }

    return cipher;
  }

  /// Algorithm 2 / 3: Computing Document Encryption Key $K$.
  static Uint8List _computeDocumentEncryptionKey({
    required String userPassword,
    required Uint8List ownerValueO,
    required int permissionsP,
    required List<int> fileId,
    required PdfEncryptionAlgorithm algorithm,
    required bool encryptMetadata,
  }) {
    final keyLen = algorithm.keyLengthBytes;
    final bytes = BytesBuilder(copy: false);

    // a) Pad or truncate user password
    bytes.add(_padPassword(userPassword));

    // b) Pass the /O entry
    bytes.add(ownerValueO);

    // c) Pass the 4-byte permissions integer (little-endian)
    bytes.addByte(permissionsP & 0xFF);
    bytes.addByte((permissionsP >> 8) & 0xFF);
    bytes.addByte((permissionsP >> 16) & 0xFF);
    bytes.addByte((permissionsP >> 24) & 0xFF);

    // d) Pass the first element of /ID array
    bytes.add(fileId);

    // e) If Revision 4 or greater and metadata is NOT encrypted, pass 4 bytes of 0xFF
    if (algorithm.revision >= 4 && !encryptMetadata) {
      bytes.add(const [0xFF, 0xFF, 0xFF, 0xFF]);
    }

    var digest = PdfMd5.digest(bytes.takeBytes());

    // f) For Revision 3 or 4: 50 MD5 iterations
    if (algorithm.revision >= 3) {
      for (var i = 0; i < 50; i++) {
        digest = PdfMd5.digest(digest.sublist(0, keyLen));
      }
    }

    return Uint8List.fromList(digest.sublist(0, keyLen));
  }

  /// Algorithm 4 / 5: Computing User Password Value `/U` (32 bytes).
  static Uint8List _computeUserValueU({
    required Uint8List documentKey,
    required List<int> fileId,
    required PdfEncryptionAlgorithm algorithm,
  }) {
    if (algorithm.revision == 2) {
      // Revision 2: Encrypt standard padding string with document key
      return PdfRc4.encrypt(documentKey, pdfStandardPaddingBytes);
    }

    // Revision 3 or 4:
    // a) Compute MD5 hash of standard padding string + fileId
    final hashInput = BytesBuilder(copy: false);
    hashInput.add(pdfStandardPaddingBytes);
    hashInput.add(fileId);
    final hash16 = PdfMd5.digest(hashInput.takeBytes());

    // b) Encrypt the 16-byte hash with documentKey using RC4
    var cipher = PdfRc4.encrypt(documentKey, hash16);

    // c) 19 iterations with XORed key
    final iterKey = Uint8List(documentKey.length);
    for (var i = 1; i <= 19; i++) {
      for (var j = 0; j < documentKey.length; j++) {
        iterKey[j] = documentKey[j] ^ i;
      }
      cipher = PdfRc4.encrypt(iterKey, cipher);
    }

    // The /U entry is 32 bytes: the 16-byte encrypted hash followed by 16 arbitrary or padded bytes
    final result = Uint8List(32);
    result.setRange(0, 16, cipher);
    result.setRange(16, 32, pdfStandardPaddingBytes.sublist(0, 16));
    return result;
  }

  /// Algorithm 1: Computing object-specific encryption key $K_{obj}$.
  static Uint8List _computeObjectKey({
    required Uint8List documentKey,
    required int objId,
    required int gen,
    required PdfEncryptionAlgorithm algorithm,
  }) {
    final builder = BytesBuilder(copy: false);
    builder.add(documentKey);

    // 3 bytes of object number (little-endian)
    builder.addByte(objId & 0xFF);
    builder.addByte((objId >> 8) & 0xFF);
    builder.addByte((objId >> 16) & 0xFF);

    // 2 bytes of generation number (little-endian)
    builder.addByte(gen & 0xFF);
    builder.addByte((gen >> 8) & 0xFF);

    // For AES (Revision 4), append 'sAlT' (0x73, 0x41, 0x6C, 0x54) per ISO 32000-1 §7.6.6.2
    if (algorithm == PdfEncryptionAlgorithm.aes128) {
      builder.add(const [0x73, 0x41, 0x6C, 0x54]);
    }

    final digest = PdfMd5.digest(builder.takeBytes());
    final keyLen = (algorithm == PdfEncryptionAlgorithm.aes128)
        ? 16
        : (documentKey.length + 5).clamp(5, 16);

    return Uint8List.fromList(digest.sublist(0, keyLen));
  }

  static Uint8List _padPassword(String password) {
    final bytes = utf8.encode(password);
    final padded = Uint8List(32);
    if (bytes.length >= 32) {
      padded.setRange(0, 32, bytes);
    } else {
      padded.setRange(0, bytes.length, bytes);
      padded.setRange(bytes.length, 32,
          pdfStandardPaddingBytes.sublist(0, 32 - bytes.length));
    }
    return padded;
  }
}
