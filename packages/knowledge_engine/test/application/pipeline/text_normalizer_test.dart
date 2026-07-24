import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/knowledge_engine.dart';

void main() {
  group('TextNormalizer Tests', () {
    late TextNormalizer normalizer;

    setUp(() {
      normalizer = TextNormalizer();
    });

    test('returns empty string when input is empty', () {
      expect(normalizer.normalize(''), equals(''));
      expect(normalizer.normalize('   '), equals(''));
    });

    test('strips control characters and normalizes CRLF line endings', () {
      const input = "Header\r\nLine 1\x00\x07\r\nLine 2\x1F";
      final result = normalizer.normalize(input);

      expect(result, isNot(contains('\r')));
      expect(result, isNot(contains('\x00')));
      expect(result, isNot(contains('\x07')));
      expect(result, isNot(contains('\x1F')));
      expect(result, equals("Header\nLine 1\nLine 2"));
    });

    test('collapses multiple horizontal spaces while preserving single space',
        () {
      const input = "UPSC   Civil    Services  Exam";
      final result = normalizer.normalize(input);

      expect(result, equals("UPSC Civil Services Exam"));
    });

    test('collapses 3+ consecutive newlines into paragraph double newlines',
        () {
      const input = "Paragraph 1\n\n\n\n\nParagraph 2";
      final result = normalizer.normalize(input);

      expect(result, equals("Paragraph 1\n\nParagraph 2"));
    });
  });
}
