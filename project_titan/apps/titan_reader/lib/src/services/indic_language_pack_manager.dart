import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

import '../domain/entities/ocr/indic_language_pack.dart';

/// Security and integrity exception thrown during language pack operations.
class IndicPackSecurityException implements Exception {
  final String message;
  final String? path;

  const IndicPackSecurityException(this.message, [this.path]);

  @override
  String toString() =>
      'IndicPackSecurityException: $message${path != null ? ' (Path: $path)' : ''}';
}

/// Standalone, pure-Dart cryptographic SHA-256 hash calculator (FIPS 180-4).
///
/// Implemented directly to guarantee zero unvetted runtime dependencies.
class Sha256Checksum {
  static const List<int> _k = [
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];

  static int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xFFFFFFFF;
  static int _ch(int x, int y, int z) => ((x & y) ^ (~x & z)) & 0xFFFFFFFF;
  static int _maj(int x, int y, int z) =>
      ((x & y) ^ (x & z) ^ (y & z)) & 0xFFFFFFFF;
  static int _sigma0(int x) =>
      (_rotr(x, 2) ^ _rotr(x, 13) ^ _rotr(x, 22)) & 0xFFFFFFFF;
  static int _sigma1(int x) =>
      (_rotr(x, 6) ^ _rotr(x, 11) ^ _rotr(x, 25)) & 0xFFFFFFFF;
  static int _gamma0(int x) =>
      (_rotr(x, 7) ^ _rotr(x, 18) ^ (x >> 3)) & 0xFFFFFFFF;
  static int _gamma1(int x) =>
      (_rotr(x, 17) ^ _rotr(x, 19) ^ (x >> 10)) & 0xFFFFFFFF;

