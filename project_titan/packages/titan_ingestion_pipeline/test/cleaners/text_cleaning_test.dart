import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';

void main() {
  group('TextCleaningEngine Tests', () {
    late TextCleaningEngine cleaner;

    setUp(() {
      cleaner = TextCleaningEngine();
    });

    test('1. Unicode Normalization replaces curly quotes and zero-width spaces',
        () {
      const raw = '“Smart” quotes and ‘single’ quotes with \u200Bzero width.';
      final result = cleaner.normalizeUnicode(raw);
      expect(result, contains('"Smart" quotes'));
      expect(result, contains("'single' quotes"));
      expect(result, isNot(contains('\u200B')));
    });

    test('2. OCR Cleanup repairs common OCR glitches', () {
      const raw = 'The l11 people vvith |barriers|';
      final result = cleaner.cleanupOcr(raw);
      expect(result, contains('all people'));
      expect(result, contains('with'));
    });

    test('3. Page Number Removal strips page footers', () {
      const raw = 'Header Text\nPage 1 of 10\nContent line\n- 12 -';
      final result = cleaner.removePageNumbers(raw);
      expect(result, isNot(contains('Page 1 of 10')));
      expect(result, isNot(contains('- 12 -')));
      expect(result, contains('Content line'));
    });

    test('4. Header and Footer Removal strips running headers', () {
      const raw = 'CHAPTER 1\nActual educational text.\nALL RIGHTS RESERVED';
      final result = cleaner.removeHeadersAndFooters(raw);
      expect(result, isNot(contains('CHAPTER 1')));
      expect(result, isNot(contains('ALL RIGHTS RESERVED')));
      expect(result, contains('Actual educational text.'));
    });

    test('5. Broken Line Repair reconnects hyphenated line breaks', () {
      const raw = 'The con-\n stitution of India.';
      final result = cleaner.repairBrokenLines(raw);
      expect(result, contains('constitution of India.'));
    });

    test('6. Whitespace Normalization collapses extra spaces and line breaks',
        () {
      const raw = 'Word1   Word2\n\n\n\nWord3';
      final result = cleaner.normalizeWhitespace(raw);
      expect(result, equals('Word1 Word2\n\nWord3'));
    });

    test('7. Duplicate Paragraph Removal removes exact duplicate paragraphs',
        () {
      const raw =
          'Unique paragraph one.\n\nUnique paragraph one.\n\nParagraph two.';
      final result = cleaner.removeDuplicateParagraphs(raw);
      expect(result, equals('Unique paragraph one.\n\nParagraph two.'));
    });

    test('8. Full cleaning pipeline combines all steps', () {
      const raw =
          '“Heading”\nPage 5 of 20\n\nThe fundamental con-\n stitution of law.\n\nThe fundamental con-\n stitution of law.';
      final result = cleaner.clean(raw);
      expect(result, contains('"Heading"'));
      expect(result, contains('constitution of law.'));
      expect(result, isNot(contains('Page 5 of 20')));
    });
  });
}
