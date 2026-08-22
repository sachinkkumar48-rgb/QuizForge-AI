import 'dart:math';
import 'dart:typed_data';

/// Standard 32-byte PDF padding string defined in ISO 32000-1 §7.6.3.3 Algorithm 2.
final Uint8List pdfStandardPaddingBytes = Uint8List.fromList(const [
  0x28,
  0xBF,
  0x4E,
  0x5E,
  0x4E,
  0x75,
  0x8A,
  0x41,
  0x64,
  0x00,
  0x4E,
  0x56,
  0xFF,
  0xFA,
  0x01,
  0x08,
  0x2E,
  0x2E,
  0x00,
  0xB6,
  0xD0,
  0x68,
  0x3E,
  0x80,
  0x2F,
  0x0C,
  0xA9,
  0xFE,
  0x64,
  0x53,
  0x69,
  0x7A,
]);

/// High-performance RFC 1321 MD5 message digest implementation for pure Dart PDF security handlers.
class PdfMd5 {
  /// Computes 16-byte MD5 digest over given bytes.
  static Uint8List digest(List<int> input) {
    var a = 0x67452301;
    var b = 0xefcdab89;
    var c = 0x98badcfe;
    var d = 0x10325476;

    final length = input.length;
    final bitLength = length * 8;

    // Pre-processing: padding
    final padLength =
        (length % 64 < 56) ? (56 - length % 64) : (120 - length % 64);
    final totalLength = length + padLength + 8;
    final padded = Uint8List(totalLength);
    padded.setRange(0, length, input);
    padded[length] = 0x80;

    // Append 64-bit length in little-endian format
    padded[totalLength - 8] = bitLength & 0xFF;
    padded[totalLength - 7] = (bitLength >> 8) & 0xFF;
    padded[totalLength - 6] = (bitLength >> 16) & 0xFF;
    padded[totalLength - 5] = (bitLength >> 24) & 0xFF;
    // Upper 32 bits of 64-bit length
    padded[totalLength - 4] = 0;
    padded[totalLength - 3] = 0;
    padded[totalLength - 2] = 0;
    padded[totalLength - 1] = 0;

    final view = ByteData.view(padded.buffer);

    for (var chunk = 0; chunk < totalLength; chunk += 64) {
      final x = List<int>.generate(
          16, (i) => view.getUint32(chunk + i * 4, Endian.little));

      var aa = a;
      var bb = b;
      var cc = c;
      var dd = d;

      int f(int x, int y, int z) => (x & y) | ((~x) & z);
      int g(int x, int y, int z) => (x & z) | (y & (~z));
      int h(int x, int y, int z) => x ^ y ^ z;
      int k(int x, int y, int z) => y ^ (x | (~z));

      int rot(int x, int s) => ((x << s) | (x >>> (32 - s))) & 0xFFFFFFFF;

      int step(
          int a, int b, int c, int d, int funcResult, int m, int s, int t) {
        final sum = (a + funcResult + m + t) & 0xFFFFFFFF;
        return (b + rot(sum, s)) & 0xFFFFFFFF;
      }

      // Round 1
      a = step(a, b, c, d, f(b, c, d), x[0], 7, 0xd76aa478);
      d = step(d, a, b, c, f(a, b, c), x[1], 12, 0xe8c7b756);
      c = step(c, d, a, b, f(d, a, b), x[2], 17, 0x242070db);
      b = step(b, c, d, a, f(c, d, a), x[3], 22, 0xc1bdceee);
      a = step(a, b, c, d, f(b, c, d), x[4], 7, 0xf57c0faf);
      d = step(d, a, b, c, f(a, b, c), x[5], 12, 0x4787c62a);
      c = step(c, d, a, b, f(d, a, b), x[6], 17, 0xa8304613);
      b = step(b, c, d, a, f(c, d, a), x[7], 22, 0xfd469501);
      a = step(a, b, c, d, f(b, c, d), x[8], 7, 0x698098d8);
      d = step(d, a, b, c, f(a, b, c), x[9], 12, 0x8b44f7af);
      c = step(c, d, a, b, f(d, a, b), x[10], 17, 0xffff5bb1);
      b = step(b, c, d, a, f(c, d, a), x[11], 22, 0x895cd7be);
      a = step(a, b, c, d, f(b, c, d), x[12], 7, 0x6b901122);
      d = step(d, a, b, c, f(a, b, c), x[13], 12, 0xfd987193);
      c = step(c, d, a, b, f(d, a, b), x[14], 17, 0xa679438e);
      b = step(b, c, d, a, f(c, d, a), x[15], 22, 0x49b40821);

      // Round 2
      a = step(a, b, c, d, g(b, c, d), x[1], 5, 0xf61e2562);
      d = step(d, a, b, c, g(a, b, c), x[6], 9, 0xc040b340);
      c = step(c, d, a, b, g(d, a, b), x[11], 14, 0x265e5a51);
      b = step(b, c, d, a, g(c, d, a), x[0], 20, 0xe9b6c7aa);
      a = step(a, b, c, d, g(b, c, d), x[5], 5, 0xd62f105d);
      d = step(d, a, b, c, g(a, b, c), x[10], 9, 0x02441453);
      c = step(c, d, a, b, g(d, a, b), x[15], 14, 0xd8a1e681);
      b = step(b, c, d, a, g(c, d, a), x[4], 20, 0xe7d3fbc8);
      a = step(a, b, c, d, g(b, c, d), x[9], 5, 0x21e1cde6);
      d = step(d, a, b, c, g(a, b, c), x[14], 9, 0xc33707d6);
      c = step(c, d, a, b, g(d, a, b), x[3], 14, 0xf4d50d87);
      b = step(b, c, d, a, g(c, d, a), x[8], 20, 0x455a14ed);
      a = step(a, b, c, d, g(b, c, d), x[13], 5, 0xa9e3e905);
      d = step(d, a, b, c, g(a, b, c), x[2], 9, 0xfcefa3f8);
      c = step(c, d, a, b, g(d, a, b), x[7], 14, 0x676f02d9);
      b = step(b, c, d, a, g(c, d, a), x[12], 20, 0x8d2a4c8a);

      // Round 3
      a = step(a, b, c, d, h(b, c, d), x[5], 4, 0xfffa3942);
      d = step(d, a, b, c, h(a, b, c), x[8], 11, 0x8771f681);
      c = step(c, d, a, b, h(d, a, b), x[11], 16, 0x6d9d6122);
      b = step(b, c, d, a, h(c, d, a), x[14], 23, 0xfde5380c);
      a = step(a, b, c, d, h(b, c, d), x[1], 4, 0xa4beea44);
      d = step(d, a, b, c, h(a, b, c), x[4], 11, 0x4bdecfa9);
      c = step(c, d, a, b, h(d, a, b), x[7], 16, 0xf6bb4b60);
      b = step(b, c, d, a, h(c, d, a), x[10], 23, 0xbebfbc70);
      a = step(a, b, c, d, h(b, c, d), x[13], 4, 0x289b7ec6);
      d = step(d, a, b, c, h(a, b, c), x[0], 11, 0xeaa127fa);
      c = step(c, d, a, b, h(d, a, b), x[3], 16, 0xd4ef3085);
      b = step(b, c, d, a, h(c, d, a), x[6], 23, 0x04881d05);
      a = step(a, b, c, d, h(b, c, d), x[9], 4, 0xd9d4d039);
      d = step(d, a, b, c, h(a, b, c), x[12], 11, 0xe6db99e5);
      c = step(c, d, a, b, h(d, a, b), x[15], 16, 0x1fa27cf8);
      b = step(b, c, d, a, h(c, d, a), x[2], 23, 0xc4ac5665);

      // Round 4
      a = step(a, b, c, d, k(b, c, d), x[0], 6, 0xf4292244);
      d = step(d, a, b, c, k(a, b, c), x[7], 10, 0x432aff97);
      c = step(c, d, a, b, k(d, a, b), x[14], 15, 0xab9423a7);
      b = step(b, c, d, a, k(c, d, a), x[5], 21, 0xfc93a039);
      a = step(a, b, c, d, k(b, c, d), x[12], 6, 0x655b59c3);
      d = step(d, a, b, c, k(a, b, c), x[3], 10, 0x8f0ccc92);
      c = step(c, d, a, b, k(d, a, b), x[10], 15, 0xffeff47d);
      b = step(b, c, d, a, k(c, d, a), x[1], 21, 0x85845dd1);
      a = step(a, b, c, d, k(b, c, d), x[8], 6, 0x6fa87e4f);
      d = step(d, a, b, c, k(a, b, c), x[15], 10, 0xfe2ce6e0);
      c = step(c, d, a, b, k(d, a, b), x[6], 15, 0xa3014314);
      b = step(b, c, d, a, k(c, d, a), x[13], 21, 0x4e0811a1);
      a = step(a, b, c, d, k(b, c, d), x[4], 6, 0xf7537e82);
      d = step(d, a, b, c, k(a, b, c), x[11], 10, 0xbd3af235);
      c = step(c, d, a, b, k(d, a, b), x[2], 15, 0x2ad7d2bb);
      b = step(b, c, d, a, k(c, d, a), x[9], 21, 0xeb86d391);

      a = (a + aa) & 0xFFFFFFFF;
      b = (b + bb) & 0xFFFFFFFF;
      c = (c + cc) & 0xFFFFFFFF;
      d = (d + dd) & 0xFFFFFFFF;
    }

    final result = Uint8List(16);
    final resultView = ByteData.view(result.buffer);
    resultView.setUint32(0, a, Endian.little);
    resultView.setUint32(4, b, Endian.little);
    resultView.setUint32(8, c, Endian.little);
    resultView.setUint32(12, d, Endian.little);
    return result;
  }
}

