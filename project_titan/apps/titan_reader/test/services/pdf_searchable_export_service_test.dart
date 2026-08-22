import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_result.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_text_region.dart';
import 'package:titan_reader/src/domain/entities/pdf_searchable_export_result.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_parser.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/services/pdf_searchable_export_service.dart';

Future<File> _createSamplePdf(String path, int pageCount) async {
  final objects = <int, PdfObject>{};
  final gens = <int, int>{};
  final pageRefs = <PdfRef>[];

  for (var i = 1; i <= pageCount; i++) {
    final pageObjNum = 2 + i;
    final pageDict = PdfDict({
      'Type': const PdfName('Page'),
      'Parent': const PdfRef(2),
      'MediaBox': PdfArray(const [
        PdfNumber(0),
        PdfNumber(0),
        PdfNumber(600),
        PdfNumber(800),
      ]),
    });
    objects[pageObjNum] = pageDict;
    gens[pageObjNum] = 0;
    pageRefs.add(PdfRef(pageObjNum));
  }

  final catalog = PdfDict(const {
    'Type': PdfName('Catalog'),
    'Pages': PdfRef(2),
  });
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
  group('PdfSearchableExportService End-to-End Pipeline Tests', () {
    late Directory tempDir;
    const service = PdfSearchableExportService();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('titan_ocr_export_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
        'successfully exports searchable PDF with invisible text and preserves source SHA-256',
        () async {
      final inputPath = p.join(tempDir.path, 'source_scanned.pdf');
      final outputPath = p.join(tempDir.path, 'source_searchable.pdf');

      await _createSamplePdf(inputPath, 2);

      // Read source bytes before export
      final sourceBytesBefore = await File(inputPath).readAsBytes();

      final ocrResults = {
        1: OcrResult.success(
          pageNumber: 1,
          blocks: const [
            OcrBlock(
              text: 'Constitution of India',
              boundingBox: NormalizedPageRect(
                  left: 0.1, top: 0.1, right: 0.8, bottom: 0.2),
              confidence: OcrConfidence(0.98),
              lines: [
                OcrLine(
                  text: 'Constitution of India',
                  boundingBox: NormalizedPageRect(
                      left: 0.1, top: 0.1, right: 0.8, bottom: 0.2),
                  confidence: OcrConfidence(0.98),
                  words: [
                    OcrWord(
                      text: 'Constitution',
                      boundingBox: NormalizedPageRect(
                          left: 0.1, top: 0.1, right: 0.45, bottom: 0.2),
                      confidence: OcrConfidence(0.99),
                      wordIndex: 0,
                    ),
                    OcrWord(
                      text: 'of',
                      boundingBox: NormalizedPageRect(
                          left: 0.48, top: 0.1, right: 0.55, bottom: 0.2),
                      confidence: OcrConfidence(0.98),
                      wordIndex: 1,
                    ),
                    OcrWord(
                      text: 'India',
                      boundingBox: NormalizedPageRect(
                          left: 0.58, top: 0.1, right: 0.8, bottom: 0.2),
                      confidence: OcrConfidence(0.99),
                      wordIndex: 2,
                    ),
                  ],
                ),
              ],
            ),
          ],
          processingDurationMs: 40,
          engineName: 'MockEngine',
          modelIdentifier: 'mock-1.0',
        ),
      };

      final exportResult = await service.exportSearchablePdf(
        inputPath: inputPath,
        outputPath: outputPath,
        pageOcrResults: ocrResults,
      );

      expect(exportResult.status, PdfSearchableExportStatus.success);
      expect(exportResult.isSuccess, isTrue);
      expect(exportResult.exportedPagesCount, 1);
      expect(exportResult.totalPagesCount, 2);
      expect(exportResult.fileSizeBytes, greaterThan(100));

      final outFile = File(outputPath);
      expect(await outFile.exists(), isTrue);

      // Verify source PDF bytes are strictly unchanged (Zero PDF mutation)
      final sourceBytesAfter = await File(inputPath).readAsBytes();
      expect(sourceBytesAfter, equals(sourceBytesBefore));

      // Parse output PDF and verify searchable text contents
      final outputBytes = await outFile.readAsBytes();
      final parsedAst = PdfParser(outputBytes).parse();
      expect(parsedAst.pageCount, 2);

      // Inspect page 1 contents
      final page1Ref = parsedAst.pageRefs[0];
      final page1Dict = parsedAst.objects[page1Ref.objectNumber] as PdfDict;
      final contentsRef = page1Dict['Contents'];
      expect(contentsRef, isNotNull);

      var contentsObjNum = 0;
      if (contentsRef is PdfRef) {
        contentsObjNum = contentsRef.objectNumber;
      } else if (contentsRef is PdfArray && contentsRef.items.isNotEmpty) {
        final last = contentsRef.items.last;
        if (last is PdfRef) {
          contentsObjNum = last.objectNumber;
        }
      }

      final streamObj = parsedAst.objects[contentsObjNum] as PdfStream;
      final contentString = utf8.decode(streamObj.data);

      expect(contentString, contains('3 Tr')); // Invisible text operator
      expect(contentString, contains('/F_OCR')); // Font reference
      expect(contentString, contains('(Constitution) Tj'));
      expect(contentString, contains('(India) Tj'));
    });

    test('returns noOcrData when OCR results map is empty', () async {
      final inputPath = p.join(tempDir.path, 'source.pdf');
      final outputPath = p.join(tempDir.path, 'out.pdf');

      await _createSamplePdf(inputPath, 1);

      final result = await service.exportSearchablePdf(
        inputPath: inputPath,
        outputPath: outputPath,
        pageOcrResults: const {},
      );

      expect(result.status, PdfSearchableExportStatus.noOcrData);
      expect(result.isSuccess, isFalse);
    });

    test('fails gracefully when input path matches output path', () async {
      final path = p.join(tempDir.path, 'same_file.pdf');
      await _createSamplePdf(path, 1);

      final result = await service.exportSearchablePdf(
        inputPath: path,
        outputPath: path,
        pageOcrResults: const {},
      );

      expect(result.status, PdfSearchableExportStatus.failed);
      expect(result.errorMessage, contains('cannot overwrite'));
    });

    test('returns invalidDocument when source file does not exist', () async {
      final inputPath = p.join(tempDir.path, 'non_existent.pdf');
      final outputPath = p.join(tempDir.path, 'out.pdf');

      final result = await service.exportSearchablePdf(
        inputPath: inputPath,
        outputPath: outputPath,
        pageOcrResults: const {},
      );

      expect(result.status, PdfSearchableExportStatus.invalidDocument);
    });

    test('supports cancellation token', () async {
      final inputPath = p.join(tempDir.path, 'source.pdf');
      final outputPath = p.join(tempDir.path, 'out.pdf');

      await _createSamplePdf(inputPath, 2);

      var cancelled = true;
      final result = await service.exportSearchablePdf(
        inputPath: inputPath,
        outputPath: outputPath,
        pageOcrResults: {
          1: OcrResult.success(
            pageNumber: 1,
            blocks: const [],
            processingDurationMs: 1,
            engineName: 'Mock',
            modelIdentifier: 'm',
          ),
        },
        isCancelled: () => cancelled,
      );

      expect(result.status, PdfSearchableExportStatus.cancelled);
      expect(result.isCancelled, isTrue);
    });
  });
}
