import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_encryption_options.dart';
import 'package:titan_reader/src/manipulation/crypto/pdf_crypto_primitives.dart';
import 'package:titan_reader/src/manipulation/crypto/pdf_standard_security_handler.dart';

void main() {
  group('PdfMd5 RFC 1321 Tests', () {
    test('computes MD5 of empty string correctly', () {
      final digest = PdfMd5.digest([]);
      final hex = digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, 'd41d8cd98f00b204e9800998ecf8427e');
    });

    test('computes MD5 of "abc" correctly', () {
      final digest = PdfMd5.digest(utf8.encode('abc'));
      final hex = digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, '900150983cd24fb0d6963f7d28e17f72');
    });

    test('computes MD5 of "message digest" correctly', () {
      final digest = PdfMd5.digest(utf8.encode('message digest'));
      final hex = digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, 'f96b697d7cb7938d525a2f31aaf161d0');
    });
  });

  group('PdfRc4 Tests', () {
    test('encrypts with RC4 key and round-trips correctly', () {
      final key = utf8.encode('Key');
      final plain = utf8.encode('Plaintext');

      final cipher = PdfRc4.encrypt(key, plain);
      expect(cipher, isNot(equals(plain)));

      final decrypted = PdfRc4.encrypt(key, cipher);
      expect(decrypted, equals(plain));
    });
  });

  group('PdfAes128Cbc Tests', () {
    test('encrypts with AES-128 in CBC mode and prepends 16-byte IV', () {
      final key = Uint8List.fromList(List.generate(16, (i) => i));
      final explicitIv = Uint8List.fromList(List.generate(16, (i) => 16 - i));
      final plain = utf8.encode('Hello World PDF Content');

      final encrypted = PdfAes128Cbc.encryptWithIv(
        key: key,
        plaintext: plain,
        explicitIv: explicitIv,
      );

      // Check IV is at beginning
      expect(encrypted.sublist(0, 16), equals(explicitIv));

      // Check ciphertext length is multiple of 16 after the 16-byte IV
      final cipherBody = encrypted.sublist(16);
      expect(cipherBody.length % 16, 0);
      expect(cipherBody.length, 32); // 23 bytes + 9 bytes padding = 32
    });
  });

  group('PdfStandardSecurityHandler ISO 32000-1 Tests', () {
    test('generates valid AES-128 encryption dictionary and object keys', () {
      const config = PdfEncryptionConfig(
        userPassword: 'user123',
        ownerPassword: 'owner123',
        algorithm: PdfEncryptionAlgorithm.aes128,
      );
      final fileId = Uint8List.fromList(List.generate(16, (i) => i * 3));

      final handler = PdfStandardSecurityHandler(
        config: config,
        fileId: fileId,
      );

      expect(handler.documentKey.length, 16);
      expect(handler.ownerValueO.length, 32);
      expect(handler.userValueU.length, 32);

      // Test stream encryption
      final streamData = utf8.encode('BT /F1 12 Tf (Protected Content) Tj ET');
      final encryptedStream = handler.encryptData(
        objId: 5,
        gen: 0,
        plainData: streamData,
      );
      expect(encryptedStream.length, greaterThan(streamData.length));
      expect(encryptedStream, isNot(equals(streamData)));

      // Test dictionary generation
      final dict = handler.createEncryptionDictionary();
      expect(dict['Filter'].toString(), '/Standard');
      expect(dict['V']!.toString(), '4');
      expect(dict['R']!.toString(), '4');
      expect(dict['Length']!.toString(), '128');
      expect(dict['StrF']!.toString(), '/StdCF');
      expect(dict['StmF']!.toString(), '/StdCF');
      expect(dict.containsKey('O'), isTrue);
      expect(dict.containsKey('U'), isTrue);
    });

    test('generates valid RC4-128 encryption dictionary and encrypts strings',
        () {
      const config = PdfEncryptionConfig(
        userPassword: 'secretPassword',
        algorithm: PdfEncryptionAlgorithm.rc4_128,
      );
      final fileId = Uint8List.fromList(List.generate(16, (i) => 0xFF - i));

      final handler = PdfStandardSecurityHandler(
        config: config,
        fileId: fileId,
      );

      expect(handler.documentKey.length, 16);

      final strData = utf8.encode('Confidential String');
      final encryptedStr = handler.encryptData(
        objId: 10,
        gen: 0,
        plainData: strData,
      );
      expect(encryptedStr.length, strData.length);
      expect(encryptedStr, isNot(equals(strData)));

      final dict = handler.createEncryptionDictionary();
      expect(dict['V']!.toString(), '2');
      expect(dict['R']!.toString(), '3');
    });
  });
}
