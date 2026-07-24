import 'package:test/test.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

void main() {
  group('QuizTimerService Tests', () {
    const timerService = QuizTimerService();

    test('calculateElapsedTime returns zero when session is not started', () {
      final session = QuizSession(
        sessionId: 's1',
        quizId: 'q1',
        startedAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        status: QuizSessionStatus.notStarted,
      );

      expect(timerService.calculateElapsedTime(session), equals(Duration.zero));
    });

    test('calculateElapsedTime accumulates time when inProgress', () {
      final startTime = DateTime(2026, 1, 1, 10, 0, 0);
      final lastUpdate = DateTime(2026, 1, 1, 10, 0, 0);
      final currentTime = DateTime(2026, 1, 1, 10, 5, 0);

      final session = QuizSession(
        sessionId: 's1',
        quizId: 'q1',
        startedAt: startTime,
        lastUpdatedAt: lastUpdate,
        status: QuizSessionStatus.inProgress,
        elapsedTime: const Duration(minutes: 2),
      );

      final elapsed =
          timerService.calculateElapsedTime(session, now: currentTime);
      expect(elapsed, equals(const Duration(minutes: 7)));
    });

    test('calculateRemainingTime and isExpired check limit bounds', () {
      final startTime = DateTime(2026, 1, 1, 10, 0, 0);

      final session = QuizSession(
        sessionId: 's1',
        quizId: 'q1',
        startedAt: startTime,
        lastUpdatedAt: startTime,
        status: QuizSessionStatus.inProgress,
        elapsedTime: const Duration(minutes: 10),
        configuration:
            const SessionConfiguration(timeLimit: Duration(minutes: 15)),
      );

      expect(timerService.calculateRemainingTime(session, now: startTime),
          equals(const Duration(minutes: 5)));
      expect(timerService.isExpired(session, now: startTime), isFalse);

      final expiredNow = startTime.add(const Duration(minutes: 6));
      expect(timerService.calculateRemainingTime(session, now: expiredNow),
          equals(Duration.zero));
      expect(timerService.isExpired(session, now: expiredNow), isTrue);
    });

    test(
        'updateSessionTimer updates status to expired when time limit exceeded',
        () {
      final startTime = DateTime(2026, 1, 1, 10, 0, 0);
      final session = QuizSession(
        sessionId: 's1',
        quizId: 'q1',
        startedAt: startTime,
        lastUpdatedAt: startTime,
        status: QuizSessionStatus.inProgress,
        elapsedTime: const Duration(minutes: 14),
        configuration:
            const SessionConfiguration(timeLimit: Duration(minutes: 15)),
      );

      final updated = timerService.updateSessionTimer(
        session,
        tickDuration: const Duration(minutes: 2),
        now: startTime,
      );

      expect(updated.status, equals(QuizSessionStatus.expired));
      expect(updated.remainingTime, equals(Duration.zero));
    });
  });
}
