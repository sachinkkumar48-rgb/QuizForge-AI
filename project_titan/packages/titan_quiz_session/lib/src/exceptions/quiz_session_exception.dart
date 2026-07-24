import 'package:titan_domain/titan_domain.dart';

/// Base exception for all quiz session domain errors.
abstract class QuizSessionException extends RepositoryException {
  const QuizSessionException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when an action is attempted in an invalid or non-allowed session state.
class SessionStateException extends QuizSessionException {
  const SessionStateException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when timer calculations or operations encounter errors or expiry.
class TimerException extends QuizSessionException {
  const TimerException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when question navigation or progress bounds are violated.
class ProgressException extends QuizSessionException {
  const ProgressException(super.message, [super.cause, super.stackTrace]);
}
