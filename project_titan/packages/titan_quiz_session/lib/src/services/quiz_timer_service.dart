import '../enums/quiz_session_status.dart';
import '../models/quiz_session.dart';

/// Service managing timing calculations, countdowns, and expiry detection for quiz sessions.
class QuizTimerService {
  const QuizTimerService();

  /// Calculates current total elapsed time since session start or last update.
  Duration calculateElapsedTime(QuizSession session, {DateTime? now}) {
    if (session.status == QuizSessionStatus.notStarted) {
      return Duration.zero;
    }
    if (session.status == QuizSessionStatus.paused ||
        session.status.isTerminal) {
      return session.elapsedTime;
    }
    final currentTime = now ?? DateTime.now();
    final additional = currentTime.difference(session.lastUpdatedAt);
    return session.elapsedTime +
        (additional.isNegative ? Duration.zero : additional);
  }

  /// Calculates remaining time if a time limit was configured in session.
  Duration? calculateRemainingTime(QuizSession session, {DateTime? now}) {
    final limit = session.configuration.timeLimit;
    if (limit == null) return null;

    final elapsed = calculateElapsedTime(session, now: now);
    final remaining = limit - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Evaluates whether the quiz session time limit has expired.
  bool isExpired(QuizSession session, {DateTime? now}) {
    final limit = session.configuration.timeLimit;
    if (limit == null) return false;

    final elapsed = calculateElapsedTime(session, now: now);
    return elapsed >= limit;
  }

  /// Updates a [QuizSession] with new timer state, setting status to [QuizSessionStatus.expired] if time limit is reached.
  QuizSession updateSessionTimer(QuizSession session,
      {Duration? tickDuration, DateTime? now}) {
    if (!session.status.isActive) return session;

    final currentNow = now ?? DateTime.now();
    final newElapsed = tickDuration != null
        ? session.elapsedTime + tickDuration
        : calculateElapsedTime(session, now: currentNow);

    final limit = session.configuration.timeLimit;
    Duration? newRemaining;
    var newStatus = session.status;

    if (limit != null) {
      final rem = limit - newElapsed;
      if (rem <= Duration.zero) {
        newRemaining = Duration.zero;
        newStatus = QuizSessionStatus.expired;
      } else {
        newRemaining = rem;
      }
    }

    return session.copyWith(
      elapsedTime: newElapsed,
      remainingTime: newRemaining,
      status: newStatus,
      lastUpdatedAt: currentNow,
    );
  }
}
