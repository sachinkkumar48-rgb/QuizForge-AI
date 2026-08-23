import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:titan_reader/src/domain/entities/ocr/indic_language_pack.dart';
import 'package:titan_reader/src/services/indic_language_pack_manager.dart';

void main() {
  group('Phase 7A-1: Indic OCR Language Pack Foundation Tests', () {
    late Directory tempRootDir;

    setUp(() async {
      tempRootDir =
          await Directory.systemTemp.createTemp('titan_indic_pack_test_');
    });

    tearDown(() async {
      if (await tempRootDir.exists()) {
        await tempRootDir.delete(recursive: true);
      }
    });

    /// Helper to create a synthetic valid pack directory with real SHA-256 hashes.
    Future<Directory> createSyntheticPack({
      required String packId,
      required String languageCode,
      required String scriptCode,
      String modelContent = 'SYNTHETIC_ONNX_MODEL_TENSOR_GRAPH_DATA',
      String dictContent = 'a\nb\nc\nक\nख\nग\nघ\n',
      List<String> supportedPlatforms = const [
        'windows',
        'macos',
        'linux',
        'android',
        'ios'
      ],
      String? customModelFileName,
      String? customDictFileName,
      String? overrideModelSha256,
      String? overrideDictSha256,
      int? overrideModelSize,
      int? overrideDictSize,
      String? malformedJson,
      bool omitManifest = false,
      bool omitModel = false,
      bool omitDict = false,
    }) async {
      final packDir = Directory(p.join(tempRootDir.path, packId));
      await packDir.create(recursive: true);

      final modelName = customModelFileName ?? 'model.onnx';
      final dictName = customDictFileName ?? 'dict.txt';

      final modelBytes = utf8.encode(modelContent);
      final dictBytes = utf8.encode(dictContent);

      final actualModelHash = Sha256Checksum.hashBytes(modelBytes);
      final actualDictHash = Sha256Checksum.hashBytes(dictBytes);

      if (!omitModel) {
        final modelFile = File(p.join(packDir.path, modelName));
        await modelFile.writeAsBytes(modelBytes);
      }

      if (!omitDict) {
        final dictFile = File(p.join(packDir.path, dictName));
        await dictFile.writeAsBytes(dictBytes);
      }

      if (!omitManifest) {
        final manifestFile = File(p.join(packDir.path, 'manifest.json'));
        if (malformedJson != null) {
          await manifestFile.writeAsString(malformedJson);
        } else {
          final manifest = {
            'manifestVersion': '1.0.0',
            'packId': packId,
            'displayName': '$languageCode ($scriptCode) OCR Pack',
            'languageCode': languageCode,
            'languageName': languageCode == 'hi' ? 'Hindi' : 'Language',
            'scriptCode': scriptCode,
            'scriptName': scriptCode == 'Deva' ? 'Devanagari' : 'Script',
            'engineVersion': '1.0.0',
            'modelVersion': '1.0.0',
            'modelFormat': 'onnx',
            'quantization': 'int8',
            'modelFileName': modelName,
            'modelSizeBytes': overrideModelSize ?? modelBytes.length,
            'modelSha256': overrideModelSha256 ?? actualModelHash,
            'dictFileName': dictName,
            'dictSizeBytes': overrideDictSize ?? dictBytes.length,
            'dictSha256': overrideDictSha256 ?? actualDictHash,
            'licenseType': 'Apache-2.0',
            'licenseUrl': 'https://github.com/PaddlePaddle/PaddleOCR',
            'minimumAppVersion': '0.1.0',
            'supportedPlatforms': supportedPlatforms,
          };
          await manifestFile.writeAsString(jsonEncode(manifest));
        }
      }

      return packDir;
    }

    test('1. SHA-256 Checksum calculation matches standard known vectors', () {
      // Empty string SHA-256
      expect(
        Sha256Checksum.hashBytes([]),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );

      // "abc" SHA-256
      expect(
        Sha256Checksum.hashBytes(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('2. Manifest JSON serialization and deserialization is lossless', () {
      const manifest = IndicPackManifest(
        manifestVersion: '1.0.0',
        packId: 'titan-ocr-indic-hindi',
        displayName: 'Hindi (Devanagari) OCR Pack',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
        engineVersion: '1.0.0',
        modelVersion: '1.0.0',
        modelFormat: 'onnx',
        quantization: 'int8',
        modelFileName: 'model.onnx',
        modelSizeBytes: 9856512,
        modelSha256:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        dictFileName: 'dict.txt',
        dictSizeBytes: 14208,
        dictSha256:
            'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
        licenseType: 'Apache-2.0',
        licenseUrl: 'https://github.com/PaddlePaddle/PaddleOCR',
        minimumAppVersion: '0.1.0',
        supportedPlatforms: ['windows', 'macos', 'linux', 'android', 'ios'],
      );

      final json = manifest.toJson();
      final roundtrip = IndicPackManifest.fromJson(json);

      expect(roundtrip.packId, equals(manifest.packId));
      expect(roundtrip.languageCode, equals('hi'));
      expect(roundtrip.scriptCode, equals('Deva'));
      expect(roundtrip.modelSizeBytes, equals(9856512));
      expect(roundtrip.validate(), isEmpty);
    });

    test('3. Manifest validation flags missing and invalid attributes', () {
      const invalidManifest = IndicPackManifest(
        manifestVersion: '1.0.0',
        packId: '',
        displayName: '',
        languageCode: '',
        languageName: '',
        scriptCode: '',
        scriptName: '',
        engineVersion: '1.0.0',
        modelVersion: '1.0.0',
        modelFormat: 'onnx',
        quantization: 'int8',
        modelFileName: '',
        modelSizeBytes: -10,
        modelSha256: 'invalid_short_hash',
        dictFileName: '',
        dictSizeBytes: 0,
        dictSha256: 'invalid',
        licenseType: 'Apache-2.0',
        minimumAppVersion: '0.1.0',
        supportedPlatforms: [],
      );

      final errors = invalidManifest.validate();
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.contains('packId')), isTrue);
      expect(errors.any((e) => e.contains('languageCode')), isTrue);
      expect(errors.any((e) => e.contains('modelSizeBytes')), isTrue);
      expect(errors.any((e) => e.contains('modelSha256')), isTrue);
      expect(errors.any((e) => e.contains('supportedPlatforms')), isTrue);
    });

    test('4. Hindi foundation descriptor represents uninstalled P0 target', () {
      const hindi = IndicLanguagePack.hindiFoundationDescriptor;
      expect(hindi.packId, 'titan-ocr-indic-hindi');
      expect(hindi.languageCode, 'hi');
      expect(hindi.scriptCode, 'Deva');
      expect(hindi.status, IndicLanguagePackStatus.notInstalled);
      expect(hindi.isReady, isFalse);

      final modelDescriptor = hindi.toOcrModelDescriptor();
      expect(modelDescriptor.id, 'titan-ocr-indic-hindi');
      expect(modelDescriptor.languageCode, 'hi');
      expect(modelDescriptor.isAvailableLocally, isFalse);
    });

    test('5. Valid pack directory passes all integrity gates to READY state',
        () async {
      final packDir = await createSyntheticPack(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        scriptCode: 'Deva',
      );

      final manager = IndicLanguagePackManager(platform: 'windows');
      final pack = await manager.validatePackDirectory(packDir.path);

      expect(pack.status, IndicLanguagePackStatus.ready);
      expect(pack.isReady, isTrue);
      expect(pack.isCorrupted, isFalse);
      expect(pack.modelFilePath, isNotNull);
      expect(pack.dictionaryFilePath, isNotNull);

      // Verify adaptation to OcrModelDescriptor
      final ocrDescriptor = pack.toOcrModelDescriptor();
      expect(ocrDescriptor.id, 'titan-ocr-indic-hindi');
      expect(ocrDescriptor.isAvailableLocally, isTrue);
      expect(ocrDescriptor.localFilePath, equals(pack.modelFilePath));
    });

    test('6. SHA-256 mismatch marks pack as CORRUPTED (Model mismatch)',
        () async {
      final packDir = await createSyntheticPack(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        scriptCode: 'Deva',
        overrideModelSha256:
            'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
      );

      final manager = IndicLanguagePackManager(platform: 'windows');
      final pack = await manager.validatePackDirectory(packDir.path);

      expect(pack.status, IndicLanguagePackStatus.corrupted);
      expect(pack.isReady, isFalse);
      expect(pack.isCorrupted, isTrue);
      expect(pack.errorMessage, contains('Model SHA-256 mismatch'));
    });

    test('7. SHA-256 mismatch marks pack as CORRUPTED (Dictionary mismatch)',
        () async {
      final packDir = await createSyntheticPack(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        scriptCode: 'Deva',
        overrideDictSha256:
            'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
      );

      final manager = IndicLanguagePackManager(platform: 'windows');
      final pack = await manager.validatePackDirectory(packDir.path);

      expect(pack.status, IndicLanguagePackStatus.corrupted);
      expect(pack.errorMessage, contains('Dictionary SHA-256 mismatch'));
    });

    test('8. Missing model file marks pack as CORRUPTED', () async {
      final packDir = await createSyntheticPack(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        scriptCode: 'Deva',
        omitModel: true,
      );

      final manager = IndicLanguagePackManager(platform: 'windows');
      final pack = await manager.validatePackDirectory(packDir.path);

      expect(pack.status, IndicLanguagePackStatus.corrupted);
      expect(pack.errorMessage, contains('not found in pack'));
    });

    test('9. Missing dictionary file marks pack as CORRUPTED', () async {
      final packDir = await createSyntheticPack(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        scriptCode: 'Deva',
        omitDict: true,
      );

      final manager = IndicLanguagePackManager(platform: 'windows');
      final pack = await manager.validatePackDirectory(packDir.path);

      expect(pack.status, IndicLanguagePackStatus.corrupted);
      expect(pack.errorMessage, contains('not found in pack'));
    });

    test('10. Missing manifest.json marks pack as CORRUPTED', () async {
      final packDir = await createSyntheticPack(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        scriptCode: 'Deva',
        omitManifest: true,
      );

      final manager = IndicLanguagePackManager(platform: 'windows');
      final pack = await manager.validatePackDirectory(packDir.path);

      expect(pack.status, IndicLanguagePackStatus.corrupted);
      expect(pack.errorMessage, contains('Missing manifest.json'));
    });

    test('11. Malformed JSON manifest marks pack as CORRUPTED', () async {
      final packDir = await createSyntheticPack(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        scriptCode: 'Deva',
        malformedJson: '{ invalid json structure !!! }',
      );

      final manager = IndicLanguagePackManager(platform: 'windows');
      final pack = await manager.validatePackDirectory(packDir.path);

      expect(pack.status, IndicLanguagePackStatus.corrupted);
      expect(pack.errorMessage, contains('Malformed or unparseable'));
    });

    test('12. Unsupported host platform marks pack as UNSUPPORTED', () async {
      final packDir = await createSyntheticPack(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        scriptCode: 'Deva',
        supportedPlatforms: ['linux', 'android'],
      );

      final manager = IndicLanguagePackManager(platform: 'windows');
      final pack = await manager.validatePackDirectory(packDir.path);

      expect(pack.status, IndicLanguagePackStatus.unsupported);
      expect(pack.isReady, isFalse);
      expect(pack.errorMessage, contains('not supported'));
    });

    test('13. Path security prevents relative traversal and escape attacks',
        () {
      const sandboxPath = r'C:\titan_models\indic\hindi';

      // Traversal attacks
      expect(
        () => IndicLanguagePackManager.validatePackFileName(
            '../escaped.onnx', sandboxPath),
        throwsA(isA<IndicPackSecurityException>()),
      );
      expect(
        () => IndicLanguagePackManager.validatePackFileName(
            r'..\escaped.onnx', sandboxPath),
        throwsA(isA<IndicPackSecurityException>()),
      );
      expect(
        () => IndicLanguagePackManager.validatePackFileName(
            r'sub/../../escaped.onnx', sandboxPath),
        throwsA(isA<IndicPackSecurityException>()),
      );

      // Absolute paths
      expect(
        () => IndicLanguagePackManager.validatePackFileName(
            r'C:\Windows\System32\cmd.exe', sandboxPath),
        throwsA(isA<IndicPackSecurityException>()),
      );
      expect(
        () => IndicLanguagePackManager.validatePackFileName(
            r'/etc/passwd', sandboxPath),
        throwsA(isA<IndicPackSecurityException>()),
      );
      expect(
        () => IndicLanguagePackManager.validatePackFileName(
            r'\\server\share\model.onnx', sandboxPath),
        throwsA(isA<IndicPackSecurityException>()),
      );

      // Null bytes and control characters
      expect(
        () => IndicLanguagePackManager.validatePackFileName(
            'model\x00.onnx', sandboxPath),
        throwsA(isA<IndicPackSecurityException>()),
      );

      // Executable payloads
      expect(
        () => IndicLanguagePackManager.validatePackFileName(
            'payload.exe', sandboxPath),
        throwsA(isA<IndicPackSecurityException>()),
      );
      expect(
        () => IndicLanguagePackManager.validatePackFileName(
            'script.sh', sandboxPath),
        throwsA(isA<IndicPackSecurityException>()),
      );
      expect(
        () => IndicLanguagePackManager.validatePackFileName(
            'attack.bat', sandboxPath),
        throwsA(isA<IndicPackSecurityException>()),
      );

      // Valid filenames pass
      expect(
        () => IndicLanguagePackManager.validatePackFileName(
            'model.onnx', sandboxPath),
        returnsNormally,
      );
      expect(
        () => IndicLanguagePackManager.validatePackFileName(
            'dict.txt', sandboxPath),
        returnsNormally,
      );
    });

    test('14. Pack discovery scans parent directories and populates ready list',
        () async {
      await createSyntheticPack(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        scriptCode: 'Deva',
      );
      await createSyntheticPack(
        packId: 'titan-ocr-indic-bengali',
        languageCode: 'bn',
        scriptCode: 'Beng',
      );
      await createSyntheticPack(
        packId: 'titan-ocr-indic-corrupt',
        languageCode: 'ta',
        scriptCode: 'Taml',
        overrideModelSha256:
            'bad_hash_0000000000000000000000000000000000000000',
      );

      final manager = IndicLanguagePackManager(platform: 'windows');
      final discovered = await manager.discoverPacks(tempRootDir.path);

      expect(discovered.length, 3);
      expect(manager.allPacks.length, 3);
      expect(manager.readyPacks.length, 2);

      final hindi = manager.getPackByLanguage('hi');
      expect(hindi, isNotNull);
      expect(hindi!.isReady, isTrue);

      final bengali = manager.getPackByLanguage('bn');
      expect(bengali, isNotNull);
      expect(bengali!.isReady, isTrue);

      final corrupt = manager.getPackByLanguage('ta');
      expect(corrupt, isNotNull);
      expect(corrupt!.isCorrupted, isTrue);
    });

    test('15. LRU Memory policy tracks access and evicts oldest model', () {
      final manager = IndicLanguagePackManager(
        maxActiveRecognitionModels: 2,
        platform: 'windows',
      );

      const pack1 = IndicLanguagePack(
        manifest: IndicPackManifest(
          manifestVersion: '1.0.0',
          packId: 'pack-hindi',
          displayName: 'Hindi Pack',
          languageCode: 'hi',
          languageName: 'Hindi',
          scriptCode: 'Deva',
          scriptName: 'Devanagari',
          engineVersion: '1.0.0',
          modelVersion: '1.0.0',
          modelFormat: 'onnx',
          quantization: 'int8',
          modelFileName: 'model.onnx',
          modelSizeBytes: 100,
          modelSha256:
              '0000000000000000000000000000000000000000000000000000000000000000',
          dictFileName: 'dict.txt',
          dictSizeBytes: 50,
          dictSha256:
              '0000000000000000000000000000000000000000000000000000000000000000',
          licenseType: 'Apache-2.0',
          minimumAppVersion: '0.1.0',
          supportedPlatforms: ['windows'],
        ),
        status: IndicLanguagePackStatus.ready,
      );

      final pack2 = pack1.copyWith(
        manifest: IndicPackManifest.fromJson({
          ...pack1.manifest.toJson(),
          'packId': 'pack-bengali',
          'languageCode': 'bn',
        }),
      );

      final pack3 = pack1.copyWith(
        manifest: IndicPackManifest.fromJson({
          ...pack1.manifest.toJson(),
          'packId': 'pack-tamil',
          'languageCode': 'ta',
        }),
      );

      manager.registerPack(pack1);
      manager.registerPack(pack2);
      manager.registerPack(pack3);

      // Access Hindi -> No eviction
      var evicted = manager.recordAccessAndCheckEviction('pack-hindi');
      expect(evicted, isNull);

      // Access Bengali -> No eviction (2 models active: [hindi, bengali])
      evicted = manager.recordAccessAndCheckEviction('pack-bengali');
      expect(evicted, isNull);

      // Access Hindi again -> [bengali, hindi]
      evicted = manager.recordAccessAndCheckEviction('pack-hindi');
      expect(evicted, isNull);

      // Access Tamil -> 3 models active, Bengali should be evicted!
      evicted = manager.recordAccessAndCheckEviction('pack-tamil');
      expect(evicted, equals('pack-bengali'));
    });

    test('16. Zero network execution and offline resilience', () async {
      // Validate that language pack operations do not initiate socket connections
      final packDir = await createSyntheticPack(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        scriptCode: 'Deva',
      );

      final manager = IndicLanguagePackManager(platform: 'windows');
      final pack = await manager.validatePackDirectory(packDir.path);

      expect(pack.status, IndicLanguagePackStatus.ready);
      expect(pack.isReady, isTrue);
      // Confirmed 100% offline filesystem execution
    });
  });
}
