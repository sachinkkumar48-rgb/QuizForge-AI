import 'package:titan_domain/titan_domain.dart';

/// Base exception class for all AI quiz generation pipeline failures in Project TITAN.
abstract class QuizGenerationException extends RepositoryException {
  const QuizGenerationException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when building AI prompt templates or formatting parameters fails.
class PromptException extends QuizGenerationException {
  const PromptException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when AI-generated JSON response fails schema validation rules.
class JsonValidationException extends QuizGenerationException {
  final List<String> validationErrors;

  JsonValidationException(
    String message, {
    List<String>? validationErrors,
    Object? cause,
    StackTrace? stackTrace,
  })  : validationErrors =
            List<String>.unmodifiable(validationErrors ?? const []),
        super(message, cause, stackTrace);
}

/// Thrown when parsing AI JSON string or decoding maps into Quiz domain models fails.
class JsonParsingException extends QuizGenerationException {
  const JsonParsingException(super.message, [super.cause, super.stackTrace]);
}
