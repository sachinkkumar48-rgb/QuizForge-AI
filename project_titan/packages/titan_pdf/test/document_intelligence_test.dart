import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:titan_domain/titan_domain.dart' as domain;
import 'package:titan_pdf/titan_pdf.dart';

void main() {
  group('Phase 8A: Document Intelligence Foundation & Domain Entities Tests',
      () {
    test('1. DocumentSource creates from file path and bytes correctly', () {
      final fileSource = DocumentSource.fromFilePath(
        filePath: 'C:/docs/upsc_polity.pdf',
        displayName: 'UPSC Polity Notes',
        sizeBytes: 2048,
        languageCode: 'en',
      );

      expect(fileSource.fileName, 'upsc_polity.pdf');
      expect(fileSource.displayName, 'UPSC Polity Notes');
      expect(fileSource.sizeBytes, 2048);
      expect(fileSource.languageCode, 'en');

      final rawBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x31, 0x2E]);
      final byteSource = DocumentSource.fromBytes(
        bytes: rawBytes,
        fileName: 'scanned_hindi.pdf',
        displayName: 'Scanned Hindi Notes',
        languageCode: 'hi',
      );

      expect(byteSource.fileName, 'scanned_hindi.pdf');
      expect(byteSource.sizeBytes, 6);
      expect(byteSource.languageCode, 'hi');
    });

    test('2. LearningPage and LearningPageBlock maintain provenance and script',
        () {
      const block1 = LearningPageBlock(
        text: 'Introduction to Fundamental Rights',
        blockIndex: 0,
        script: 'latin',
        confidence: 1.0,
      );

      const block2 = LearningPageBlock(
        text: 'मौलिक अधिकारों का परिचय',
        blockIndex: 1,
        script: 'devanagari',
        confidence: 0.95,
      );

      final page = LearningPage(
        documentId: 'doc_polity_01',
        pageNumber: 1,
        text: 'Introduction to Fundamental Rights\n\nमौलिक अधिकारों का परिचय',
        provenance: TextProvenance.mixed,
        script: 'bilingual',
        confidence: 0.975,
        blocks: const [block1, block2],
      );

      expect(page.documentId, 'doc_polity_01');
      expect(page.pageNumber, 1);
      expect(page.provenance, TextProvenance.mixed);
      expect(page.script, 'bilingual');
      expect(page.confidence, 0.975);
      expect(page.blocks.length, 2);
      expect(page.characterCount, page.text.length);
    });

    test(
        '3. LearningDocumentChunk supports deterministic IDs and bidirectional conversion',
        () {
      final chunk = LearningDocumentChunk(
        chunkId: 'doc_123_chunk_0',
        documentId: 'doc_123',
        index: 0,
        text:
            'Article 21 guarantees the protection of life and personal liberty.',
        startPage: 1,
        endPage: 2,
        provenance: TextProvenance.nativePdf,
        tokenEstimate: 14,
        script: 'latin',
        confidence: 1.0,
        sectionHeadings: const ['Part III', 'Right to Life'],
        metadata: const {'chapter': 'Fundamental Rights'},
      );

      expect(chunk.chunkId, 'doc_123_chunk_0');
      expect(chunk.sectionHeadings, contains('Part III'));

      // Convert to legacy PdfChunk
      final legacyChunk = chunk.toPdfChunk();
      expect(legacyChunk.chunkId, chunk.chunkId);
      expect(legacyChunk.text, chunk.text);
      expect(legacyChunk.startPage, 1);
      expect(legacyChunk.endPage, 2);

      // Convert back to LearningDocumentChunk
      final restoredChunk = LearningDocumentChunk.fromPdfChunk(
        legacyChunk,
        provenance: TextProvenance.nativePdf,
        script: 'latin',
        sectionHeadings: const ['Part III'],
      );
      expect(restoredChunk.chunkId, chunk.chunkId);
      expect(restoredChunk.text, chunk.text);
      expect(restoredChunk.sectionHeadings, const ['Part III']);
    });

    test(
        '4. LearningDocument aggregates pages, rawText, and resolves provenance',
        () {
      final page1 = LearningPage(
        documentId: 'doc_eco_01',
        pageNumber: 1,
        text: 'Fiscal Policy and Inflation Targeting in India.',
        provenance: TextProvenance.nativePdf,
        script: 'latin',
        confidence: 1.0,
      );

      final page2 = LearningPage(
        documentId: 'doc_eco_01',
        pageNumber: 2,
        text: 'राजकोषीय नीति और मुद्रास्फीति नियंत्रण।',
        provenance: TextProvenance.ocr,
        script: 'devanagari',
        confidence: 0.92,
      );

      final doc = LearningDocument(
        id: 'doc_eco_01',
        fileName: 'economics_notes.pdf',
        displayName: 'Economics Notes',
        totalPages: 2,
        sizeBytes: 4096,
        primaryLanguage: 'bilingual',
        createdAt: DateTime(2026, 8, 23),
        pages: [page1, page2],
      );

      expect(doc.rawText, contains('Fiscal Policy'));
      expect(doc.rawText, contains('राजकोषीय नीति'));
      expect(doc.provenance, TextProvenance.mixed);

      final legacyDoc = doc.toPdfDocument();
      expect(legacyDoc.id, 'doc_eco_01');
      expect(legacyDoc.fileName, 'economics_notes.pdf');
      expect(legacyDoc.pageCount, 2);
    });

    test('5. DocumentIngestionResult properly exposes status and warnings', () {
      final successResult = DocumentIngestionResult.success(
        document: LearningDocument(
          id: 'doc_01',
          fileName: 'test.pdf',
          displayName: 'Test',
          totalPages: 1,
          sizeBytes: 1024,
          createdAt: DateTime.now(),
        ),
        warnings: ['Scanned page fell back to OCR'],
      );

      expect(successResult.isSuccess, isTrue);
      expect(successResult.status, DocumentIngestionStatus.success);
      expect(successResult.warnings, contains('Scanned page fell back to OCR'));

      final emptyResult =
          DocumentIngestionResult.empty(message: 'No readable text');
      expect(emptyResult.isSuccess, isFalse);
      expect(emptyResult.status, DocumentIngestionStatus.emptyDocument);

      final failResult = DocumentIngestionResult.failure(
        status: DocumentIngestionStatus.corrupted,
        errorMessage: 'Invalid PDF trailer',
      );
      expect(failResult.isSuccess, isFalse);
      expect(failResult.status, DocumentIngestionStatus.corrupted);
    });
  });

  group('Phase 8A: Document Text Extraction & Ingestion Pipeline Tests', () {
    test(
        '6. DefaultPdfTextExtractor performs native extraction and script detection',
        () async {
      final extractor = DefaultPdfTextExtractor(
        nativeExtractor: (source, pageNumber) async {
          if (pageNumber == 1) {
            return 'Parliament consists of President, Lok Sabha, and Rajya Sabha.';
          }
          if (pageNumber == 2) {
            return 'संसद में राष्ट्रपति, लोक सभा और राज्य सभा शामिल हैं।';
          }
          return 'Mixed bilingual text: भारत का संविधान (Constitution of India).';
        },
        pageCountResolver: (source) async => 3,
      );

      final source = DocumentSource.fromFilePath(filePath: 'constitution.pdf');
      expect(await extractor.getPageCount(source), 3);

      final page1 =
          await extractor.extractPageText(source: source, pageNumber: 1);
      expect(page1.provenance, TextProvenance.nativePdf);
      expect(page1.script, 'latin');

      final page2 =
          await extractor.extractPageText(source: source, pageNumber: 2);
      expect(page2.provenance, TextProvenance.nativePdf);
      expect(page2.script, 'devanagari');

      final page3 =
          await extractor.extractPageText(source: source, pageNumber: 3);
      expect(page3.provenance, TextProvenance.nativePdf);
      expect(page3.script, 'bilingual');
    });

    test(
        '7. DefaultPdfTextExtractor triggers OcrFallbackProvider when native text is empty',
        () async {
      var ocrInvoked = false;
      final extractor = DefaultPdfTextExtractor(
        nativeExtractor: (source, pageNumber) async =>
            null, // empty native digital text
        ocrFallback: _MockOcrFallbackProvider(
          onRecognize: (source, pageNumber, preferredLanguage) async {
            ocrInvoked = true;
            return ExtractedPageText(
              pageNumber: pageNumber,
              text: 'Recognized OCR text from scanned image.',
              provenance: TextProvenance.ocr,
              script: 'latin',
              confidence: 0.94,
            );
          },
        ),
      );

      final source = DocumentSource.fromFilePath(filePath: 'scanned_doc.pdf');
      final page =
          await extractor.extractPageText(source: source, pageNumber: 1);

      expect(ocrInvoked, isTrue);
      expect(page.provenance, TextProvenance.ocr);
      expect(page.text, 'Recognized OCR text from scanned image.');
      expect(page.confidence, 0.94);
    });

    test(
        '8. PdfChunkService chunkLearningPages maintains deterministic chunks and page boundaries',
        () {
      const chunkService = PdfChunkService();
      final page1 = LearningPage(
        documentId: 'doc_polity',
        pageNumber: 1,
        text:
            'Paragraph 1: The Supreme Court is the apex judicial body.\n\nParagraph 2: It possesses original and appellate jurisdiction.',
        provenance: TextProvenance.nativePdf,
        script: 'latin',
        confidence: 1.0,
      );

      final page2 = LearningPage(
        documentId: 'doc_polity',
        pageNumber: 2,
        text:
            'Paragraph 3: High Courts function at the state level.\n\nParagraph 4: Subordinate courts resolve local civil and criminal disputes.',
        provenance: TextProvenance.nativePdf,
        script: 'latin',
        confidence: 1.0,
      );

      final chunks = chunkService.chunkLearningPages(
        documentId: 'doc_polity',
        pages: [page1, page2],
        options: const ChunkOptions(maxCharacters: 130, minChunkSize: 10),
      );

      expect(chunks.isNotEmpty, isTrue);
      for (var i = 0; i < chunks.length; i++) {
        expect(chunks[i].chunkId, 'doc_polity_chunk_$i');
        expect(chunks[i].index, i);
        expect(chunks[i].documentId, 'doc_polity');
      }
    });

    test(
        '9. DefaultDocumentIntelligenceService executes complete ingestion on digital PDF',
        () async {
      final extractor = DefaultPdfTextExtractor(
        nativeExtractor: (source, pageNumber) async =>
            'Page $pageNumber: Digital learning content for environmental ecology and biodiversity.',
        pageCountResolver: (source) async => 2,
      );

      final service = DefaultDocumentIntelligenceService(
        textExtractor: extractor,
      );

      final source = DocumentSource.fromFilePath(
        filePath: 'environment.pdf',
        displayName: 'Environment & Ecology',
        sizeBytes: 5000,
      );

      final result = await service.ingestDocument(source);

      expect(result.isSuccess, isTrue);
      expect(result.document, isNotNull);
      expect(result.document!.totalPages, 2);
      expect(result.document!.pages.length, 2);
      expect(result.document!.chunks.isNotEmpty, isTrue);
      expect(result.document!.provenance, TextProvenance.nativePdf);
      expect(result.document!.displayName, 'Environment & Ecology');
    });

    test(
        '10. DefaultDocumentIntelligenceService handles mixed native + OCR documents with warnings',
        () async {
      final extractor = DefaultPdfTextExtractor(
        nativeExtractor: (source, pageNumber) async {
          if (pageNumber == 1) return 'Page 1 digital text.';
          return null; // Page 2 is scanned
        },
        ocrFallback: _MockOcrFallbackProvider(
          onRecognize: (source, pageNumber, preferredLanguage) async {
            return ExtractedPageText(
              pageNumber: pageNumber,
              text:
                  'Page 2 OCR recognized Hindi text: पर्यावरण एवं पारिस्थितिकी।',
              provenance: TextProvenance.ocr,
              script: 'devanagari',
              confidence: 0.91,
            );
          },
        ),
        pageCountResolver: (source) async => 2,
      );

      final service = DefaultDocumentIntelligenceService(
        textExtractor: extractor,
      );

      final source = DocumentSource.fromFilePath(
        filePath: 'mixed_notes.pdf',
        sizeBytes: 2048,
      );
      final result = await service.ingestDocument(source);

      expect(result.isSuccess, isTrue);
      expect(result.document!.provenance, TextProvenance.mixed);
      expect(result.warnings.isNotEmpty, isTrue);
      expect(result.warnings.first, contains('mixed text extraction layers'));
    });

    test(
        '11. DefaultDocumentIntelligenceService handles corrupted/encrypted/empty documents',
        () async {
      final extractor = DefaultPdfTextExtractor(
        nativeExtractor: (source, pageNumber) async => 'text',
        pageCountResolver: (source) async => 1,
      );
      final service =
          DefaultDocumentIntelligenceService(textExtractor: extractor);

      // Corrupted document
      final corruptedSource = DocumentSource.fromFilePath(
        filePath: 'corrupted.pdf',
        sizeBytes: 1024,
        metadata: const {'isCorrupted': true},
      );
      final corResult = await service.ingestDocument(corruptedSource);
      expect(corResult.status, DocumentIngestionStatus.corrupted);
      expect(corResult.isSuccess, isFalse);

      // Encrypted document
      final encryptedSource = DocumentSource.fromFilePath(
        filePath: 'secret.pdf',
        sizeBytes: 1024,
        metadata: const {'isEncrypted': true},
      );
      final encResult = await service.ingestDocument(encryptedSource);
      expect(encResult.status, DocumentIngestionStatus.encrypted);
      expect(encResult.isSuccess, isFalse);

      // Empty document
      final emptySource = DocumentSource.fromFilePath(
        filePath: 'empty.pdf',
        sizeBytes: 1024,
        metadata: const {'isEmpty': true},
      );
      final empResult = await service.ingestDocument(emptySource);
      expect(empResult.status, DocumentIngestionStatus.emptyDocument);
      expect(empResult.isSuccess, isFalse);
    });
  });

  group('Phase 8A: AssessmentDocumentBridge Tests', () {
    test(
        '12. AssessmentDocumentBridge registers LearningDocument in PdfRepository seamlessly',
        () async {
      final mockStorage = _MockStorageService();
      final pdfRepo = PdfRepositoryImpl(
        aiService: _MockAiService(),
        storageService: mockStorage,
        networkService: _MockNetworkService(),
      );
      await pdfRepo.initialize();

      final learningChunk = LearningDocumentChunk(
        chunkId: 'doc_test_chunk_0',
        documentId: 'doc_test',
        index: 0,
        text: 'Sample test learning chunk text for quiz generation.',
        startPage: 1,
        endPage: 1,
        tokenEstimate: 10,
      );

      final learningDoc = LearningDocument(
        id: 'doc_test',
        fileName: 'test_assessment.pdf',
        displayName: 'Test Assessment',
        totalPages: 1,
        sizeBytes: 1024,
        createdAt: DateTime.now(),
        chunks: [learningChunk],
      );

      final registeredPdfDoc =
          await AssessmentDocumentBridge.registerLearningDocument(
        document: learningDoc,
        pdfRepository: pdfRepo,
      );

      expect(registeredPdfDoc.displayName, 'Test Assessment');
      expect(registeredPdfDoc.pageCount, 1);

      // Verify chunks were registered in repository
      final loadedDoc = await pdfRepo.loadPdf(registeredPdfDoc.id);
      expect(loadedDoc, isNotNull);
      expect(loadedDoc!.fileName, 'test_assessment.pdf');
    });
  });
}

