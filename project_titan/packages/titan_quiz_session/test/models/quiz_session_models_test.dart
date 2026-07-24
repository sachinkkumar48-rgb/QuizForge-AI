import 'package:test/test.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

void main() {
  group('Quiz Session Models & Enums Tests', () {
    test('QuizSessionStatus enum getters work correctly', () {
      expect(QuizSessionStatus.notStarted.isActive, isFalse);
      expect(QuizSessionStatus.inProgress.isActive, isTrue);
      expect(QuizSessionStatus.paused.isActive, isFalse);
      expect(QuizSessionStatus.completed.isTerminal, isTrue);
      expect(QuizSessionStatus.expired.isTerminal, isTrue);
      expect(QuizSessionStatus.abandoned.isTerminal, isTrue);
    });

    test('QuestionAttempt equality, hashCode, and copyWith', () {
      final attempt1 = QuestionAttempt(
        questionId: 'q1',
        selectedOptionId: 'opt1',
        isAnswered: true,
        timeSpent: const Duration(seconds: 15),
      );

      final attempt2 = attempt1.copyWith();
      expect(attempt1, equals(attempt2));
      expect(attempt1.hashCode, equals(attempt2.hashCode));

      final attempt3 = attempt1.copyWith(selectedOptionId: 'opt2');
      expect(attempt1, isNot(equals(attempt3)));
    });

    test('SessionConfiguration immutability and copyWith', () {
      const config = SessionConfiguration(
        allowReview: true,
        allowSkip: false,
        timeLimit: Duration(minutes: 30),
      );

      final updated = config.copyWith(allowSkip: true);
      expect(updated.allowSkip, isTrue);
      expect(updated.timeLimit, equals(const Duration(minutes: 30)));
    });

    test('QuizSession copyWith updates properties correctly', () {
      final now = DateTime.now();
      final session = QuizSession(
        sessionId: 's1',
        quizId: 'q1',
        startedAt: now,
        lastUpdatedAt: now,
        status: QuizSessionStatus.notStarted,
      );

      final started = session.copyWith(status: QuizSessionStatus.inProgress);
      expect(started.status, equals(QuizSessionStatus.inProgress));
      expect(started.sessionId, equals('s1'));
    });
  });
}
