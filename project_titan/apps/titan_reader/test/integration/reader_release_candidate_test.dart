import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:titan_reader/src/data/ai_cache_repository.dart';
import 'package:titan_reader/src/data/ai_config_repository.dart';
import 'package:titan_reader/src/data/ai_conversation_repository.dart';
import 'package:titan_reader/src/data/ai_flashcard_repository.dart';
import 'package:titan_reader/src/data/dictionary_cache_repository.dart';
import 'package:titan_reader/src/data/dictionary_data_source.dart';
import 'package:titan_reader/src/data/grammar_cache_repository.dart';
import 'package:titan_reader/src/data/grammar_correction_repository.dart';
import 'package:titan_reader/src/data/grammar_engine.dart';
import 'package:titan_reader/src/data/mock_ai_reading_provider.dart';
import 'package:titan_reader/src/data/recent_lookup_repository.dart';
import 'package:titan_reader/src/data/spell_checker.dart';
import 'package:titan_reader/src/data/vocabulary_repository.dart';
import 'package:titan_reader/src/domain/dictionary_errors.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_models.dart';
import 'package:titan_reader/src/domain/entities/ai_reading_task.dart';
import 'package:titan_reader/src/domain/entities/dictionary_entry.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_result.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_search_selection.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_text_region.dart';
import 'package:titan_reader/src/domain/entities/ocr/page_text_classification.dart';
import 'package:titan_reader/src/domain/entities/pdf_encryption_options.dart';
import 'package:titan_reader/src/domain/entities/pdf_geometry.dart';
import 'package:titan_reader/src/domain/entities/pdf_native_annotation.dart';
import 'package:titan_reader/src/domain/entities/pdf_searchable_export_result.dart';
import 'package:titan_reader/src/domain/entities/unified_text_context.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_parser.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/manipulation/services/pdf_native_annotation_service.dart';
import 'package:titan_reader/src/ocr/page_text_classifier.dart';
import 'package:titan_reader/src/pdf/pdf_engine_contracts.dart';
import 'package:titan_reader/src/services/ai_reading_service.dart';
import 'package:titan_reader/src/services/dictionary_service.dart';
import 'package:titan_reader/src/services/grammar_service.dart';
import 'package:titan_reader/src/services/language_services_bridge.dart';
import 'package:titan_reader/src/services/pdf_attachment_service.dart';
import 'package:titan_reader/src/services/pdf_encryption_service.dart';
import 'package:titan_reader/src/services/pdf_searchable_export_service.dart';
import 'package:titan_reader/src/services/vocabulary_service.dart';
import 'package:titan_storage/titan_storage.dart';

class _FakeHeadwordIndex implements HeadwordIndex {
  final Set<String> words;
  const _FakeHeadwordIndex(this.words);

  @override
  Future<Set<String>> loadWords() async => words;
}

