import 'package:test/test.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

void main() {
  group('QuizSessionValidator Tests', () {
    const validator = QuizSessionValidator();

    test('validateSession throws when sessionId or quizId is empty', () {
      final badSession = QuizSession(
        sessionId: '  ',
        quizId: 'q1',
        startedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      expect(
        () => validator.validateSession(badSession),
        throwsA(isA<SessionStateException>()),
      );
    });

    test(
        'validateQuestionIndex throws ProgressException for out-of-bound indices',
        () {
      final session = QuizSession(
        sessionId: 's1',
        quizId: 'q1',
        startedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      expect(
        () => validator.validateQuestionIndex(session, -1, 5),
        throwsA(isA<ProgressException>()),
      );
      expect(
        () => validator.validateQuestionIndex(session, 5, 5),
        throwsA(isA<ProgressException>()),
      );
      expect(
        () => validator.validateQuestionIndex(session, 2, 5),
        returnsNormally,
      );
    });

    test('validateActiveState rejects operations when paused or terminal', () {
      final now = DateTime.now();
      final pausedSession = QuizSession(
        sessionId: 's1',
        quizId: 'q1',
        startedAt: now,
        lastUpdatedAt: now,
        status: QuizSessionStatus.paused,
      );

      expect(
        () => validator.validateActiveState(pausedSession),
        throwsA(isA<SessionStateException>()),
      );

      final completedSession =
          pausedSession.copyWith(status: QuizSessionStatus.completed);
      expect(
        () => validator.validateActiveState(completedSession),
        throwsA(isA<SessionStateException>()),
      );
    });
  });
}