/// RC4 (ARC4) stream cipher used in PDF Standard Security Handler Revisions 2 and 3.
class PdfRc4 {
  final Uint8List _s = Uint8List(256);
  int _i = 0;
  int _j = 0;

  PdfRc4(List<int> key) {
    for (var i = 0; i < 256; i++) {
      _s[i] = i;
    }
    var j = 0;
    for (var i = 0; i < 256; i++) {
      j = (j + _s[i] + key[i % key.length]) & 0xFF;
      final temp = _s[i];
      _s[i] = _s[j];
      _s[j] = temp;
    }
  }

  /// Encrypts or decrypts bytes in-place using RC4 stream keystream.
  Uint8List process(List<int> input) {
    final output = Uint8List(input.length);
    for (var k = 0; k < input.length; k++) {
      _i = (_i + 1) & 0xFF;
      _j = (_j + _s[_i]) & 0xFF;
      final temp = _s[_i];
      _s[_i] = _s[_j];
      _s[_j] = temp;
      final t = (_s[_i] + _s[_j]) & 0xFF;
      output[k] = input[k] ^ _s[t];
    }
    return output;
  }

  /// Static helper to encrypt/decrypt a single buffer.
  static Uint8List encrypt(List<int> key, List<int> data) {
    return PdfRc4(key).process(data);
  }
}

