import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/ocr/page_text_classification.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/ocr/page_text_classifier.dart';

void main() {
  const classifier = PageTextClassifier();

  group('PageTextClassifier Metrics Classification Tests', () {
    test('classifies image-only scanned page accurately', () {
      final res = classifier.classifyPageMetrics(
        pageNumber: 1,
        characterCount: 0,
        rasterImageCount: 1,
      );

      expect(res.category, PageTextCategory.imageOnly);
      expect(res.isOcrRecommended, isTrue);
      expect(res.nativeCharacterCount, 0);
      expect(res.rasterImageCount, 1);
    });

    test('classifies native searchable PDF page accurately', () {
      final res = classifier.classifyPageMetrics(
        pageNumber: 2,
        characterCount: 1540,
        rasterImageCount: 0,
      );

      expect(res.category, PageTextCategory.nativeText);
      expect(res.isOcrRecommended, isFalse);
      expect(res.nativeCharacterCount, 1540);
    });

    test('classifies mixed page accurately', () {
      final res = classifier.classifyPageMetrics(
        pageNumber: 3,
        characterCount: 45,
        rasterImageCount: 2,
      );

      expect(res.category, PageTextCategory.mixed);
      expect(res.isOcrRecommended, isTrue); // low character count + images
    });

    test('classifies unknown / empty page', () {
      final res = classifier.classifyPageMetrics(
        pageNumber: 4,
        characterCount: 0,
        rasterImageCount: 0,
      );

      expect(res.category, PageTextCategory.unknown);
      expect(res.isOcrRecommended, isFalse);
    });
  });

  group('PageTextClassifier AST Image Inspection Tests', () {
    test('counts embedded raster images in PDF AST page dictionary', () {
      final imageStream = PdfStream(
        dict: PdfDict(const {
          'Type': PdfName('XObject'),
          'Subtype': PdfName('Image'),
        }),
        data: Uint8List(0),
      );

      final resourcesDict = PdfDict({
        'XObject': PdfDict(const {'Im1': PdfRef(10)}),
      });

      final pageDict = PdfDict({
        'Type': const PdfName('Page'),
        'Resources': const PdfRef(20),
        'MediaBox': PdfArray(const [
          PdfNumber(0),
          PdfNumber(0),
          PdfNumber(612),
          PdfNumber(792),
        ]),
      });

      final pagesDict = PdfDict({
        'Type': const PdfName('Pages'),
        'Kids': PdfArray(const [PdfRef(30)]),
        'Count': const PdfNumber(1),
      });

      final catalog = PdfDict(const {
        'Type': PdfName('Catalog'),
        'Pages': PdfRef(40),
      });

      final objects = <int, PdfObject>{
        10: imageStream,
        20: resourcesDict,
        30: pageDict,
        40: pagesDict,
        50: catalog,
      };

      final ast = PdfDocumentAst(
        header: '%PDF-1.7',
        objects: objects,
        objectGenerations: const {10: 0, 20: 0, 30: 0, 40: 0, 50: 0},
        trailer: PdfDict(const {'Root': PdfRef(50)}),
        catalog: catalog,
      );

      final count = classifier.countPageRasterImages(ast, 1);
      expect(count, 1);
    });
  });
}
