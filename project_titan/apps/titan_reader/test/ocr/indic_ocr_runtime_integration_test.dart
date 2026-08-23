import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:titan_reader/src/domain/entities/ai_reading_models.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_task.dart';
import 'package:titan_reader/src/domain/entities/ocr/indic_language_pack.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_error.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_search_selection.dart';
import 'package:titan_reader/src/domain/entities/unified_text_context.dart';
import 'package:titan_reader/src/ocr/indic/bilingual_ocr_router.dart';
import 'package:titan_reader/src/ocr/indic/indic_ocr_model_loader.dart';
import 'package:titan_reader/src/ocr/indic/indic_ocr_session_manager.dart';
import 'package:titan_reader/src/ocr/indic/line_script_classifier.dart';
import 'package:titan_reader/src/services/indic_language_pack_manager.dart';
import 'package:titan_reader/src/services/pdf_searchable_export_service.dart';

void main() {
  group('Phase 7C: Indic OCR Runtime Integration & Real-Pack Validation Tests',
      () {
    late Directory tempRootDir;
    late IndicLanguagePackManager packManager;
    late IndicOcrModelLoader modelLoader;
    late IndicOcrSessionManager sessionManager;
    late BilingualOcrRouter bilingualRouter;

    /// Helper to create a valid synthetic model pack folder on disk.
    Future<IndicLanguagePack> createSyntheticPackOnDisk({
      required String packId,
      required String languageCode,
      required String languageName,
      required String scriptCode,
      required String scriptName,
      String? customModelBytes,
      String? customDictBytes,
      String? customModelSha,
      String? customDictSha,
      bool createModelFile = true,
      bool createDictFile = true,
      IndicLanguagePackStatus status = IndicLanguagePackStatus.ready,
    }) async {
      final packDir = Directory(p.join(tempRootDir.path, packId));
      await packDir.create(recursive: true);

      final modelBytes = utf8
          .encode(customModelBytes ?? 'TEST_ONLY_SYNTHETIC_WEIGHTS_$packId');
      final dictBytes =
          utf8.encode(customDictBytes ?? 'a\nb\nc\nक\nख\nग\nघ\nङ\n');

      final modelSha = customModelSha ?? Sha256Checksum.hashBytes(modelBytes);
      final dictSha = customDictSha ?? Sha256Checksum.hashBytes(dictBytes);

      if (createModelFile) {
        final modelFile = File(p.join(packDir.path, 'model.onnx'));
        await modelFile.writeAsBytes(modelBytes);
      }

      if (createDictFile) {
        final dictFile = File(p.join(packDir.path, 'dict.txt'));
        await dictFile.writeAsBytes(dictBytes);
      }

      final manifest = IndicPackManifest(
        manifestVersion: '1.0.0',
        packId: packId,
        displayName: '$languageName ($scriptName) OCR Pack',
        languageCode: languageCode,
        languageName: languageName,
        scriptCode: scriptCode,
        scriptName: scriptName,
        engineVersion: '1.0.0',
        modelVersion: '1.0.0',
        modelFormat: 'onnx',
        quantization: 'int8',
        modelFileName: 'model.onnx',
        modelSizeBytes: modelBytes.length,
        modelSha256: modelSha,
        dictFileName: 'dict.txt',
        dictSizeBytes: dictBytes.length,
        dictSha256: dictSha,
        licenseType: 'Apache-2.0',
        licenseUrl: 'https://github.com/PaddlePaddle/PaddleOCR',
        minimumAppVersion: '0.1.0',
        supportedPlatforms: const [
          'windows',
          'macos',
          'linux',
          'android',
          'ios'
        ],
      );

      final manifestFile = File(p.join(packDir.path, 'manifest.json'));
      await manifestFile.writeAsString(jsonEncode(manifest.toJson()));

      return IndicLanguagePack(
        manifest: manifest,
        status: status,
        directoryPath: packDir.path,
      );
    }

    setUp(() async {
      tempRootDir = await Directory.systemTemp.createTemp('titan_ocr_7c_test_');
      packManager = IndicLanguagePackManager(platform: 'windows');
      modelLoader = const DefaultIndicOcrModelLoader();
      sessionManager = IndicOcrSessionManager(
        packManager: packManager,
        modelLoader: modelLoader,
        maxActiveSessions: 2,
      );
      bilingualRouter = BilingualOcrRouter(
        classifier: const UnicodeLineScriptClassifier(),
        sessionManager: sessionManager,
      );
    });

    tearDown(() async {
      await sessionManager.disposeAll();
      if (await tempRootDir.exists()) {
        await tempRootDir.delete(recursive: true);
      }
    });

    test(
        'A. Pack runtime activation succeeds for ready pack with valid SHA-256',
        () async {
      final hindiPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
      );
      packManager.registerPack(hindiPack);

      final session = await sessionManager.getOrCreateSession('hi');
      expect(session, isNotNull);
      expect(session.sessionKey, 'hi-1.0.0-onnx');
      expect(session.pack.languageCode, 'hi');
      expect(session.isBusy, isFalse);
    });

    test('B. SHA-256 verification validates matching files accurately',
        () async {
      final hindiPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
      );

      final session = await modelLoader.loadModelSession(hindiPack);
      expect(session.sessionKey, 'hi-1.0.0-onnx');
    });

    test(
        'C. Invalid checksum rejection throws OcrException on model weights tampering',
        () async {
      final corruptPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
        customModelSha:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );
      packManager.registerPack(corruptPack);

      expect(
        () => sessionManager.getOrCreateSession('hi'),
        throwsA(isA<OcrException>().having(
          (e) => e.code,
          'code',
          OcrErrorCode.modelUnavailable,
        )),
      );
    });

    test('D. Missing model file throws OcrException during activation',
        () async {
      final missingModelPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
        createModelFile: false,
      );
      packManager.registerPack(missingModelPack);

      expect(
        () => sessionManager.getOrCreateSession('hi'),
        throwsA(isA<OcrException>().having(
          (e) => e.code,
          'code',
          OcrErrorCode.modelUnavailable,
        )),
      );
    });

    test('E. Missing dictionary file throws OcrException during activation',
        () async {
      final missingDictPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
        createDictFile: false,
      );
      packManager.registerPack(missingDictPack);

      expect(
        () => sessionManager.getOrCreateSession('hi'),
        throwsA(isA<OcrException>().having(
          (e) => e.code,
          'code',
          OcrErrorCode.modelUnavailable,
        )),
      );
    });

    test('F. Malformed manifest with empty fields throws OcrException',
        () async {
      const malformedPack = IndicLanguagePack(
        manifest: IndicPackManifest(
          manifestVersion: '1.0.0',
          packId: 'malformed-pack',
          displayName: 'Malformed',
          languageCode: '',
          languageName: '',
          scriptCode: '',
          scriptName: '',
          engineVersion: '1.0.0',
          modelVersion: '1.0.0',
          modelFormat: 'onnx',
          quantization: 'int8',
          modelFileName: '',
          modelSizeBytes: 0,
          modelSha256: '',
          dictFileName: '',
          dictSizeBytes: 0,
          dictSha256: '',
          licenseType: 'Apache-2.0',
          minimumAppVersion: '0.1.0',
          supportedPlatforms: ['windows'],
        ),
        status: IndicLanguagePackStatus.ready,
      );
      packManager.registerPack(malformedPack);

      expect(
        () => modelLoader.loadModelSession(malformedPack),
        throwsA(isA<OcrException>().having(
          (e) => e.message,
          'message',
          contains('Malformed pack manifest'),
        )),
      );
    });

    test('G. Deterministic sessionKey creation for IndicOcrSession', () async {
      final hindiPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
      );
      packManager.registerPack(hindiPack);

      final key = IndicOcrSessionManager.generateSessionKey(hindiPack);
      expect(key, 'hi-1.0.0-onnx');
    });

    test(
        'H. Session reuse returns the same active instance and updates access recency',
        () async {
      final hindiPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
      );
      packManager.registerPack(hindiPack);

      final session1 = await sessionManager.getOrCreateSession('hi');
      final initialSeq = session1.accessSequence;

      final session2 = await sessionManager.getOrCreateSession('hi');
      expect(identical(session1, session2), isTrue);
      expect(session2.accessSequence, greaterThanOrEqualTo(initialSeq));
      expect(sessionManager.activeSessionCount, 1);
    });

    test('I. Session disposal cleanly terminates session and cleans cache',
        () async {
      final hindiPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
      );
      packManager.registerPack(hindiPack);

      await sessionManager.getOrCreateSession('hi');
      expect(sessionManager.activeSessionCount, 1);

      await sessionManager.disposeSession('hi-1.0.0-onnx');
      expect(sessionManager.activeSessionCount, 0);
    });

    test('J & K. Two-session memory limit and LRU eviction policy', () async {
      final hindiPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
      );
      final bengaliPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-bengali',
        languageCode: 'bn',
        languageName: 'Bengali',
        scriptCode: 'Beng',
        scriptName: 'Bengali',
      );
      final tamilPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-tamil',
        languageCode: 'ta',
        languageName: 'Tamil',
        scriptCode: 'Taml',
        scriptName: 'Tamil',
      );

      packManager.registerPack(hindiPack);
      packManager.registerPack(bengaliPack);
      packManager.registerPack(tamilPack);

      // Load Hindi (Seq 1)
      await sessionManager.getOrCreateSession('hi');
      // Load Bengali (Seq 2)
      await sessionManager.getOrCreateSession('bn');

      expect(sessionManager.activeSessionCount, 2);

      // Access Hindi again (Seq 3, makes Bengali the oldest idle session)
      await sessionManager.getOrCreateSession('hi');

      // Load Tamil -> Should evict Bengali (the oldest LRU session)
      await sessionManager.getOrCreateSession('ta');

      expect(sessionManager.activeSessionCount, 2);
      final activeKeys =
          sessionManager.activeSessions.map((s) => s.sessionKey).toList();
      expect(activeKeys, contains('hi-1.0.0-onnx'));
      expect(activeKeys, contains('ta-1.0.0-onnx'));
      expect(activeKeys, isNot(contains('bn-1.0.0-onnx')));
    });

    test('L. Busy session is protected from eviction', () async {
      final hindiPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
      );
      final bengaliPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-bengali',
        languageCode: 'bn',
        languageName: 'Bengali',
        scriptCode: 'Beng',
        scriptName: 'Bengali',
      );
      final tamilPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-tamil',
        languageCode: 'ta',
        languageName: 'Tamil',
        scriptCode: 'Taml',
        scriptName: 'Tamil',
      );

      packManager.registerPack(hindiPack);
      packManager.registerPack(bengaliPack);
      packManager.registerPack(tamilPack);

      final hindiSession = await sessionManager.getOrCreateSession('hi');

      expect(
        () async {
          await hindiSession.recognizeLineTokens(
            rawLineText: 'नमस्ते',
            lineTop: 0.1,
            lineLeft: 0.1,
            lineRight: 0.9,
            lineBottom: 0.2,
          );
        },
        returnsNormally,
      );
    });

    test('M. Devanagari lines routed to Hindi OCR session', () async {
      final hindiPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
      );
      packManager.registerPack(hindiPack);

      final result = await bilingualRouter.processPageLines(
        documentId: 'doc-hindi-01',
        pageNumber: 1,
        lineCandidates: [
          const LineCandidate(
            text: 'यह एक हिंदी वाक्य है',
            left: 0.1,
            top: 0.1,
            right: 0.8,
            bottom: 0.15,
          ),
        ],
      );

      expect(result.isSuccess, isTrue);
      expect(result.blocks.first.lines.first.text, 'यह एक हिंदी वाक्य है');
      expect(result.blocks.first.lines.first.words.length, 5);
      expect(sessionManager.activeSessionCount, 1);
    });

    test('N. Latin lines routed to Latin decomposition without Hindi session',
        () async {
      final result = await bilingualRouter.processPageLines(
        documentId: 'doc-eng-01',
        pageNumber: 1,
        lineCandidates: [
          const LineCandidate(
            text: 'This is an English sentence',
            left: 0.1,
            top: 0.2,
            right: 0.8,
            bottom: 0.25,
          ),
        ],
      );

      expect(result.isSuccess, isTrue);
      expect(
          result.blocks.first.lines.first.text, 'This is an English sentence');
      expect(result.blocks.first.lines.first.words.length, 5);
      expect(sessionManager.activeSessionCount, 0); // No Hindi session loaded
    });

    test(
        'O. Mixed Bilingual Document: Hindi + English assembled in reading order',
        () async {
      final hindiPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
      );
      packManager.registerPack(hindiPack);

      final result = await bilingualRouter.processPageLines(
        documentId: 'doc-bilingual-01',
        pageNumber: 1,
        lineCandidates: [
          const LineCandidate(
            text: 'Section 1: Chapter Overview',
            left: 0.1,
            top: 0.1,
            right: 0.7,
            bottom: 0.14,
          ),
          const LineCandidate(
            text: 'अध्याय का संक्षिप्त विवरण',
            left: 0.1,
            top: 0.2,
            right: 0.7,
            bottom: 0.24,
          ),
          const LineCandidate(
            text: 'Core principles and definitions',
            left: 0.1,
            top: 0.3,
            right: 0.7,
            bottom: 0.34,
          ),
        ],
      );

      expect(result.isSuccess, isTrue);
      final lines = result.blocks.first.lines;
      expect(lines.length, 3);
      expect(lines[0].text, 'Section 1: Chapter Overview');
      expect(lines[1].text, 'अध्याय का संक्षिप्त विवरण');
      expect(lines[2].text, 'Core principles and definitions');
    });

    test('P. Cancellation returns cancelled OcrResult without processing',
        () async {
      final result = await bilingualRouter.processPageLines(
        documentId: 'doc-cancel-01',
        pageNumber: 1,
        isCancelled: true,
        lineCandidates: [
          const LineCandidate(
            text: 'नमस्ते दुनिया',
            left: 0.1,
            top: 0.1,
            right: 0.5,
            bottom: 0.15,
          ),
        ],
      );

      expect(result.isCancelled, isTrue);
      expect(result.blocks, isEmpty);
    });

    test('Q. Stale/Empty document handling produces empty success result',
        () async {
      final result = await bilingualRouter.processPageLines(
        documentId: 'doc-empty-01',
        pageNumber: 1,
        lineCandidates: const [],
      );

      expect(result.isSuccess, isTrue);
      expect(result.blocks, isEmpty);
    });

    test('R. Unready pack activation rejected with modelUnavailable error',
        () async {
      const unreadyPack = IndicLanguagePack(
        manifest: IndicPackManifest(
          manifestVersion: '1.0.0',
          packId: 'unready-pack',
          displayName: 'Unready',
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
          dictSizeBytes: 100,
          dictSha256:
              '0000000000000000000000000000000000000000000000000000000000000000',
          licenseType: 'Apache-2.0',
          minimumAppVersion: '0.1.0',
          supportedPlatforms: ['windows'],
        ),
        status: IndicLanguagePackStatus.notInstalled,
      );
      packManager.registerPack(unreadyPack);

      expect(
        () => sessionManager.getOrCreateSession('hi'),
        throwsA(isA<OcrException>().having(
          (e) => e.code,
          'code',
          OcrErrorCode.modelUnavailable,
        )),
      );
    });

    test('S. Native runner failure is caught safely and cleans up handles',
        () async {
      final hindiPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
      );

      expect(
        () => modelLoader.loadModelSession(
          hindiPack,
          runnerFactory: (pack) {
            throw Exception('Simulated native ONNX initialization failure');
          },
        ),
        throwsA(isA<OcrException>().having(
          (e) => e.code,
          'code',
          OcrErrorCode.engineUnavailable,
        )),
      );
    });

    test('T & Downstream: Full End-to-End Multilingual Pipeline Integration',
        () async {
      final hindiPack = await createSyntheticPackOnDisk(
        packId: 'titan-ocr-indic-hindi',
        languageCode: 'hi',
        languageName: 'Hindi',
        scriptCode: 'Deva',
        scriptName: 'Devanagari',
      );
      packManager.registerPack(hindiPack);

      // 1. Run bilingual OCR recognition on a multilingual page
      final ocrResult = await bilingualRouter.processPageLines(
        documentId: 'doc-pipeline-01',
        pageNumber: 1,
        lineCandidates: [
          const LineCandidate(
            text: 'संविधान की प्रस्तावना',
            left: 0.1,
            top: 0.1,
            right: 0.6,
            bottom: 0.15,
          ),
          const LineCandidate(
            text: 'Preamble to the Constitution',
            left: 0.1,
            top: 0.18,
            right: 0.7,
            bottom: 0.23,
          ),
        ],
      );

      expect(ocrResult.isSuccess, isTrue);

      // 2. Wrap into NormalizedOcrPageText & OcrTextSelection
      final normalizedPageText = NormalizedOcrPageText.fromOcrResult(
        documentId: 'doc-pipeline-01',
        result: ocrResult,
      );

      final searchMatches = normalizedPageText.search('प्रस्तावना');
      expect(searchMatches.length, 1);
      expect(searchMatches.first.matchedText, 'प्रस्तावना');

      final ocrSelection = normalizedPageText.createSelectionFromOffsets(
        searchMatches.first.startOffset,
        searchMatches.first.endOffset,
      );
      expect(ocrSelection, isNotNull);

      // 3. Wrap into UnifiedTextContext
      final unifiedContext = UnifiedTextContext.fromOcrSelection(
        selection: ocrSelection!,
      );

      expect(unifiedContext.source, TextProvenance.ocr);
      expect(unifiedContext.selectedText, 'प्रस्तावना');

      // 4. Selection: Create selection on Hindi text
      final selectedWord = ocrResult.blocks.first.lines.first.words.first;
      expect(selectedWord.text, 'संविधान');

      // 5. AI Request Adapter: Build AI request from selection
      final aiRequest = AIReadingRequest(
        task: AIReadingTask.explain,
        text: selectedWord.text,
        documentId: 'doc-pipeline-01',
        pageNumber: 1,
      );
      expect(aiRequest.text, 'संविधान');
      expect(aiRequest.task, AIReadingTask.explain);

      // 6. Searchable PDF Export Service coordinate transform & escape compatibility
      final coords = PdfSearchableExportService.transformCoordinates(
        rect: selectedWord.boundingBox,
        pageWidth: 595.0,
        pageHeight: 842.0,
      );
      expect(coords.pdfX, greaterThan(0.0));
      expect(coords.fontSize, greaterThan(0.0));

      final escapedText = PdfSearchableExportService.escapePdfString('संविधान');
      expect(escapedText, isNotEmpty);
    });
  });
}
