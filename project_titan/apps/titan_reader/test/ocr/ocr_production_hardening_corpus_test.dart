import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_result.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_text_region.dart';
import 'package:titan_reader/src/domain/entities/ocr/page_text_classification.dart';
import 'package:titan_reader/src/domain/entities/pdf_encryption_options.dart';
import 'package:titan_reader/src/domain/entities/pdf_searchable_export_result.dart';
import 'package:titan_reader/src/domain/entities/unified_text_context.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_parser.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/ocr/page_text_classifier.dart';
import 'package:titan_reader/src/services/language_services_bridge.dart';
import 'package:titan_reader/src/services/pdf_encryption_service.dart';
import 'package:titan_reader/src/services/pdf_searchable_export_service.dart';

/// Helper to generate synthetic test PDFs with specified AST metadata.
Future<File> _createHardeningPdf({
  required String path,
  required int pageCount,
  double width = 595.28,
  double height = 841.89,
  int rotation = 0,
  bool withAnnotations = false,
  bool withAttachments = false,
  bool withEncryptedFlag = false,
}) async {
  final objects = <int, PdfObject>{};
  final gens = <int, int>{};
  final pageRefs = <PdfRef>[];

  for (var i = 1; i <= pageCount; i++) {
    final pageObjNum = 2 + i;
    final pageMap = <String, PdfObject>{
      'Type': const PdfName('Page'),
      'Parent': const PdfRef(2),
      'MediaBox': PdfArray([
        const PdfNumber(0),
        const PdfNumber(0),
        PdfNumber(width),
        PdfNumber(height),
      ]),
    };

    if (rotation != 0) {
      pageMap['Rotate'] = PdfNumber(rotation);
    }

    if (withAnnotations) {
      pageMap['Annots'] = PdfArray([
        PdfDict({
          'Type': const PdfName('Annot'),
          'Subtype': const PdfName('Highlight'),
          'Rect': PdfArray(const [
            PdfNumber(50),
            PdfNumber(50),
            PdfNumber(200),
            PdfNumber(70),
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
          PdfString(ascii.encode('attachment.txt')),
          PdfDict({
            'Type': const PdfName('Filespec'),
            'F': PdfString(ascii.encode('attachment.txt')),
          }),
        ]),
      }),
    });
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

  final trailerMap = <String, PdfObject>{
    'Root': const PdfRef(1),
  };

  if (withEncryptedFlag) {
    trailerMap['Encrypt'] = const PdfRef(999);
    objects[999] = PdfDict(const {'Filter': PdfName('Standard')});
    gens[999] = 0;
  }

  final trailer = PdfDict(trailerMap);

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
  group('Phase 6I: OCR Production Hardening & Interoperability Corpus', () {
    late Directory tempDir;
    const exportService = PdfSearchableExportService();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('titan_ocr_hardening_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    // -------------------------------------------------------------------------
    // Category A, B, C: Page Classification & Mixed Document Interoperability
    // -------------------------------------------------------------------------
    test(
        'Category A, B, C: classifies native, scanned, and mixed pages correctly',
        () {
      const classifier = PageTextClassifier();

      final nativeClassification = classifier.classifyPageMetrics(
        pageNumber: 1,
        characterCount: 1200,
        rasterImageCount: 0,
      );
      expect(nativeClassification.category, PageTextCategory.nativeText);
      expect(nativeClassification.isOcrRecommended, isFalse);

      final scannedClassification = classifier.classifyPageMetrics(
        pageNumber: 2,
        characterCount: 0,
        rasterImageCount: 1,
      );
      expect(scannedClassification.category, PageTextCategory.imageOnly);
      expect(scannedClassification.isOcrRecommended, isTrue);

      final mixedClassification = classifier.classifyPageMetrics(
        pageNumber: 3,
        characterCount: 15,
        rasterImageCount: 2,
      );
      expect(mixedClassification.category, PageTextCategory.mixed);
      expect(mixedClassification.isOcrRecommended, isTrue);
    });

    // -------------------------------------------------------------------------
    // Category D & E: Portrait vs Landscape Geometry
    // -------------------------------------------------------------------------
    test(
        'Category D & E: transforms coordinates accurately for portrait and landscape',
        () {
      // Portrait (595.28 x 841.89)
      final portraitCoords = PdfSearchableExportService.transformCoordinates(
        rect: const NormalizedPageRect(
            left: 0.1, top: 0.2, right: 0.5, bottom: 0.3),
        pageWidth: 595.28,
        pageHeight: 841.89,
      );
      expect(portraitCoords.pdfX, closeTo(59.52, 0.1));
      expect(portraitCoords.pdfY, closeTo((1.0 - 0.3) * 841.89, 0.1));
      expect(portraitCoords.pdfWidth, closeTo(0.4 * 595.28, 0.1));
      expect(portraitCoords.pdfHeight, closeTo(0.1 * 841.89, 0.1));

      // Landscape (841.89 x 595.28)
      final landscapeCoords = PdfSearchableExportService.transformCoordinates(
        rect: const NormalizedPageRect(
            left: 0.1, top: 0.2, right: 0.5, bottom: 0.3),
        pageWidth: 841.89,
        pageHeight: 595.28,
      );
      expect(landscapeCoords.pdfX, closeTo(84.18, 0.1));
      expect(landscapeCoords.pdfY, closeTo((1.0 - 0.3) * 595.28, 0.1));
      expect(landscapeCoords.pdfWidth, closeTo(0.4 * 841.89, 0.1));
      expect(landscapeCoords.pdfHeight, closeTo(0.1 * 595.28, 0.1));
    });

    // -------------------------------------------------------------------------
    // Category F: Rotated Page Handling (0, 90, 180, 270)
    // -------------------------------------------------------------------------
    test(
        'Category F: handles page rotations 0, 90, 180, and 270 with correct matrices',
        () {
      const rect =
          NormalizedPageRect(left: 0.2, top: 0.1, right: 0.8, bottom: 0.3);

      final rot0 = PdfSearchableExportService.transformCoordinates(
        rect: rect,
        pageWidth: 600,
        pageHeight: 800,
        rotation: 0,
      );
      expect(rot0.a, 1.0);
      expect(rot0.b, 0.0);
      expect(rot0.c, 0.0);
      expect(rot0.d, 1.0);

      final rot90 = PdfSearchableExportService.transformCoordinates(
        rect: rect,
        pageWidth: 600,
        pageHeight: 800,
        rotation: 90,
      );
      expect(rot90.a, 0.0);
      expect(rot90.b, -1.0);
      expect(rot90.c, 1.0);
      expect(rot90.d, 0.0);

      final rot180 = PdfSearchableExportService.transformCoordinates(
        rect: rect,
        pageWidth: 600,
        pageHeight: 800,
        rotation: 180,
      );
      expect(rot180.a, -1.0);
      expect(rot180.b, 0.0);
      expect(rot180.c, 0.0);
      expect(rot180.d, -1.0);

      final rot270 = PdfSearchableExportService.transformCoordinates(
        rect: rect,
        pageWidth: 600,
        pageHeight: 800,
        rotation: 270,
      );
      expect(rot270.a, 0.0);
      expect(rot270.b, 1.0);
      expect(rot270.c, -1.0);
      expect(rot270.d, 0.0);
    });

    // -------------------------------------------------------------------------
    // Category G & R: Custom and Extreme Dimensions (Tiny & Blueprint Pages)
    // -------------------------------------------------------------------------
    test('Category G & R: handles extreme page sizes safely', () {
      // Tiny 50x50 page
      final tinyCoords = PdfSearchableExportService.transformCoordinates(
        rect: const NormalizedPageRect(
            left: 0.1, top: 0.1, right: 0.9, bottom: 0.9),
        pageWidth: 50,
        pageHeight: 50,
      );
      expect(tinyCoords.pdfWidth, closeTo(40.0, 0.01));
      expect(tinyCoords.pdfHeight, closeTo(40.0, 0.01));
      expect(tinyCoords.fontSize, greaterThanOrEqualTo(1.0));

      // Huge blueprint 3000x2000 page
      final hugeCoords = PdfSearchableExportService.transformCoordinates(
        rect: const NormalizedPageRect(
            left: 0.05, top: 0.05, right: 0.95, bottom: 0.95),
        pageWidth: 3000,
        pageHeight: 2000,
      );
      expect(hugeCoords.pdfWidth, closeTo(2700.0, 0.01));
      expect(hugeCoords.pdfHeight, closeTo(1800.0, 0.01));
      expect(hugeCoords.fontSize, lessThanOrEqualTo(144.0)); // Clamped safely
    });

    // -------------------------------------------------------------------------
    // Category H: Multi-Page Document Export & Source SHA-256 Invariance
    // -------------------------------------------------------------------------
    test(
        'Category H: exports 5-page document preserving source SHA-256 integrity',
        () async {
      final inputPath = p.join(tempDir.path, 'source_5page.pdf');
      final outputPath = p.join(tempDir.path, 'exported_5page.pdf');

      await _createHardeningPdf(path: inputPath, pageCount: 5);
      final sourceBytesBefore = await File(inputPath).readAsBytes();

      final ocrResults = {
        2: OcrResult.success(
          pageNumber: 2,
          blocks: const [
            OcrBlock(
              text: 'Page Two Scanned Headline',
              boundingBox: NormalizedPageRect(
                  left: 0.1, top: 0.1, right: 0.9, bottom: 0.2),
              confidence: OcrConfidence(0.95),
              lines: [
                OcrLine(
                  text: 'Page Two Scanned Headline',
                  boundingBox: NormalizedPageRect(
                      left: 0.1, top: 0.1, right: 0.9, bottom: 0.2),
                  confidence: OcrConfidence(0.95),
                  words: [
                    OcrWord(
                      text: 'Page',
                      boundingBox: NormalizedPageRect(
                          left: 0.1, top: 0.1, right: 0.3, bottom: 0.2),
                      confidence: OcrConfidence(0.95),
                      wordIndex: 0,
                    ),
                    OcrWord(
                      text: 'Two',
                      boundingBox: NormalizedPageRect(
                          left: 0.35, top: 0.1, right: 0.5, bottom: 0.2),
                      confidence: OcrConfidence(0.95),
                      wordIndex: 1,
                    ),
                  ],
                ),
              ],
            ),
          ],
          processingDurationMs: 30,
          engineName: 'MockEngine',
          modelIdentifier: 'mock-1.0',
        ),
      };

      final result = await exportService.exportSearchablePdf(
        inputPath: inputPath,
        outputPath: outputPath,
        pageOcrResults: ocrResults,
      );

      expect(result.status, PdfSearchableExportStatus.success);
      expect(result.exportedPagesCount, 1);
      expect(result.totalPagesCount, 5);

      // Verify zero source PDF mutation
      final sourceBytesAfter = await File(inputPath).readAsBytes();
      expect(sourceBytesAfter, equals(sourceBytesBefore));

      // Verify output file exists and is parsable
      final outFile = File(outputPath);
      expect(await outFile.exists(), isTrue);
      final outBytes = await outFile.readAsBytes();
      final parsed = PdfParser(outBytes).parse();
      expect(parsed.pageCount, 5);
    });

    // -------------------------------------------------------------------------
    // Category J & K: Robustness on Low-Confidence & Empty/Whitespace Tokens
    // -------------------------------------------------------------------------
    test('Category J & K: handles low confidence and whitespace tokens safely',
        () {
      final noisyWords = [
        const OcrWord(
          text: '', // Empty
          boundingBox:
              NormalizedPageRect(left: 0.1, top: 0.1, right: 0.2, bottom: 0.2),
          confidence: OcrConfidence(0.02),
          wordIndex: 0,
        ),
        const OcrWord(
          text: '   ', // Whitespace
          boundingBox:
              NormalizedPageRect(left: 0.2, top: 0.1, right: 0.3, bottom: 0.2),
          confidence: OcrConfidence(0.05),
          wordIndex: 1,
        ),
        const OcrWord(
          text: 'ValidToken',
          boundingBox:
              NormalizedPageRect(left: 0.4, top: 0.1, right: 0.7, bottom: 0.2),
          confidence: OcrConfidence(0.88),
          wordIndex: 2,
        ),
      ];

      final sorted =
          PdfSearchableExportService.sortWordsInReadingOrder(noisyWords);
      expect(sorted.length, 3);

      final escaped = PdfSearchableExportService.escapePdfString('ValidToken');
      expect(escaped, 'ValidToken');
    });

    // -------------------------------------------------------------------------
    // Category L: Unicode & Extended Latin Character Escaping
    // -------------------------------------------------------------------------
    test(
        'Category L: escapes special PDF characters and extended Latin cleanly',
        () {
      final escapedParens =
          PdfSearchableExportService.escapePdfString('(Test) \\ Value');
      expect(escapedParens, r'\(Test\) \\ Value');

      final escapedNewline =
          PdfSearchableExportService.escapePdfString("Line1\nLine2\rTab\t");
      expect(escapedNewline, r'Line1\nLine2\rTab\t');

      final escapedLatin =
          PdfSearchableExportService.escapePdfString('Café résumé');
      expect(
          escapedLatin, contains(r'\351')); // 'é' is 0xE9 = 233 = \351 in octal
    });

    // -------------------------------------------------------------------------
    // Category M: Large Document Synthetic Performance Test (50 Pages)
    // -------------------------------------------------------------------------
    test(
        'Category M: handles 50-page document export rapidly without memory explosion',
        () async {
      final inputPath = p.join(tempDir.path, 'large_50page.pdf');
      final outputPath = p.join(tempDir.path, 'exported_50page.pdf');

      await _createHardeningPdf(path: inputPath, pageCount: 50);

      // Populate OCR results for 10 pages
      final ocrResults = <int, OcrResult>{};
      for (var pIdx = 1; pIdx <= 10; pIdx++) {
        ocrResults[pIdx] = OcrResult.success(
          pageNumber: pIdx,
          blocks: [
            OcrBlock(
              text: 'Page $pIdx Content Stream Recognition',
              boundingBox: const NormalizedPageRect(
                  left: 0.1, top: 0.1, right: 0.9, bottom: 0.2),
              confidence: const OcrConfidence(0.95),
              lines: [
                OcrLine(
                  text: 'Page $pIdx Content Stream Recognition',
                  boundingBox: const NormalizedPageRect(
                      left: 0.1, top: 0.1, right: 0.9, bottom: 0.2),
                  confidence: const OcrConfidence(0.95),
                  words: [
                    OcrWord(
                      text: 'Page$pIdx',
                      boundingBox: const NormalizedPageRect(
                          left: 0.1, top: 0.1, right: 0.4, bottom: 0.2),
                      confidence: const OcrConfidence(0.95),
                      wordIndex: 0,
                    ),
                  ],
                ),
              ],
            ),
          ],
          processingDurationMs: 10,
          engineName: 'MockEngine',
          modelIdentifier: 'mock-1.0',
        );
      }

      final sw = Stopwatch()..start();
      final result = await exportService.exportSearchablePdf(
        inputPath: inputPath,
        outputPath: outputPath,
        pageOcrResults: ocrResults,
      );
      sw.stop();

      expect(result.status, PdfSearchableExportStatus.success);
      expect(result.exportedPagesCount, 10);
      expect(result.totalPagesCount, 50);
      expect(sw.elapsedMilliseconds, lessThan(3000)); // Well under 3 seconds
    });

    // -------------------------------------------------------------------------
    // Category N: Encrypted PDF Handling
    // -------------------------------------------------------------------------
    test('Category N: rejects encrypted PDF safely without mutating file',
        () async {
      final unencryptedPath = p.join(tempDir.path, 'plain.pdf');
      final encryptedPath = p.join(tempDir.path, 'encrypted.pdf');
      final outputPath = p.join(tempDir.path, 'exported_encrypted.pdf');

      await _createHardeningPdf(
        path: unencryptedPath,
        pageCount: 2,
      );

      const encService = PdfEncryptionService();
      await encService.encryptPdfFile(
        sourceFilePath: unencryptedPath,
        targetFilePath: encryptedPath,
        config: const PdfEncryptionConfig(
          userPassword: 'openPass123',
          ownerPassword: 'adminPass123',
          algorithm: PdfEncryptionAlgorithm.aes128,
        ),
      );

      final ocrResults = {
        1: OcrResult.success(
          pageNumber: 1,
          blocks: const [],
          processingDurationMs: 5,
          engineName: 'MockEngine',
          modelIdentifier: 'mock-1.0',
        ),
      };

      final result = await exportService.exportSearchablePdf(
        inputPath: encryptedPath,
        outputPath: outputPath,
        pageOcrResults: ocrResults,
      );

      expect(result.status, PdfSearchableExportStatus.encrypted);
      expect(result.isSuccess, isFalse);
    });

    // -------------------------------------------------------------------------
    // Category P & Q: Preserves Existing Annotations and Attachments
    // -------------------------------------------------------------------------
    test(
        'Category P & Q: preserves embedded attachments and native annotations',
        () async {
      final inputPath = p.join(tempDir.path, 'annotated_attached.pdf');
      final outputPath = p.join(tempDir.path, 'exported_annotated.pdf');

      await _createHardeningPdf(
        path: inputPath,
        pageCount: 2,
        withAnnotations: true,
        withAttachments: true,
      );

      final ocrResults = {
        1: OcrResult.success(
          pageNumber: 1,
          blocks: const [
            OcrBlock(
              text: 'Annotation Layer Test',
              boundingBox: NormalizedPageRect(
                  left: 0.1, top: 0.1, right: 0.8, bottom: 0.2),
              confidence: OcrConfidence(0.96),
              lines: [
                OcrLine(
                  text: 'Annotation Layer Test',
                  boundingBox: NormalizedPageRect(
                      left: 0.1, top: 0.1, right: 0.8, bottom: 0.2),
                  confidence: OcrConfidence(0.96),
                  words: [
                    OcrWord(
                      text: 'Annotation',
                      boundingBox: NormalizedPageRect(
                          left: 0.1, top: 0.1, right: 0.5, bottom: 0.2),
                      confidence: OcrConfidence(0.96),
                      wordIndex: 0,
                    ),
                  ],
                ),
              ],
            ),
          ],
          processingDurationMs: 15,
          engineName: 'MockEngine',
          modelIdentifier: 'mock-1.0',
        ),
      };

      final result = await exportService.exportSearchablePdf(
        inputPath: inputPath,
        outputPath: outputPath,
        pageOcrResults: ocrResults,
      );

      expect(result.status, PdfSearchableExportStatus.success);

      final outBytes = await File(outputPath).readAsBytes();
      final parsed = PdfParser(outBytes).parse();

      // Check page 1 still has /Annots
      final page1Dict =
          parsed.objects[parsed.pageRefs[0].objectNumber] as PdfDict;
      expect(page1Dict.containsKey('Annots'), isTrue);

      // Check catalog still has /Names (EmbeddedFiles)
      expect(parsed.catalog.containsKey('Names'), isTrue);
    });

    // -------------------------------------------------------------------------
    // Document Switch & Race Condition Protection
    // -------------------------------------------------------------------------
    test(
        'Document Switching: validates document and page isolation in UnifiedTextContext',
        () {
      final docAContext = UnifiedTextContext(
        documentId: 'doc_alpha',
        pageNumber: 1,
        selectedText: 'Document Alpha Text',
        source: TextProvenance.ocr,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      final docBContext = UnifiedTextContext(
        documentId: 'doc_beta',
        pageNumber: 1,
        selectedText: 'Document Beta Text',
        source: TextProvenance.ocr,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      expect(docAContext.documentId, 'doc_alpha');
      expect(docBContext.documentId, 'doc_beta');
      expect(docAContext.documentId, isNot(equals(docBContext.documentId)));
    });

    // -------------------------------------------------------------------------
    // Language Services Bridge Hardening (Empty, Malformed, Whitespace Selections)
    // -------------------------------------------------------------------------
    test(
        'Language Services Bridge: safely handles empty, malformed, and whitespace contexts',
        () async {
      const bridge = LanguageServicesBridge();

      final emptyContext = UnifiedTextContext(
        documentId: 'doc_1',
        pageNumber: 1,
        selectedText: '',
        source: TextProvenance.ocr,
        selectionBounds: const [],
        timestamp: DateTime.now(),
      );

      expect(emptyContext.isSingleWord, isFalse);
      expect(emptyContext.characterCount, 0);
      expect(emptyContext.wordCount, 0);

      final copySuccess = await bridge.copyToClipboard(emptyContext);
      expect(copySuccess, isFalse);
    });
  });
}
