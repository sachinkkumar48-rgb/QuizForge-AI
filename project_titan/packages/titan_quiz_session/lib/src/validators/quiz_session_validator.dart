import 'package:titan_quiz/titan_quiz.dart';
import '../enums/quiz_session_status.dart';
import '../exceptions/quiz_session_exception.dart';
import '../models/quiz_session.dart';

/// Validator enforcing domain invariants and integrity rules for quiz sessions.
class QuizSessionValidator {
  const QuizSessionValidator();

  /// Validates basic structural non-nullability and identifier presence.
  void validateSession(QuizSession session) {
    if (session.sessionId.trim().isEmpty) {
      throw const SessionStateException('Session ID cannot be empty.');
    }
    if (session.quizId.trim().isEmpty) {
      throw const SessionStateException('Quiz ID cannot be empty.');
    }
  }

  /// Ensures that [index] falls within valid question bounds for [totalQuestions].
  void validateQuestionIndex(
      QuizSession session, int index, int totalQuestions) {
    if (totalQuestions <= 0) {
      throw const ProgressException(
          'Total questions count must be greater than zero.');
    }
    if (index < 0 || index >= totalQuestions) {
      throw ProgressException(
        'Target question index ($index) is out of bounds for quiz with $totalQuestions questions.',
      );
    }
  }

  /// Enforces that the session is in [QuizSessionStatus.inProgress] for mutation actions.
  void validateActiveState(QuizSession session) {
    if (session.status.isTerminal) {
      throw SessionStateException(
        'Cannot modify session in terminal state "${session.status.name}".',
      );
    }
    if (session.status == QuizSessionStatus.paused) {
      throw const SessionStateException(
          'Cannot perform active operations while session is paused.');
    }
    if (session.status == QuizSessionStatus.notStarted) {
      throw const SessionStateException('Session has not been started yet.');
    }
  }

  /// Verifies that answering/modifying question attempts is permitted under session status and config.
  void validateAnsweringAllowed(QuizSession session) {
    validateActiveState(session);
  }

  /// Verifies completion prerequisites (e.g. valid active state or timer status).
  void validateCompletionAllowed(QuizSession session) {
    if (session.status == QuizSessionStatus.completed) {
      throw const SessionStateException('Session is already completed.');
    }
    if (session.status == QuizSessionStatus.abandoned) {
      throw const SessionStateException(
          'Cannot complete an abandoned session.');
    }
  }

  /// Verifies question attempts do not contain duplicate entries for the same questionId.
  void validateNoDuplicateAnswers(QuizSession session) {
    final seen = <String>{};
    for (final attempt in session.answers) {
      if (seen.contains(attempt.questionId)) {
        throw SessionStateException(
          'Duplicate QuestionAttempt found for questionId [${attempt.questionId}].',
        );
      }
      seen.add(attempt.questionId);
    }
  }

  /// Validates session consistency against the underlying [quiz] domain model.
  void validateSessionAgainstQuiz(QuizSession session, Quiz quiz) {
    validateSession(session);
    if (session.quizId != quiz.id) {
      throw SessionStateException(
        'Session quizId [${session.quizId}] does not match provided quiz.id [${quiz.id}].',
      );
    }
    validateNoDuplicateAnswers(session);
  }
}
