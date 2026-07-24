import 'package:titan_domain/titan_domain.dart';

/// Base exception class for all Quiz domain operations in Project TITAN.
abstract class QuizException extends RepositoryException {
  const QuizException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when a Quiz document fails validation rules.
class QuizValidationException extends QuizException {
  final List<String> validationErrors;

  QuizValidationException(
    String message, {
    List<String>? validationErrors,
    Object? cause,
    StackTrace? stackTrace,
  })  : validationErrors =
            List<String>.unmodifiable(validationErrors ?? const []),
        super(message, cause, stackTrace);
}

/// Thrown when quiz scoring or evaluation fails.
class QuizScoringException extends QuizException {
  const QuizScoringException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when a Quiz repository operation fails.
class QuizRepositoryException extends QuizException {
  const QuizRepositoryException(super.message, [super.cause, super.stackTrace]);
}
