import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_geometry.dart';
import 'package:titan_reader/src/domain/entities/pdf_native_annotation.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/manipulation/engine/default_pdf_native_annotation_engine.dart';

void main() {
  late Directory tempDir;
  const engine = DefaultPdfNativeAnnotationEngine();

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('titan_native_engine_test_');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 6B: DefaultPdfNativeAnnotationEngine CRUD & Flattening Tests',
      () {
    test('Add, Load, Update, and Delete Native Annotations lifecycle',
        () async {
      final doc = _createTestPdf(pageCount: 2);
      final pdfFile = File('${tempDir.path}/test_doc.pdf');
      await pdfFile.writeAsBytes(PdfWriter(doc).writeBytes());

      // 1. Initial load should be empty
      final initialAnnots = await engine.loadAnnotations(pdfFile.path);
      expect(initialAnnots, isEmpty);

      // 2. Add Highlight on page 0
      final now = DateTime.now();
      const box1 = PdfBoundingBox(left: 100, bottom: 700, right: 300, top: 720);
      final hl = PdfNativeHighlightAnnotation(
        id: 'hl-crud-1',
        pageIndex: 0,
        boundingBox: box1,
        creationDate: now,
        modificationDate: now,
        quadPoints: [PdfQuadPoint.fromBox(box1)],
        contents: 'Initial highlight note',
      );

      await engine.addAnnotation(pdfFile.path, hl);

      final afterAdd = await engine.loadAnnotations(pdfFile.path);
      expect(afterAdd.length, 1);
      expect(afterAdd.first.id, 'hl-crud-1');
      expect(afterAdd.first.contents, 'Initial highlight note');

      // 3. Update annotation contents and color
      final updatedHl = hl.copyWith(
        contents: 'Updated text content',
        color: const PdfColor.pink(),
      );
      await engine.updateAnnotation(pdfFile.path, updatedHl);

      final afterUpdate = await engine.loadAnnotations(pdfFile.path);
      expect(afterUpdate.length, 1);
      expect(afterUpdate.first.contents, 'Updated text content');
      expect(afterUpdate.first.color, const PdfColor.pink());

      // 4. Delete annotation
      await engine.deleteAnnotation(pdfFile.path, 'hl-crud-1');
      final afterDelete = await engine.loadAnnotations(pdfFile.path);
      expect(afterDelete, isEmpty);
    });

    test('Multi-page saveAllAnnotations and exportWithNativeAnnotations',
        () async {
      final doc = _createTestPdf(pageCount: 3);
      final sourceFile = File('${tempDir.path}/source_doc.pdf');
      await sourceFile.writeAsBytes(PdfWriter(doc).writeBytes());

      final now = DateTime.now();
      final annotations = <PdfNativeAnnotation>[
        PdfNativeHighlightAnnotation(
          id: 'hl-p0',
          pageIndex: 0,
          boundingBox:
              const PdfBoundingBox(left: 50, bottom: 600, right: 250, top: 620),
          creationDate: now,
          modificationDate: now,
          quadPoints: [
            PdfQuadPoint.fromBox(const PdfBoundingBox(
                left: 50, bottom: 600, right: 250, top: 620)),
          ],
        ),
        PdfNativeUnderlineAnnotation(
          id: 'un-p1',
          pageIndex: 1,
          boundingBox:
              const PdfBoundingBox(left: 70, bottom: 500, right: 200, top: 515),
          creationDate: now,
          modificationDate: now,
          quadPoints: [
            PdfQuadPoint.fromBox(const PdfBoundingBox(
                left: 70, bottom: 500, right: 200, top: 515)),
          ],
        ),
        PdfNativeInkAnnotation(
          id: 'ink-p2',
          pageIndex: 2,
          boundingBox: const PdfBoundingBox(
              left: 100, bottom: 100, right: 300, top: 300),
          creationDate: now,
          modificationDate: now,
          inkList: const [
            [PdfPoint(100, 100), PdfPoint(300, 300)],
          ],
        ),
      ];

      final exportedPath = '${tempDir.path}/exported_doc.pdf';
      await engine.exportWithNativeAnnotations(
        sourceFile.path,
        annotations,
        exportedPath,
      );

      expect(await File(exportedPath).exists(), isTrue);

      final p0Annots = await engine.loadAnnotations(exportedPath, pageIndex: 0);
      expect(p0Annots.length, 1);
      expect(p0Annots.first.subtype, 'Highlight');

      final p1Annots = await engine.loadAnnotations(exportedPath, pageIndex: 1);
      expect(p1Annots.length, 1);
      expect(p1Annots.first.subtype, 'Underline');

      final p2Annots = await engine.loadAnnotations(exportedPath, pageIndex: 2);
      expect(p2Annots.length, 1);
      expect(p2Annots.first.subtype, 'Ink');
    });

    test('Flatten native annotations into page content stream', () async {
      final doc = _createTestPdf(pageCount: 1);
      final sourceFile = File('${tempDir.path}/flatten_src.pdf');
      await sourceFile.writeAsBytes(PdfWriter(doc).writeBytes());

      final now = DateTime.now();
      const box = PdfBoundingBox(left: 100, bottom: 500, right: 300, top: 520);
      final hl = PdfNativeHighlightAnnotation(
        id: 'hl-flat-1',
        pageIndex: 0,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        quadPoints: [PdfQuadPoint.fromBox(box)],
      );

      await engine.addAnnotation(sourceFile.path, hl);
      expect((await engine.loadAnnotations(sourceFile.path)).length, 1);

      final flattenedPath = '${tempDir.path}/flattened_out.pdf';
      await engine.flattenAnnotations(sourceFile.path,
          outputPath: flattenedPath);

      // Once flattened, annotation dictionary is removed from /Annots
      final annotsAfterFlatten = await engine.loadAnnotations(flattenedPath);
      expect(annotsAfterFlatten, isEmpty);

      // Verify page content stream grew to include graphics operators
      final flattenedBytes = await File(flattenedPath).readAsBytes();
      expect(flattenedBytes.length, greaterThan(100));
    });

    test('Scale test: 100 annotations load, persist and reload accurately',
        () async {
      final doc = _createTestPdf(pageCount: 5);
      final sourceFile = File('${tempDir.path}/scale_doc.pdf');
      await sourceFile.writeAsBytes(PdfWriter(doc).writeBytes());

      final now = DateTime.now();
      final bulkAnnots = <PdfNativeAnnotation>[];
      for (var i = 0; i < 100; i++) {
        final pIdx = i % 5;
        const box = PdfBoundingBox(left: 50, bottom: 100, right: 250, top: 120);
        bulkAnnots.add(PdfNativeHighlightAnnotation(
          id: 'hl-bulk-$i',
          pageIndex: pIdx,
          boundingBox: box,
          creationDate: now,
          modificationDate: now,
          quadPoints: [PdfQuadPoint.fromBox(box)],
        ));
      }

      final sw = Stopwatch()..start();
      await engine.saveAllAnnotations(sourceFile.path, bulkAnnots);
      final loaded = await engine.loadAnnotations(sourceFile.path);
      sw.stop();

      expect(loaded.length, 100);
      expect(sw.elapsedMilliseconds, lessThan(2000));
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
