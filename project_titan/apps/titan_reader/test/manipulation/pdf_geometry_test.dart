import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/pdf_geometry.dart';

void main() {
  group('Phase 6B: PDF Geometry & Coordinate Transformer Tests', () {
    test('PdfPoint equality, hashCode and string formatting', () {
      const p1 = PdfPoint(100.5, 200.25);
      const p2 = PdfPoint(100.50001, 200.24999);
      const p3 = PdfPoint(100.0, 200.0);

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
      expect(p1.toString(), 'PdfPoint(100.50, 200.25)');
    });

    test('PdfBoundingBox normalization and union calculations', () {
      // Inverted box (top < bottom, right < left)
      const invBox =
          PdfBoundingBox(left: 300, bottom: 500, right: 100, top: 200);
      final norm = invBox.normalized();

      expect(norm.left, 100.0);
      expect(norm.right, 300.0);
      expect(norm.bottom, 200.0);
      expect(norm.top, 500.0);
      expect(norm.width, 200.0);
      expect(norm.height, 300.0);
      expect(norm.toPdfRect(), [100.0, 200.0, 300.0, 500.0]);

      // Union of two boxes
      const boxB = PdfBoundingBox(left: 50, bottom: 250, right: 400, top: 600);
      final unionBox = norm.union(boxB);
      expect(unionBox.left, 50.0);
      expect(unionBox.bottom, 200.0);
      expect(unionBox.right, 400.0);
      expect(unionBox.top, 600.0);
    });

    test('PdfQuadPoint conversion and bounding box computation', () {
      const box = PdfBoundingBox(left: 50, bottom: 100, right: 250, top: 150);
      final quad = PdfQuadPoint.fromBox(box);

      expect(quad.x1, 50.0); // Top-Left X
      expect(quad.y1, 150.0); // Top-Left Y
      expect(quad.x2, 250.0); // Top-Right X
      expect(quad.y2, 150.0); // Top-Right Y
      expect(quad.x3, 50.0); // Bottom-Left X
      expect(quad.y3, 100.0); // Bottom-Left Y
      expect(quad.x4, 250.0); // Bottom-Right X
      expect(quad.y4, 100.0); // Bottom-Right Y

      expect(quad.toList(),
          [50.0, 150.0, 250.0, 150.0, 50.0, 100.0, 250.0, 100.0]);
      final computedBox = quad.computeBoundingBox();
      expect(computedBox, equals(box));
    });

    test('PdfCoordinateTransformer round-trip across standard page sizes', () {
      final pageSizes = [
        const [595.28, 841.89], // A4
        const [612.0, 792.0], // US Letter
        const [1200.0, 400.0], // Custom Banner
      ];

      for (final size in pageSizes) {
        final w = size[0];
        final h = size[1];

        // 1. Box roundtrip
        const normRect =
            NormalizedPageRect(left: 0.1, top: 0.2, right: 0.8, bottom: 0.4);
        final pdfBox = PdfCoordinateTransformer.normalizedToPdfBox(
          normRect,
          pageWidth: w,
          pageHeight: h,
        );

        final backToNorm = PdfCoordinateTransformer.pdfBoxToNormalized(
          pdfBox,
          pageWidth: w,
          pageHeight: h,
        );

        expect(backToNorm.left, closeTo(normRect.left, 1e-4));
        expect(backToNorm.top, closeTo(normRect.top, 1e-4));
        expect(backToNorm.right, closeTo(normRect.right, 1e-4));
        expect(backToNorm.bottom, closeTo(normRect.bottom, 1e-4));

        // 2. QuadPoint roundtrip
        final pdfQuad = PdfCoordinateTransformer.normalizedToPdfQuad(
          normRect,
          pageWidth: w,
          pageHeight: h,
        );
        final quadBackToNorm = PdfCoordinateTransformer.pdfQuadToNormalized(
          pdfQuad,
          pageWidth: w,
          pageHeight: h,
        );

        expect(quadBackToNorm.left, closeTo(normRect.left, 1e-4));
        expect(quadBackToNorm.top, closeTo(normRect.top, 1e-4));
        expect(quadBackToNorm.right, closeTo(normRect.right, 1e-4));
        expect(quadBackToNorm.bottom, closeTo(normRect.bottom, 1e-4));

        // 3. Ink strokes roundtrip
        final normStroke = [
          const math.Point<double>(0.1, 0.1),
          const math.Point<double>(0.5, 0.5),
          const math.Point<double>(0.9, 0.8),
        ];

        final pdfPoints = PdfCoordinateTransformer.normalizedStrokeToPdfPoints(
          normStroke,
          pageWidth: w,
          pageHeight: h,
        );

        final strokeBack = PdfCoordinateTransformer.pdfPointsToNormalizedStroke(
          pdfPoints,
          pageWidth: w,
          pageHeight: h,
        );

        expect(strokeBack.length, normStroke.length);
        for (var i = 0; i < normStroke.length; i++) {
          expect(strokeBack[i].x, closeTo(normStroke[i].x, 1e-4));
          expect(strokeBack[i].y, closeTo(normStroke[i].y, 1e-4));
        }
      }
    });
  });
}