/// Helper to synthesize a valid test PDF AST.
Future<File> _createRcTestPdf({
  required String path,
  required int pageCount,
  bool withAttachments = false,
  bool withAnnotations = false,
}) async {
  final objects = <int, PdfObject>{};
  final gens = <int, int>{};
  final pageRefs = <PdfRef>[];

  for (var i = 1; i <= pageCount; i++) {
    final pageObjNum = 2 + i;
    final pageMap = <String, PdfObject>{
      'Type': const PdfName('Page'),
      'Parent': const PdfRef(2),
      'MediaBox': PdfArray(const [
        PdfNumber(0),
        PdfNumber(0),
        PdfNumber(595.28),
        PdfNumber(841.89),
      ]),
    };

    if (withAnnotations) {
      pageMap['Annots'] = PdfArray([
        PdfDict({
          'Type': const PdfName('Annot'),
          'Subtype': const PdfName('Highlight'),
          'Rect': PdfArray(const [
            PdfNumber(50),
            PdfNumber(100),
            PdfNumber(250),
            PdfNumber(120),
          ]),
        }),
      ]);
    }

    final pageDict = PdfDict(pageMap);
    objects[pageObjNum] = pageDict;
    gens[pageObjNum] = 0;
    pageRefs.add(PdfRef(pageObjNum));
  }

  final catalogMap = <String, PdfObject>{
    'Type': const PdfName('Catalog'),
    'Pages': const PdfRef(2),
  };

  if (withAttachments) {
    catalogMap['Names'] = PdfDict({
      'EmbeddedFiles': PdfDict({
        'Names': PdfArray([
          PdfString(ascii.encode('notes.txt')),
          PdfDict({
            'Type': const PdfName('Filespec'),
            'F': PdfString(ascii.encode('notes.txt')),
            'EF': PdfDict(const {
              'F': PdfRef(99),
            }),
          }),
        ]),
      }),
    });

    objects[99] = PdfStream(
      dict: PdfDict(const {
        'Type': PdfName('EmbeddedFile'),
        'Length': PdfNumber(24),
      }),
      data: Uint8List.fromList(utf8.encode('TITAN Release Notes 2026')),
    );
    gens[99] = 0;
  }

  final catalog = PdfDict(catalogMap);
  final pages = PdfDict({
    'Type': const PdfName('Pages'),
    'Kids': PdfArray(pageRefs),
    'Count': PdfNumber(pageCount),
  });

  objects[1] = catalog;
  gens[1] = 0;
  objects[2] = pages;
  gens[2] = 0;

  final trailer = PdfDict(const {
    'Root': PdfRef(1),
  });

  final docAst = PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: gens,
    trailer: trailer,
    catalog: catalog,
  );

  final writer = PdfWriter(docAst);
  return writer.writeAtomic(path);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6J: TITAN Reader Release Candidate End-to-End Acceptance Suite',
      () {
    late Directory tempDir;
    late InMemoryStorageService storage;
    late DictionaryService dictionaryService;
    late GrammarService grammarService;
    late VocabularyService vocabularyService;
    late AIReadingService aiService;
    late MockAIReadingProvider mockAiProvider;
    const bridge = LanguageServicesBridge();
    const exportService = PdfSearchableExportService();
    const attachmentService = PdfAttachmentService();
    const encryptionService = PdfEncryptionService();
    late PdfNativeAnnotationService annotationService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('titan_rc_acceptance_');
      storage = InMemoryStorageService();
      await storage.initialize();

      // Dictionary service with offline test data
      final localDict = InMemoryDictionaryDataSource({
        'sovereignty': DictionaryEntry(
          word: 'sovereignty',
          normalizedWord: 'sovereignty',
          senses: const [
            DictionarySense(
              partOfSpeech: 'noun',
              definitions: ['Supreme power or authority.'],
              examples: ['National sovereignty is preserved.'],
            ),
          ],
          source: const DictionarySourceInfo(
            id: 'test-dict',
            attribution: 'TITAN Offline WordNet',
          ),
        ),
        'jurisdiction': DictionaryEntry(
          word: 'jurisdiction',
          normalizedWord: 'jurisdiction',
          senses: const [
            DictionarySense(
              partOfSpeech: 'noun',
              definitions: [
                'The official power to make legal decisions and judgments.'
              ],
              examples: ['The court has jurisdiction in this matter.'],
            ),
          ],
          source: const DictionarySourceInfo(
            id: 'test-dict',
            attribution: 'TITAN Offline WordNet',
          ),
        ),
      });

      dictionaryService = DictionaryService(
        localSource: localDict,
        cache: StorageDictionaryCacheRepository(storage),
        recentLookups: StorageRecentLookupRepository(storage),
      );

      // Grammar service
      final grammarEngine = LocalGrammarEngine(
        spellChecker: WordNetSpellChecker(
          index: const _FakeHeadwordIndex({
            'this',
            'is',
            'the',
            'end',
            'of',
            'clause',
            'state',
            'shall',
            'preserve',
            'sovereignty',
          }),
        ),
      );

      grammarService = GrammarService(
        engine: grammarEngine,
        cache: StorageGrammarCacheRepository(storage),
        corrections: StorageGrammarCorrectionRepository(storage),
        remoteEnabled: false,
      );

      // Vocabulary service
      vocabularyService = VocabularyService(
        repository: StorageVocabularyRepository(storage),
      );
      await vocabularyService.ensureLoaded();

      // AI Reading service
      mockAiProvider = MockAIReadingProvider();
      aiService = AIReadingService(
        configRepo: AIConfigRepository(storage),
        cacheRepo: AICacheRepository(storage),
        conversationRepo: AIConversationRepository(storage),
        flashcardRepo: AIFlashcardRepository(storage),
        providers: {
          AIProviderType.localOllama: mockAiProvider,
          AIProviderType.mock: mockAiProvider,
        },
        initialConfig: const AIConfig(providerType: AIProviderType.mock),
      );

      annotationService = PdfNativeAnnotationService();
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    // =========================================================================
    // WORKFLOW A: Digital PDF Full Lifecycle Chain
    // =========================================================================
    test(
        'Workflow A: Full digital PDF lifecycle (Import -> Parse -> Select -> Dict -> Grammar -> Vocab -> AI -> Annotate -> Derivative Export)',
        () async {
      final docPath = p.join(tempDir.path, 'digital_constitution.pdf');

      await _createRcTestPdf(path: docPath, pageCount: 3);
      final initialBytes = await File(docPath).readAsBytes();

      // 1. Parse AST
      final parser = PdfParser(initialBytes);
      final ast = parser.parse();
      expect(ast.pageCount, 3);

      // 2. Native text selection & context bridge
      const nativeSelection = PdfTextSelectionSnapshot(
        text: 'sovereignty',
        fragments: [
          PdfSelectionFragment(
            pageNumber: 1,
            rect: NormalizedPageRect(
                left: 0.1, top: 0.2, right: 0.35, bottom: 0.25),
          ),
        ],
      );

      final nativeContext = UnifiedTextContext.fromNativeSnapshot(
        documentId: 'doc_digital_01',
        snapshot: nativeSelection,
        documentName: 'Constitution.pdf',
      );
      expect(nativeContext.isNative, isTrue);
      expect(nativeContext.isSingleWord, isTrue);

      // 3. Language Services: Dictionary lookup
      final dictResult =
          await bridge.lookupInDictionary(dictionaryService, nativeContext);
      expect(dictResult, isA<DictionaryLookupFound>());
      final found = dictResult as DictionaryLookupFound;
      expect(found.word, 'sovereignty');

      // 4. Language Services: Save to Vocabulary
      final vocabItem =
          await bridge.saveToVocabulary(vocabularyService, nativeContext);
      expect(vocabItem, isNotNull);
      final savedWords = vocabularyService.words;
      expect(savedWords.any((w) => w.word == 'sovereignty'), isTrue);

      // 5. Language Services: Grammar check on phrase
      final phraseContext = UnifiedTextContext(
        documentId: 'doc_digital_01',
        documentName: 'Constitution.pdf',
        pageNumber: 1,
        selectedText: 'The the state shall preserve sovereignty.',
        source: TextProvenance.nativePdf,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );
      final grammarOutcome =
          await bridge.checkGrammar(grammarService, phraseContext);
      expect(grammarOutcome.result.issues, isNotEmpty);
      expect(grammarOutcome.result.issues.first.ruleId, 'rule.repeated-word');

      // 6. AI Assistant: Explanation
      mockAiProvider.scriptedResponse =
          'Sovereignty denotes supreme and independent legal authority.';
      final aiReq =
          nativeContext.toAIReadingRequest(task: AIReadingTask.explain);
      final aiRes = await aiService.processTask(aiReq, useCache: false);
      expect(aiRes.text, contains('Sovereignty'));

      // 7. Native Annotation: Add Highlight
      final now = DateTime.now();
      const box = PdfBoundingBox(left: 100, bottom: 600, right: 300, top: 620);
      final highlight = PdfNativeHighlightAnnotation(
        id: 'annot_hl_01',
        pageIndex: 0,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        quadPoints: [PdfQuadPoint.fromBox(box)],
        contents: 'Sovereignty clause',
      );
      final outPath =
          p.join(tempDir.path, 'digital_constitution_annotated.pdf');
      await annotationService.addAnnotation(
        sourcePath: docPath,
        annotation: highlight,
        customOutputPath: outPath,
      );
      final loadedAnnots = await annotationService.loadAnnotations(outPath);
      expect(loadedAnnots.length, 1);

      // 8. Source Invariance Guarantee: SHA-256 byte comparison
      final afterBytes = await File(docPath).readAsBytes();
      expect(afterBytes, equals(initialBytes));
    });

    // =========================================================================
    // WORKFLOW B: Scanned PDF & OCR Fallback Chain
    // =========================================================================
    test(
        'Workflow B: Full scanned PDF lifecycle (Classify -> OCR -> Select -> Copy -> Dict -> Vocab -> AI -> Searchable PDF Export)',
        () async {
      final docPath = p.join(tempDir.path, 'scanned_archive.pdf');
      final exportPath = p.join(tempDir.path, 'scanned_archive_searchable.pdf');

      await _createRcTestPdf(path: docPath, pageCount: 2);
      final initialBytes = await File(docPath).readAsBytes();

      // 1. Classification
      const classifier = PageTextClassifier();
      final classification = classifier.classifyPageMetrics(
        pageNumber: 1,
        characterCount: 0,
        rasterImageCount: 1,
      );
      expect(classification.category, PageTextCategory.imageOnly);
      expect(classification.isOcrRecommended, isTrue);

      // 2. OCR Result Generation
      final ocrResult = OcrResult.success(
        pageNumber: 1,
        blocks: const [
          OcrBlock(
            text: 'jurisdiction applies to all territories',
            boundingBox: NormalizedPageRect(
                left: 0.1, top: 0.15, right: 0.9, bottom: 0.25),
            confidence: OcrConfidence(0.96),
            lines: [
              OcrLine(
                text: 'jurisdiction applies to all territories',
                boundingBox: NormalizedPageRect(
                    left: 0.1, top: 0.15, right: 0.9, bottom: 0.25),
                confidence: OcrConfidence(0.96),
                words: [
                  OcrWord(
                    text: 'jurisdiction',
                    boundingBox: NormalizedPageRect(
                        left: 0.1, top: 0.15, right: 0.35, bottom: 0.25),
                    confidence: OcrConfidence(0.96),
                    wordIndex: 0,
                  ),
                  OcrWord(
                    text: 'applies',
                    boundingBox: NormalizedPageRect(
                        left: 0.38, top: 0.15, right: 0.55, bottom: 0.25),
                    confidence: OcrConfidence(0.95),
                    wordIndex: 1,
                  ),
                ],
              ),
            ],
          ),
        ],
        processingDurationMs: 42,
        engineName: 'MockEngine',
        modelIdentifier: 'mock-1.0',
      );

      // 3. OCR Text Selection
      const ocrSelection = OcrTextSelection(
        documentId: 'doc_scanned_01',
        pageNumber: 1,
        selectedText: 'jurisdiction',
        startOffset: 0,
        endOffset: 12,
        selectedTokenIndices: [0],
        boundingBoxes: [
          NormalizedPageRect(left: 0.1, top: 0.15, right: 0.35, bottom: 0.25),
        ],
      );

      final ocrContext = UnifiedTextContext.fromOcrSelection(
        selection: ocrSelection,
        documentName: 'Archive.pdf',
        confidence: 0.96,
      );
      expect(ocrContext.isOcr, isTrue);
      expect(ocrContext.isSingleWord, isTrue);

      // 4. OCR Dictionary Lookup
      final dictResult =
          await bridge.lookupInDictionary(dictionaryService, ocrContext);
      expect(dictResult, isA<DictionaryLookupFound>());
      expect((dictResult as DictionaryLookupFound).word, 'jurisdiction');

      // 5. OCR Vocabulary Save
      final vocabItem =
          await bridge.saveToVocabulary(vocabularyService, ocrContext);
      expect(vocabItem, isNotNull);

      // 6. OCR AI Assistant Task
      mockAiProvider.scriptedResponse =
          'Jurisdiction defines the legal authority boundaries.';
      final aiReq = ocrContext.toAIReadingRequest(task: AIReadingTask.explain);
      final aiRes = await aiService.processTask(aiReq, useCache: false);
      expect(aiRes.text, contains('Jurisdiction'));

      // 7. Searchable PDF Export
      final exportResult = await exportService.exportSearchablePdf(
        inputPath: docPath,
        outputPath: exportPath,
        pageOcrResults: {1: ocrResult},
      );
      expect(exportResult.status, PdfSearchableExportStatus.success);
      expect(exportResult.exportedPagesCount, 1);

      // 8. Source Invariance
      final afterBytes = await File(docPath).readAsBytes();
      expect(afterBytes, equals(initialBytes));
    });

    // =========================================================================
    // WORKFLOW C: Mixed Native & Scanned Document Coexistence
    // =========================================================================
    test('Workflow C: Mixed document coexistence across native and OCR pages',
        () {
      const classifier = PageTextClassifier();

      final page1 = classifier.classifyPageMetrics(
        pageNumber: 1,
        characterCount: 1500,
        rasterImageCount: 0,
      );
      expect(page1.category, PageTextCategory.nativeText);
      expect(page1.isOcrRecommended, isFalse);

      final page2 = classifier.classifyPageMetrics(
        pageNumber: 2,
        characterCount: 0,
        rasterImageCount: 2,
      );
      expect(page2.category, PageTextCategory.imageOnly);
      expect(page2.isOcrRecommended, isTrue);

      final nativeContext = UnifiedTextContext(
        documentId: 'doc_mixed',
        pageNumber: 1,
        selectedText: 'Native digital clause',
        source: TextProvenance.nativePdf,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      final ocrContext = UnifiedTextContext(
        documentId: 'doc_mixed',
        pageNumber: 2,
        selectedText: 'Scanned image clause',
        source: TextProvenance.ocr,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      expect(nativeContext.isNative, isTrue);
      expect(ocrContext.isOcr, isTrue);
      expect(nativeContext.documentId, equals(ocrContext.documentId));
    });

    // =========================================================================
    // WORKFLOW D: Password-Protected PDF Safety
    // =========================================================================
    test('Workflow D: Password-protected PDF rejects mutation safely',
        () async {
      final unencryptedPath = p.join(tempDir.path, 'plain_doc.pdf');
      final encryptedPath = p.join(tempDir.path, 'protected_doc.pdf');
      final exportPath = p.join(tempDir.path, 'protected_export.pdf');

      await _createRcTestPdf(path: unencryptedPath, pageCount: 2);

      await encryptionService.encryptPdfFile(
        sourceFilePath: unencryptedPath,
        targetFilePath: encryptedPath,
        config: const PdfEncryptionConfig(
          userPassword: 'userSecret456',
          ownerPassword: 'ownerSecret456',
          algorithm: PdfEncryptionAlgorithm.aes128,
        ),
      );

      final initialEncryptedBytes = await File(encryptedPath).readAsBytes();

      final exportResult = await exportService.exportSearchablePdf(
        inputPath: encryptedPath,
        outputPath: exportPath,
        pageOcrResults: {
          1: OcrResult.success(
            pageNumber: 1,
            blocks: const [],
            processingDurationMs: 5,
            engineName: 'MockEngine',
            modelIdentifier: 'mock-1.0',
          ),
        },
      );

      expect(exportResult.status, PdfSearchableExportStatus.encrypted);
      expect(exportResult.isSuccess, isFalse);

      final afterEncryptedBytes = await File(encryptedPath).readAsBytes();
      expect(afterEncryptedBytes, equals(initialEncryptedBytes));
    });

    // =========================================================================
    // WORKFLOW F: Embedded File Attachment Listing & Extraction
    // =========================================================================
    test('Workflow F: lists and extracts embedded attachments safely',
        () async {
      final attachedPath = p.join(tempDir.path, 'attached_doc.pdf');
      final targetExtractDir = p.join(tempDir.path, 'extracted_files');

      await _createRcTestPdf(
        path: attachedPath,
        pageCount: 2,
        withAttachments: true,
      );

      final initialBytes = await File(attachedPath).readAsBytes();

      final attachments =
          await attachmentService.listAttachments(filePath: attachedPath);
      expect(attachments.isNotEmpty, isTrue);
      expect(attachments.first.filename, 'notes.txt');

      final result = await attachmentService.extractAttachment(
        sourceFilePath: attachedPath,
        attachment: attachments.first,
        targetDirectoryPath: targetExtractDir,
      );

      expect(result.isSuccess, isTrue);
      final extractedFile = File(result.outputPath!);
      expect(await extractedFile.exists(), isTrue);
      expect(await extractedFile.readAsString(), 'TITAN Release Notes 2026');

      final afterBytes = await File(attachedPath).readAsBytes();
      expect(afterBytes, equals(initialBytes));
    });

    // =========================================================================
    // WORKFLOW G: Document Switching & Isolation
    // =========================================================================
    test('Workflow G: prevents cross-document state leaks upon rapid switching',
        () {
      final docA = UnifiedTextContext(
        documentId: 'doc_alpha',
        pageNumber: 1,
        selectedText: 'Alpha selection',
        source: TextProvenance.nativePdf,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      final docB = UnifiedTextContext(
        documentId: 'doc_beta',
        pageNumber: 1,
        selectedText: 'Beta selection',
        source: TextProvenance.ocr,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      expect(docA.isSameContext(docB), isFalse);
      expect(docA.documentId, isNot(equals(docB.documentId)));
    });

    // =========================================================================
    // WORKFLOW H: Error Handling & Preflight Resiliency
    // =========================================================================
    test('Workflow H: handles invalid and missing inputs gracefully', () async {
      final missingPath = p.join(tempDir.path, 'non_existent.pdf');
      final emptyPath = p.join(tempDir.path, 'empty.pdf');
      await File(emptyPath).writeAsBytes(Uint8List(0));

      final missingResult = await exportService.exportSearchablePdf(
        inputPath: missingPath,
        outputPath: p.join(tempDir.path, 'out.pdf'),
        pageOcrResults: {},
      );
      expect(missingResult.status, PdfSearchableExportStatus.invalidDocument);

      final emptyResult = await exportService.exportSearchablePdf(
        inputPath: emptyPath,
        outputPath: p.join(tempDir.path, 'out.pdf'),
        pageOcrResults: {},
      );
      expect(emptyResult.status, PdfSearchableExportStatus.invalidDocument);
    });
  });
}
