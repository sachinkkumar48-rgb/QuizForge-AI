import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_geometry.dart';
import 'package:titan_reader/src/domain/entities/pdf_native_annotation.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_annotation_builder.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_annotation_parser.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';

void main() {
  group('Phase 6B: PDF Annotation Builder & Parser AST Round-Trip Tests', () {
    test('Build & parse Highlight annotation with QuadPoints and Appearance',
        () {
      final now = DateTime.utc(2026, 8, 20, 10, 0, 0);
      const box = PdfBoundingBox(left: 72, bottom: 700, right: 250, top: 720);
      final quad = PdfQuadPoint.fromBox(box);

      final highlight = PdfNativeHighlightAnnotation(
        id: 'hl-test-1',
        pageIndex: 0,
        boundingBox: box,
        color: const PdfColor.yellow(),
        opacity: 0.4,
        contents: 'Important text section',
        author: 'TITAN Architect',
        creationDate: now,
        modificationDate: now,
        quadPoints: [quad],
      );

      // Build annotation dictionary and appearance stream
      final apStream =
          PdfAnnotationBuilder.buildAppearanceStream(highlight, 99);
      expect(apStream.dict.getName('Type'), 'XObject');
      expect(apStream.dict.getName('Subtype'), 'Form');

      final dict = PdfAnnotationBuilder.buildAnnotationDict(
        highlight,
        pageRef: const PdfRef(3),
        appearanceStreamRef: const PdfRef(100),
      );

      expect(dict.getName('Type'), 'Annot');
      expect(dict.getName('Subtype'), 'Highlight');
      expect(dict.getString('NM')?.asString(), 'hl-test-1');
      expect(dict.getString('Contents')?.asString(), 'Important text section');
      expect(dict.getString('T')?.asString(), 'TITAN Architect');
      expect(dict.getArray('QuadPoints')?.length, 8);

      // Parse back from dictionary
      final parsed =
          PdfAnnotationParser.parseAnnotationDict(dict, pageIndex: 0);
      expect(parsed, isA<PdfNativeHighlightAnnotation>());
      final hlParsed = parsed as PdfNativeHighlightAnnotation;
      expect(hlParsed.id, 'hl-test-1');
      expect(hlParsed.contents, 'Important text section');
      expect(hlParsed.quadPoints.length, 1);
      expect(hlParsed.quadPoints.first, equals(quad));
    });

    test('Build & parse Ink annotation with multi-stroke InkList', () {
      final now = DateTime.utc(2026, 8, 20, 10, 0, 0);
      const box = PdfBoundingBox(left: 50, bottom: 100, right: 200, top: 300);
      final strokes = [
        const [PdfPoint(50, 100), PdfPoint(75, 150), PdfPoint(100, 200)],
        const [PdfPoint(150, 250), PdfPoint(200, 300)],
      ];

      final ink = PdfNativeInkAnnotation(
        id: 'ink-test-1',
        pageIndex: 0,
        boundingBox: box,
        color: const PdfColor.blue(),
        creationDate: now,
        modificationDate: now,
        inkList: strokes,
        strokeWidth: 2.5,
      );

      final dict = PdfAnnotationBuilder.buildAnnotationDict(ink);
      expect(dict.getName('Subtype'), 'Ink');
      expect(dict.getArray('InkList')?.length, 2);

      final parsed =
          PdfAnnotationParser.parseAnnotationDict(dict, pageIndex: 0);
      expect(parsed, isA<PdfNativeInkAnnotation>());
      final parsedInk = parsed as PdfNativeInkAnnotation;
      expect(parsedInk.inkList.length, 2);
      expect(parsedInk.inkList[0].length, 3);
      expect(parsedInk.inkList[1].length, 2);
      expect(parsedInk.strokeWidth, 2.5);
    });

    test('Build & parse FreeText and Sticky Note Text annotations', () {
      final now = DateTime.utc(2026, 8, 20, 10, 0, 0);
      const box = PdfBoundingBox(left: 100, bottom: 500, right: 300, top: 550);

      final freeText = PdfNativeFreeTextAnnotation(
        id: 'ft-test-1',
        pageIndex: 0,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        text: 'Summary of Chapter 1',
        fontSize: 16.0,
      );

      final ftDict = PdfAnnotationBuilder.buildAnnotationDict(freeText);
      expect(ftDict.getName('Subtype'), 'FreeText');
      expect(ftDict.getString('Contents')?.asString(), 'Summary of Chapter 1');

      final parsedFt =
          PdfAnnotationParser.parseAnnotationDict(ftDict, pageIndex: 0);
      expect(parsedFt, isA<PdfNativeFreeTextAnnotation>());
      expect((parsedFt as PdfNativeFreeTextAnnotation).text,
          'Summary of Chapter 1');

      final sticky = PdfNativeTextAnnotation(
        id: 'text-test-1',
        pageIndex: 0,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        contents: 'Needs verification',
        iconName: 'Help',
        isOpen: true,
      );

      final stickyDict = PdfAnnotationBuilder.buildAnnotationDict(sticky);
      expect(stickyDict.getName('Subtype'), 'Text');
      expect(stickyDict.getName('Name'), 'Help');

      final parsedSticky =
          PdfAnnotationParser.parseAnnotationDict(stickyDict, pageIndex: 0);
      expect(parsedSticky, isA<PdfNativeTextAnnotation>());
      expect((parsedSticky as PdfNativeTextAnnotation).iconName, 'Help');
      expect(parsedSticky.isOpen, isTrue);
    });

    test('Extract page annotations from complete AST with multiple items', () {
      final doc = _buildPdfWithMultipleAnnots();
      final annots = PdfAnnotationParser.parsePageAnnotations(doc, 0);

      expect(annots.length, 3);
      expect(annots.map((a) => a.subtype).toList(),
          ['Highlight', 'Underline', 'Ink']);
    });
  });
}