class _MockOcrFallbackProvider implements OcrFallbackProvider {
  final Future<ExtractedPageText> Function(
    DocumentSource source,
    int pageNumber,
    String? preferredLanguage,
  ) onRecognize;

  const _MockOcrFallbackProvider({required this.onRecognize});

  @override
  Future<ExtractedPageText> recognizePage({
    required DocumentSource source,
    required int pageNumber,
    String? preferredLanguage,
  }) {
    return onRecognize(source, pageNumber, preferredLanguage);
  }
}

class _MockStorageService implements domain.StorageService {
  bool _initialized = false;
  final Map<String, dynamic> _store = {};

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<bool> contains(domain.StorageKey key) async =>
      _store.containsKey(key.qualifiedKey);

  @override
  Future<T?> read<T>(domain.StorageKey key) async =>
      _store[key.qualifiedKey] as T?;

  @override
  Future<domain.StorageEntry<T>?> readEntry<T>(domain.StorageKey key) async =>
      null;

  @override
  Future<void> write<T>(domain.StorageKey key, T value) async {
    _store[key.qualifiedKey] = value;
  }

  @override
  Future<void> delete(domain.StorageKey key) async {
    _store.remove(key.qualifiedKey);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<List<domain.StorageKey>> keys({String? namespace}) async {
    final result = <domain.StorageKey>[];
    for (final k in _store.keys) {
      if (namespace == null || k.startsWith('$namespace:')) {
        final id = k.contains(':') ? k.split(':').last : k;
        result.add(domain.StorageKey(id, namespace: namespace ?? 'default'));
      }
    }
    return result;
  }

  @override
  Future<void> close() async {
    _initialized = false;
  }
}

class _MockAiService implements domain.AIService {
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  List<domain.AIModel> availableModels() => const [];

  @override
  domain.AIModel defaultModel() => throw UnimplementedError();

  @override
  Future<domain.AIResponse<T>> generate<T>(domain.AIRequest request) async =>
      throw UnimplementedError();

  @override
  Future<void> close() async {
    _initialized = false;
  }
}

class _MockNetworkService implements domain.NetworkService {
  bool _initialized = false;

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<domain.NetworkResponse<T>> get<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();

  @override
  Future<domain.NetworkResponse<T>> post<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();

  @override
  Future<domain.NetworkResponse<T>> put<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();

  @override
  Future<domain.NetworkResponse<T>> delete<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();

  @override
  Future<domain.NetworkResponse<T>> patch<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();

  @override
  Future<domain.NetworkResponse<T>> head<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();

  @override
  Future<domain.NetworkResponse<T>> request<T>(
          domain.NetworkRequest request) async =>
      throw UnimplementedError();

  @override
  Future<void> close() async {
    _initialized = false;
  }
}
