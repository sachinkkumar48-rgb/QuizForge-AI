import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/normalized_page_rect.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_confidence.dart';
import 'package:titan_reader/src/domain/entities/ocr/ocr_text_region.dart';
import 'package:titan_reader/src/services/pdf_searchable_export_service.dart';

void main() {
  group('PdfSearchableExport Coordinate Transformation Tests', () {
    const a4Width = 595.28;
    const a4Height = 841.89;

    test('transforms top-left normalized box to bottom-up PDF point space', () {
      // Normalized box at top-left: left: 0.1, top: 0.1, right: 0.3, bottom: 0.15
      const rect =
          NormalizedPageRect(left: 0.1, top: 0.1, right: 0.3, bottom: 0.15);

      final coords = PdfSearchableExportService.transformCoordinates(
        rect: rect,
        pageWidth: a4Width,
        pageHeight: a4Height,
      );

      // pdfX = 0.1 * 595.28 = 59.528
      expect(coords.pdfX, closeTo(59.528, 0.01));
      // pdfWidth = (0.3 - 0.1) * 595.28 = 119.056
      expect(coords.pdfWidth, closeTo(119.056, 0.01));
      // pdfY = (1.0 - 0.15) * 841.89 = 0.85 * 841.89 = 715.6065
      expect(coords.pdfY, closeTo(715.6065, 0.01));
      // pdfHeight = (0.15 - 0.10) * 841.89 = 42.0945
      expect(coords.pdfHeight, closeTo(42.0945, 0.01));
      // fontSize = 42.0945
      expect(coords.fontSize, closeTo(42.0945, 0.01));
    });

    test('transforms bottom-right normalized box correctly', () {
      // Normalized box at bottom-right: left: 0.7, top: 0.85, right: 0.95, bottom: 0.95
      const rect =
          NormalizedPageRect(left: 0.7, top: 0.85, right: 0.95, bottom: 0.95);

      final coords = PdfSearchableExportService.transformCoordinates(
        rect: rect,
        pageWidth: a4Width,
        pageHeight: a4Height,
      );

      expect(coords.pdfX, closeTo(0.7 * a4Width, 0.01));
      expect(coords.pdfWidth, closeTo(0.25 * a4Width, 0.01));
      // In bottom-up coordinates, pdfY is at (1.0 - 0.95) * a4Height = 0.05 * 841.89 = 42.0945
      expect(coords.pdfY, closeTo(0.05 * a4Height, 0.01));
      expect(coords.pdfHeight, closeTo(0.10 * a4Height, 0.01));
    });

    test('transforms landscape page dimensions accurately', () {
      const landscapeWidth = 841.89;
      const landscapeHeight = 595.28;
      const centerRect =
          NormalizedPageRect(left: 0.4, top: 0.4, right: 0.6, bottom: 0.6);

      final coords = PdfSearchableExportService.transformCoordinates(
        rect: centerRect,
        pageWidth: landscapeWidth,
        pageHeight: landscapeHeight,
      );

      expect(coords.pdfX, closeTo(0.4 * landscapeWidth, 0.01));
      expect(coords.pdfY, closeTo((1.0 - 0.6) * landscapeHeight, 0.01));
      expect(coords.pdfWidth, closeTo(0.2 * landscapeWidth, 0.01));
      expect(coords.pdfHeight, closeTo(0.2 * landscapeHeight, 0.01));
    });

    test('handles non-zero lower-left origin offsets', () {
      const rect =
          NormalizedPageRect(left: 0.2, top: 0.2, right: 0.4, bottom: 0.3);

      final coords = PdfSearchableExportService.transformCoordinates(
        rect: rect,
        pageWidth: 500,
        pageHeight: 500,
        lowerLeftX: 50,
        lowerLeftY: 50,
      );

      expect(coords.pdfX, closeTo(50 + 0.2 * 500, 0.01));
      expect(coords.pdfY, closeTo(50 + (1.0 - 0.3) * 500, 0.01));
      expect(coords.pdfWidth, closeTo(0.2 * 500, 0.01));
      expect(coords.pdfHeight, closeTo(0.1 * 500, 0.01));
    });

    test('transforms boundary normalized coordinates safely', () {
      const boundaryRect =
          NormalizedPageRect(left: 0.0, top: 0.0, right: 1.0, bottom: 1.0);

      final coords = PdfSearchableExportService.transformCoordinates(
        rect: boundaryRect,
        pageWidth: 100,
        pageHeight: 100,
      );

      expect(coords.pdfX, closeTo(0.0, 0.01));
      expect(coords.pdfY, closeTo(0.0, 0.01));
      expect(coords.pdfWidth, closeTo(100.0, 0.01));
      expect(coords.pdfHeight, closeTo(100.0, 0.01));
    });
  });

  group('Reading Order & PDF String Escaping Tests', () {
    test(
        'sorts OCR words deterministically from top-to-bottom and left-to-right',
        () {
      final words = [
        const OcrWord(
          text: 'World',
          boundingBox:
              NormalizedPageRect(left: 0.3, top: 0.1, right: 0.5, bottom: 0.15),
          confidence: OcrConfidence(0.99),
          wordIndex: 1,
        ),
        const OcrWord(
          text: 'Hello',
          boundingBox: NormalizedPageRect(
              left: 0.1, top: 0.1, right: 0.25, bottom: 0.15),
          confidence: OcrConfidence(0.99),
          wordIndex: 0,
        ),
        const OcrWord(
          text: 'Second',
          boundingBox:
              NormalizedPageRect(left: 0.1, top: 0.3, right: 0.3, bottom: 0.35),
          confidence: OcrConfidence(0.99),
          wordIndex: 2,
        ),
        const OcrWord(
          text: 'Line',
          boundingBox: NormalizedPageRect(
              left: 0.35, top: 0.3, right: 0.5, bottom: 0.35),
          confidence: OcrConfidence(0.99),
          wordIndex: 3,
        ),
      ];

      final sorted = PdfSearchableExportService.sortWordsInReadingOrder(words);

      expect(sorted[0].text, 'Hello');
      expect(sorted[1].text, 'World');
      expect(sorted[2].text, 'Second');
      expect(sorted[3].text, 'Line');
    });

    test('escapes special characters in PDF literal string format', () {
      expect(PdfSearchableExportService.escapePdfString('Hello (World)'),
          r'Hello \(World\)');
      expect(PdfSearchableExportService.escapePdfString(r'C:\Program Files'),
          r'C:\\Program Files');
      expect(PdfSearchableExportService.escapePdfString('Line1\nLine2\tTab'),
          r'Line1\nLine2\tTab');
      expect(PdfSearchableExportService.escapePdfString('Standard text 123'),
          'Standard text 123');
    });
  });
}
