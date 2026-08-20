import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_geometry.dart';
import 'package:titan_reader/src/domain/entities/pdf_native_annotation.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_parser.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/manipulation/engine/default_pdf_native_annotation_engine.dart';

void main() {
  late Directory tempDir;
  const nativeEngine = DefaultPdfNativeAnnotationEngine();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('titan_interop_test_');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 6B: PDF Native Annotation Cross-Viewer Interoperability Tests',
      () {
    test(
        'Generate document with all 6 native annotation types + Appearance Streams',
        () async {
      final doc = _createTestPdf(pageCount: 1);
      final pdfFile = File('${tempDir.path}/all_annots.pdf')
        ..writeAsBytesSync(PdfWriter(doc).writeBytes());

      final now = DateTime.utc(2026, 8, 20, 10, 0, 0);
      final annotations = <PdfNativeAnnotation>[
        // 1. Highlight
        PdfNativeHighlightAnnotation(
          id: 'hl-interop',
          pageIndex: 0,
          boundingBox:
              const PdfBoundingBox(left: 72, bottom: 700, right: 300, top: 720),
          color: const PdfColor.yellow(),
          opacity: 0.4,
          contents: 'Highlight for cross-viewer verification',
          creationDate: now,
          modificationDate: now,
          quadPoints: [
            PdfQuadPoint.fromBox(const PdfBoundingBox(
                left: 72, bottom: 700, right: 300, top: 720)),
          ],
        ),
        // 2. Underline
        PdfNativeUnderlineAnnotation(
          id: 'un-interop',
          pageIndex: 0,
          boundingBox:
              const PdfBoundingBox(left: 72, bottom: 650, right: 250, top: 665),
          color: const PdfColor.blue(),
          contents: 'Underline for cross-viewer verification',
          creationDate: now,
          modificationDate: now,
          quadPoints: [
            PdfQuadPoint.fromBox(const PdfBoundingBox(
                left: 72, bottom: 650, right: 250, top: 665)),
          ],
        ),
        // 3. StrikeOut
        PdfNativeStrikeOutAnnotation(
          id: 'st-interop',
          pageIndex: 0,
          boundingBox:
              const PdfBoundingBox(left: 72, bottom: 600, right: 200, top: 615),
          color: const PdfColor.red(),
          contents: 'Deprecated provision',
          creationDate: now,
          modificationDate: now,
          quadPoints: [
            PdfQuadPoint.fromBox(const PdfBoundingBox(
                left: 72, bottom: 600, right: 200, top: 615)),
          ],
        ),
        // 4. Ink
        PdfNativeInkAnnotation(
          id: 'ink-interop',
          pageIndex: 0,
          boundingBox:
              const PdfBoundingBox(left: 50, bottom: 400, right: 200, top: 500),
          color: const PdfColor.purple(),
          strokeWidth: 3.0,
          creationDate: now,
          modificationDate: now,
          inkList: const [
            [PdfPoint(50, 400), PdfPoint(100, 450), PdfPoint(200, 500)],
          ],
        ),
        // 5. FreeText
        PdfNativeFreeTextAnnotation(
          id: 'ft-interop',
          pageIndex: 0,
          boundingBox:
              const PdfBoundingBox(left: 72, bottom: 300, right: 350, top: 350),
          color: const PdfColor.black(),
          text: 'Standardized FreeText Box',
          fontSize: 14.0,
          creationDate: now,
          modificationDate: now,
        ),
        // 6. Sticky Note
        PdfNativeTextAnnotation(
          id: 'note-interop',
          pageIndex: 0,
          boundingBox: const PdfBoundingBox(
              left: 400, bottom: 700, right: 424, top: 724),
          color: const PdfColor.yellow(),
          contents: 'Sticky note comment',
          iconName: 'Comment',
          isOpen: false,
          creationDate: now,
          modificationDate: now,
        ),
      ];

      await nativeEngine.saveAllAnnotations(pdfFile.path, annotations);

      // Verify file is structurally valid and readable
      final reloadedBytes = await pdfFile.readAsBytes();
      final ast = PdfParser(reloadedBytes).parse();
      expect(ast.pageCount, 1);

      final loadedAnnots = await nativeEngine.loadAnnotations(pdfFile.path);
      expect(loadedAnnots.length, 6);

      // Verify each annotation has an associated Form XObject appearance stream
      final pageDict = ast.getPageDict(0);
      final annotsArray = pageDict.getArray('Annots')!;
      expect(annotsArray.length, 6);

      for (var i = 0; i < annotsArray.length; i++) {
        final ref = annotsArray[i] as PdfRef;
        final annotObj = ast.objects[ref.objectNumber] as PdfDict;
        final apDict = annotObj.getDict('AP');
        expect(apDict, isNotNull);
        final normalApRef = apDict!['N'] as PdfRef;
        final apStreamObj = ast.objects[normalApRef.objectNumber];
        expect(apStreamObj, isA<PdfStream>());
        final apStream = apStreamObj as PdfStream;
        expect(apStream.dict.getName('Type'), 'XObject');
        expect(apStream.dict.getName('Subtype'), 'Form');
        expect(apStream.data.length, greaterThan(0));
      }
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