/// AES-128 block cipher in CBC mode with PKCS#7 padding (NIST FIPS-197) for PDF Standard Security Handler Revision 4 (AESV2).
class PdfAes128Cbc {
  static const int blockSize = 16;

  // Rijndael S-Box
  static const List<int> _sBox = [
    0x63,
    0x7c,
    0x77,
    0x7b,
    0xf2,
    0x6b,
    0x6f,
    0xc5,
    0x30,
    0x01,
    0x67,
    0x2b,
    0xfe,
    0xd7,
    0xab,
    0x76,
    0xca,
    0x82,
    0xc9,
    0x7d,
    0xfa,
    0x59,
    0x47,
    0xf0,
    0xad,
    0xd4,
    0xa2,
    0xaf,
    0x9c,
    0xa4,
    0x72,
    0xc0,
    0xb7,
    0xfd,
    0x93,
    0x26,
    0x36,
    0x3f,
    0xf7,
    0xcc,
    0x34,
    0xa5,
    0xe5,
    0xf1,
    0x71,
    0xd8,
    0x31,
    0x15,
    0x04,
    0xc7,
    0x23,
    0xc3,
    0x18,
    0x96,
    0x05,
    0x9a,
    0x07,
    0x12,
    0x80,
    0xe2,
    0xeb,
    0x27,
    0xb2,
    0x75,
    0x09,
    0x83,
    0x2c,
    0x1a,
    0x1b,
    0x6e,
    0x5a,
    0xa0,
    0x52,
    0x3b,
    0xd6,
    0xb3,
    0x29,
    0xe3,
    0x2f,
    0x84,
    0x53,
    0xd1,
    0x00,
    0xed,
    0x20,
    0xfc,
    0xb1,
    0x5b,
    0x6a,
    0xcb,
    0xbe,
    0x39,
    0x4a,
    0x4c,
    0x58,
    0xcf,
    0xd0,
    0xef,
    0xaa,
    0xfb,
    0x43,
    0x4d,
    0x33,
    0x85,
    0x45,
    0xf9,
    0x02,
    0x7f,
    0x50,
    0x3c,
    0x9f,
    0xa8,
    0x51,
    0xa3,
    0x40,
    0x8f,
    0x92,
    0x9d,
    0x38,
    0xf5,
    0xbc,
    0xb6,
    0xda,
    0x21,
    0x10,
    0xff,
    0xf3,
    0xd2,
    0xcd,
    0x0c,
    0x13,
    0xec,
    0x5f,
    0x97,
    0x44,
    0x17,
    0xc4,
    0xa7,
    0x7e,
    0x3d,
    0x64,
    0x5d,
    0x19,
    0x73,
    0x60,
    0x81,
    0x4f,
    0xdc,
    0x22,
    0x2a,
    0x90,
    0x88,
    0x46,
    0xee,
    0xb8,
    0x14,
    0xde,
    0x5e,
    0x0b,
    0xdb,
    0xe0,
    0x32,
    0x3a,
    0x0a,
    0x49,
    0x06,
    0x24,
    0x5e,
    0xc2,
    0xd3,
    0xac,
    0x62,
    0x91,
    0x95,
    0xe4,
    0x79,
    0xe7,
    0xc8,
    0x37,
    0x6d,
    0x8d,
    0xd5,
    0x4e,
    0xa9,
    0x6c,
    0x56,
    0xf4,
    0xea,
    0x65,
    0x7a,
    0xae,
    0x08,
    0xba,
    0x78,
    0x25,
    0x2e,
    0x1c,
    0xa6,
    0xb4,
    0xc6,
    0xe8,
    0xdd,
    0x74,
    0x1f,
    0x4b,
    0xbd,
    0x8b,
    0x8a,
    0x70,
    0x3e,
    0xb5,
    0x66,
    0x48,
    0x03,
    0xf6,
    0x0e,
    0x61,
    0x35,
    0x57,
    0xb9,
    0x86,
    0xc1,
    0x1d,
    0x9e,
    0xe1,
    0xf8,
    0x98,
    0x11,
    0x69,
    0xd9,
    0x8e,
    0x94,
    0x9b,
    0x1e,
    0x87,
    0xe9,
    0xce,
    0x55,
    0x28,
    0xdf,
    0x8c,
    0xa1,
    0x89,
    0x0d,
    0xbf,
    0xe6,
    0x42,
    0x68,
    0x41,
    0x99,
    0x2d,
    0x0f,
    0xb0,
    0x54,
    0xbb,
    0x16
  ];

