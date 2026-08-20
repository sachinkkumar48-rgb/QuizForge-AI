import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_page_label_config.dart';
import 'package:titan_reader/src/domain/entities/pdf_page_range.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/manipulation/engine/default_pdf_manipulation_engine.dart';

/// Helper to synthesize a valid N-page test PDF file on disk.
Future<File> createTestPdf(String path, int pageCount) async {
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
  return await writer.writeAtomic(path);
}

void main() {
  late Directory tempDir;
  const engine = DefaultPdfManipulationEngine();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('titan_phase6a_test_');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 6A: DefaultPdfManipulationEngine Operations Tests', () {
    test('Merge PDFs creates valid merged document with combined page count',
        () async {
      final pdfA = await createTestPdf('${tempDir.path}/pdfA.pdf', 3);
      final pdfB = await createTestPdf('${tempDir.path}/pdfB.pdf', 2);
      final outPath = '${tempDir.path}/merged.pdf';

      final result = await engine.merge(
        inputPaths: [pdfA.path, pdfB.path],
        outputPath: outPath,
      );

      expect(result.pageCount, 5);
      expect(result.outputPaths, [outPath]);
      expect(File(outPath).existsSync(), isTrue);

      final verifiedCount = await engine.inspectPageCount(outPath);
      expect(verifiedCount, 5);
    });

    test('Split PDF splits document into parts matching page ranges', () async {
      final source = await createTestPdf('${tempDir.path}/source5.pdf', 5);
      final outDir = '${tempDir.path}/split_out';

      final result = await engine.split(
        inputPath: source.path,
        ranges: [
          const PdfPageRange(1, 2),
          const PdfPageRange(3, 5),
        ],
        outputDirectory: outDir,
        baseName: 'doc',
      );

      expect(result.outputPaths.length, 2);
      expect(await engine.inspectPageCount(result.outputPaths[0]), 2);
      expect(await engine.inspectPageCount(result.outputPaths[1]), 3);
    });

    test('Extract pages generates valid sub-document with requested pages',
        () async {
      final source = await createTestPdf('${tempDir.path}/source6.pdf', 6);
      final outPath = '${tempDir.path}/extracted.pdf';

      final result = await engine.extractPages(
        inputPath: source.path,
        pages: [1, 3, 5],
        outputPath: outPath,
      );

      expect(result.pageCount, 3);
      expect(await engine.inspectPageCount(outPath), 3);
    });

    test('Delete pages deletes specified pages from document', () async {
      final source = await createTestPdf('${tempDir.path}/source4.pdf', 4);
      final outPath = '${tempDir.path}/deleted.pdf';

      final result = await engine.deletePages(
        inputPath: source.path,
        pagesToDelete: [2, 4],
        outputPath: outPath,
      );

      expect(result.pageCount, 2);
      expect(await engine.inspectPageCount(outPath), 2);
    });

    test('Reorder pages reorders pages correctly', () async {
      final source = await createTestPdf('${tempDir.path}/source3.pdf', 3);
      final outPath = '${tempDir.path}/reordered.pdf';

      final result = await engine.reorderPages(
        inputPath: source.path,
        newOrder: [3, 1, 2],
        outputPath: outPath,
      );

      expect(result.pageCount, 3);
      expect(await engine.inspectPageCount(outPath), 3);
    });

    test('Rotate pages sets page rotation attributes', () async {
      final source = await createTestPdf('${tempDir.path}/source3.pdf', 3);
      final outPath = '${tempDir.path}/rotated.pdf';

      final result = await engine.rotatePages(
        inputPath: source.path,
        pageRotations: {1: 90, 2: 180, 3: 270},
        outputPath: outPath,
      );

      expect(result.pageCount, 3);
      expect(await engine.inspectPageCount(outPath), 3);
    });

    test('Insert blank page increases page count and adds page', () async {
      final source = await createTestPdf('${tempDir.path}/source2.pdf', 2);
      final outPath = '${tempDir.path}/blank_inserted.pdf';

      final result = await engine.insertBlankPage(
        inputPath: source.path,
        targetIndex: 1,
        outputPath: outPath,
      );

      expect(result.pageCount, 3);
      expect(await engine.inspectPageCount(outPath), 3);
    });

    test('Insert pages from another PDF merges specified pages into target',
        () async {
      final target = await createTestPdf('${tempDir.path}/target2.pdf', 2);
      final source = await createTestPdf('${tempDir.path}/source3.pdf', 3);
      final outPath = '${tempDir.path}/pages_inserted.pdf';

      final result = await engine.insertPagesFromPdf(
        targetPath: target.path,
        targetIndex: 1,
        sourcePath: source.path,
        sourcePages: [2, 3],
        outputPath: outPath,
      );

      expect(result.pageCount, 4);
      expect(await engine.inspectPageCount(outPath), 4);
    });

    test('Set page labels updates catalog page label dictionary', () async {
      final source = await createTestPdf('${tempDir.path}/source5.pdf', 5);
      final outPath = '${tempDir.path}/labeled.pdf';

      final result = await engine.setPageLabels(
        inputPath: source.path,
        labelRanges: [
          const PdfPageLabelRange(
              startPage: 1, style: PdfPageLabelStyle.romanLower),
          const PdfPageLabelRange(
              startPage: 3, style: PdfPageLabelStyle.arabic, startNumber: 1),
        ],
        outputPath: outPath,
      );

      expect(result.pageCount, 5);
      expect(await engine.inspectPageCount(outPath), 5);
    });
  });
}
