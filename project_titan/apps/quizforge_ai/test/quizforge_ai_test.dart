import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/quizforge_ai.dart';

void main() {
  group('QuizForge AI Package Export Tests', () {
    test('QuizForgeAppBootstrap can be instantiated', () {
      final bootstrap = QuizForgeAppBootstrap();
      expect(bootstrap.isInitialized, isFalse);
    });

    test('ApplicationState default values', () {
      const state = ApplicationState.idle();
      expect(state.isIdle, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isGeneratingQuiz, isFalse);
      expect(state.isReady, isFalse);
      expect(state.hasError, isFalse);
    });
  });
}