  static const List<int> _rCon = [
    0x00,
    0x01,
    0x02,
    0x04,
    0x08,
    0x10,
    0x20,
    0x40,
    0x80,
    0x1b,
    0x36
  ];

  /// Generates 16-byte cryptographically random IV.
  static Uint8List generateIv() {
    final random = Random.secure();
    final iv = Uint8List(blockSize);
    for (var i = 0; i < blockSize; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  /// Encrypts [plaintext] using 128-bit key [key] in CBC mode with PKCS#7 padding.
  /// Prepend [iv] (16 bytes) to the returned ciphertext per ISO 32000-1 §7.6.6.2.
  static Uint8List encryptWithIv({
    required List<int> key,
    required List<int> plaintext,
    Uint8List? explicitIv,
  }) {
    if (key.length != 16) {
      throw ArgumentError('AES-128 requires a 16-byte key.');
    }

    final iv = explicitIv ?? generateIv();
    if (iv.length != 16) {
      throw ArgumentError('AES IV must be 16 bytes.');
    }

    // Key Expansion (11 round keys of 16 bytes each = 176 bytes)
    final roundKeys = _expandKey(key);

    // PKCS#7 padding
    final padLen = blockSize - (plaintext.length % blockSize);
    final totalLen = plaintext.length + padLen;
    final padded = Uint8List(totalLen);
    padded.setRange(0, plaintext.length, plaintext);
    for (var i = plaintext.length; i < totalLen; i++) {
      padded[i] = padLen;
    }

    // Result buffer: 16-byte IV followed by ciphertext blocks
    final result = Uint8List(blockSize + totalLen);
    result.setRange(0, blockSize, iv);

    final prevBlock = Uint8List.fromList(iv);
    final block = Uint8List(blockSize);

    for (var offset = 0; offset < totalLen; offset += blockSize) {
      // CBC Mode: XOR with previous ciphertext block (or IV for first block)
      for (var i = 0; i < blockSize; i++) {
        block[i] = padded[offset + i] ^ prevBlock[i];
      }

      // AES-128 Single Block Encryption
      _encryptBlock(block, roundKeys);

      result.setRange(
          blockSize + offset, blockSize + offset + blockSize, block);
      prevBlock.setRange(0, blockSize, block);
    }

    return result;
  }

  static Uint8List _expandKey(List<int> key) {
    final w = Uint32List(44);
    for (var i = 0; i < 4; i++) {
      w[i] = (key[4 * i] << 24) |
          (key[4 * i + 1] << 16) |
          (key[4 * i + 2] << 8) |
          key[4 * i + 3];
    }

    for (var i = 4; i < 44; i++) {
      var temp = w[i - 1];
      if (i % 4 == 0) {
        // RotWord + SubWord + Rcon
        final rot = ((temp << 8) | (temp >>> 24)) & 0xFFFFFFFF;
        final sub = (_sBox[(rot >>> 24) & 0xFF] << 24) |
            (_sBox[(rot >>> 16) & 0xFF] << 16) |
            (_sBox[(rot >>> 8) & 0xFF] << 8) |
            _sBox[rot & 0xFF];
        temp = sub ^ (_rCon[i ~/ 4] << 24);
      }
      w[i] = w[i - 4] ^ temp;
    }

    final roundKeys = Uint8List(176);
    for (var i = 0; i < 44; i++) {
      final val = w[i];
      roundKeys[i * 4] = (val >>> 24) & 0xFF;
      roundKeys[i * 4 + 1] = (val >>> 16) & 0xFF;
      roundKeys[i * 4 + 2] = (val >>> 8) & 0xFF;
      roundKeys[i * 4 + 3] = val & 0xFF;
    }
    return roundKeys;
  }

  static void _encryptBlock(Uint8List state, Uint8List roundKeys) {
    // AddRoundKey 0
    _addRoundKey(state, roundKeys, 0);

    // Rounds 1..9
    for (var round = 1; round <= 9; round++) {
      _subBytes(state);
      _shiftRows(state);
      _mixColumns(state);
      _addRoundKey(state, roundKeys, round);
    }

    // Round 10 (no MixColumns)
    _subBytes(state);
    _shiftRows(state);
    _addRoundKey(state, roundKeys, 10);
  }

  static void _addRoundKey(Uint8List state, Uint8List roundKeys, int round) {
    final offset = round * 16;
    for (var i = 0; i < 16; i++) {
      state[i] ^= roundKeys[offset + i];
    }
  }

  static void _subBytes(Uint8List state) {
    for (var i = 0; i < 16; i++) {
      state[i] = _sBox[state[i]];
    }
  }

  static void _shiftRows(Uint8List state) {
    // Row 1: shift left 1
    final temp1 = state[1];
    state[1] = state[5];
    state[5] = state[9];
    state[9] = state[13];
    state[13] = temp1;

    // Row 2: shift left 2
    final temp2a = state[2];
    final temp2b = state[6];
    state[2] = state[10];
    state[6] = state[14];
    state[10] = temp2a;
    state[14] = temp2b;

    // Row 3: shift left 3 (shift right 1)
    final temp3 = state[15];
    state[15] = state[11];
    state[11] = state[7];
    state[7] = state[3];
    state[3] = temp3;
  }

  static int _gMul(int a, int b) {
    var p = 0;
    var aa = a;
    var bb = b;
    for (var i = 0; i < 8; i++) {
      if ((bb & 1) != 0) p ^= aa;
      final hiBit = (aa & 0x80) != 0;
      aa = (aa << 1) & 0xFF;
      if (hiBit) aa ^= 0x1b;
      bb >>= 1;
    }
    return p;
  }

  static void _mixColumns(Uint8List state) {
    for (var c = 0; c < 4; c++) {
      final i = c * 4;
      final s0 = state[i];
      final s1 = state[i + 1];
      final s2 = state[i + 2];
      final s3 = state[i + 3];

      state[i] = _gMul(0x02, s0) ^ _gMul(0x03, s1) ^ s2 ^ s3;
      state[i + 1] = s0 ^ _gMul(0x02, s1) ^ _gMul(0x03, s2) ^ s3;
      state[i + 2] = s0 ^ s1 ^ _gMul(0x02, s2) ^ _gMul(0x03, s3);
      state[i + 3] = _gMul(0x03, s0) ^ s1 ^ s2 ^ _gMul(0x02, s3);
    }
  }
}
