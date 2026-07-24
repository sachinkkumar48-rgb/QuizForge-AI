import 'package:test/test.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

void main() {
  group('QuizAIUtils Tests', () {
    test('sanitizeInputText removes control characters', () {
      final input = "Header\x00\x07Text\nLine 2";
      final sanitized = QuizAIUtils.sanitizeInputText(input);
      expect(sanitized, equals("HeaderText\nLine 2"));
    });

    test('estimateTokenCount returns ~1 token per 4 characters', () {
      expect(QuizAIUtils.estimateTokenCount(''), equals(0));
      expect(QuizAIUtils.estimateTokenCount('12345678'), equals(2));
      expect(QuizAIUtils.estimateTokenCount('Hello World'), equals(3));
    });
  });
}