PdfDocumentAst _buildPdfWithMultipleAnnots() {
  final now = DateTime.utc(2026, 8, 20, 10, 0, 0);
  final objects = <int, PdfObject>{};
  final gens = <int, int>{};

  const box1 = PdfBoundingBox(left: 72, bottom: 700, right: 200, top: 720);
  final hl = PdfNativeHighlightAnnotation(
    id: 'hl-1',
    pageIndex: 0,
    boundingBox: box1,
    creationDate: now,
    modificationDate: now,
    quadPoints: [PdfQuadPoint.fromBox(box1)],
  );
  final hlDict =
      PdfAnnotationBuilder.buildAnnotationDict(hl, pageRef: const PdfRef(3));

  const box2 = PdfBoundingBox(left: 72, bottom: 650, right: 200, top: 665);
  final un = PdfNativeUnderlineAnnotation(
    id: 'un-1',
    pageIndex: 0,
    boundingBox: box2,
    creationDate: now,
    modificationDate: now,
    quadPoints: [PdfQuadPoint.fromBox(box2)],
  );
  final unDict =
      PdfAnnotationBuilder.buildAnnotationDict(un, pageRef: const PdfRef(3));

  const box3 = PdfBoundingBox(left: 100, bottom: 200, right: 300, top: 400);
  final ink = PdfNativeInkAnnotation(
    id: 'ink-1',
    pageIndex: 0,
    boundingBox: box3,
    creationDate: now,
    modificationDate: now,
    inkList: const [
      [PdfPoint(100, 200), PdfPoint(200, 300)],
    ],
  );
  final inkDict =
      PdfAnnotationBuilder.buildAnnotationDict(ink, pageRef: const PdfRef(3));

  objects[4] = hlDict;
  gens[4] = 0;
  objects[5] = unDict;
  gens[5] = 0;
  objects[6] = inkDict;
  gens[6] = 0;

  final page = PdfDict({
    'Type': const PdfName('Page'),
    'Parent': const PdfRef(2),
    'MediaBox': PdfArray(const [
      PdfNumber(0),
      PdfNumber(0),
      PdfNumber(612),
      PdfNumber(792),
    ]),
    'Annots': PdfArray(const [PdfRef(4), PdfRef(5), PdfRef(6)]),
  });
  objects[3] = page;
  gens[3] = 0;

  final pages = PdfDict({
    'Type': const PdfName('Pages'),
    'Kids': PdfArray(const [PdfRef(3)]),
    'Count': const PdfNumber(1),
  });
  objects[2] = pages;
  gens[2] = 0;

  final catalog = PdfDict(const {
    'Type': PdfName('Catalog'),
    'Pages': PdfRef(2),
  });
  objects[1] = catalog;
  gens[1] = 0;

  return PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: gens,
    trailer: PdfDict(const {'Root': PdfRef(1)}),
    catalog: catalog,
  );
}
