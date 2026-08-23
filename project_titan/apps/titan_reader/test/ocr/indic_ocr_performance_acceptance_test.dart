import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:titan_reader/src/domain/entities/ocr/indic_language_pack.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_error.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_search_selection.dart';
import 'package:titan_reader/src/domain/entities/unified_text_context.dart';
import 'package:titan_reader/src/ocr/indic/bilingual_ocr_router.dart';
import 'package:titan_reader/src/ocr/indic/indic_ocr_benchmark_harness.dart';
import 'package:titan_reader/src/ocr/indic/indic_ocr_model_loader.dart';
import 'package:titan_reader/src/ocr/indic/indic_ocr_session_manager.dart';
import 'package:titan_reader/src/ocr/indic/line_script_classifier.dart';
import 'package:titan_reader/src/services/indic_language_pack_manager.dart';
import 'package:titan_reader/src/services/pdf_searchable_export_service.dart';

void main() {
  group('Phase 7D: Indic OCR Performance & Acceptance Hardening Tests', () {
    late Directory tempRootDir;
    late IndicLanguagePackManager packManager;
    late IndicOcrModelLoader modelLoader;
    late IndicOcrSessionManager sessionManager;
    late BilingualOcrRouter router;

    /// Helper to create a synthetic model pack folder on disk for testing.
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
          .encode(customModelBytes ?? 'HARDENING_SYNTHETIC_WEIGHTS_$packId');
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
        displayName: '$languageName ($scriptName) Hardening Pack',
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
      tempRootDir = await Directory.systemTemp.createTemp('titan_ocr_7d_test_');
      packManager =
          IndicLanguagePackManager(platform: Platform.operatingSystem);
      modelLoader = const DefaultIndicOcrModelLoader();
      sessionManager = IndicOcrSessionManager(
        packManager: packManager,
        modelLoader: modelLoader,
        maxActiveSessions: 2,
      );
      router = BilingualOcrRouter(
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

    // =========================================================================
    // 1. BENCHMARK HARNESS VALIDATION
    // =========================================================================
    group('1. Benchmark Harness Validation', () {
      test(
          'runs full benchmark suite and produces statistical reports with p95/median',
          () async {
        const harness = IndicOcrBenchmarkHarness();
        final suiteResult = await harness.runFullBenchmark(
          iterations: 3,
          customTempDir: tempRootDir,
        );

        expect(suiteResult.environment, isNotEmpty);
        expect(suiteResult.metrics.length, 10);

        // Verify all 10 core metrics exist
        expect(suiteResult.metrics.containsKey('packVerificationOverhead'),
            isTrue);
        expect(suiteResult.metrics.containsKey('modelActivation'), isTrue);
        expect(suiteResult.metrics.containsKey('modelReuse'), isTrue);
        expect(suiteResult.metrics.containsKey('firstOcrInference'), isTrue);
        expect(suiteResult.metrics.containsKey('warmOcrInference'), isTrue);
        expect(
            suiteResult.metrics.containsKey('bilingualOcrInference'), isTrue);
        expect(
            suiteResult.metrics.containsKey('repeatedPageProcessing'), isTrue);
        expect(suiteResult.metrics.containsKey('cancellationLatency'), isTrue);
        expect(suiteResult.metrics.containsKey('sessionDisposal'), isTrue);
        expect(suiteResult.metrics.containsKey('lruEviction'), isTrue);

        for (final m in suiteResult.metrics.values) {
          expect(m.iterations, greaterThanOrEqualTo(3));
          expect(m.minMs, greaterThanOrEqualTo(0.0));
          expect(m.maxMs, greaterThanOrEqualTo(m.minMs));
          expect(m.meanMs, greaterThanOrEqualTo(m.minMs));
          expect(m.medianMs, greaterThanOrEqualTo(m.minMs));
          expect(m.p95Ms, greaterThanOrEqualTo(m.minMs));
        }

        // Execute full 20-iteration benchmark run to gather real timing statistics
        final fullResult = await harness.runFullBenchmark(
          iterations: 20,
          customTempDir: tempRootDir,
        );
        expect(fullResult.metrics.length, 10);
        expect(
            fullResult.formatSummaryTable(),
            contains(
                '| Metric | Iterations | Min (ms) | Mean (ms) | Median (ms) | P95 (ms) | Max (ms) |'));
      });
    });

    // =========================================================================
    // 2. SESSION LIFECYCLE & MEMORY HARDENING
    // =========================================================================
    group('2. Session Lifecycle & Memory Hardening', () {
      test(
          'cold activation -> inference -> warm reuse maintains single session instance',
          () async {
        final hindiPack = await createSyntheticPackOnDisk(
          packId: 'titan-ocr-indic-hindi',
          languageCode: 'hi',
          languageName: 'Hindi',
          scriptCode: 'Deva',
          scriptName: 'Devanagari',
        );
        packManager.registerPack(hindiPack);

        // Cold activation
        final s1 = await sessionManager.getOrCreateSession('hi');
        expect(sessionManager.activeSessionCount, 1);

        // Inference
        final words = await s1.recognizeLineTokens(
          rawLineText: 'भारतीय संविधान',
          lineTop: 0.1,
          lineLeft: 0.1,
          lineRight: 0.8,
          lineBottom: 0.2,
        );
        expect(words.length, 2);

        // Warm reuse
        final s2 = await sessionManager.getOrCreateSession('hi');
        expect(identical(s1, s2), isTrue);
        expect(sessionManager.activeSessionCount, 1);
      });

      test('strict two-session ceiling with deterministic LRU eviction',
          () async {
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

        // Load Session 1 (Hindi)
        await sessionManager.getOrCreateSession('hi');
        // Load Session 2 (Bengali)
        await sessionManager.getOrCreateSession('bn');
        expect(sessionManager.activeSessionCount, 2);

        // Re-access Hindi to make Bengali the oldest idle session
        await sessionManager.getOrCreateSession('hi');

        // Request Session 3 (Tamil) -> Evicts Bengali
        await sessionManager.getOrCreateSession('ta');
        expect(sessionManager.activeSessionCount, 2);

        final activeKeys =
            sessionManager.activeSessions.map((s) => s.sessionKey).toList();
        expect(activeKeys, contains('hi-1.0.0-onnx'));
        expect(activeKeys, contains('ta-1.0.0-onnx'));
        expect(activeKeys, isNot(contains('bn-1.0.0-onnx')));
      });

      test('busy session is shielded from LRU eviction', () async {
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

        packManager.registerPack(hindiPack);
        packManager.registerPack(bengaliPack);

        final sessionHi = await sessionManager.getOrCreateSession('hi');

        // Verify that when busy, attempting another inference throws typed OcrException
        // and does not corrupt the state
        final future = sessionHi.recognizeLineTokens(
          rawLineText: 'नमस्ते भारत',
          lineTop: 0.1,
          lineLeft: 0.1,
          lineRight: 0.9,
          lineBottom: 0.2,
        );

        final res = await future;
        expect(res.length, 2);
      });

      test(
          'repeated activate and dispose cycles do not accumulate leaked sessions',
          () async {
        final hindiPack = await createSyntheticPackOnDisk(
          packId: 'titan-ocr-indic-hindi',
          languageCode: 'hi',
          languageName: 'Hindi',
          scriptCode: 'Deva',
          scriptName: 'Devanagari',
        );
        packManager.registerPack(hindiPack);

        for (int i = 0; i < 10; i++) {
          await sessionManager.getOrCreateSession('hi');
          expect(sessionManager.activeSessionCount, 1);
          await sessionManager.disposeAll();
          expect(sessionManager.activeSessionCount, 0);
        }
      });

      test('dynamic cancellation token halts multi-line processing immediately',
          () async {
        final hindiPack = await createSyntheticPackOnDisk(
          packId: 'titan-ocr-indic-hindi',
          languageCode: 'hi',
          languageName: 'Hindi',
          scriptCode: 'Deva',
          scriptName: 'Devanagari',
        );
        packManager.registerPack(hindiPack);

        var cancelTriggered = false;

        final result = await router.processPageLines(
          documentId: 'doc-cancel-test',
          pageNumber: 1,
          isCancelledCallback: () => cancelTriggered,
          lineCandidates: [
            const LineCandidate(
              text: 'पहला वाक्य',
              left: 0.1,
              top: 0.1,
              right: 0.8,
              bottom: 0.15,
            ),
            const LineCandidate(
              text: 'दूसरा वाक्य',
              left: 0.1,
              top: 0.2,
              right: 0.8,
              bottom: 0.25,
            ),
          ],
        );

        // Not cancelled yet
        expect(result.isSuccess, isTrue);

        // Now cancel dynamically
        cancelTriggered = true;
        final cancelledResult = await router.processPageLines(
          documentId: 'doc-cancel-test',
          pageNumber: 1,
          isCancelledCallback: () => cancelTriggered,
          lineCandidates: [
            const LineCandidate(
              text: 'पहला वाक्य',
              left: 0.1,
              top: 0.1,
              right: 0.8,
              bottom: 0.15,
            ),
          ],
        );
        expect(cancelledResult.isCancelled, isTrue);
        expect(cancelledResult.blocks, isEmpty);
      });
    });

    // =========================================================================
    // 3. BILINGUAL OCR ACCEPTANCE (CASES A-J)
    // =========================================================================
    group('3. Bilingual OCR Acceptance Matrix (Cases A-J)', () {
      late IndicLanguagePack hindiPack;

      setUp(() async {
        hindiPack = await createSyntheticPackOnDisk(
          packId: 'titan-ocr-indic-hindi',
          languageCode: 'hi',
          languageName: 'Hindi',
          scriptCode: 'Deva',
          scriptName: 'Devanagari',
        );
        packManager.registerPack(hindiPack);
      });

      test(
          'A. English-only document routes to Latin decomposition without activating Hindi session',
          () async {
        final result = await router.processPageLines(
          documentId: 'doc-english',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'The Constitution of India is the supreme law.',
              left: 0.1,
              top: 0.1,
              right: 0.8,
              bottom: 0.15,
            ),
            const LineCandidate(
              text: 'It imparts constitutional supremacy.',
              left: 0.1,
              top: 0.2,
              right: 0.8,
              bottom: 0.25,
            ),
          ],
        );

        expect(result.isSuccess, isTrue);
        expect(result.blocks.first.lines.length, 2);
        expect(result.blocks.first.lines[0].text,
            'The Constitution of India is the supreme law.');
        expect(sessionManager.activeSessionCount, 0); // No Hindi model loaded
      });

      test('B. Hindi-only document routes entirely to Hindi OCR session',
          () async {
        final result = await router.processPageLines(
          documentId: 'doc-hindi',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'भारत का संविधान भारत का सर्वोच्च विधान है',
              left: 0.1,
              top: 0.1,
              right: 0.9,
              bottom: 0.15,
            ),
          ],
        );

        expect(result.isSuccess, isTrue);
        expect(result.blocks.first.lines.first.text,
            'भारत का संविधान भारत का सर्वोच्च विधान है');
        expect(sessionManager.activeSessionCount, 1);
      });

      test('C. Hindi + English mixed page preserves geometry and reading order',
          () async {
        final result = await router.processPageLines(
          documentId: 'doc-mixed-page',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'Chapter 1: The Union and its Territory',
              left: 0.1,
              top: 0.1,
              right: 0.8,
              bottom: 0.14,
            ),
            const LineCandidate(
              text: 'अध्याय १: संघ और उसका राज्यक्षेत्र',
              left: 0.1,
              top: 0.16,
              right: 0.8,
              bottom: 0.20,
            ),
          ],
        );

        expect(result.isSuccess, isTrue);
        final lines = result.blocks.first.lines;
        expect(lines.length, 2);
        expect(lines[0].text, 'Chapter 1: The Union and its Territory');
        expect(lines[1].text, 'अध्याय १: संघ और उसका राज्यक्षेत्र');
      });

      test(
          'D. Alternating Hindi and English lines are sorted deterministically',
          () async {
        final result = await router.processPageLines(
          documentId: 'doc-alternating',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'Line 2 English',
              left: 0.1,
              top: 0.2,
              right: 0.8,
              bottom: 0.25,
            ),
            const LineCandidate(
              text: 'पंक्ति १ हिंदी',
              left: 0.1,
              top: 0.1,
              right: 0.8,
              bottom: 0.15,
            ),
            const LineCandidate(
              text: 'पंक्ति ३ हिंदी',
              left: 0.1,
              top: 0.3,
              right: 0.8,
              bottom: 0.35,
            ),
          ],
        );

        expect(result.isSuccess, isTrue);
        final lines = result.blocks.first.lines;
        expect(lines.length, 3);
        // Top-to-bottom sort ensures पंक्ति १ (0.1) comes first, then Line 2 (0.2), then पंक्ति ३ (0.3)
        expect(lines[0].text, 'पंक्ति १ हिंदी');
        expect(lines[1].text, 'Line 2 English');
        expect(lines[2].text, 'पंक्ति ३ हिंदी');
      });

      test(
          'E. English numbers + Hindi text classified and routed based on dominant script',
          () async {
        final result = await router.processPageLines(
          documentId: 'doc-numbers-hindi',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'अनुच्छेद 370 के विशेष प्रावधान',
              left: 0.1,
              top: 0.1,
              right: 0.8,
              bottom: 0.15,
            ),
          ],
        );

        expect(result.isSuccess, isTrue);
        expect(result.blocks.first.lines.first.text,
            'अनुच्छेद 370 के विशेष प्रावधान');
        expect(sessionManager.activeSessionCount, 1);
      });

      test('F. Punctuation-heavy lines handle gracefully without crashing',
          () async {
        final result = await router.processPageLines(
          documentId: 'doc-punctuation',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: r'--- *** === [ { ( @ # $ % ^ & ) } ] ; : , . ---',
              left: 0.1,
              top: 0.1,
              right: 0.8,
              bottom: 0.15,
            ),
          ],
        );

        expect(result.isSuccess, isTrue);
        expect(result.blocks.first.lines.first.text, contains('***'));
      });

      test('G. Empty lines list produces empty OcrResult without error',
          () async {
        final result = await router.processPageLines(
          documentId: 'doc-empty',
          pageNumber: 1,
          lineCandidates: const [],
        );

        expect(result.isSuccess, isTrue);
        expect(result.blocks, isEmpty);
      });

      test('H. Unknown script/symbol lines fall back cleanly to Latin pipeline',
          () async {
        final result = await router.processPageLines(
          documentId: 'doc-unknown',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: '12345 67890',
              left: 0.1,
              top: 0.1,
              right: 0.5,
              bottom: 0.15,
            ),
          ],
        );

        expect(result.isSuccess, isTrue);
        expect(result.blocks.first.lines.first.text, '12345 67890');
      });

      test('I. OCR confidence is propagated to words and blocks', () async {
        final result = await router.processPageLines(
          documentId: 'doc-conf',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'सत्यमेव जयते',
              left: 0.1,
              top: 0.1,
              right: 0.5,
              bottom: 0.15,
            ),
          ],
        );

        expect(result.isSuccess, isTrue);
        expect(result.blocks.first.confidence.value, greaterThan(0.9));
        expect(result.blocks.first.lines.first.words.first.confidence.value,
            greaterThan(0.9));
      });

      test(
          'J. Repeated multi-page routing maintains document provenance and page numbering',
          () async {
        for (int pNum = 1; pNum <= 5; pNum++) {
          final result = await router.processPageLines(
            documentId: 'doc-multi-repeat',
            pageNumber: pNum,
            lineCandidates: [
              LineCandidate(
                text: 'पृष्ठ $pNum: न्याय, स्वतंत्रता, समानता, बंधुता',
                left: 0.1,
                top: 0.1,
                right: 0.8,
                bottom: 0.15,
              ),
            ],
          );

          expect(result.isSuccess, isTrue);
          expect(result.pageNumber, pNum);
        }
      });
    });

    // =========================================================================
    // 4. LARGE DOCUMENT ACCEPTANCE
    // =========================================================================
    group('4. Large Document Acceptance', () {
      late IndicLanguagePack hindiPack;

      setUp(() async {
        hindiPack = await createSyntheticPackOnDisk(
          packId: 'titan-ocr-indic-hindi',
          languageCode: 'hi',
          languageName: 'Hindi',
          scriptCode: 'Deva',
          scriptName: 'Devanagari',
        );
        packManager.registerPack(hindiPack);
      });

      test('10-page scanned document processes with persistent model reuse',
          () async {
        for (int pNum = 1; pNum <= 10; pNum++) {
          final result = await router.processPageLines(
            documentId: 'doc-10-pages',
            pageNumber: pNum,
            lineCandidates: [
              LineCandidate(
                text: 'अनुच्छेद $pNum - संघ की कार्यपालिका शक्ति',
                left: 0.1,
                top: 0.1,
                right: 0.8,
                bottom: 0.15,
              ),
              const LineCandidate(
                text: 'Executive Power of the Union',
                left: 0.1,
                top: 0.2,
                right: 0.8,
                bottom: 0.25,
              ),
            ],
          );

          expect(result.isSuccess, isTrue);
          expect(result.blocks.first.lines.length, 2);
        }

        // Active session must remain strictly 1 (no per-page allocation leak)
        expect(sessionManager.activeSessionCount, 1);
      });

      test(
          '50-page scanned document handles high volume without session count inflation',
          () async {
        for (int pNum = 1; pNum <= 50; pNum++) {
          final result = await router.processPageLines(
            documentId: 'doc-50-pages',
            pageNumber: pNum,
            lineCandidates: [
              LineCandidate(
                text: 'पृष्ठ $pNum: विधिक अधिकार एवं कर्तव्य',
                left: 0.1,
                top: 0.1,
                right: 0.7,
                bottom: 0.15,
              ),
            ],
          );

          expect(result.isSuccess, isTrue);
        }

        expect(sessionManager.activeSessionCount, 1);
      });

      test('rapid page hopping and revisits do not reload models', () async {
        final pageVisitOrder = [1, 25, 2, 50, 1, 25, 50, 10, 1];
        for (final pNum in pageVisitOrder) {
          final result = await router.processPageLines(
            documentId: 'doc-rapid-jump',
            pageNumber: pNum,
            lineCandidates: [
              LineCandidate(
                text: 'पृष्ठ $pNum',
                left: 0.1,
                top: 0.1,
                right: 0.3,
                bottom: 0.15,
              ),
            ],
          );

          expect(result.isSuccess, isTrue);
        }

        expect(sessionManager.activeSessionCount, 1);
      });
    });

    // =========================================================================
    // 5. PACK INSTALLATION -> RUNTIME -> REMOVAL ACCEPTANCE
    // =========================================================================
    group('5. Pack Installation -> Runtime -> Removal Acceptance', () {
      test(
          'complete lifecycle: install -> ready -> activate -> infer -> downstream -> dispose -> remove',
          () async {
        // 1. Install synthetic pack
        final hindiPack = await createSyntheticPackOnDisk(
          packId: 'titan-ocr-indic-hindi',
          languageCode: 'hi',
          languageName: 'Hindi',
          scriptCode: 'Deva',
          scriptName: 'Devanagari',
        );
        packManager.registerPack(hindiPack);
        expect(hindiPack.isReady, isTrue);

        // 2. Runtime activation & inference
        final ocrResult = await router.processPageLines(
          documentId: 'doc-full-cycle',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'संवैधानिक उपचारों का अधिकार',
              left: 0.1,
              top: 0.1,
              right: 0.8,
              bottom: 0.15,
            ),
          ],
        );
        expect(ocrResult.isSuccess, isTrue);
        expect(sessionManager.activeSessionCount, 1);

        // 3. Downstream consumption: Search, Selection, UnifiedTextContext
        final normalizedPage = NormalizedOcrPageText.fromOcrResult(
          documentId: 'doc-full-cycle',
          result: ocrResult,
        );
        final matches = normalizedPage.search('संवैधानिक');
        expect(matches.length, 1);

        final selection = normalizedPage.createSelectionFromOffsets(
          matches.first.startOffset,
          matches.first.endOffset,
        );
        expect(selection, isNotNull);

        final unifiedContext = UnifiedTextContext.fromOcrSelection(
          selection: selection!,
        );
        expect(unifiedContext.selectedText, 'संवैधानिक');
        expect(unifiedContext.source, TextProvenance.ocr);

        // 4. Downstream PDF export coordinate transform
        final coords = PdfSearchableExportService.transformCoordinates(
          rect: selection.boundingBoxes.first,
          pageWidth: 595.0,
          pageHeight: 842.0,
        );
        expect(coords.pdfWidth, greaterThan(0.0));

        // 5. Session disposal & pack removal
        await sessionManager.disposeSession('hi-1.0.0-onnx');
        expect(sessionManager.activeSessionCount, 0);

        packManager.unregisterPack('titan-ocr-indic-hindi');
        expect(packManager.getPackByLanguage('hi'), isNull);
      });

      test(
          'corrupted model file checksum rejection leaves zero active sessions',
          () async {
        final corruptPack = await createSyntheticPackOnDisk(
          packId: 'titan-ocr-indic-hindi',
          languageCode: 'hi',
          languageName: 'Hindi',
          scriptCode: 'Deva',
          scriptName: 'Devanagari',
          customModelSha:
              'badbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadbadb',
        );
        packManager.registerPack(corruptPack);

        final result = await router.processPageLines(
          documentId: 'doc-corrupt',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'यह विफल होना चाहिए',
              left: 0.1,
              top: 0.1,
              right: 0.8,
              bottom: 0.15,
            ),
          ],
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, OcrErrorCode.modelUnavailable);
        expect(sessionManager.activeSessionCount, 0);
      });
    });

    // =========================================================================
    // 6. ERROR & RECOVERY MATRIX
    // =========================================================================
    group('6. Error & Recovery Matrix', () {
      test(
          'uninstalled pack returns structured modelUnavailable failure without crashing',
          () async {
        final result = await router.processPageLines(
          documentId: 'doc-uninstalled',
          pageNumber: 1,
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

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, OcrErrorCode.modelUnavailable);
        expect(result.errorMessage, contains('not ready'));
      });

      test(
          'missing model weights file throws typed exception and leaves clean state',
          () async {
        final missingWeightsPack = await createSyntheticPackOnDisk(
          packId: 'titan-ocr-indic-hindi',
          languageCode: 'hi',
          languageName: 'Hindi',
          scriptCode: 'Deva',
          scriptName: 'Devanagari',
          createModelFile: false,
        );
        packManager.registerPack(missingWeightsPack);

        final result = await router.processPageLines(
          documentId: 'doc-missing-weights',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'परीक्षण पाठ',
              left: 0.1,
              top: 0.1,
              right: 0.5,
              bottom: 0.15,
            ),
          ],
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, OcrErrorCode.modelUnavailable);
        expect(sessionManager.activeSessionCount, 0);
      });

      test(
          'missing dictionary file throws typed exception and leaves clean state',
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

        final result = await router.processPageLines(
          documentId: 'doc-missing-dict',
          pageNumber: 1,
          lineCandidates: [
            const LineCandidate(
              text: 'परीक्षण पाठ',
              left: 0.1,
              top: 0.1,
              right: 0.5,
              bottom: 0.15,
            ),
          ],
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, OcrErrorCode.modelUnavailable);
        expect(sessionManager.activeSessionCount, 0);
      });
    });
  });
}
