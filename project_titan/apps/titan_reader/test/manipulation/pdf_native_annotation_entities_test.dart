import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_geometry.dart';
import 'package:titan_reader/src/domain/entities/pdf_native_annotation.dart';

void main() {
  group('Phase 6B: PDF Native Annotation Domain Entities Tests', () {
    test('PdfColor conversions and constants', () {
      const yellow = PdfColor.yellow();
      expect(yellow.r, 1.0);
      expect(yellow.toPdfArray(), [1.0, 0.92, 0.23]);

      // Hex integer to PdfColor
      final color = PdfColor.fromInt(0xFF2196F3);
      expect(color.r, closeTo(0.13, 0.01));
      expect(color.g, closeTo(0.59, 0.01));
      expect(color.b, closeTo(0.95, 0.01));

      // toArgbInt
      final argb = color.toArgbInt(0.5);
      expect((argb >> 24) & 0xFF, 128); // 50% opacity
    });

    test('PdfNativeHighlightAnnotation immutability and copyWith', () {
      final now = DateTime.now();
      const box = PdfBoundingBox(left: 72, bottom: 700, right: 200, top: 720);
      final quad = PdfQuadPoint.fromBox(box);

      final annot = PdfNativeHighlightAnnotation(
        id: 'hl-001',
        pageIndex: 0,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        quadPoints: [quad],
      );

      expect(annot.subtype, 'Highlight');
      expect(annot.opacity, 0.4);
      expect(annot.quadPoints.length, 1);

      final updated = annot.copyWith(
        contents: 'Important statutory principle',
        color: const PdfColor.pink(),
      );

      expect(updated.id, 'hl-001');
      expect(updated.contents, 'Important statutory principle');
      expect(updated.color, const PdfColor.pink());
    });

    test('PdfNativeUnderlineAnnotation & StrikeOutAnnotation properties', () {
      final now = DateTime.now();
      const box = PdfBoundingBox(left: 50, bottom: 500, right: 300, top: 515);
      final quad = PdfQuadPoint.fromBox(box);

      final under = PdfNativeUnderlineAnnotation(
        id: 'un-001',
        pageIndex: 1,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        quadPoints: [quad],
      );
      expect(under.subtype, 'Underline');

      final strike = PdfNativeStrikeOutAnnotation(
        id: 'st-001',
        pageIndex: 1,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        quadPoints: [quad],
      );
      expect(strike.subtype, 'StrikeOut');
    });

    test('PdfNativeInkAnnotation strokes and width', () {
      final now = DateTime.now();
      const box = PdfBoundingBox(left: 100, bottom: 200, right: 300, top: 400);
      final strokes = [
        const [PdfPoint(100, 200), PdfPoint(150, 250), PdfPoint(200, 300)],
        const [PdfPoint(250, 350), PdfPoint(300, 400)],
      ];

      final ink = PdfNativeInkAnnotation(
        id: 'ink-001',
        pageIndex: 0,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        inkList: strokes,
        strokeWidth: 3.5,
      );

      expect(ink.subtype, 'Ink');
      expect(ink.inkList.length, 2);
      expect(ink.strokeWidth, 3.5);
    });

    test('PdfNativeFreeTextAnnotation and TextAnnotation (Sticky Note)', () {
      final now = DateTime.now();
      const box = PdfBoundingBox(left: 100, bottom: 600, right: 250, top: 650);

      final freeText = PdfNativeFreeTextAnnotation(
        id: 'ft-001',
        pageIndex: 0,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        text: 'Section 42 Analysis',
        fontSize: 14.0,
      );

      expect(freeText.subtype, 'FreeText');
      expect(freeText.text, 'Section 42 Analysis');
      expect(freeText.fontSize, 14.0);

      final sticky = PdfNativeTextAnnotation(
        id: 'txt-001',
        pageIndex: 0,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        contents: 'Review before sprint submission',
        iconName: 'Note',
        isOpen: true,
      );

      expect(sticky.subtype, 'Text');
      expect(sticky.iconName, 'Note');
      expect(sticky.isOpen, isTrue);
    });

    test('PdfNativeRawAnnotation preserves unsupported annotation types', () {
      final now = DateTime.now();
      const box = PdfBoundingBox(left: 10, bottom: 10, right: 50, top: 50);

      final raw = PdfNativeRawAnnotation(
        id: 'link-001',
        pageIndex: 0,
        boundingBox: box,
        creationDate: now,
        modificationDate: now,
        rawSubtype: 'Link',
        rawProperties: const {'Dest': 'Page1'},
      );

      expect(raw.subtype, 'Link');
      expect(raw.rawProperties['Dest'], 'Page1');
    });
  });
}
