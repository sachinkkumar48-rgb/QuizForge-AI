import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_geometry.dart';
import 'package:titan_reader/src/domain/entities/pdf_native_annotation.dart';
import 'package:titan_reader/src/domain/entities/pdf_page_range.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/manipulation/engine/default_pdf_manipulation_engine.dart';
import 'package:titan_reader/src/manipulation/engine/default_pdf_native_annotation_engine.dart';
import 'package:titan_reader/src/manipulation/services/pdf_document_manipulation_service.dart';

void main() {
  late Directory tempDir;
  const manipEngine = DefaultPdfManipulationEngine();
  const nativeEngine = DefaultPdfNativeAnnotationEngine();
  final manipService = PdfDocumentManipulationService(engine: manipEngine);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('titan_preservation_test_');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 6B: Native Annotation Preservation during Phase 6A Operations',
      () {
    test(
        'Merge operation preserves native annotations across combined documents',
        () async {
      // Create Document A with Highlight on Page 0
      final docA = _createTestPdf(pageCount: 2);
      final fileA = File('${tempDir.path}/docA.pdf')
        ..writeAsBytesSync(PdfWriter(docA).writeBytes());

      final now = DateTime.now();
      const boxA = PdfBoundingBox(left: 100, bottom: 600, right: 300, top: 620);
      await nativeEngine.addAnnotation(
        fileA.path,
        PdfNativeHighlightAnnotation(
          id: 'hl-docA',
          pageIndex: 0,
          boundingBox: boxA,
          creationDate: now,
          modificationDate: now,
          quadPoints: [PdfQuadPoint.fromBox(boxA)],
          contents: 'Doc A Highlight',
        ),
      );

      // Create Document B with Ink on Page 0
      final docB = _createTestPdf(pageCount: 1);
      final fileB = File('${tempDir.path}/docB.pdf')
        ..writeAsBytesSync(PdfWriter(docB).writeBytes());

      const boxB = PdfBoundingBox(left: 50, bottom: 200, right: 250, top: 400);
      await nativeEngine.addAnnotation(
        fileB.path,
        PdfNativeInkAnnotation(
          id: 'ink-docB',
          pageIndex: 0,
          boundingBox: boxB,
          creationDate: now,
          modificationDate: now,
          inkList: const [
            [PdfPoint(50, 200), PdfPoint(250, 400)],
          ],
          contents: 'Doc B Drawing',
        ),
      );

      // Merge Doc A (2 pages) + Doc B (1 page) = 3 pages
      final mergedPath = '${tempDir.path}/merged_annots.pdf';
      await manipService.mergePdfs(
        inputPaths: [fileA.path, fileB.path],
        customOutputPath: mergedPath,
      );

      expect(await manipEngine.inspectPageCount(mergedPath), 3);

      // Annotation from Doc A should be on Page 0
      final p0Annots =
          await nativeEngine.loadAnnotations(mergedPath, pageIndex: 0);
      expect(p0Annots.length, 1);
      expect(p0Annots.first.contents, 'Doc A Highlight');

      // Annotation from Doc B should be on Page 2 (0-based)
      final p2Annots =
          await nativeEngine.loadAnnotations(mergedPath, pageIndex: 2);
      expect(p2Annots.length, 1);
      expect(p2Annots.first.contents, 'Doc B Drawing');
    });

    test('Extract page operation preserves native annotation on extracted page',
        () async {
      final doc = _createTestPdf(pageCount: 3);
      final file = File('${tempDir.path}/doc_extract.pdf')
        ..writeAsBytesSync(PdfWriter(doc).writeBytes());

      final now = DateTime.now();
      const box = PdfBoundingBox(left: 80, bottom: 500, right: 280, top: 515);
      await nativeEngine.addAnnotation(
        file.path,
        PdfNativeUnderlineAnnotation(
          id: 'un-p1',
          pageIndex: 1, // Page 2 (1-based)
          boundingBox: box,
          creationDate: now,
          modificationDate: now,
          quadPoints: [PdfQuadPoint.fromBox(box)],
          contents: 'Underline on Page 2',
        ),
      );

      final extractedPath = '${tempDir.path}/extracted_page2.pdf';
      await manipService.extractPages(
        sourcePath: file.path,
        pages: [2], // 1-based page 2
        customOutputPath: extractedPath,
      );

      expect(await manipEngine.inspectPageCount(extractedPath), 1);
      final annots =
          await nativeEngine.loadAnnotations(extractedPath, pageIndex: 0);
      expect(annots.length, 1);
      expect(annots.first.contents, 'Underline on Page 2');
      expect(annots.first.subtype, 'Underline');
    });

    test('Rotate page preserves native annotation reference and geometry',
        () async {
      final doc = _createTestPdf(pageCount: 2);
      final file = File('${tempDir.path}/doc_rotate.pdf')
        ..writeAsBytesSync(PdfWriter(doc).writeBytes());

      final now = DateTime.now();
      const box = PdfBoundingBox(left: 100, bottom: 600, right: 300, top: 620);
      await nativeEngine.addAnnotation(
        file.path,
        PdfNativeHighlightAnnotation(
          id: 'hl-rotate',
          pageIndex: 0,
          boundingBox: box,
          creationDate: now,
          modificationDate: now,
          quadPoints: [PdfQuadPoint.fromBox(box)],
          contents: 'Rotate test note',
        ),
      );

      final rotatedPath = '${tempDir.path}/rotated_out.pdf';
      await manipService.rotatePages(
        sourcePath: file.path,
        pageRotations: {1: 90},
        customOutputPath: rotatedPath,
      );

      final annots =
          await nativeEngine.loadAnnotations(rotatedPath, pageIndex: 0);
      expect(annots.length, 1);
      expect(annots.first.contents, 'Rotate test note');
    });

    test('Split operation preserves respective annotations in split documents',
        () async {
      final doc = _createTestPdf(pageCount: 4);
      final file = File('${tempDir.path}/doc_split.pdf')
        ..writeAsBytesSync(PdfWriter(doc).writeBytes());

      final now = DateTime.now();
      const box = PdfBoundingBox(left: 50, bottom: 500, right: 250, top: 520);
      await nativeEngine.addAnnotation(
        file.path,
        PdfNativeHighlightAnnotation(
          id: 'hl-split-p0',
          pageIndex: 0,
          boundingBox: box,
          creationDate: now,
          modificationDate: now,
          quadPoints: [PdfQuadPoint.fromBox(box)],
          contents: 'Part 1 note',
        ),
      );
      await nativeEngine.addAnnotation(
        file.path,
        PdfNativeHighlightAnnotation(
          id: 'hl-split-p2',
          pageIndex: 2,
          boundingBox: box,
          creationDate: now,
          modificationDate: now,
          quadPoints: [PdfQuadPoint.fromBox(box)],
          contents: 'Part 2 note',
        ),
      );

      final splitDir = '${tempDir.path}/split_output';
      final res = await manipService.splitPdf(
        sourcePath: file.path,
        ranges: [const PdfPageRange(1, 2), const PdfPageRange(3, 4)],
        outputDirectory: splitDir,
      );

      expect(res.outputPaths.length, 2);

      // Part 1 (pages 1..2) has Part 1 note on page 0
      final part1Annots =
          await nativeEngine.loadAnnotations(res.outputPaths[0]);
      expect(part1Annots.length, 1);
      expect(part1Annots.first.contents, 'Part 1 note');

      // Part 2 (pages 3..4) has Part 2 note on page 0
      final part2Annots =
          await nativeEngine.loadAnnotations(res.outputPaths[1]);
      expect(part2Annots.length, 1);
      expect(part2Annots.first.contents, 'Part 2 note');
    });
  });
}

PdfDocumentAst _createTestPdf({required int pageCount}) {
  final objects = <int, PdfObject>{};
  final gens = <int, int>{};
  final pageRefs = <PdfRef>[];

  for (var i = 1; i <= pageCount; i++) {
    final pageId = 2 + i;
    objects[pageId] = PdfDict({
      'Type': const PdfName('Page'),
      'Parent': const PdfRef(2),
      'MediaBox': PdfArray(const [
        PdfNumber(0),
        PdfNumber(0),
        PdfNumber(612),
        PdfNumber(792),
      ]),
    });
    gens[pageId] = 0;
    pageRefs.add(PdfRef(pageId));
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

  return PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: gens,
    trailer: PdfDict(const {'Root': PdfRef(1)}),
    catalog: catalog,
  );
}