  /// Computes the 64-character hexadecimal SHA-256 hash of [bytes].
  static String hashBytes(List<int> bytes) {
    int h0 = 0x6a09e667;
    int h1 = 0xbb67ae85;
    int h2 = 0x3c6ef372;
    int h3 = 0xa54ff53a;
    int h4 = 0x510e527f;
    int h5 = 0x9b05688c;
    int h6 = 0x1f83d9ab;
    int h7 = 0x5be0cd19;

    final length = bytes.length;
    final bitLength = length * 8;

    // Create padded buffer
    final padLength = (length + 9 + 63) & ~63;
    final padded = Uint8List(padLength);
    padded.setRange(0, length, bytes);
    padded[length] = 0x80;

    final view = ByteData.view(padded.buffer);
    view.setUint64(padLength - 8, bitLength, Endian.big);

    final w = List<int>.filled(64, 0);

    for (int chunk = 0; chunk < padLength; chunk += 64) {
      for (int i = 0; i < 16; i++) {
        w[i] = view.getUint32(chunk + i * 4, Endian.big);
      }
      for (int i = 16; i < 64; i++) {
        final s0 = _gamma0(w[i - 15]);
        final s1 = _gamma1(w[i - 2]);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xFFFFFFFF;
      }

      int a = h0;
      int b = h1;
      int c = h2;
      int d = h3;
      int e = h4;
      int f = h5;
      int g = h6;
      int h = h7;

      for (int i = 0; i < 64; i++) {
        final t1 = (h + _sigma1(e) + _ch(e, f, g) + _k[i] + w[i]) & 0xFFFFFFFF;
        final t2 = (_sigma0(a) + _maj(a, b, c)) & 0xFFFFFFFF;
        h = g;
        g = f;
        f = e;
        e = (d + t1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (t1 + t2) & 0xFFFFFFFF;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
      h5 = (h5 + f) & 0xFFFFFFFF;
      h6 = (h6 + g) & 0xFFFFFFFF;
      h7 = (h7 + h) & 0xFFFFFFFF;
    }

    final out = StringBuffer();
    for (final val in [h0, h1, h2, h3, h4, h5, h6, h7]) {
      out.write(val.toRadixString(16).padLeft(8, '0'));
    }
    return out.toString().toLowerCase();
  }

  /// Computes the SHA-256 hash of a file on disk.
  static Future<String> hashFile(File file) async {
    final bytes = await file.readAsBytes();
    return hashBytes(bytes);
  }
}

/// Application service coordinator for Indic OCR Language Packs.
///
/// Responsibilities:
/// - Discovers and indexes local model packs.
/// - Validates manifest syntax, schema, and security boundaries.
/// - Enforces strict SHA-256 cryptographic verification.
/// - Manages LRU memory cache policy (max 2 active recognition models).
/// - Ensures 100% offline-first execution.
class IndicLanguagePackManager {
  /// Maximum number of active recognition model sessions allowed concurrently in RAM.
  final int maxActiveRecognitionModels;

  /// Current host operating system platform identifier (e.g. 'windows', 'macos', 'android').
  final String currentPlatform;

  /// Current application version string.
  final String appVersion;

  /// Current OCR engine version string.
  final String engineVersion;

  /// Internal registry of discovered language packs keyed by packId.
  final Map<String, IndicLanguagePack> _packs = {};

  /// Access history queue for LRU eviction tracking.
  final List<String> _accessQueue = [];

  IndicLanguagePackManager({
    this.maxActiveRecognitionModels = 2,
    String? platform,
    this.appVersion = '0.1.0',
    this.engineVersion = '1.0.0',
  }) : currentPlatform = platform ?? _resolveCurrentPlatform();

  static String _resolveCurrentPlatform() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// All registered language packs.
  List<IndicLanguagePack> get allPacks => List.unmodifiable(_packs.values);

  /// All packs verified and ready for inference.
  List<IndicLanguagePack> get readyPacks =>
      _packs.values.where((p) => p.isReady).toList();

  /// Gets a registered language pack by its canonical [packId].
  IndicLanguagePack? getPackById(String packId) => _packs[packId];

  /// Gets a registered language pack by language code (e.g. 'hi', 'bn').
  IndicLanguagePack? getPackByLanguage(String languageCode) {
    final code = languageCode.trim().toLowerCase();
    for (final pack in _packs.values) {
      if (pack.languageCode.toLowerCase() == code) return pack;
    }
    return null;
  }

  /// Registers a pack directly into memory.
  void registerPack(IndicLanguagePack pack) {
    _packs[pack.packId] = pack;
  }

  /// Unregisters a pack from memory.
  void unregisterPack(String packId) {
    _packs.remove(packId);
    _accessQueue.remove(packId);
  }

  /// Validates and sanitizes a relative file name inside a pack directory.
  ///
  /// Prevents directory traversal (`../`, `..\`), absolute paths, UNC paths,
  /// control characters, null bytes, and dangerous executable file extensions.
  static void validatePackFileName(String fileName, String packDirectoryPath) {
    if (fileName.trim().isEmpty) {
      throw const IndicPackSecurityException('File name cannot be empty.');
    }

    // Check for null bytes or control characters
    for (int i = 0; i < fileName.length; i++) {
      final code = fileName.codeUnitAt(i);
      if (code < 32 || code == 0x7F) {
        throw IndicPackSecurityException(
          'File name contains illegal control characters.',
          fileName,
        );
      }
    }

    // Check for directory traversal patterns
    if (fileName.contains('..') ||
        fileName.contains('/') ||
        fileName.contains('\\')) {
      throw IndicPackSecurityException(
        'Path traversal or nested directory separators detected in file name.',
        fileName,
      );
    }

    // Check for drive letters, colons, or UNC prefixes
    if (fileName.contains(':') ||
        fileName.startsWith(r'\\') ||
        fileName.startsWith('//')) {
      throw IndicPackSecurityException(
        'Absolute or UNC path detected in manifest file name.',
        fileName,
      );
    }

    // Verify resolved path stays strictly within the pack root
    final canonicalDir = p.canonicalize(packDirectoryPath);
    final resolvedPath = p.canonicalize(p.join(packDirectoryPath, fileName));
    if (!p.isWithin(canonicalDir, resolvedPath) &&
        resolvedPath != canonicalDir) {
      throw IndicPackSecurityException(
        'Resolved path escapes the sandboxed pack directory boundary.',
        resolvedPath,
      );
    }

    // Disallow dangerous executable extensions
    const dangerousExtensions = [
      '.exe',
      '.dll',
      '.so',
      '.dylib',
      '.bat',
      '.cmd',
      '.sh',
      '.ps1',
      '.vbs',
      '.js',
      '.py',
      '.bin',
    ];
    final ext = p.extension(fileName).toLowerCase();
    if (dangerousExtensions.contains(ext) && ext != '.bin') {
      throw IndicPackSecurityException(
        'Prohibited executable file extension in model pack payload.',
        fileName,
      );
    }
  }

  /// Helper to record and return a pack result.
  IndicLanguagePack _recordResult(IndicLanguagePack pack) {
    _packs[pack.packId] = pack;
    return pack;
  }

  /// Validates an installed language pack directory and returns the validated entity.
  ///
  /// Executes:
  /// 1. Manifest discovery and JSON parsing.
  /// 2. Path security validation.
  /// 3. Platform & version compatibility checks.
  /// 4. File existence and size validation.
  /// 5. Cryptographic SHA-256 checksum comparison.
  Future<IndicLanguagePack> validatePackDirectory(
      String packDirectoryPath) async {
    final dir = Directory(packDirectoryPath);
    if (!await dir.exists()) {
      throw IndicPackSecurityException(
        'Pack directory does not exist.',
        packDirectoryPath,
      );
    }

    final manifestFile = File(p.join(packDirectoryPath, 'manifest.json'));
    if (!await manifestFile.exists()) {
      final defaultPack = IndicLanguagePack(
        manifest: IndicLanguagePack.hindiFoundationDescriptor.manifest,
        directoryPath: packDirectoryPath,
        status: IndicLanguagePackStatus.corrupted,
        errorMessage: 'Missing manifest.json file in pack directory.',
      );
      return _recordResult(defaultPack);
    }

    // Parse manifest JSON
    IndicPackManifest manifest;
    try {
      final jsonString = await manifestFile.readAsString();
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      manifest = IndicPackManifest.fromJson(decoded);
    } catch (e) {
      final errorPack = IndicLanguagePack(
        manifest: IndicLanguagePack.hindiFoundationDescriptor.manifest,
        directoryPath: packDirectoryPath,
        status: IndicLanguagePackStatus.corrupted,
        errorMessage: 'Malformed or unparseable manifest.json: $e',
      );
      return _recordResult(errorPack);
    }

    // Validate manifest schema
    final schemaErrors = manifest.validate();
    if (schemaErrors.isNotEmpty) {
      final errorPack = IndicLanguagePack(
        manifest: manifest,
        directoryPath: packDirectoryPath,
        status: IndicLanguagePackStatus.corrupted,
        errorMessage: 'Manifest schema errors: ${schemaErrors.join('; ')}',
      );
      return _recordResult(errorPack);
    }

    // Validate path security on model and dictionary filenames
    try {
      validatePackFileName(manifest.modelFileName, packDirectoryPath);
      validatePackFileName(manifest.dictFileName, packDirectoryPath);
    } on IndicPackSecurityException catch (e) {
      final errorPack = IndicLanguagePack(
        manifest: manifest,
        directoryPath: packDirectoryPath,
        status: IndicLanguagePackStatus.corrupted,
        errorMessage: 'Security violation: ${e.message}',
      );
      return _recordResult(errorPack);
    }

    // Validate platform support
    if (!manifest.supportedPlatforms.contains(currentPlatform.toLowerCase())) {
      final unsupportedPack = IndicLanguagePack(
        manifest: manifest,
        directoryPath: packDirectoryPath,
        status: IndicLanguagePackStatus.unsupported,
        errorMessage:
            'Platform "$currentPlatform" is not supported by this language pack.',
      );
      return _recordResult(unsupportedPack);
    }

    // Validate model file existence & size
    final modelFile = File(p.join(packDirectoryPath, manifest.modelFileName));
    if (!await modelFile.exists()) {
      final errorPack = IndicLanguagePack(
        manifest: manifest,
        directoryPath: packDirectoryPath,
        status: IndicLanguagePackStatus.corrupted,
        errorMessage:
            'Model weights file "${manifest.modelFileName}" not found in pack.',
      );
      return _recordResult(errorPack);
    }
    final modelSize = await modelFile.length();
    if (modelSize != manifest.modelSizeBytes) {
      final errorPack = IndicLanguagePack(
        manifest: manifest,
        directoryPath: packDirectoryPath,
        status: IndicLanguagePackStatus.corrupted,
        errorMessage:
            'Model size mismatch: expected ${manifest.modelSizeBytes} bytes, found $modelSize bytes.',
      );
      return _recordResult(errorPack);
    }

    // Validate dictionary file existence & size
    final dictFile = File(p.join(packDirectoryPath, manifest.dictFileName));
    if (!await dictFile.exists()) {
      final errorPack = IndicLanguagePack(
        manifest: manifest,
        directoryPath: packDirectoryPath,
        status: IndicLanguagePackStatus.corrupted,
        errorMessage:
            'Dictionary file "${manifest.dictFileName}" not found in pack.',
      );
      return _recordResult(errorPack);
    }
    final dictSize = await dictFile.length();
    if (dictSize != manifest.dictSizeBytes) {
      final errorPack = IndicLanguagePack(
        manifest: manifest,
        directoryPath: packDirectoryPath,
        status: IndicLanguagePackStatus.corrupted,
        errorMessage:
            'Dictionary size mismatch: expected ${manifest.dictSizeBytes} bytes, found $dictSize bytes.',
      );
      return _recordResult(errorPack);
    }

    // Validate SHA-256 checksums
    final calculatedModelHash = await Sha256Checksum.hashFile(modelFile);
    if (calculatedModelHash.toLowerCase() !=
        manifest.modelSha256.toLowerCase()) {
      final errorPack = IndicLanguagePack(
        manifest: manifest,
        directoryPath: packDirectoryPath,
        status: IndicLanguagePackStatus.corrupted,
        errorMessage:
            'Model SHA-256 mismatch: expected ${manifest.modelSha256}, calculated $calculatedModelHash.',
      );
      return _recordResult(errorPack);
    }

    final calculatedDictHash = await Sha256Checksum.hashFile(dictFile);
    if (calculatedDictHash.toLowerCase() != manifest.dictSha256.toLowerCase()) {
      final errorPack = IndicLanguagePack(
        manifest: manifest,
        directoryPath: packDirectoryPath,
        status: IndicLanguagePackStatus.corrupted,
        errorMessage:
            'Dictionary SHA-256 mismatch: expected ${manifest.dictSha256}, calculated $calculatedDictHash.',
      );
      return _recordResult(errorPack);
    }

    // All validation gates passed
    final pack = IndicLanguagePack(
      manifest: manifest,
      directoryPath: packDirectoryPath,
      status: IndicLanguagePackStatus.ready,
      installedAt: DateTime.now(),
    );
    return _recordResult(pack);
  }

  /// Discovers all packs in a given parent directory.
  Future<List<IndicLanguagePack>> discoverPacks(
      String parentDirectoryPath) async {
    final dir = Directory(parentDirectoryPath);
    if (!await dir.exists()) return [];

    final discovered = <IndicLanguagePack>[];
    final entities = await dir.list().toList();

    for (final entity in entities) {
      if (entity is Directory) {
        try {
          final pack = await validatePackDirectory(entity.path);
          discovered.add(pack);
        } catch (e) {
          // If top-level validation throws, ignore
        }
      }
    }
    return discovered;
  }

  /// Registers an access to [packId] and enforces the LRU memory policy.
  ///
  /// Returns the pack ID of any model that should be evicted from RAM, or null
  /// if within the [maxActiveRecognitionModels] memory budget.
  String? recordAccessAndCheckEviction(String packId) {
    final pack = _packs[packId];
    if (pack == null) return null;

    final updated = pack.copyWith(lastAccessedAt: DateTime.now());
    _packs[packId] = updated;

    _accessQueue.remove(packId);
    _accessQueue.add(packId);

    if (_accessQueue.length > maxActiveRecognitionModels) {
      // Evict oldest accessed model
      final evictedPackId = _accessQueue.removeAt(0);
      return evictedPackId;
    }
    return null;
  }
}
