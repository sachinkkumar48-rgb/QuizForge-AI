import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/quizforge_ai.dart';

void main() {
  group('QuizForgeApp Application Layer Tests', () {
    test('QuizForgeAppBootstrap initializes cleanly', () {
      final bootstrap = QuizForgeAppBootstrap();
      expect(bootstrap.isInitialized, isFalse);
    });
  });
}
