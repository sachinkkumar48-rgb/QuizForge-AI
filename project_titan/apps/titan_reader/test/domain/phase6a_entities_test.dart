import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_page_label_config.dart';
import 'package:titan_reader/src/domain/entities/pdf_page_operation.dart';
import 'package:titan_reader/src/domain/entities/pdf_page_range.dart';
import 'package:titan_reader/src/domain/pdf_manipulation_errors.dart';

void main() {
  group('Phase 6A: PdfPageRange Entity Tests', () {
    test('PdfPageRange single page creation and properties', () {
      const range = PdfPageRange.single(5);
      expect(range.startPage, 5);
      expect(range.endPage, 5);
      expect(range.count, 1);
      expect(range.contains(5), isTrue);
      expect(range.contains(4), isFalse);
      expect(range.toPageList(), [5]);
      expect(range.toString(), '5');
    });

    test('PdfPageRange multi-page creation and properties', () {
      const range = PdfPageRange(3, 7);
      expect(range.startPage, 3);
      expect(range.endPage, 7);
      expect(range.count, 5);
      expect(range.contains(3), isTrue);
      expect(range.contains(5), isTrue);
      expect(range.contains(7), isTrue);
      expect(range.contains(2), isFalse);
      expect(range.contains(8), isFalse);
      expect(range.toPageList(), [3, 4, 5, 6, 7]);
      expect(range.toString(), '3-7');
    });

    test('parseMultiple parses single numbers, ranges, and comma lists', () {
      final ranges = PdfPageRange.parseMultiple('1, 3-5, 8, 10-12');
      expect(ranges.length, 4);
      expect(ranges[0], const PdfPageRange.single(1));
      expect(ranges[1], const PdfPageRange(3, 5));
      expect(ranges[2], const PdfPageRange.single(8));
      expect(ranges[3], const PdfPageRange(10, 12));

      final expanded = PdfPageRange.expandToPageNumbers(ranges);
      expect(expanded, [1, 3, 4, 5, 8, 10, 11, 12]);
    });

    test('parseMultiple throws on empty or invalid syntax', () {
      expect(() => PdfPageRange.parseMultiple(''),
          throwsA(isA<PdfPageRangeParseException>()));
      expect(() => PdfPageRange.parseMultiple('abc'),
          throwsA(isA<PdfPageRangeParseException>()));
      expect(() => PdfPageRange.parseMultiple('5-3'),
          throwsA(isA<PdfPageRangeParseException>()));
      expect(() => PdfPageRange.parseMultiple('0'),
          throwsA(isA<PdfPageRangeParseException>()));
    });

    test('parseMultiple respects maxPages bounds', () {
      expect(
        () => PdfPageRange.parseMultiple('1-10', maxPages: 5),
        throwsA(isA<PdfPageRangeOutOfBoundsException>()),
      );
      final valid = PdfPageRange.parseMultiple('1-5', maxPages: 5);
      expect(valid.length, 1);
      expect(valid.first.count, 5);
    });
  });

  group('Phase 6A: PdfPageLabelConfig Tests', () {
    test('PdfPageLabelStyle codes and conversions', () {
      expect(PdfPageLabelStyle.arabic.pdfStyleCode, 'D');
      expect(PdfPageLabelStyle.romanLower.pdfStyleCode, 'r');
      expect(PdfPageLabelStyle.romanUpper.pdfStyleCode, 'R');
      expect(PdfPageLabelStyle.alphaLower.pdfStyleCode, 'a');
      expect(PdfPageLabelStyle.alphaUpper.pdfStyleCode, 'A');
      expect(PdfPageLabelStyle.none.pdfStyleCode, isNull);

      expect(
          PdfPageLabelStyleExtension.fromCode('D'), PdfPageLabelStyle.arabic);
      expect(PdfPageLabelStyleExtension.fromCode('r'),
          PdfPageLabelStyle.romanLower);
      expect(PdfPageLabelStyleExtension.fromCode('R'),
          PdfPageLabelStyle.romanUpper);
      expect(PdfPageLabelStyleExtension.fromCode('a'),
          PdfPageLabelStyle.alphaLower);
      expect(PdfPageLabelStyleExtension.fromCode('A'),
          PdfPageLabelStyle.alphaUpper);
    });

    test('PdfPageLabelRange formatting labels', () {
      const romanRange = PdfPageLabelRange(
        startPage: 1,
        style: PdfPageLabelStyle.romanLower,
        prefix: 'Preface-',
      );
      expect(romanRange.formatLabelForIndex(1), 'Preface-i');
      expect(romanRange.formatLabelForIndex(2), 'Preface-ii');
      expect(romanRange.formatLabelForIndex(4), 'Preface-iv');

      const arabicRange = PdfPageLabelRange(
        startPage: 5,
        style: PdfPageLabelStyle.arabic,
        startNumber: 1,
      );
      expect(arabicRange.formatLabelForIndex(5), '1');
      expect(arabicRange.formatLabelForIndex(6), '2');
    });
  });

  group('Phase 6A: PdfPageRotation Tests', () {
    test('PdfPageRotation degrees and 90 degree increments', () {
      expect(PdfPageRotation.none.degrees, 0);
      expect(PdfPageRotation.cw90.degrees, 90);
      expect(PdfPageRotation.cw180.degrees, 180);
      expect(PdfPageRotation.cw270.degrees, 270);

      expect(PdfPageRotation.fromDegrees(0), PdfPageRotation.none);
      expect(PdfPageRotation.fromDegrees(90), PdfPageRotation.cw90);
      expect(PdfPageRotation.fromDegrees(180), PdfPageRotation.cw180);
      expect(PdfPageRotation.fromDegrees(270), PdfPageRotation.cw270);
      expect(PdfPageRotation.fromDegrees(360), PdfPageRotation.none);
      expect(PdfPageRotation.fromDegrees(450), PdfPageRotation.cw90);

      expect(PdfPageRotation.none.rotateClockwise90(), PdfPageRotation.cw90);
      expect(PdfPageRotation.cw90.rotateClockwise90(), PdfPageRotation.cw180);
      expect(PdfPageRotation.cw180.rotateClockwise90(), PdfPageRotation.cw270);
      expect(PdfPageRotation.cw270.rotateClockwise90(), PdfPageRotation.none);
    });
  });
}
