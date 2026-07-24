import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_ai/src/presentation/providers/result_controller.dart';
import 'package:quizforge_ai/src/presentation/states/result_state.dart';
import 'package:titan_quiz/titan_quiz.dart';

void main() {
  group('ResultController', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is ResultState.initial()', () {
      final state = container.read(resultControllerProvider);
      expect(state.status, equals(ResultStateStatus.initial));
      expect(state.analytics, isNull);
    });

    test('analyzeQuizResult updates state to success with ResultAnalytics',
        () async {
      final controller = container.read(resultControllerProvider.notifier);

      final quizResult = QuizResult(
        quizId: 'session_test_1',
        attempted: 5,
        correct: 4,
        wrong: 1,
        unanswered: 0,
        score: 7.67,
        maxScore: 10.0,
        percentage: 76.7,
      );

      await controller.analyzeQuizResult(quizResult);

      final updatedState = container.read(resultControllerProvider);
      expect(updatedState.status, equals(ResultStateStatus.success));
      expect(updatedState.analytics, isNotNull);
      expect(
          updatedState.analytics!.quizResult.quizId, equals('session_test_1'));
      expect(updatedState.analytics!.scoreMetrics.percentage, equals(76.7));
    });
  });
}
